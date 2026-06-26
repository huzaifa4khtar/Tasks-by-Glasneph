import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants.dart';
import '../providers/services_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/info_box.dart';
import 'login_screen.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key, required this.userEmail});

  final String userEmail;

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  bool _isDeleting = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _deleteAccount() async {
    if (!_formKey.currentState!.validate()) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account Permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    setState(() => _isDeleting = true);
    final password = _passwordController.text;

    try {
      await ref.read(authServiceProvider).reauthenticateWithEmail(widget.userEmail, password);
      await ref.read(authServiceProvider).deleteCurrentUserAccount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted successfully.')),
      );
      await ref.read(authServiceProvider).signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(authServiceProvider).readableAuthError(e))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(authServiceProvider).readableAuthError(e))),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
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
            Icon(Icons.delete_forever_rounded, size: AppIconSizes.header, color: AppColors.primaryDark),
            const SizedBox(width: AppSpacing.md),
            Text('Delete Account', style: AppTextStyles.headlineMd),
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
          const SizedBox(height: AppSpacing.sm),
          _buildField(
            initialValue: widget.userEmail,
            icon: Icons.email_outlined,
            label: 'Account Email',
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            validator: _validatePassword,
            enabled: !_isDeleting,
            style: AppTextStyles.bodyMd,
            decoration: InputDecoration(
              hintText: 'Enter your password to confirm deletion',
              hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.outlineVariant),
              prefixIcon: Icon(Icons.lock_outlined, size: AppIconSizes.md, color: AppColors.iconForm),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.onSurfaceVariant,
                  size: AppIconSizes.md,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
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
          const SizedBox(height: AppSpacing.lg),
          const InfoBox(
            prefix: 'Warning: ',
            text: 'This action is permanent. Your account and all associated data will be deleted immediately and cannot be recovered.',
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildDeleteButton(),
          const SizedBox(height: AppSpacing.md),
          _buildCancelButton(),
        ],
      ),
    );
  }

  Widget _buildField({
    required String initialValue,
    required IconData icon,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.onSurfaceVariantVeryLow,
        borderRadius: AppRadius.radiusPill,
      ),
      child: TextFormField(
        initialValue: initialValue,
        enabled: false,
        style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: AppIconSizes.md, color: AppColors.iconForm),
          labelText: label,
          labelStyle: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: _isDeleting ? null : _deleteAccount,
      child: Container(
        width: double.infinity,
        height: AppComponentSizes.buttonHeight,
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: AppRadius.radiusPill,
        ),
        child: Center(
          child: _isDeleting
              ? const SizedBox(
                  width: AppIconSizes.md,
                  height: AppIconSizes.md,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                  ),
                )
              : const Text('Delete Account Permanently', style: AppTextStyles.button),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: _isDeleting ? null : () => Navigator.pop(context),
      child: Container(
        width: double.infinity,
        height: AppComponentSizes.buttonHeight,
        decoration: BoxDecoration(
          borderRadius: AppRadius.radiusPill,
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: const Center(
          child: Text(
            'Cancel, Keep My Account',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
