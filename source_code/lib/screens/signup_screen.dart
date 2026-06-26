import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants.dart';
import '../providers/services_provider.dart';
import '../widgets/auth_background.dart';
import '../widgets/glass_auth_text_field.dart';
import '../widgets/glass_card.dart';
import '../widgets/google_login_button.dart';
import '../widgets/password_rule.dart';
import 'email_verification_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  bool get _hasMinimumLength =>
      _passwordController.text.length >= 8 &&
      _passwordController.text.length <= 64;
  bool get _hasLowercaseLetter =>
      RegExp(r'[a-z]').hasMatch(_passwordController.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_passwordController.text);
  bool get _isPasswordPolicySatisfied =>
      _hasMinimumLength && _hasLowercaseLetter && _hasNumber;

  @override
  void initState() {
    super.initState();
    // Ensure password policy rules (3 items) turn green immediately per rule.
    _passwordController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8 || value.length > 64) {
      return '8-64 characters long';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'At least one lowercase letter (a-z)';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'At least one number (0-9)';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match, confirm again';
    }
    return null;
  }

  Future<void> _onSignupPressed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(authServiceProvider).signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      await Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(authServiceProvider).readableAuthError(e)),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _onGooglePressed() async {
    setState(() => _isSubmitting = true);

    try {
      final credential = await ref.read(authServiceProvider).signInWithGoogle();
      if (credential == null || !mounted) return;
      final fullName = credential.user?.displayName?.trim().isNotEmpty == true
          ? credential.user!.displayName!.trim()
          : (credential.user?.email?.trim() ?? 'User');

      await Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            email: credential.user?.email ?? '',
            loginMessageName: fullName,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(authServiceProvider).readableAuthError(e)),
          duration: const Duration(seconds: 5),
        ),
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
              'Create Account',
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
                    controller: _nameController,
                    label: '',
                    hint: 'Full name',
                    leadingIcon: const Icon(
                      Icons.person_outline,
                      color: AppColors.onSurfaceVariant,
                    ),
                    keyboardType: TextInputType.name,
                    obscureText: false,
                    enabled: !_isSubmitting,
                    validator: _validateName,
                    onToggleObscure: null,
                    hasLeftInsetGlow: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                    hasLeftInsetGlow: true,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Password
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
                    hasLeftInsetGlow: true,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Password requirements list
                  Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: PasswordRule(
                      text: '8-64 characters long',
                      isMet: _hasMinimumLength,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: PasswordRule(
                      text: 'At least one lowercase letter (a-z)',
                      isMet: _hasLowercaseLetter,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: PasswordRule(
                      text: 'At least one number (0-9)',
                      isMet: _hasNumber,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  GlassAuthTextField(
                    controller: _confirmPasswordController,
                    label: '',
                    hint: 'Confirm password',
                    leadingIcon: const Icon(
                      Icons.lock_clock_outlined,
                      color: AppColors.onSurfaceVariant,
                    ),
                    keyboardType: TextInputType.text,
                    obscureText: _obscureConfirmPassword,
                    enabled: !_isSubmitting,
                    validator: _validateConfirmPassword,
                    onToggleObscure: () {
                      setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword,
                      );
                    },
                    hasLeftInsetGlow: true,
                  ),
                  const SizedBox(height: 30),

                  GestureDetector(
                    onTap: (_isSubmitting || !_isPasswordPolicySatisfied)
                        ? null
                        : _onSignupPressed,
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
                            : Text('Sign up', style: AppTextStyles.button),
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
                      Padding(
                        padding: AppSpacing.horizontalMd,
                        child: const Text(
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
                          const TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Login',
                            style: AppTextStyles.link,
                            recognizer: TapGestureRecognizer()
                              ..onTap = _isSubmitting
                                  ? null
                                  : () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const LoginScreen(),
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
