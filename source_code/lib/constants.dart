import 'package:flutter/material.dart';

// ──────────────────────────────────────────────
// Design System
// ──────────────────────────────────────────────

/// Centralized app colors
abstract final class AppColors {
  // Primary palette
  static const Color primaryDark = Color(0xFF0077B6); //145DA0
  static const Color primaryLight = Color(0xFF94CCFF);
  static const Color primaryContainer = Color(0xFFCDE5FF);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Secondary palette
  static const Color secondary = Color(0xFF006875);
  static const Color secondaryContainer = Color(0xFF9CECFB);

  // Surface & background
  static const Color background = Color(0xFFF7F9FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFD8DADC);
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);
  static const Color surfaceContainer = Color(0xFFECEEF0);
  static const Color surfaceContainerHigh = Color(0xFFE6E8EA);

  // Text / on-surface
  static const Color onSurface = Color(0xFF191C1E);
  static const Color onSurfaceVariant = Color(0xFF404850);

  // Outline
  static const Color outline = Color(0xFF707881);
  static const Color outlineVariant = Color(0xFFBFC7D1);

  // Gradient
  static const Color gradientStart = Color(0xFFCAF0F8);
  static const Color gradientEnd = Color(0xFFE7FBFF);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFBA1A1A);
  static const Color warning = Color(0xFFF59E0B);

  // Category colors
  static const Color categoryImportant = Color(0xFFEAB308);
  static const Color categoryStudy = Color(0xFF8B5CF6);
  static const Color categoryWork = Color(0xFF2563EB);
  static const Color categoryHome = Color(0xFFF97316);

  // Semantic
  static const Color dueTeal = Color(0xFF006875);
  static const Color badgeBg = Color(0xFFE6E8EA);

  // Glass / shadows
  static Color glassWhite = surface.withValues(alpha: 0.6);
  static Color glassBorder = surface.withValues(alpha: 0.3);
  static Color glassBorderLight = surface.withValues(alpha: 0.2);
  static Color glassMenuBg = surface.withValues(alpha: 0.8);

  // Primary alpha method
  static Color primaryAlpha(double opacity) =>
      primaryDark.withValues(alpha: opacity);

  static Color onSurfaceVariantLow = onSurfaceVariant.withValues(alpha: 0.7);
  static Color onSurfaceVariantVeryLow = onSurfaceVariant.withValues(
    alpha: 0.06,
  );

  // ─── Icon colors ───
  static const Color iconForm = Color(
    0xFF404850,
  ); // form field prefix icons (onSurfaceVariant)
  static const Color iconMain = Color(
    0xFF145DA0,
  ); // main app icons (primaryDark)
  static const Color iconDestructive = Color(
    0xFFEF4444,
  ); // destructive action icons (error)
}

abstract final class AppTextStyles {
  // Font family
  static const String fontFamily = 'Inter';

  // ─── Display / Headings ───
  static const TextStyle displayLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.02,
    color: AppColors.onSurface,
  );

  static const TextStyle headlineLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.01,
    color: AppColors.primaryDark,
  );

  static const TextStyle headlineMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
    color: AppColors.onSurface,
  );

  static const TextStyle headlineSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.27,
    color: AppColors.primaryDark,
  );

  // ─── Body ───
  static const TextStyle bodyLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.onSurfaceVariant,
  );

  static const TextStyle bodyHandwritten = TextStyle(
    fontFamily: 'PatrickHand',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.primaryDark,
  );

  // ─── Labels ───
  static const TextStyle labelMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.01,
    color: AppColors.onSurfaceVariant,
  );

  static const TextStyle labelSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.02,
    color: AppColors.onSurfaceVariant,
  );

  // ─── Auth panel ───
  static const TextStyle authTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.01,
    color: AppColors.primaryDark,
  );

  // ─── Button ───
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.onPrimary,
  );

  // ─── Utility ───
  static const TextStyle link = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryDark,
  );

  static const TextStyle bodyLink = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
  );

  static const TextStyle orDivider = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 2,
    color: AppColors.onSurfaceVariant,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.error,
  );

  static const TextStyle myListsHeader = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
    color: AppColors.outlineVariant,
  );
}

