import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class _PendingEmailChangeSession {
  const _PendingEmailChangeSession({
    required this.currentEmail,
    required this.pendingEmail,
    required this.password,
    required this.expiresAt,
  });

  final String currentEmail;
  final String pendingEmail;
  final String password;
  final DateTime expiresAt;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static _PendingEmailChangeSession? _pendingEmailChangeSession;
  static const Duration _pendingSessionTtl = Duration(minutes: 30);

  // Stores pending display name across signUp → finalizeSignUp
  static String? _pendingName;

  bool get hasEmailChangeRecoverySession {
    final session = _pendingEmailChangeSession;
    if (session == null) return false;
    if (DateTime.now().isAfter(session.expiresAt)) {
      _pendingEmailChangeSession = null;
      return false;
    }
    return true;
  }

  void registerEmailChangeRecoverySession({
    required String currentEmail,
    required String pendingEmail,
    required String password,
  }) {
    _pendingEmailChangeSession = _PendingEmailChangeSession(
      currentEmail: currentEmail.trim(),
      pendingEmail: pendingEmail.trim(),
      password: password,
      expiresAt: DateTime.now().add(_pendingSessionTtl),
    );
  }

  void clearEmailChangeRecoverySession() {
    _pendingEmailChangeSession = null;
  }

  /// Creates the Firebase Auth account and sends a verification email.
  /// Firestore document is NOT created until [finalizeSignUp] is called.
  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Could not create account. Please try again.',
      );
    }

    try {
      _pendingName = name.trim();
      await user.sendEmailVerification();
      return credential;
    } on FirebaseException {
      try {
        await user.delete();
      } catch (_) {}
      await _auth.signOut();
      _pendingName = null;
      rethrow;
    }
  }

  /// Called after email is verified. Sets display name and creates
  /// the Firestore user document. Idempotent — safe to call multiple times.
  Future<void> finalizeSignUp() async {
    final user = _auth.currentUser;
    if (user == null || !user.emailVerified) return;

    // Check if already finalized
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) return;
    } catch (_) {}

    final name = _pendingName;
    final resolvedName =
        (name != null && name.trim().isNotEmpty) ? name.trim() : 'User';

    try {
      await user.updateDisplayName(resolvedName);
    } catch (_) {}

    await _ensureUserDocument(
      user,
      preferredName: resolvedName,
      preferredEmail: user.email,
    );

    await user.reload();
    _pendingName = null;
  }

  void clearPendingName() {
    _pendingName = null;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    UserCredential credential;
    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'user does not exist, try signing in',
        );
      }
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw FirebaseAuthException(
          code: 'wrong-password',
          message: 'Incorrect password.',
        );
      }
      rethrow;
    }

    final user = credential.user;
    if (user != null) {
      if (user.emailVerified) {
        await ensureCurrentUserDocument();
      } else {
        await user.sendEmailVerification();
      }
    }

    return credential;
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;
      final authz = await googleUser.authorizationClient.authorizeScopes(
        ['email'],
      );
      final authCredential = GoogleAuthProvider.credential(
        accessToken: authz.accessToken,
        idToken: googleAuth.idToken,
      );

      final credential = await _auth.signInWithCredential(authCredential);
      final user = credential.user;
      if (user != null) {
        await _ensureUserDocument(
          user,
          preferredName: user.displayName,
          preferredEmail: user.email,
        );
      }

      return credential;
    } catch (e) {
      if (e.toString().contains('cancelled') ||
          e.toString().contains('canceled')) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> _ensureUserDocument(
    User user, {
    String? preferredName,
    String? preferredEmail,
  }) async {
    final docRef = _firestore.collection('users').doc(user.uid);

    final resolvedName =
        (preferredName != null && preferredName.trim().isNotEmpty)
        ? preferredName.trim()
        : (user.displayName != null && user.displayName!.trim().isNotEmpty)
        ? user.displayName!.trim()
        : 'User';
    final resolvedEmail =
        (preferredEmail != null && preferredEmail.trim().isNotEmpty)
        ? preferredEmail.trim()
        : (user.email ?? '').trim();

    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.update({
        'name': resolvedName,
        'email': resolvedEmail,
      });
    } else {
      await docRef.set({
        'name': resolvedName,
        'email': resolvedEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> ensureCurrentUserDocument() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) return;
    } catch (_) {}
    await _ensureUserDocument(user);
  }

  Future<void> updateCurrentUserName(String name) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No signed-in user found.',
      );
    }

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-display-name',
        message: 'Name cannot be empty.',
      );
    }

    await user.updateDisplayName(trimmedName);
    await _ensureUserDocument(
      user,
      preferredName: trimmedName,
      preferredEmail: user.email,
    );
    await user.reload();
  }

  Future<void> updateUserProfile({
    required String name,
    required String avatar,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No signed-in user found.',
      );
    }

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-display-name',
        message: 'Name cannot be empty.',
      );
    }

    await user.updateDisplayName(trimmedName);
    await _firestore.collection('users').doc(user.uid).update({
      'name': trimmedName,
      'avatar': avatar,
    });
    await user.reload();
  }

  Future<void> incrementSessionsCompleted(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'sessionsCompleted': FieldValue.increment(1),
    });
  }

  Future<void> resendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return user.emailVerified;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userProfileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Future<void> signOut() async {
    clearEmailChangeRecoverySession();
    _pendingName = null;
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  String readableAuthError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Invalid email or password.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'user-not-found':
          return 'Invalid email or password.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Invalid email or password.';
        case 'email-already-in-use':
          return 'user already exists, try logging in';
        case 'weak-password':
          return 'Passwords must be 8-64 characters long and include at least one lowercase letter (a-z) and one number (0-9).';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with this email using a different sign-in method.';
        case 'missing-email':
          return 'Please enter your email address.';
        case 'invalid-display-name':
          return 'Please enter a valid full name.';
        case 'requires-recent-login':
          return 'Please re-enter your password to perform this action.';
        default:
          return error.message ?? 'Authentication failed.';
      }
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Firestore permissions blocked this action. Check and publish your Firestore rules.';
        case 'unavailable':
          return 'Could not reach Firestore. Please check your internet connection.';
        default:
          final message =
              error.message ?? 'A database error occurred. Please try again.';
          return 'Firestore error (${error.code}): $message';
      }
    }

    return 'Something went wrong. Please try again.';
  }

  String readableDataError(Object? error) {
    if (error == null) return 'Something went wrong. Please try again.';
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Access denied by Firestore rules. Ensure users can access users/{uid} and users/{uid}/tasks.';
        case 'unavailable':
          return 'Cloud Firestore is currently unreachable. Check your connection.';
        default:
          final message = error.message ?? 'A Firestore error occurred.';
          return 'Firestore error (${error.code}): $message';
      }
    }
    return error.toString();
  }

  Future<void> reauthenticateWithEmail(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No signed-in user found.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );

    await user.reauthenticateWithCredential(credential);
  }

  Future<void> sendEmailVerificationForNewEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No signed-in user found.',
      );
    }

    await user.verifyBeforeUpdateEmail(newEmail.trim());
  }

  Future<String?> refreshAndSyncCurrentUserEmail() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    await user.reload();
    final refreshedUser = _auth.currentUser;
    if (refreshedUser == null) return null;

    final refreshedEmail = refreshedUser.email?.trim();
    if (refreshedEmail == null || refreshedEmail.isEmpty) return null;

    await _firestore.collection('users').doc(refreshedUser.uid).set({
      'email': refreshedEmail,
    }, SetOptions(merge: true));

    if (hasEmailChangeRecoverySession) {
      final pendingEmail = _pendingEmailChangeSession!.pendingEmail;
      if (refreshedEmail.toLowerCase() == pendingEmail.toLowerCase()) {
        clearEmailChangeRecoverySession();
      }
    }

    return refreshedEmail;
  }

  Future<bool> tryRecoverEmailChangeSession() async {
    if (!hasEmailChangeRecoverySession) return false;

    if (_auth.currentUser != null) {
      try {
        await refreshAndSyncCurrentUserEmail();
      } catch (_) {}
      return true;
    }

    final session = _pendingEmailChangeSession!;
    final candidateEmails = <String>{
      session.pendingEmail,
      session.currentEmail,
    };

    for (final email in candidateEmails) {
      try {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: session.password,
        );
        await refreshAndSyncCurrentUserEmail();
        return true;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          clearEmailChangeRecoverySession();
          return false;
        }
      }
    }

    return false;
  }

  Future<void> updateCurrentUserPassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No signed-in user found.',
      );
    }

    await user.updatePassword(newPassword);
  }

  Future<void> deleteCurrentUserAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No signed-in user found.',
      );
    }

    final uid = user.uid;

    try {
      final tasksSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .get();
      for (final doc in tasksSnapshot.docs) {
        await doc.reference.delete();
      }

      await _firestore.collection('users').doc(uid).delete();
    } catch (_) {}

    await user.delete();
  }
}
