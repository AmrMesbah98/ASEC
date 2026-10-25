/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: app_theme.dart
/// Purpose: Declares `AppTheme`.
/// Author: Manger Plus team
/// Updated: 11/8/2026 - Added the standard module + FILE INFO header.

// Date: 1/8/2024
// By: Youssef Ashraf, Mohamed Ashraf, Nada Mohammed
// Last update: 20/8/2024
// Objectives: This file is responsible for providing the app themes that is used in the app.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:get_storage/get_storage.dart';
import 'package:asec/core/animation/app_animations.dart';
import './app_font_weights.dart';

abstract class AppTheme {
  static bool isDark = false;

  // Getters, not `static final`: a final is built ONCE with whichever palette
  // is current at first read (dark, if the app opens in dark mode), so the
  // light theme kept white `onSurface` and every IconButton / ListTile icon
  // vanished after switching to light. A getter rebuilds with live colours.
  static ThemeData get lightTheme => ThemeData.light().copyWith(
    textTheme: TextTheme(

      headlineMedium: StyleText.fontSize20Weight500,
      headlineSmall: StyleText.fontSize16Weight500,
      titleLarge: StyleText.fontSize18Weight500,
      titleMedium: StyleText.fontSize16Weight500,
      titleSmall: StyleText.fontSize14Weight500,
      bodyLarge: StyleText.fontSize14Weight500,
      bodySmall: StyleText.fontSize12Weight500,
      bodyMedium: StyleText.fontSize14Weight600,
      labelLarge: StyleText.fontSize14Weight500,
      labelMedium: StyleText.fontSize12Weight500,
      labelSmall: StyleText.fontSize10Weight400,
      displayLarge: StyleText.fontSize23Weight400,
      displayMedium: StyleText.fontSize20Weight500,
      displaySmall: StyleText.fontSize16Weight500,
    ),
    splashFactory: NoSplash.splashFactory,  // ADD THIS
    highlightColor: Colors.transparent,     // ADD THIS
    splashColor: Colors.transparent,        // ADD THIS
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,

    pageTransitionsTheme: appPageTransitions,
    colorScheme: ColorScheme.light(
      primary: AppColors.secondaryPrimary,
      onPrimary: AppColors.secondaryPrimaryText,
      outlineVariant: AppColors.lightGrey,
      onSurface: AppColors.inverseBase,
    ),
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(AppRadius.buttonRadius),
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      headerHeadlineStyle: StyleText.fontSize23Weight400,
      weekdayStyle: StyleText.fontSize12Weight600.copyWith(color: AppColors.darkGrey),
      headerBackgroundColor: AppColors.secondaryPrimary,
      headerForegroundColor: AppColors.secondaryPrimaryText,
      backgroundColor: AppColors.card,
      todayBackgroundColor: WidgetStatePropertyAll(AppColors.card),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(AppRadius.containerRadius),
      ),
      dayStyle: StyleText.fontSize14Weight500,
      dayBackgroundColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondaryPrimary;
          }
          return AppColors.card;
        },
      ),
      dayForegroundColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondaryPrimaryText;
          } else if (states.contains(WidgetState.disabled)) {
            return AppColors.lightGrey;
          }
          return AppColors.text;
        },
      ),
      yearBackgroundColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondaryPrimary;
          }
          return AppColors.card;
        },
      ),
      yearForegroundColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondaryPrimaryText;
          }
          return AppColors.text;
        },
      ),
      dividerColor: AppColors.secondaryPrimary,
      dayShape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: AppRadius.containerR,
        ),
      ),
      todayForegroundColor: WidgetStateProperty.all(
        AppColors.secondaryPrimary,
      ),
    ),
  );

  static ThemeData get darkTheme => ThemeData.dark().copyWith(
    primaryColor: AppColors.primary,
    textTheme: TextTheme(
      headlineMedium: StyleText.fontSize20Weight500,
      headlineSmall: StyleText.fontSize16Weight500,
      titleLarge: StyleText.fontSize18Weight500,
      titleMedium: StyleText.fontSize16Weight500,
      titleSmall: StyleText.fontSize14Weight500,
      bodyLarge: StyleText.fontSize14Weight500,
      bodySmall: StyleText.fontSize12Weight500,
      bodyMedium: StyleText.fontSize14Weight600,
      labelLarge: StyleText.fontSize14Weight500,
      labelMedium: StyleText.fontSize12Weight500,
      labelSmall: StyleText.fontSize10Weight400,
      displayLarge: StyleText.fontSize23Weight400,
      displayMedium: StyleText.fontSize20Weight500,
      displaySmall: StyleText.fontSize16Weight500,
    ),
    scaffoldBackgroundColor: AppColors.background,
    splashFactory: NoSplash.splashFactory,  // ADD THIS
    highlightColor: Colors.transparent,     // ADD THIS
    splashColor: Colors.transparent,        // ADD THIS
    pageTransitionsTheme: appPageTransitions,
    colorScheme: ColorScheme.dark(
      primary: AppColors.secondaryPrimary,
      onPrimary: AppColors.secondaryPrimaryText,
      outlineVariant: AppColors.lightGrey,
      onSurface: AppColors.inverseBase,
    ),
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(AppRadius.buttonRadius),
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      headerHeadlineStyle: StyleText.fontSize23Weight400,
      weekdayStyle: StyleText.fontSize12Weight600.copyWith(color: AppColors.darkGrey),
      headerBackgroundColor: AppColors.secondaryPrimary,
      headerForegroundColor: AppColors.secondaryPrimaryText,
      backgroundColor: AppColors.card,
      todayBackgroundColor: WidgetStatePropertyAll(AppColors.card),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(AppRadius.containerRadius),
      ),
      dayStyle: StyleText.fontSize14Weight500,
      dayBackgroundColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondaryPrimary;
          }
          return AppColors.white;
        },
      ),
      dayForegroundColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondaryPrimaryText;
          } else if (states.contains(WidgetState.disabled)) {
            return AppColors.lightGrey;
          }
          return AppColors.black;
        },
      ),
      yearBackgroundColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondaryPrimary;
          }
          return AppColors.card;
        },
      ),
      yearForegroundColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondaryPrimaryText;
          }
          return AppColors.text;
        },
      ),
      dividerColor: AppColors.secondaryPrimary,
      dayShape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: AppRadius.containerR,
        ),
      ),
      todayForegroundColor: WidgetStateProperty.all(
        AppColors.secondaryPrimary,
      ),
    ),
  );

  // ****************** DEFINE COLOR PALETTE HERE ******************
  static Map<String, Color> lightThemeColors = {
    'greyDark': const Color(0xff8D8D8D),
    'pending': const Color(0xffFF814A),
    'switchOff': const Color(0xffe9e9eb),

    'evenRowColor': const Color(0xFFf1f1f1),
    'secondaryPrimary': const Color(0xff4B45C6),
    'primary': const Color(0xff6C63FF),
    'inputColor': const Color(0xff8D8D8D),
    'grey': const Color(0xffD9D9D9),
    'lightGrey': const Color(0xffC3C3C3),
    'moreLightGrey': const Color(0xffEFEFEF),
    'mediumGrey': const Color(0xffA6A6A6),
    'darkGrey': const Color(0xff858585),
    'blackShadow': const Color.fromRGBO(0, 0, 0, 0.4),
    'green': const Color(0xff008000),
    'red': const Color(0xffDF1C1C),
    'header': const Color(0xff2D2D2D),
    'warming': const Color(0xffFF814A),
    'blue': const Color(0xff1F78D1),
    'card': Colors.white,
    'field': Colors.white,
    'text': const Color(0xff2D2D2D),
    'lightPrimary': const Color(0xFFE7E5FF),

    'base': Colors.white,
    'inverseBase': const Color(0xff797979),
    'dropShadow': const Color(0xffC3C3C3).withOpacity(0.5),
    'borderCard': const Color(0xffFFFFFF),
    'message': const Color(0xffEFEFEF),
    'messageText': const Color(0xff858585),
    'border': const Color(0xffD9D9D9),
    'background': const Color(0xffF5F5F5),
    'appBar': const Color(0xffF5F5F5),
    'indicator': const Color(0xffE9E9E9),
    'starredCard': Colors.white,
    'black': const Color(0xff2D2D2D),
    'secondaryBlack': const Color(0xff797979),
    'whiteShadow': const Color(0xD9D9D9E0),
    'darkWhiteShadow': const Color(0x9E9E9E9E),
    'white': Colors.white,
    'darkWhite': const Color(0xffF2F2F2),
    'dialog': Colors.white,
    'button': const Color(0xffF2F2F2),
    'icon': const Color(0xff2D2D2D),
    'chatBackground': const Color(0xffF5F5F5),
    'chatField': Colors.white,
    'lightGreen': const Color(0xff4BB609),
    'orange': const Color(0xffFF814A),
    // Cancelled reads as a deeper red than Rejected. Was 0xffDF1C1C —
    // byte-identical to 'red', so the two statuses were indistinguishable
    // on the requests filter (bug report p.15).
    'darkRed': const Color(0xff8E1616),
    "lightRed": const Color(0xffFF0000),

    'yellow': const Color(0xff4B45C6),
    'fieldBorder': const Color(0xffE5E5ED),
    'oddRowColor': Colors.white,
    'secondaryText': const Color(0xff797979),
    'spanText': const Color(0xff797979),
    'secondaryButton': const Color(0xCCCCCCCC),
    'fullBlack': const Color(0xff000000),
    'lighterGrey': const Color(0xff999999),
    'liteBlue': const Color(0xff1877F2), // Same as light theme
// Stays the same in dark theme
    'borderGrey': const Color(0xffB5B4B4), // Stays the same in dark theme
    'darkerGrey': const Color(0xffcccccc), // Stays the same in dark theme
    'unBlock': const Color(0xFF4BB609),
    'navyBlue': const Color(0xFF768396),

    'greyBack': const Color(0xFFBCCCCC),
    'darkBackGround': const Color(0xFF545454),
    'block': const Color(0xFFDF0C0C),
    'warning': const Color(0xFFFF814A),
    'delete': const Color(0xFFDF1C1C),
    'expiringSoon': const Color(0xFF991010),
    'onboardingDotInactive': const Color(0x332D2D2D),
    'differentGrey': const Color(0xFF9E9E9E),
    'barrierColor': const Color(0XFFD9D9D9).withOpacity(.9),
    'totalBlack': const Color(0xFF000000),
    'whiteDark': Color(0xFFF2F2F2),
    'crimson': const Color(0xFFDF0C0C),
    'whiteDashboardTable': const Color(0xFFF1F1F1),
    'darkDashboardTable': const Color(0xFF28282B),
    'greyIcon': const Color(0xffA6A6A6),
    'drawerColor': const Color(0xFF797979),
    'blackButton': Colors.black
  };

  // ****************** DEFINE DARK COLOR PALETTE HERE ******************
  static Map<String, Color> darkThemeColors = {
    "greyDark": const Color(0xff8D8D8D),
    'greyIcon': const Color(0xFF6F6F6F),
    'secondaryPrimary': const Color(0xff4B45C6),
    'evenRowColor': const Color(0xFF545454),
    'oddRowColor': const Color(0xFF28282B),
    'primary': const Color(0xff6C63FF),
    'inputColor': const Color(0xff8D8D8D),
    'grey': const Color(0xffD9D9D9),
    'lightGrey': const Color(0xffC3C3C3),
    'moreLightGrey': const Color(0xffEFEFEF),
    'mediumGrey': const Color(0xffA6A6A6),
    'darkGrey': const Color(0xff858585),
    'blackShadow': const Color.fromRGBO(0, 0, 0, 0.4),
    'green': const Color(0xff008000),
    'red': const Color(0xffDF1C1C),
    'header': const Color(0xFF171717),
    'warming': const Color(0xffFF814A),
    'blue': const Color(0xff1F78D1),
    'card': const Color(0xff4B4B4B),
    'field': const Color(0xff4B4B4B),
    'text': Colors.white,
    'base': const Color(0xff797979),
    'inverseBase': Colors.white,
    'dropShadow': const Color(0xffC3C3C3).withOpacity(0.5),
    'borderCard': const Color(0xffFFFFFF),
    'message': const Color(0xffEFEFEF),
    'messageText': const Color(0xff858585),
    'border': Colors.transparent,
    'navyBlue': const Color(0xFF768396),
    'switchOff': const Color(0xffe9e9eb),

    'background': const Color(0xff2D2D2D),
    'appBar': const Color(0xff2D2D2D),
    'indicator': const Color(0xffE9E9E9),
    'starredCard': Colors.white,
    'black': const Color(0xff2D2D2D),
    'secondaryBlack': Colors.white,
    'whiteShadow': const Color(0xD9D9D9E0),
    'lightPrimary': const Color(0xFFE7E5FF),

    'darkWhiteShadow': const Color(0x9E9E9E9E),
    'white': Colors.white,
    'darkWhite': const Color(0xffF2F2F2),
    'dialog': const Color(0xff2D2D2D),
    'button': const Color(0xD9D9D9E0),
    'icon': const Color(0xD9D9D9E0),
    'chatBackground': const Color(0xff4B4B4B),
    'chatField': const Color(0xff2D2D2D),
    'lightGreen': const Color(0xff4BB609),
    'orange': const Color(0xffFF814A),
    // Lighter than the light-theme value so it still reads against the
    // dark background, while staying clearly darker than 'red'.
    'darkRed': const Color(0xffB03030),
    'yellow': const Color(0xff4B45C6),
    'fieldBorder': const Color(0xff797979),
    'secondaryText': const Color(0xffcccccc),
    'spanText': const Color(0xffd3d3d3),
    'secondaryButton': const Color(0xff858585),
    'fullBlack': const Color(0xffffffff),
    'lighterGrey': const Color(0xff999999), // Same as light theme
    'liteBlue': const Color(0xff1877F2), // Same as light theme
    'borderGrey': const Color(0xffB5B4B4), // Same as light theme
    'darkerGrey': const Color(0xffcccccc), // Same as light theme
    'crimson': const Color(0xFFDF0C0C),
    'whiteDashboardTable': const Color(0xFFF1F1F1),
    'darkDashboardTable': const Color(0xFF28282B),
    'drawerColor': const Color(0xFFCCCCCC),
    'blackButton': Colors.white,
    // Keys present in lightThemeColors that must also exist in dark to prevent null crashes:
    'barrierColor': const Color(0xFFD9D9D9),
    'pending': const Color(0xffFF814A),
    'totalBlack': const Color(0xFF000000),
    'whiteDark': const Color(0xFFF2F2F2),
    'block': const Color(0xFFDF0C0C),
    'warning': const Color(0xffFF814A),
    'delete': const Color(0xFFDF1C1C),
    'expiringSoon': const Color(0xFF991010),
    // FIXED 22/8/2026: was 0xFFF2F2F2 — an almost-white dot on the dark
    // 0xff2D2D2D background, so in dark mode the inactive indicators read
    // brighter than the active one. Matches `darkGrey`, the palette's neutral.
    'onboardingDotInactive': const Color(0xff858585),
    'differentGrey': const Color(0xFF9E9E9E),
    'unBlock': const Color(0xFF4BB609),
    'greyBack': const Color(0xFFBCCCCC),
    'darkBackGround': const Color(0xFF545454),
    'lightRed': const Color(0xffFF0000),
  };

  static void setCurrentThemeColors() {
    AppColors.currentThemeColors =
        isDark ?? false ? darkThemeColors : lightThemeColors;
    Get.forceAppUpdate();
  }

  static void initTheme(
      Color primaryColor, Color secondaryColor, bool isDarkMode) async {
    isDark = isDarkMode;
    interfaceUpdateBrandingColors(primaryColor, secondaryColor);
    // Get.changeThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
    setCurrentThemeColors();
  }

  static void interfaceUpdateBrandingColors(
      Color primaryColor, Color secondaryColor) {
    lightThemeColors['secondaryPrimary'] = secondaryColor;
    lightThemeColors['primary'] = primaryColor;
    darkThemeColors['secondaryPrimary'] = secondaryColor;
    darkThemeColors['primary'] = primaryColor;

    setCurrentThemeColors();
  }

  static void interfaceInitTheme(
      Color primaryColor, Color secondaryColor, bool isDarkMode) =>
      initTheme(primaryColor, secondaryColor, isDarkMode);

  static void interfaceToggleTheme() => toggleTheme();

  static void toggleTheme() async {
    isDark = !isDark!;
    setCurrentThemeColors();
  }

  /// Text / icon colour that reads on [fill]: dark on a light fill, white on
  /// a dark one — the services_module rule (ADDED 22/10/2026). Follows the
  /// chosen brand colour, so a light primary flips its text to black.
  static Color readableOn(Color fill) =>
      fill.computeLuminance() > 0.5 ? AppColors.black : AppColors.white;

  /// The colour to draw a "selected / active" label or icon in when it sits on
  /// [surface] (a card, the rail, the bar). Normally the brand [primary]; but
  /// when the chosen primary is too close to the surface (a grey brand colour
  /// on the dark card, a dark purple in dark mode) it would vanish, so the
  /// readable ink for that surface is used instead. Contrast ≥ 3:1 (WCAG for
  /// large text / icons). ADDED 22/10/2026.
  static Color accentOn(Color surface) {
    final Color primary = AppColors.primary;
    final double a = primary.computeLuminance();
    final double b = surface.computeLuminance();
    final double ratio = (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
    return ratio >= 3 ? primary : readableOn(surface);
  }

  /// Before 22/10/2026 this mixed primary AND secondary; now it is the ink
  /// on [AppColors.primary] alone, like services_module.
  static Color contrastColor() => readableOn(AppColors.primary);

  static Color secondaryPrimaryText() => readableOn(AppColors.secondaryPrimary);

  static Color contrastGreyColor() {
    final double primaryLuminance = AppColors.primary.computeLuminance();
    final double secondaryPrimaryLuminance =
        AppColors.secondaryPrimary.computeLuminance();

    // Check if both colors are light or dark
    if (primaryLuminance > 0.5 && secondaryPrimaryLuminance > 0.5) {
      return AppColors.secondaryBlack; // Return black for light colors
    } else if (primaryLuminance <= 0.5 && secondaryPrimaryLuminance <= 0.5) {
      return AppColors.white; // Return white for dark colors
    } else {
      // If one color is light and the other is dark, return a contrasting color
      return AppColors.white; // Change this to the desired contrasting color
    }
  }
}

