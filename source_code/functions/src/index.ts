import { onUserDeleted } from 'firebase-functions/v2/auth';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import * as nodemailer from 'nodemailer';
import * as crypto from 'crypto';

initializeApp();

const db = getFirestore();
const auth = getAuth();

// ---------------------------------------------------------------------------
// Nodemailer transporter – configure SMTP via Firebase Functions environment
// variables.  At minimum you must set:
//
//   SMTP_HOST (e.g. "smtp.gmail.com")
//   SMTP_PORT (e.g. 587)
//   SMTP_USER (your SMTP login)
//   SMTP_PASS (your SMTP password / Gmail App Password)
//   SMTP_FROM (the "From" address shown in the email)
//
// Set them with:
//   firebase functions:config:set smtp.host="..." smtp.port="587" ...
// ---------------------------------------------------------------------------
function createTransporter() {
  const config = process.env;
  const host = config.SMTP_HOST || 'smtp.gmail.com';
  const port = parseInt(config.SMTP_PORT || '587', 10);
  const user = config.SMTP_USER || '';
  const pass = config.SMTP_PASS || '';
  const from = config.SMTP_FROM || 'noreply@todo-app-6828d.firebaseapp.com';

  const transporter = nodemailer.createTransport({
    host,
    port,
    secure: port === 465,
    auth: user && pass ? { user, pass } : undefined,
  });

  return { transporter, from };
}

async function getTransporter() {
  // Try Firebase Functions config first, then fall back to env vars
  try {
    const fnConfig = require('firebase-functions').config();
    const smtp = fnConfig?.smtp;
    if (smtp?.host && smtp?.user && smtp?.pass) {
      const transporter = nodemailer.createTransport({
        host: smtp.host,
        port: parseInt(smtp.port || '587', 10),
        secure: smtp.port === '465',
        auth: { user: smtp.user, pass: smtp.pass },
      });
      return { transporter, from: smtp.from || 'noreply@todo-app-6828d.firebaseapp.com' };
    }
  } catch (_) {
    // No Firebase Functions config – fall through to env vars
  }

  return createTransporter();
}

