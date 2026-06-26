import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants.dart';
import '../providers/services_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/info_box.dart';
import 'reset_password_screen.dart';

class UpdateEmailScreen extends ConsumerStatefulWidget {
  const UpdateEmailScreen({super.key, required this.currentEmail});

  final String currentEmail;

  @override
  ConsumerState<UpdateEmailScreen> createState() => _UpdateEmailScreenState();
}

class _UpdateEmailScreenState extends ConsumerState<UpdateEmailScreen> {
  static final RegExp _emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');

  final _formKey = GlobalKey<FormState>();
  final _newEmailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSubmitting = false;
  bool _showInfo = false;
  bool _showPassword = false;
  String? _passwordError;

  @override
  void dispose() {
    _newEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
    if (value.trim() == widget.currentEmail) return 'New email must be different from current email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  Future<void> _updateEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isSubmitting = true; _passwordError = null; });
    final newEmail = _newEmailController.text.trim();
    final password = _passwordController.text;

    try {
      await ref.read(authServiceProvider).reauthenticateWithEmail(widget.currentEmail, password);
      await ref.read(authServiceProvider).sendEmailVerificationForNewEmail(newEmail);
      ref.read(authServiceProvider).registerEmailChangeRecoverySession(
        currentEmail: widget.currentEmail,
        pendingEmail: newEmail,
        password: password,
      );
      if (!mounted) return;
      Navigator.pop(context, newEmail);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        setState(() => _passwordError = 'Invalid password');
      } else {
        String errorMessage = ref.read(authServiceProvider).readableAuthError(e);
        if (e.code == 'email-already-in-use') {
          errorMessage = 'This email is already associated with another account.';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.containerPadding,
                      AppSpacing.xl,
                      AppSpacing.containerPadding,
                      100,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildGlassCard(),
                          const SizedBox(height: AppSpacing.xl),
                          _buildSubmitButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.containerPadding,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: AppRadius.radiusMd,
        border: Border(bottom: BorderSide(color: AppColors.glassBorderLight)),
      ),
      child: SizedBox(
        height: AppComponentSizes.headerHeight,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.arrow_back_rounded, size: AppIconSizes.header, color: AppColors.primaryDark),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.email_rounded, size: AppIconSizes.header, color: AppColors.primaryDark),
            const SizedBox(width: AppSpacing.md),
            Text('Update Email', style: AppTextStyles.headlineMd),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _showInfo = !_showInfo),
              child: Icon(
                _showInfo ? Icons.info : Icons.info_outlined,
                size: AppIconSizes.header,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard() {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.containerPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_showInfo)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: AppRadius.radiusMd,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outlined, size: AppIconSizes.md, color: AppColors.primaryDark),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'After you click the email verification link, your account email updates automatically in the app.',
                      style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 13, color: AppColors.onSurface, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          _buildField(
            initialValue: widget.currentEmail,
            enabled: false,
            prefixIcon: Icons.email_outlined,
            label: 'Current Email',
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _newEmailController,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            enabled: !_isSubmitting,
            style: AppTextStyles.bodyMd,
            decoration: _inputDecoration(hintText: 'Enter new email', prefixIcon: Icons.email_outlined),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            validator: _validatePassword,
            onChanged: (_) {
              if (_passwordError != null) setState(() => _passwordError = null);
            },
            enabled: !_isSubmitting,
            style: AppTextStyles.bodyMd,
            decoration: _inputDecoration(
              hintText: 'Current password to confirm',
              prefixIcon: Icons.lock_outlined,
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.onSurfaceVariant,
                  size: AppIconSizes.md,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
              errorText: _passwordError,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResetPasswordScreen(initialEmail: widget.currentEmail),
                        ),
                      ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Forgot password?', style: AppTextStyles.link),
            ),
          ),
          const InfoBox(
            text: 'If you don\'t receive a verification email, the new email may already be linked to another account. Try a different email.',
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String initialValue,
    required bool enabled,
    required IconData prefixIcon,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.onSurfaceVariantVeryLow,
        borderRadius: AppRadius.radiusPill,
      ),
      child: TextFormField(
        initialValue: initialValue,
        enabled: enabled,
        style: AppTextStyles.bodyMd.copyWith(
          color: enabled ? AppColors.onSurface : AppColors.onSurfaceVariant,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(prefixIcon, size: AppIconSizes.md, color: AppColors.iconForm),
          labelText: label,
          labelStyle: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.outlineVariant),
      prefixIcon: Icon(prefixIcon, size: AppIconSizes.md, color: AppColors.iconForm),
      suffixIcon: suffixIcon,
      errorText: errorText,
      errorStyle: AppTextStyles.caption,
      filled: true,
      fillColor: AppColors.onSurfaceVariantVeryLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      border: OutlineInputBorder(
        borderRadius: AppRadius.radiusPill,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.radiusPill,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.radiusPill,
        borderSide: BorderSide(color: AppColors.primaryDark.withValues(alpha: 0.3)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.radiusPill,
        borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.radiusPill,
        borderSide: BorderSide(color: AppColors.error),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isSubmitting ? null : _updateEmail,
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
              : const Text('Send Verification Email', style: AppTextStyles.button),
        ),
      ),
    );
  }
}