// ===== Legacy TextStyle Redirects (StyleText) =====
abstract class StyleText {
  static final _storage = GetStorage();

  // ✅ CHANGED: Made font families getters that read from storage
  static String get englishFontFamily => _storage.read('font') ?? 'Cairo';
  static String get arabicFontFamily => _storage.read('font_arabic') ?? 'Cairo';

  // Helper method to apply font family based on locale.
  //
  // CHANGED 3/9/2026: this used to call `GoogleFonts.getFont`, which fetches
  // the face over the network on first paint. The families are now vendored
  // under assets/fonts and declared in pubspec.yaml — exactly the arrangement
  // knowticed_plus uses — so the family name alone resolves them, offline and
  // with no first-frame flash of a fallback typeface.
  //
  // A family the user picked that is NOT declared in pubspec still resolves
  // through this same line: Flutter simply falls back to the platform default
  // rather than throwing, so there is nothing left to catch.
  static TextStyle _withFontFamily(TextStyle style) {
    final String family = Get.locale?.languageCode == 'en'
        ? englishFontFamily
        : arabicFontFamily;
    return style.copyWith(fontFamily: family);
  }

  // ─── Canonical text styles ──────────────────────────────────────────────────
  //
  // Naming: fontSize<size>Weight<w400|500|600|700>. Size and weight are the
  // ONLY dimensions in the name — what you read is exactly what renders.
  // The colour defaults to AppColors.text; for any other colour use copyWith:
  //
  //   StyleText.fontSize14Weight600.copyWith(color: AppColors.white)
  //
  // These are the only text styles new code should use.

