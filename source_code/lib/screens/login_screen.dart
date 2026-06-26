import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants.dart';
import '../providers/services_provider.dart';
import '../widgets/auth_background.dart';
import '../widgets/glass_auth_text_field.dart';
import '../widgets/glass_card.dart';
import '../widgets/google_login_button.dart';

import 'home_screen.dart';
import 'reset_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const String _genericCredentialError = 'Invalid email or password.';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _emailAuthError;
  String? _passwordAuthError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    if (_emailAuthError != null) {
      return _emailAuthError;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (_passwordAuthError != null) {
      return _passwordAuthError;
    }
    return null;
  }

  void _clearCredentials() {
    _emailController.clear();
    _passwordController.clear();
    _formKey.currentState?.reset();
    setState(() {
      _obscurePassword = true;
      _emailAuthError = null;
      _passwordAuthError = null;
    });
  }

  Future<void> _onLoginPressed() async {
    setState(() {
      _emailAuthError = null;
      _passwordAuthError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final credential = await ref.read(authServiceProvider).login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final fullName = credential.user?.displayName?.trim().isNotEmpty == true
          ? credential.user!.displayName!.trim()
          : (credential.user?.email?.trim() ?? 'User');

      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            email: credential.user?.email ?? _emailController.text.trim(),
            loginMessageName: fullName,
          ),
        ),
      );

      if (!mounted) return;
      _clearCredentials();
    } catch (e) {
      if (!mounted) return;

      if (e is FirebaseAuthException &&
          (e.code == 'invalid-credential' ||
              e.code == 'wrong-password' ||
              e.code == 'user-not-found' ||
              e.code == 'invalid-email')) {
        setState(() {
          _emailAuthError = _genericCredentialError;
          _passwordAuthError = _genericCredentialError;
        });
        _formKey.currentState?.validate();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(authServiceProvider).readableAuthError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _onGooglePressed() async {
    setState(() {
      _emailAuthError = null;
      _passwordAuthError = null;
      _isSubmitting = true;
    });

    try {
      final credential = await ref.read(authServiceProvider).signInWithGoogle();
      if (credential == null || !mounted) return;

      final fullName = credential.user?.displayName?.trim().isNotEmpty == true
          ? credential.user!.displayName!.trim()
          : (credential.user?.email?.trim() ?? 'User');

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            email: credential.user?.email ?? '',
            loginMessageName: fullName,
          ),
        ),
      );

      if (!mounted) return;
      _clearCredentials();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(authServiceProvider).readableAuthError(e))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: GlassCard(
        padding: const EdgeInsets.only(
          left: AppSpacing.containerPadding,
          right: AppSpacing.containerPadding,
          top: 36,
          bottom: 36,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome Back',
              textAlign: TextAlign.center,
              style: AppTextStyles.authTitle,
            ),
            const SizedBox(height: AppSpacing.xl),
            Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassAuthTextField(
                    controller: _emailController,
                    label: '',
                    hint: 'Email address',
                    leadingIcon: const Icon(
                      Icons.mail_outline,
                      color: AppColors.onSurfaceVariant,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    obscureText: false,
                    enabled: !_isSubmitting,
                    validator: _validateEmail,
                    onToggleObscure: null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  GlassAuthTextField(
                    controller: _passwordController,
                    label: '',
                    hint: 'Password',
                    leadingIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.onSurfaceVariant,
                    ),
                    keyboardType: TextInputType.text,
                    obscureText: _obscurePassword,
                    enabled: !_isSubmitting,
                    validator: _validatePassword,
                    onToggleObscure: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _isSubmitting
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ResetPasswordScreen(
                                    initialEmail: _emailController.text,
                                  ),
                                ),
                              );
                            },
                      child: const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          'Forgot Password?',
                          style: AppTextStyles.link,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  GestureDetector(
                    onTap: _isSubmitting ? null : _onLoginPressed,
                    child: Container(
                      width: double.infinity,
                      height: AppComponentSizes.buttonHeight,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: AppRadius.radiusPill,
                        boxShadow: [AppShadows.primaryButton],
                      ),
                      child: Center(
                        child: _isSubmitting
                            ? const SizedBox(
                                width: AppIconSizes.md,
                                height: AppIconSizes.md,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                                ),
                              )
                            : Text('Login', style: AppTextStyles.button),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: AppColors.outlineVariant.withValues(alpha: 0.6),
                          height: 1,
                          thickness: 1,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Text(
                          'OR',
                          style: AppTextStyles.orDivider,
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: AppColors.outlineVariant.withValues(alpha: 0.6),
                          height: 1,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  GoogleSignInButton(
                    onPressed: _isSubmitting ? null : _onGooglePressed,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodyLink,
                        children: [
                          const TextSpan(text: "Don't have an account? "),
                          TextSpan(
                            text: 'Sign Up',
                            style: AppTextStyles.link,
                            recognizer: TapGestureRecognizer()
                              ..onTap = _isSubmitting
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const SignupScreen(),
                                        ),
                                      );
                                    },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
