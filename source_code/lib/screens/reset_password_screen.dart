import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants.dart';
import '../providers/services_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/info_box.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  static final RegExp _emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail?.trim() ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final email = _emailController.text.trim();

    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email')),
        );
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
            Text('Reset Password', style: AppTextStyles.headlineMd),
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
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            enabled: widget.initialEmail == null,
            style: AppTextStyles.bodyMd,
            decoration: InputDecoration(
              hintText: 'Enter your email',
              hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.outlineVariant),
              prefixIcon: Icon(Icons.email_outlined, size: AppIconSizes.md, color: AppColors.iconForm),
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
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const InfoBox(
            text: 'If you do not see the reset email in your inbox, check your spam folder. If it is still missing, the email address may not be linked to an account.',
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isSubmitting ? null : _sendResetLink,
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
              : const Text('Send Reset Password Link', style: AppTextStyles.button),
        ),
      ),
    );
  }
}