  static TextStyle get fontSize8Weight400 => _withFontFamily(
        TextStyle(
          fontSize: 8.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.regular,
        ),
      );

  static TextStyle get fontSize8Weight500 => _withFontFamily(
        TextStyle(
          fontSize: 8.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.medium,
        ),
      );

  static TextStyle get fontSize10Weight400 => _withFontFamily(
        TextStyle(
          fontSize: 10.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.regular,
        ),
      );

  static TextStyle get fontSize10Weight500 => _withFontFamily(
        TextStyle(
          fontSize: 10.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.medium,
        ),
      );

  static TextStyle get fontSize10Weight600 => _withFontFamily(
        TextStyle(
          fontSize: 10.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.semiBold,
        ),
      );

  static TextStyle get fontSize10Weight700 => _withFontFamily(
        TextStyle(
          fontSize: 10.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.bold,
        ),
      );

  static TextStyle get fontSize11Weight400 => _withFontFamily(
        TextStyle(
          fontSize: 11.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.regular,
        ),
      );

  static TextStyle get fontSize11Weight600 => _withFontFamily(
        TextStyle(
          fontSize: 11.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.semiBold,
        ),
      );

  static TextStyle get fontSize11Weight500 => _withFontFamily(
        TextStyle(
          fontSize: 11.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.medium,
        ),
      );