/// Centralized spacing and padding
abstract final class AppSpacing {
  // Base unit
  static const double unit = 4;

  // Standard gaps
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  // Container padding (matching DESIGN.md)
  static const double containerPadding = 24;

  // Standard EdgeInsets helpers
  static const EdgeInsets allXs = EdgeInsets.all(xs);
  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allLg = EdgeInsets.all(lg);
  static const EdgeInsets allXl = EdgeInsets.all(xl);

  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
}

/// Centralized border radii
abstract final class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 42;
  static const double pill = 9999;

  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius radiusPill = BorderRadius.all(
    Radius.circular(pill),
  );

  static const BorderRadius topMd = BorderRadius.vertical(
    top: Radius.circular(md),
  );
  static const BorderRadius bottomMd = BorderRadius.vertical(
    bottom: Radius.circular(md),
  );
}

/// Centralized icon sizes
abstract final class AppIconSizes {
  static const double xs = 16;
  static const double sm = 18;
  static const double md = 20;
  static const double lg = 22;
  static const double xl = 24;
  static const double xxl = 26;
  static const double header = 28;
  static const double fab = 32;
  static const double emptyState = 90;
}

/// Centralized component sizes
abstract final class AppComponentSizes {
  // Buttons
  static const double buttonHeight = 52;
  static const double googleButtonHeight = 50;

  // FAB
  static const double fabSize = 56;

  // Bottom nav
  static const double bottomNavHeight = 70;

  // Task cards
  static const double taskCardRadius = 20;

  // Sheet
  static const double sheetRadius = 24;
  static const double sheetMaxTextFieldHeight = 120;

  // Avatar
  static const double avatarSize = 104;

  // Header
  static const double headerHeight = 48;

  // Misc
  static const double expandButtonSize = 40;
  static const double envelopeSize = 96;
  static const double glassCardMaxWidth = 440;
}

/// Centralized shadow styles
abstract final class AppShadows {
  static BoxShadow glassCard = BoxShadow(
    blurRadius: 32,
    offset: const Offset(0, 8),
    color: AppColors.primaryAlpha(0.10),
  );

  static BoxShadow sortBar = BoxShadow(
    blurRadius: 8,
    offset: const Offset(0, 2),
    color: AppColors.primaryAlpha(0.08),
  );

  static BoxShadow sortDropdown = BoxShadow(
    blurRadius: 12,
    offset: const Offset(0, 4),
    color: AppColors.primaryAlpha(0.10),
  );

  static BoxShadow taskCard = BoxShadow(
    blurRadius: 20,
    offset: const Offset(0, 4),
    color: AppColors.primaryAlpha(0.08),
  );

  static BoxShadow fab = BoxShadow(
    blurRadius: 12,
    offset: const Offset(0, 4),
    color: AppColors.primaryAlpha(0.20),
  );

  static BoxShadow navBar = BoxShadow(
    blurRadius: 20,
    offset: const Offset(0, -4),
    color: AppColors.primaryAlpha(0.10),
  );

  static BoxShadow emptyStateCircle = BoxShadow(
    blurRadius: 50,
    offset: const Offset(0, 16),
    color: AppColors.primaryAlpha(0.28),
  );

  static BoxShadow primaryButton = BoxShadow(
    blurRadius: 15,
    offset: const Offset(0, 4),
    color: Color.fromRGBO(0, 119, 182, 0.25),
  );

  static BoxShadow envelope = BoxShadow(
    blurRadius: 20,
    offset: const Offset(0, 10),
    color: AppColors.primaryAlpha(0.20),
  );
}

/// Centralized duration constants
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration long = Duration(milliseconds: 500);
  static const Duration veryLong = Duration(seconds: 1);
  static const Duration superLong = Duration(seconds: 2);
}

/// Centralized asset paths
abstract final class AppAssets {
  static const String userProfileDefault =
      'assets/user_profile_default_image.jpg';
}