// ---------------------------------------------------------------------------
// initiateSignUp – stores pending data, sends verification email
// ---------------------------------------------------------------------------
export const initiateSignUp = onCall(async (request) => {
  const { name, email, password } = request.data;

  if (!name || !email || !password) {
    throw new HttpsError('invalid-argument', 'Name, email, and password are required');
  }

  const normalizedEmail = String(email).trim().toLowerCase();

  // Check email not already taken
  try {
    await auth.getUserByEmail(normalizedEmail);
    throw new HttpsError('already-exists', 'An account with this email already exists.');
  } catch (error: any) {
    if (error instanceof HttpsError) throw error;
    // "auth/user-not-found" means we can proceed
  }

  // Generate unique token
  const token = crypto.randomUUID();

  // Store pending user data (expires in 1 hour)
  await db.collection('pendingUsers').doc(token).set({
    name: String(name).trim(),
    email: normalizedEmail,
    password: password,
    createdAt: FieldValue.serverTimestamp(),
    expiresAt: new Date(Date.now() + 60 * 60 * 1000), // 1 hour
  });

  // Send verification email
  const verificationUrl = `https://todo-app-6828d.firebaseapp.com/verify?token=${token}`;
  const { transporter, from } = await getTransporter();

  try {
    await transporter.sendMail({
      from,
      to: normalizedEmail,
      subject: 'Verify your email for Tasks',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;">
          <h2>Welcome to Tasks!</h2>
          <p>Hi ${String(name).trim()},</p>
          <p>Click the button below to verify your email address and create your account:</p>
          <div style="text-align: center; margin: 32px 0;">
            <a href="${verificationUrl}"
               style="background-color: #0077B6; color: white; padding: 14px 36px;
                      text-decoration: none; border-radius: 8px; font-size: 16px;
                      display: inline-block;">
              Verify Email &rarr;
            </a>
          </div>
          <p style="color: #666; font-size: 13px;">
            If you didn't request this, you can safely ignore this email.
          </p>
          <hr style="border: none; border-top: 1px solid #eee;" />
          <p style="color: #999; font-size: 12px;">
            Tasks &middot; ${verificationUrl}
          </p>
        </div>
      `,
    });
  } catch (emailError: any) {
    // Cleanup pending record if email fails
    await db.collection('pendingUsers').doc(token).delete();
    throw new HttpsError('internal', `Failed to send email: ${emailError.message}`);
  }

  return { success: true, token };
});

// ---------------------------------------------------------------------------
// completeSignUp – validates token, creates Auth user + Firestore doc
// ---------------------------------------------------------------------------
export const completeSignUp = onCall(async (request) => {
  const { token } = request.data;

  if (!token) {
    throw new HttpsError('invalid-argument', 'Token is required');
  }

  // Read pending record
  const pendingDoc = await db.collection('pendingUsers').doc(token).get();

  if (!pendingDoc.exists) {
    throw new HttpsError('not-found', 'Verification link is invalid or has already been used.');
  }

  const data = pendingDoc.data()!;
  const expiresAt = data.expiresAt?.toDate?.() ?? new Date(data.expiresAt as string);

  if (new Date() > expiresAt) {
    await db.collection('pendingUsers').doc(token).delete();
    throw new HttpsError('deadline-exceeded', 'Verification link has expired. Please sign up again.');
  }

  const { name, email, password } = data as {
    name: string;
    email: string;
    password: string;
  };

  // Create Firebase Auth user
  let uid: string;
  try {
    const userRecord = await auth.createUser({
      email,
      password,
      displayName: name,
      emailVerified: true, // Email was verified by clicking the link
    });
    uid = userRecord.uid;
  } catch (createError: any) {
    await db.collection('pendingUsers').doc(token).delete();
    throw new HttpsError('internal', `Failed to create account: ${createError.message}`);
  }

  // Create Firestore user document
  try {
    await db.collection('users').doc(uid).set({
      name,
      email,
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (firestoreError: any) {
    // Non-critical – auth user already exists
    console.error('Failed to create Firestore doc:', firestoreError);
  }

  // Delete pending record
  await db.collection('pendingUsers').doc(token).delete();

  return { success: true };
});

// ---------------------------------------------------------------------------
// cleanupExpiredPending – runs every hour, removes expired pending sign-ups
// ---------------------------------------------------------------------------
export const cleanupExpiredPending = onSchedule(
  { schedule: 'every 1 hours', timeZone: 'UTC' },
  async () => {
    const cutoff = new Date(Date.now() - 60 * 60 * 1000);
    const expired = await db
      .collection('pendingUsers')
      .where('createdAt', '<', cutoff)
      .get();

    const batch = db.batch();
    expired.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();

    console.log(`Cleaned up ${expired.size} expired pending sign-ups.`);
  },
);

// ---------------------------------------------------------------------------
// cleanupUnverifiedAccounts – runs every 24 hours, deletes unverified auth
// accounts older than 24 hours (safety net for any edge cases)
// ---------------------------------------------------------------------------
export const cleanupUnverifiedAccounts = onSchedule(
  { schedule: 'every 24 hours', timeZone: 'UTC' },
  async () => {
    const now = Date.now();
    const MAX_AGE_MS = 24 * 60 * 60 * 1000;
    const BATCH_SIZE = 100;

    let pageToken: string | undefined;
    let totalDeleted = 0;

    do {
      const listResult = await auth.listUsers(BATCH_SIZE, pageToken);
      pageToken = listResult.pageToken;

      for (const userRecord of listResult.users) {
        if (userRecord.emailVerified) continue;

        const createdAt = userRecord.metadata.creationTime;
        if (!createdAt) continue;

        if (now - createdAt.getTime() < MAX_AGE_MS) continue;

        try {
          await auth.deleteUser(userRecord.uid);
          totalDeleted++;
        } catch (err) {
          console.error(`Failed to delete unverified user ${userRecord.uid}:`, err);
        }
      }
    } while (pageToken);

    console.log(`Cleanup complete. Deleted ${totalDeleted} unverified accounts.`);
  },
);

// ---------------------------------------------------------------------------
// deleteUserData – safety net: cleans up Firestore when an Auth user is deleted
// ---------------------------------------------------------------------------
export const deleteUserData = onUserDeleted(async (event) => {
  const uid = event.data.uid;
  const userRef = db.collection('users').doc(uid);
  const tasksRef = userRef.collection('tasks');

  const tasksSnapshot = await tasksRef.get();
  const batch = db.batch();

  tasksSnapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  batch.delete(userRef);
  await batch.commit();
});