  static TextStyle get fontSize11Weight700 => _withFontFamily(
        TextStyle(
          fontSize: 11.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.bold,
        ),
      );

  static TextStyle get fontSize12Weight400 => _withFontFamily(
        TextStyle(
          fontSize: 12.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.regular,
        ),
      );

  static TextStyle get fontSize12Weight500 => _withFontFamily(
        TextStyle(
          fontSize: 12.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.medium,
        ),
      );

  static TextStyle get fontSize12Weight600 => _withFontFamily(
        TextStyle(
          fontSize: 12.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.semiBold,
        ),
      );

  static TextStyle get fontSize12Weight700 => _withFontFamily(
        TextStyle(
          fontSize: 12.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.bold,
        ),
      );

  static TextStyle get fontSize18Weight700 => _withFontFamily(
        TextStyle(
          fontSize: 18.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.bold,
        ),
      );

  static TextStyle get fontSize13Weight400 => _withFontFamily(
        TextStyle(
          fontSize: 13.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.regular,
        ),
      );

  static TextStyle get fontSize13Weight500 => _withFontFamily(
        TextStyle(
          fontSize: 13.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.medium,
        ),
      );

  static TextStyle get fontSize13Weight600 => _withFontFamily(
        TextStyle(
          fontSize: 13.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.semiBold,
        ),
      );

