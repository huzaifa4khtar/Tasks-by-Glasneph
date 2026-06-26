import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants.dart';
import '../providers/services_provider.dart';
import '../widgets/info_box.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  late Timer _verificationCheckTimer;
  bool _isResending = false;
  bool _isCancelling = false;

  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: AppDurations.veryLong,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _startVerificationCheck();
  }

  @override
  void dispose() {
    _verificationCheckTimer.cancel();
    _floatController.dispose();
    super.dispose();
  }

  void _startVerificationCheck() {
    _verificationCheckTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) async {
        final isVerified =
            await ref.read(authServiceProvider).isEmailVerified();
        if (isVerified && mounted) {
          _verificationCheckTimer.cancel();
          await ref.read(authServiceProvider).finalizeSignUp();
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen(email: '')),
            (route) => false,
          );
        }
      },
    );
  }

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);
    try {
      await ref.read(authServiceProvider).resendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent. Check your inbox.'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(ref.read(authServiceProvider).readableAuthError(e)),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _cleanupAndGo(Widget destination) async {
    _verificationCheckTimer.cancel();
    setState(() => _isCancelling = true);

    try {
      await ref.read(authServiceProvider).deleteCurrentUserAccount();
    } catch (_) {}

    if (!mounted) return;
    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  void _onGoBack() {
    _cleanupAndGo(const SignupScreen());
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'your email';

    final screenWidth = MediaQuery.of(context).size.width;
    final titleSize = (screenWidth * 0.085).clamp(22.0, 32.0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onGoBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.containerPadding,
                      vertical: 20,
                    ),
                    child: ClipRRect(
                      borderRadius: AppRadius.radiusXxl,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          constraints: const BoxConstraints(
                            maxWidth: AppComponentSizes.glassCardMaxWidth,
                          ),
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          decoration: BoxDecoration(
                            color: AppColors.glassWhite,
                            borderRadius: AppRadius.radiusXl,
                            border: Border.all(
                              color: AppColors.surface.withValues(alpha: 0.4),
                            ),
                            boxShadow: [
                              AppShadows.glassCard,
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedBuilder(
                                animation: _floatAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, _floatAnimation.value),
                                    child: child,
                                  );
                                },
                                child: Container(
                                  width: AppComponentSizes.envelopeSize,
                                  height: AppComponentSizes.envelopeSize,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.surface,
                                        AppColors.primaryContainer,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      AppShadows.envelope,
                                      BoxShadow(
                                        blurRadius: 8,
                                        offset: const Offset(0, -4),
                                        color: AppColors.primaryAlpha(0.10),
                                        blurStyle: BlurStyle.inner,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.mail_rounded,
                                    size: 48,
                                    color: AppColors.primaryDark.withValues(
                                      alpha: 0.9,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Text(
                                'Check Your Email',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: AppTextStyles.headlineLg.copyWith(
                                  fontSize: titleSize,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              const Padding(
                                padding: AppSpacing.horizontalLg,
                                child: Text(
                                  "We've sent a verification link to your secure inbox.",
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyMd,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.containerPadding,
                                  vertical: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryAlpha(0.10),
                                  border: Border.all(
                                    color: AppColors.primaryAlpha(0.20),
                                  ),
                                  borderRadius: AppRadius.radiusPill,
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Text(
                                    email,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const InfoBox(
                              text: 'If the email isn\'t in your primary inbox, please check your spam or junk folder. If you still don\'t see it, the new email may already be linked to another account. Try a different email.',
                            ),
                              const SizedBox(height: AppSpacing.xl),
                              const SizedBox(
                                width: AppSpacing.xl,
                                height: AppSpacing.xl,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryDark,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              const Text(
                                'CHECKING VERIFICATION STATUS...',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.labelSm,
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isResending ? null : _resendEmail,
                                  icon: _isResending
                                      ? const SizedBox(
                                          width: AppIconSizes.sm,
                                          height: AppIconSizes.sm,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              AppColors.onPrimary,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.forward_to_inbox_rounded,
                                          size: AppIconSizes.md,
                                        ),
                                  label: Text(
                                    _isResending
                                        ? 'Sending...'
                                        : 'Resend Verification Email',
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryDark,
                                    foregroundColor: AppColors.onPrimary,
                                    disabledBackgroundColor:
                                        AppColors.primaryDark.withValues(
                                      alpha: 0.7,
                                    ),
                                    disabledForegroundColor:
                                        AppColors.onPrimary.withValues(
                                      alpha: 0.7,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.md,
                                      horizontal: AppSpacing.containerPadding,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppRadius.radiusPill,
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _isCancelling ? null : _onGoBack,
                                  icon: _isCancelling
                                      ? const SizedBox(
                                          width: AppIconSizes.sm,
                                          height: AppIconSizes.sm,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              AppColors.primaryDark,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.close_rounded,
                                          size: AppIconSizes.md,
                                        ),
                                  label: Text(
                                    _isCancelling
                                        ? 'Cancelling...'
                                        : 'Cancel Sign In',
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: AppColors.surface,
                                    foregroundColor: AppColors.primaryDark,
                                    side: const BorderSide(
                                      color: AppColors.primaryDark,
                                      width: 1.5,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.md,
                                      horizontal: AppSpacing.containerPadding,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppRadius.radiusPill,
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
