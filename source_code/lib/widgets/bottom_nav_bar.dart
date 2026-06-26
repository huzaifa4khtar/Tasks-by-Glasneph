import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

import '../constants.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int index) onItemTapped;

  static const List<IconData> _icons = [
    Icons.notifications_rounded,
    Icons.timer_rounded,
    Icons.home_rounded,
    Icons.settings_rounded,
    Icons.person_rounded,
  ];

  const BottomNavBar({
    super.key,
    this.currentIndex = 2,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final items = _icons
        .map((icon) => Icon(icon, size: AppIconSizes.xxl, color: AppColors.onPrimary))
        .toList();

    return CurvedNavigationBar(
      backgroundColor: Colors.transparent,
      buttonBackgroundColor: AppColors.primaryDark,
      color: AppColors.primaryDark,
      animationDuration: AppDurations.normal,
      animationCurve: Curves.easeOut,
      height: AppComponentSizes.bottomNavHeight,
      index: currentIndex,
      onTap: onItemTapped,
      items: items,
    );
  }
}
