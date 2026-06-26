import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import 'services_provider.dart';

final authMaintenanceProvider = Provider<AuthMaintenance>((ref) {
  return AuthMaintenance(ref.read(authServiceProvider));
});

class AuthMaintenance {
  final AuthService _authService;
  AuthMaintenance(this._authService);

  AuthService get authService => _authService;

  Future<void> run() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.emailVerified) {
        await _authService.ensureCurrentUserDocument();
        await _authService.finalizeSignUp();
      }
      await _authService.refreshAndSyncCurrentUserEmail();
      return;
    }
    if (_authService.hasEmailChangeRecoverySession) {
      await _authService.tryRecoverEmailChangeSession();
    }
  }

  bool get shouldHoldForRecovery =>
      FirebaseAuth.instance.currentUser == null &&
      _authService.hasEmailChangeRecoverySession;

  Future<void> refreshSignedInUser() async {
    try {
      await _authService.refreshAndSyncCurrentUserEmail();
    } catch (_) {}
  }
}