  static TextStyle get fontSize14Weight400 => _withFontFamily(
        TextStyle(
          fontSize: 14.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.regular,
        ),
      );

  static TextStyle get fontSize14Weight500 => _withFontFamily(
        TextStyle(
          fontSize: 14.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.medium,
        ),
      );

  static TextStyle get fontSize14Weight600 => _withFontFamily(
        TextStyle(
          fontSize: 14.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.semiBold,
        ),
      );

  static TextStyle get fontSize14Weight700 => _withFontFamily(
        TextStyle(
          fontSize: 14.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.bold,
        ),
      );

  static TextStyle get fontSize15Weight400 => _withFontFamily(
        TextStyle(
          fontSize: 15.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.regular,
        ),
      );

  static TextStyle get fontSize15Weight500 => _withFontFamily(
        TextStyle(
          fontSize: 15.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.medium,
        ),
      );

  static TextStyle get fontSize15Weight600 => _withFontFamily(
        TextStyle(
          fontSize: 15.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.semiBold,
        ),
      );

  static TextStyle get fontSize16Weight400 => _withFontFamily(
        TextStyle(
          fontSize: 16.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.regular,
        ),
      );

  static TextStyle get fontSize16Weight500 => _withFontFamily(
        TextStyle(
          fontSize: 16.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.medium,
        ),
      );

