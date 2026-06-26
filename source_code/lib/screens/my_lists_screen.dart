import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants.dart';
import '../providers/services_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/slide_route.dart';
import 'sessions_list_screen.dart';
import 'reminders_screen.dart';
import 'settings_screen.dart';

class MyListsScreen extends ConsumerStatefulWidget {
  const MyListsScreen({super.key});

  @override
  ConsumerState<MyListsScreen> createState() => _MyListsScreenState();
}

class _MyListsScreenState extends ConsumerState<MyListsScreen> {
  final int _selectedNavIndex = 4;

  Map<String, Map<String, dynamic>> _customLists = {};
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _tasksStream;

  static const List<_IconOption> _iconOptions = [
    _IconOption(Icons.favorite_rounded),
    _IconOption(Icons.pets_rounded),
    _IconOption(Icons.local_hospital_rounded),
    _IconOption(Icons.medication_rounded),
    _IconOption(Icons.restaurant_rounded),
    _IconOption(Icons.shopping_cart_rounded),
    _IconOption(Icons.fitness_center_rounded),
    _IconOption(Icons.music_note_rounded),
    _IconOption(Icons.travel_explore_rounded),
    _IconOption(Icons.brush_rounded),
    _IconOption(Icons.code_rounded),
    _IconOption(Icons.directions_car_rounded),
    _IconOption(Icons.beach_access_rounded),
    _IconOption(Icons.emoji_events_rounded),
    _IconOption(Icons.auto_stories_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tasksStream = ref.read(taskServiceProvider).tasksStream(
      FirebaseAuth.instance.currentUser!.uid,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLists());
  }

  Future<void> _loadLists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final lists = await ref.read(taskServiceProvider).getLists(user.uid);
    if (!mounted) return;
    setState(() {
      _customLists = lists;
    });
  }

  void _onNavTapped(int index) {
    if (index == _selectedNavIndex) return;
    if (index == 2) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    Widget screen = const SizedBox.shrink();
    switch (index) {
      case 0:
        screen = const RemindersScreen();
        break;
      case 1:
        screen = const SessionsListScreen();
        break;
      case 3:
        screen = const SettingsScreen();
        break;
    }
    Navigator.pushReplacement(
      context,
      fadeRoute(screen),
    );
  }

  int _activeCount(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> allDocs,
    String category,
  ) {
    return allDocs.where((d) {
      final data = d.data();
      return (data['category'] as String?) == category &&
          (data['isDone'] as bool?) != true;
    }).length;
  }

  Future<void> _addList() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final controller = TextEditingController();
    String? error;
    int selectedIconIndex = 0;

