import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants.dart';
import '../providers/services_provider.dart';
import '../widgets/glass_card.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late final TextEditingController _nameController;
  bool _isMale = true;
  String? _selectedAvatar;
  bool _isSaving = false;

  static const List<String> _maleAvatars = [
    'assets/Avatars/male_1.jpg',
    'assets/Avatars/male_2.jpg',
    'assets/Avatars/male_3.jpg',
    'assets/Avatars/male_4.jpg',
    'assets/Avatars/male_5.jpg',
    'assets/Avatars/male_6.jpg',
  ];

  static const List<String> _femaleAvatars = [
    'assets/Avatars/female_1.jpg',
    'assets/Avatars/female_2.jpg',
    'assets/Avatars/female_3.jpg',
    'assets/Avatars/female_4.jpg',
    'assets/Avatars/female_5.jpg',
    'assets/Avatars/female_6.jpg',
    'assets/Avatars/female_7.jpg',
    'assets/Avatars/female_8.jpg',
    'assets/Avatars/female_9.jpg',
    'assets/Avatars/female_10.jpg',
    'assets/Avatars/female_11.jpg',
  ];

  static const String _defaultAvatar = 'assets/user_profile_default_image.jpg';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await ref
          .read(authServiceProvider)
          .userProfileStream(user.uid)
          .first;
      final data = doc.data();
      if (data == null || !mounted) return;
      final avatar = data['avatar'] as String?;
      final name = data['name'] as String?;
      setState(() {
        if (name != null && name.isNotEmpty) {
          _nameController.text = name;
        }
        if (avatar != null && avatar.isNotEmpty) {
          _selectedAvatar = avatar;
          _isMale = avatar.contains('male');
        }
      });
    } catch (_) {}
  }

  List<String> get _currentAvatars => _isMale ? _maleAvatars : _femaleAvatars;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name must be at least 2 characters')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(authServiceProvider).updateUserProfile(
            name: name,
            avatar: _selectedAvatar ?? _defaultAvatar,
          );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(authServiceProvider).readableAuthError(e),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
                    child: Column(
                      children: [
                        _buildAvatarSection(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildGenderToggle(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildAvatarGrid(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildNameField(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildSaveButton(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFooter(),
                      ],
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
              child: Icon(
                Icons.arrow_back_rounded,
                size: AppIconSizes.header,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.edit_note_rounded,
              size: AppIconSizes.header,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: AppSpacing.md),
            Text('Profile Edit', style: AppTextStyles.headlineMd),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Text(
          'Personalize username and profile avatar',
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          width: 100,
          height: 100,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primaryContainer, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 24,
                offset: const Offset(0, 8),
                color: AppColors.primaryAlpha(0.18),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 46,
            backgroundColor: Colors.transparent,
            backgroundImage: AssetImage(
              _selectedAvatar ?? _defaultAvatar,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.onSurfaceVariantVeryLow,
        borderRadius: AppRadius.radiusPill,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isMale) {
                  setState(() {
                    _isMale = true;
                    _selectedAvatar = null;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _isMale ? AppColors.primaryDark : Colors.transparent,
                  borderRadius: AppRadius.radiusPill,
                ),
                child: Center(
                  child: Text(
                    'Male',
                    style: AppTextStyles.button.copyWith(
                      color: _isMale ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isMale) {
                  setState(() {
                    _isMale = false;
                    _selectedAvatar = null;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: !_isMale ? AppColors.primaryDark : Colors.transparent,
                  borderRadius: AppRadius.radiusPill,
                ),
                child: Center(
                  child: Text(
                    'Female',
                    style: AppTextStyles.button.copyWith(
                      color: !_isMale ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarGrid() {
    const double avatarRadius = 36;
    const double spacing = AppSpacing.md;
    const int visibleRows = 2;
    const double gridHeight = (avatarRadius * 2) * visibleRows + spacing * (visibleRows - 1);

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SizedBox(
        height: gridHeight,
        child: GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: _currentAvatars.length,
          itemBuilder: (context, index) {
            final avatar = _currentAvatars[index];
            final isSelected = _selectedAvatar == avatar;
            return GestureDetector(
              onTap: () => setState(() => _selectedAvatar = avatar),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: AppColors.primaryDark, width: 3)
                      : null,
                ),
                padding: isSelected ? const EdgeInsets.all(3) : EdgeInsets.zero,
                child: CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: AppColors.surfaceContainerLow,
                  backgroundImage: AssetImage(avatar),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.containerPadding,
        vertical: AppSpacing.xs,
      ),
      child: TextFormField(
        controller: _nameController,
        style: AppTextStyles.bodyMd,
        decoration: InputDecoration(
          hintText: 'Enter your name',
          hintStyle: AppTextStyles.bodyMd.copyWith(
            color: AppColors.outlineVariant,
          ),
          prefixIcon: Icon(
            Icons.person_outline_rounded,
            size: AppIconSizes.md,
            color: AppColors.iconForm,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _save,
      child: Container(
        width: double.infinity,
        height: AppComponentSizes.buttonHeight,
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: AppRadius.radiusPill,
          boxShadow: [AppShadows.primaryButton],
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(
                  width: AppIconSizes.md,
                  height: AppIconSizes.md,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.onPrimary,
                    ),
                  ),
                )
              : const Text('Save', style: AppTextStyles.button),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      'You can change these details anytime in\nprofile edit.',
      textAlign: TextAlign.center,
      style: AppTextStyles.labelSm.copyWith(
        color: AppColors.onSurfaceVariant,
        height: 1.5,
      ),
    );
  }
}