  static TextStyle get fontSize16Weight600 => _withFontFamily(
        TextStyle(
          fontSize: 16.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.semiBold,
        ),
      );

  static TextStyle get fontSize16Weight700 => _withFontFamily(
        TextStyle(
          fontSize: 16.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.bold,
        ),
      );

  static TextStyle get fontSize18Weight400 => _withFontFamily(
        TextStyle(
          fontSize: 18.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.regular,
        ),
      );

  static TextStyle get fontSize18Weight500 => _withFontFamily(
        TextStyle(
          fontSize: 18.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.medium,
        ),
      );

  static TextStyle get fontSize18Weight600 => _withFontFamily(
        TextStyle(
          fontSize: 18.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.semiBold,
        ),
      );

  static TextStyle get fontSize19Weight400 => _withFontFamily(
        TextStyle(
          fontSize: 19.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.regular,
        ),
      );

  static TextStyle get fontSize19Weight500 => _withFontFamily(
        TextStyle(
          fontSize: 19.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.medium,
        ),
      );

  static TextStyle get fontSize19Weight600 => _withFontFamily(
        TextStyle(
          fontSize: 19.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.semiBold,
        ),
      );

  static TextStyle get fontSize20Weight400 => _withFontFamily(
        TextStyle(
          fontSize: 20.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.regular,
        ),
      );