    final result = await showDialog<_DialogResult>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.radiusXl,
              ),
              title: const Text(
                'Create New List',
                style: AppTextStyles.headlineSm,
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      maxLength: 20,
                      buildCounter: (context, {required currentLength, required maxLength, required isFocused}) {
                        return Text(
                          '$currentLength/$maxLength',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        );
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter list name',
                        errorText: error,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.radiusMd,
                        ),
                      ),
                      onChanged: (_) {
                        if (error != null) {
                          setDialogState(() => error = null);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Text('Choose an icon', style: AppTextStyles.labelSm),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 56,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _iconOptions.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (_, index) {
                          final isSelected = index == selectedIconIndex;
                          return GestureDetector(
                            onTap: () => setDialogState(
                                () => selectedIconIndex = index),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryContainer
                                    : AppColors.surfaceContainerLow,
                                borderRadius: AppRadius.radiusMd,
                                border: isSelected
                                    ? Border.all(
                                        color: AppColors.primaryDark,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: Icon(
                                _iconOptions[index].icon,
                                color: isSelected
                                    ? AppColors.primaryDark
                                    : AppColors.onSurfaceVariant,
                                size: 24,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: AppTextStyles.link),
                ),
                FilledButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isEmpty) {
                      setDialogState(() => error = 'Name cannot be empty');
                      return;
                    }
                    Navigator.of(ctx).pop(
                      _DialogResult(name: text, iconIndex: selectedIconIndex),
                    );
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    try {
      await ref.read(taskServiceProvider).addList(
        uid: user.uid,
        name: result.name,
        iconCodePoint: _iconOptions[result.iconIndex].icon.codePoint,
      );
      _loadLists();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _deleteList(String listId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXl),
        title: const Text('Delete List', style: AppTextStyles.headlineSm),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: AppTextStyles.link),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.radiusMd,
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: AppTextStyles.button),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await ref
        .read(taskServiceProvider)
        .deleteList(uid: user.uid, listId: listId);
    _loadLists();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

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
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _tasksStream,
              builder: (context, snapshot) {
                final allDocs = snapshot.data?.docs ?? [];

                return Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.containerPadding,
                          right: AppSpacing.containerPadding,
                          top: AppSpacing.xl,
                          bottom: 100,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildAddListButton(),
                            const SizedBox(height: AppSpacing.xl),
                            _buildListCard(
                              icon: Icons.school_rounded,
                              iconBg: const Color(0xFFF3E8FF),
                              iconColor: const Color(0xFF7E22CE),
                              name: 'Study Tasks',
                              activeItems: _activeCount(allDocs, 'Study'),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildListCard(
                              icon: Icons.work_rounded,
                              iconBg: const Color(0xFFE0F2FE),
                              iconColor: const Color(0xFF0077B6),
                              name: 'Work Tasks',
                              activeItems: _activeCount(allDocs, 'Work'),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildListCard(
                              icon: Icons.home_rounded,
                              iconBg: const Color(0xFFFFEDD5),
                              iconColor: const Color(0xFFEA580C),
                              name: 'Home Tasks',
                              activeItems: _activeCount(allDocs, 'Home'),
                            ),
                            if (_customLists.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.xl,
                                  bottom: AppSpacing.md,
                                ),
                                child: Text(
                                  'MY LISTS',
                                  style: AppTextStyles.myListsHeader,
                                ),
                              ),
                            ..._customLists.entries.map((entry) {
                              final listId = entry.key;
                              final data = entry.value;
                              final name = (data['name'] as String?) ?? '';
                              final iconCodePoint =
                                  (data['iconCodePoint'] as int?) ??
                                      Icons.folder_rounded.codePoint;
                              final colorValue =
                                  (data['colorValue'] as int?) ??
                                      AppColors.primaryDark.toARGB32();
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: _buildListCard(
                                  // ignore: non_const_argument_for_const_parameter
                                  icon: IconData(iconCodePoint, fontFamily: 'MaterialIcons'),
                                  iconBg:
                                      Color(colorValue).withValues(alpha: 0.12),
                                  iconColor: Color(colorValue),
                                  name: name,
                                  activeItems: _activeCount(allDocs, name),
                                  trailing: GestureDetector(
                                    onTap: () => _deleteList(listId, name),
                                    child: Icon(
                                      Icons.delete_outline_rounded,
                                      size: AppIconSizes.md,
                                      color:
                                          AppColors.error.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom,
            child: BottomNavBar(
              currentIndex: _selectedNavIndex,
              onItemTapped: _onNavTapped,
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
        border: Border(
          bottom: BorderSide(color: AppColors.glassBorderLight),
        ),
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
              Icons.list_alt_rounded,
              size: AppIconSizes.header,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: AppSpacing.md),
            Text('My Lists', style: AppTextStyles.headlineMd),
          ],
        ),
      ),
    );
  }

  Widget _buildAddListButton() {
    return GestureDetector(
      onTap: _addList,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.containerPadding,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          boxShadow: [
            BoxShadow(
              blurRadius: 15,
              offset: const Offset(0, 4),
              color: AppColors.primaryAlpha(0.25),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              size: AppIconSizes.xl,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Add List',
              style: AppTextStyles.headlineSm.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String name,
    required int activeItems,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.containerPadding,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [AppShadows.glassCard],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: iconColor, size: AppIconSizes.lg),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyLg.copyWith(
                    color: AppColors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$activeItems active items',
                  style: AppTextStyles.labelMd,
                ),
              ],
            ),
          ),
          trailing ??
              Icon(
                Icons.chevron_right_rounded,
                size: AppIconSizes.lg,
                color: AppColors.outlineVariant,
              ),
        ],
      ),
    );
  }

}

class _IconOption {
  final IconData icon;
  const _IconOption(this.icon);
}

class _DialogResult {
  final String name;
  final int iconIndex;
  const _DialogResult({required this.name, required this.iconIndex});
}
