import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants.dart';
import '../providers/services_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/password_rule.dart';
import 'reset_password_screen.dart';

class UpdatePasswordScreen extends ConsumerStatefulWidget {
  const UpdatePasswordScreen({super.key, required this.userEmail});

  final String userEmail;

  @override
  ConsumerState<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends ConsumerState<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String? _currentPasswordError;

  bool get _hasMinimumLength =>
      _newPasswordController.text.length >= 6 &&
      _newPasswordController.text.length <= 64;
  bool get _hasLowercaseLetter =>
      RegExp(r'[a-z]').hasMatch(_newPasswordController.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_newPasswordController.text);

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value, String fieldName) {
    if (value == null || value.isEmpty) return '$fieldName is required';
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) return 'New password is required';
    if (value == _currentPasswordController.text) {
      return 'New password must be different from current password';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _newPasswordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isSubmitting = true; _currentPasswordError = null; });
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;

    try {
      await ref.read(authServiceProvider).reauthenticateWithEmail(widget.userEmail, currentPassword);
      await ref.read(authServiceProvider).updateCurrentUserPassword(newPassword);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        setState(() => _currentPasswordError = 'Invalid password');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(authServiceProvider).readableAuthError(e))),
        );
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
            Icon(Icons.lock_rounded, size: AppIconSizes.header, color: AppColors.primaryDark),
            const SizedBox(width: AppSpacing.md),
            Text('Update Password', style: AppTextStyles.headlineMd),
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
          TextFormField(
            controller: _currentPasswordController,
            obscureText: !_showCurrentPassword,
            validator: (value) => _validatePassword(value, 'Current password'),
            onChanged: (_) {
              if (_currentPasswordError != null) {
                setState(() => _currentPasswordError = null);
              }
            },
            style: AppTextStyles.bodyMd,
            decoration: _inputDecoration(
              hintText: 'Enter current password',
              prefixIcon: Icons.lock_outlined,
              suffixIcon: IconButton(
                icon: Icon(
                  _showCurrentPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.onSurfaceVariant,
                  size: AppIconSizes.md,
                ),
                onPressed: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
              ),
              errorText: _currentPasswordError,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ResetPasswordScreen(initialEmail: widget.userEmail),
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
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _newPasswordController,
            obscureText: !_showNewPassword,
            onChanged: (_) { if (mounted) setState(() {}); },
            validator: _validateNewPassword,
            style: AppTextStyles.bodyMd,
            decoration: _inputDecoration(
              hintText: 'Enter new password',
              prefixIcon: Icons.lock_outlined,
              suffixIcon: IconButton(
                icon: Icon(
                  _showNewPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.onSurfaceVariant,
                  size: AppIconSizes.md,
                ),
                onPressed: () => setState(() => _showNewPassword = !_showNewPassword),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          PasswordRule(
            text: '6-64 characters long',
            isMet: _hasMinimumLength,
          ),
          const SizedBox(height: 6),
          PasswordRule(
            text: 'At least one lowercase letter (a-z)',
            isMet: _hasLowercaseLetter,
          ),
          const SizedBox(height: 6),
          PasswordRule(
            text: 'At least one number (0-9)',
            isMet: _hasNumber,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_showConfirmPassword,
            validator: _validateConfirmPassword,
            style: AppTextStyles.bodyMd,
            decoration: _inputDecoration(
              hintText: 'Re-enter new password',
              prefixIcon: Icons.lock_outlined,
              suffixIcon: IconButton(
                icon: Icon(
                  _showConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.onSurfaceVariant,
                  size: AppIconSizes.md,
                ),
                onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
              ),
            ),
          ),
        ],
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
      errorMaxLines: 2,
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
      onTap: _isSubmitting ? null : _updatePassword,
      child: Container(
        width: double.infinity,
        height: AppComponentSizes.buttonHeight,
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: AppRadius.radiusPill,
          boxShadow: !_isSubmitting ? [AppShadows.primaryButton] : null,
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
              : const Text('Update Password', style: AppTextStyles.button),
        ),
      ),
    );
  }
}