  static TextStyle get fontSize20Weight500 => _withFontFamily(
        TextStyle(
          fontSize: 20.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.medium,
        ),
      );

  static TextStyle get fontSize20Weight600 => _withFontFamily(
        TextStyle(
          fontSize: 20.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.semiBold,
        ),
      );

  static TextStyle get fontSize21Weight500 => _withFontFamily(
        TextStyle(
          fontSize: 21.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.medium,
        ),
      );

  static TextStyle get fontSize22Weight500 => _withFontFamily(
        TextStyle(
          fontSize: 22.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.medium,
        ),
      );

  static TextStyle get fontSize22Weight600 => _withFontFamily(
        TextStyle(
          fontSize: 22.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.semiBold,
        ),
      );

  static TextStyle get fontSize22Weight700 => _withFontFamily(
        TextStyle(
          fontSize: 22.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.bold,
        ),
      );

  static TextStyle get fontSize23Weight400 => _withFontFamily(
        TextStyle(
          fontSize: 23.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.regular,
        ),
      );

  static TextStyle get fontSize23Weight500 => _withFontFamily(
        TextStyle(
          fontSize: 23.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.medium,
        ),
      );

  static TextStyle get fontSize23Weight600 => _withFontFamily(
        TextStyle(
          fontSize: 23.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.semiBold,
        ),
      );

  static TextStyle get fontSize23Weight700 => _withFontFamily(
        TextStyle(
          fontSize: 23.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.bold,
        ),
      );

  static TextStyle get fontSize24Weight500 => _withFontFamily(
        TextStyle(
          fontSize: 24.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.medium,
        ),
      );

  static TextStyle get fontSize24Weight600 => _withFontFamily(
        TextStyle(
          fontSize: 24.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.semiBold,
        ),
      );

  static TextStyle get fontSize25Weight400 => _withFontFamily(
        TextStyle(
          fontSize: 25.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.regular,
        ),
      );

  static TextStyle get fontSize25Weight500 => _withFontFamily(
        TextStyle(
          fontSize: 25.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.medium,
        ),
      );

  static TextStyle get fontSize25Weight600 => _withFontFamily(
        TextStyle(
          fontSize: 25.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.semiBold,
        ),
      );

  static TextStyle get fontSize26Weight400 => _withFontFamily(
        TextStyle(
          fontSize: 26.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.regular,
        ),
      );

  static TextStyle get fontSize26Weight500 => _withFontFamily(
        TextStyle(
          fontSize: 26.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.medium,
        ),
      );

  static TextStyle get fontSize26Weight600 => _withFontFamily(
        TextStyle(
          fontSize: 26.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.semiBold,
        ),
      );

  static TextStyle get fontSize28Weight500 => _withFontFamily(
        TextStyle(
          fontSize: 28.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.medium,
        ),
      );

  static TextStyle get fontSize28Weight600 => _withFontFamily(
        TextStyle(
          fontSize: 28.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.semiBold,
        ),
      );

  static TextStyle get fontSize30Weight500 => _withFontFamily(
        TextStyle(
          fontSize: 30.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.medium,
        ),
      );

  static TextStyle get fontSize30Weight600 => _withFontFamily(
        TextStyle(
          fontSize: 30.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.semiBold,
        ),
      );

  static TextStyle get fontSize35Weight600 => _withFontFamily(
        TextStyle(
          fontSize: 35.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.semiBold,
        ),
      );

  static TextStyle get fontSize36Weight500 => _withFontFamily(
        TextStyle(
          fontSize: 36.sp,
          color: AppColors.text,
          fontWeight: AppFontWeights.medium,
        ),
      );
}
