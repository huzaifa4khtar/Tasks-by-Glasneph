import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'constants.dart';
import 'providers/auth_provider.dart';
import 'screens/email_verification_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'widgets/reminder_notification.dart';
import 'widgets/timer_notification.dart';

final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelGroupKey: 'session_group',
        channelKey: SessionNotification.channelKey,
        channelName: SessionNotification.channelName,
        channelDescription: SessionNotification.channelDesc,
        defaultColor: AppColors.primaryDark,
        importance: NotificationImportance.Default,
        playSound: false,
        enableVibration: false,
      ),
      NotificationChannel(
        channelGroupKey: 'session_group',
        channelKey: SessionNotification.completeChannelKey,
        channelName: SessionNotification.completeChannelName,
        channelDescription: SessionNotification.completeChannelDesc,
        defaultColor: AppColors.success,
        importance: NotificationImportance.High,
        playSound: true,
        enableVibration: true,
      ),
      NotificationChannel(
        channelGroupKey: 'reminder_group',
        channelKey: ReminderNotification.channelKey,
        channelName: ReminderNotification.channelName,
        channelDescription: ReminderNotification.channelDesc,
        defaultColor: AppColors.primaryDark,
        importance: NotificationImportance.High,
        playSound: true,
        enableVibration: true,
      ),
    ],
    channelGroups: [
      NotificationChannelGroup(
        channelGroupKey: 'session_group',
        channelGroupName: 'Sessions',
      ),
      NotificationChannelGroup(
        channelGroupKey: 'reminder_group',
        channelGroupName: 'Reminders',
      ),
    ],
    debug: false,
  );

  // NOTE: awesome_notifications only supports ONE setListeners call globally.
  // All notification actions (session timer + task reminders) must route through
  // SessionNotification.onActionReceived. Do NOT add another setListeners call.
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: SessionNotification.onActionReceived,
  );

  await SessionNotification.initialize();
  await ReminderNotification.initialize();
  await ReminderNotification.ensurePermissions();

  await GoogleSignIn.instance.initialize();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: MaterialApp(
        title: 'Tasks',
        debugShowCheckedModeBanner: false,
        navigatorKey: appNavigatorKey,
        scaffoldMessengerKey: appScaffoldMessengerKey,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color(0xFF0077B6),
            brightness: Brightness.light,
          ),
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: Color(0xFF0077B6),
            selectionColor: Color(0xFF94CCFF),
            selectionHandleColor: Color(0xFF0077B6),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> with WidgetsBindingObserver {
  late final AuthMaintenance _authMaintenance;
  StreamSubscription<User?>? _authSubscription;
  Timer? _pendingEmailSyncTimer;
  String? _lastObservedEmail;
  bool _didSeedObservedEmail = false;
  bool _isRunningMaintenance = false;
  bool _wasLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _authMaintenance = ref.read(authMaintenanceProvider);
    WidgetsBinding.instance.addObserver(this);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _wasLoggedIn = true;
    }

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        if (_authMaintenance.authService.hasEmailChangeRecoverySession) {
          _runAuthMaintenance();
        } else if (_wasLoggedIn) {
          _wasLoggedIn = false;
          _navigateToLogin();
        }
      } else {
        _wasLoggedIn = true;
      }
      _syncPendingEmailTimerState();
    });

    _runAuthMaintenance();
    _syncPendingEmailTimerState();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    SessionNotification.onReminderAction = (ReceivedAction received) {
      if (!mounted) return;

      final payload = received.payload;
      if (payload == null) return;

      final taskId = payload['taskId'];
      if (taskId == null) return;

      final buttonKey = received.buttonKeyPressed;
      final openEdit = buttonKey == ReminderNotification.actionReschedule;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              highlightTaskId: taskId,
              openEditSheet: openEdit,
            ),
          ),
          (route) => route.isFirst,
        );
      });
    };
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runAuthMaintenance();
    }
  }

  Future<void> _runAuthMaintenance() async {
    if (!mounted || _isRunningMaintenance) return;
    _isRunningMaintenance = true;
    try {
      await _authMaintenance.run();
    } finally {
      _isRunningMaintenance = false;
      _syncPendingEmailTimerState();
    }
  }

  void _navigateToLogin() {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _syncPendingEmailTimerState() {
    final shouldRun = _authMaintenance.authService.hasEmailChangeRecoverySession;
    if (!shouldRun) {
      _pendingEmailSyncTimer?.cancel();
      _pendingEmailSyncTimer = null;
      return;
    }
    if (_pendingEmailSyncTimer != null) return;
    _pendingEmailSyncTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      _runAuthMaintenance();
    });
  }

  @override
  void dispose() {
    SessionNotification.onReminderAction = null;
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _pendingEmailSyncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;

          final currentEmail = user.email?.trim();
          if (!_didSeedObservedEmail) {
            _lastObservedEmail = currentEmail;
            _didSeedObservedEmail = true;
          } else if (currentEmail != null &&
              currentEmail.isNotEmpty &&
              _lastObservedEmail != null &&
              currentEmail.toLowerCase() != _lastObservedEmail!.toLowerCase()) {
            _lastObservedEmail = currentEmail;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              appScaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(
                  content: Text('Email updated successfully to $currentEmail'),
                ),
              );
            });
          } else {
            _lastObservedEmail = currentEmail;
          }

          if (!user.emailVerified) {
            return const EmailVerificationScreen();
          }
          return HomeScreen(email: user.email ?? '');
        }

        if (_authMaintenance.shouldHoldForRecovery) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Restoring session after email verification...'),
                ],
              ),
            ),
          );
        }

        return const SignupScreen();
      },
    );
  }
}
