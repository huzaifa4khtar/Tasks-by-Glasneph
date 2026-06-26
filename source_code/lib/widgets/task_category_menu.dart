import 'package:flutter/material.dart';

import '../constants.dart';

class CustomListInfo {
  final String name;
  final IconData icon;
  final Color color;
  final int activeCount;

  const CustomListInfo({
    required this.name,
    required this.icon,
    required this.color,
    required this.activeCount,
  });
}

class TaskCategoryMenu extends StatelessWidget {
  final String selectedCategory;
  final bool isExpanded;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onToggleExpanded;
  final int totalCount;
  final int importantCount;
  final int studyCount;
  final int workCount;
  final int homeCount;
  final List<CustomListInfo> customLists;

  const TaskCategoryMenu({
    super.key,
    required this.selectedCategory,
    required this.isExpanded,
    required this.onCategorySelected,
    required this.onToggleExpanded,
    required this.totalCount,
    required this.importantCount,
    required this.studyCount,
    required this.workCount,
    required this.homeCount,
    this.customLists = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        if (isExpanded) _buildExpandedMenu(),
      ],
    );
  }

  Widget _buildHeader() {
    final borderRadius = isExpanded ? AppRadius.topMd : AppRadius.radiusMd;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: borderRadius,
        border: Border(bottom: BorderSide(color: AppColors.glassBorderLight)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.containerPadding,
          vertical: AppSpacing.sm,
        ),
        child: SizedBox(
          height: AppComponentSizes.headerHeight,
          child: Row(
            children: [
              selectedCategory == 'All Tasks'
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: Stack(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              color: AppColors.primaryDark,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Center(
                            child: Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Icon(
                      _iconForCategory(selectedCategory),
                      size: AppIconSizes.header,
                      color: _colorForCategory(selectedCategory),
                    ),
              const SizedBox(width: AppSpacing.md),
              Text(
                selectedCategory,
                style: AppTextStyles.headlineSm,
              ),
              const Spacer(),
              GestureDetector(
                onTap: onToggleExpanded,
                child: Container(
                  width: AppComponentSizes.expandButtonSize,
                  height: AppComponentSizes.expandButtonSize,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                  child: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedMenu() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassMenuBg,
        borderRadius: AppRadius.bottomMd,
        border: Border(bottom: BorderSide(color: AppColors.glassBorderLight)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCategoryItem(
            label: 'All Tasks',
            iconColor: AppColors.primaryDark,
            iconWidget: SizedBox(
              width: 18,
              height: 18,
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primaryDark,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Center(
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ],
              ),
            ),
            isActive: selectedCategory == 'All Tasks',
            badge: totalCount.toString(),
            onTap: () => onCategorySelected('All Tasks'),
          ),
          _buildCategoryItem(
            icon: Icons.star_rounded,
            label: 'Important',
            iconColor: AppColors.categoryImportant,
            isActive: selectedCategory == 'Important',
            badge: importantCount.toString(),
            onTap: () => onCategorySelected('Important'),
          ),
          Container(height: 1, color: AppColors.surface.withValues(alpha: 0.1)),
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.containerPadding,
              vertical: 6,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MY LISTS',
                style: AppTextStyles.myListsHeader,
              ),
            ),
          ),
          _buildCategoryItem(
            icon: Icons.school_rounded,
            label: 'Study Tasks',
            iconColor: AppColors.categoryStudy,
            isActive: selectedCategory == 'Study Tasks',
            badge: studyCount.toString(),
            onTap: () => onCategorySelected('Study Tasks'),
          ),
          _buildCategoryItem(
            icon: Icons.work_rounded,
            label: 'Work Tasks',
            iconColor: AppColors.categoryWork,
            isActive: selectedCategory == 'Work Tasks',
            badge: workCount.toString(),
            onTap: () => onCategorySelected('Work Tasks'),
          ),
          _buildCategoryItem(
            icon: Icons.home_rounded,
            label: 'Home Tasks',
            iconColor: AppColors.categoryHome,
            isActive: selectedCategory == 'Home Tasks',
            badge: homeCount.toString(),
            onTap: () => onCategorySelected('Home Tasks'),
          ),
          ...customLists.map((list) => _buildCategoryItem(
            icon: list.icon,
            label: list.name,
            iconColor: list.color,
            isActive: selectedCategory == list.name,
            badge: list.activeCount.toString(),
            onTap: () => onCategorySelected(list.name),
          )),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({
    IconData? icon,
    required String label,
    required Color iconColor,
    required bool isActive,
    String? badge,
    VoidCallback? onTap,
    Widget? iconWidget,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: isActive ? AppColors.primaryAlpha(0.12) : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerPadding,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              iconWidget ??
                  Icon(icon, size: AppIconSizes.lg, color: iconColor),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? AppColors.primaryDark
                        : AppColors.onSurface,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.badgeBg,
                    borderRadius: AppRadius.radiusPill,
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    final customMatch = customLists.where((l) => l.name == category);
    if (customMatch.isNotEmpty) return customMatch.first.icon;
    switch (category) {
      case 'Important':
        return Icons.star_rounded;
      case 'Study Tasks':
        return Icons.school_rounded;
      case 'Work Tasks':
        return Icons.work_rounded;
      case 'Home Tasks':
        return Icons.home_rounded;
      case 'All Tasks':
      default:
        return Icons.list_alt_rounded;
    }
  }

  Color _colorForCategory(String category) {
    final customMatch = customLists.where((l) => l.name == category);
    if (customMatch.isNotEmpty) return customMatch.first.color;
    switch (category) {
      case 'Important':
        return AppColors.categoryImportant;
      case 'Study Tasks':
        return AppColors.categoryStudy;
      case 'Work Tasks':
        return AppColors.categoryWork;
      case 'Home Tasks':
        return AppColors.categoryHome;
      case 'All Tasks':
      default:
        return AppColors.primaryDark;
    }
  }
}
