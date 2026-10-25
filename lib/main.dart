/// Module: app entry
///
///*************************** FILE INFO ****************************///
/// File Name: main.dart
/// Purpose: App bootstrap — storage, Firebase, controllers, screen util,
///          splash.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:asec/core/constants/app_constants.dart';
import 'package:asec/core/helper/main_helper/platform_helper.dart';
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/theme/haptic_controller.dart';
import 'package:asec/core/theme/theme_controller.dart';
import 'package:asec/features/onboarding/o1_splash/presentation/ui/pages/splash_screen.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/settings/app_features.dart';
import 'package:asec/core/settings/app_connectivity.dart';
import 'package:asec/core/settings/app_integrity.dart';
import 'package:asec/core/settings/screen_protection.dart';
import 'package:asec/core/settings/super_admin_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A hot restart (or a reload of the Dart side) loses the old
  // VideoPlayerControllers without disposing them, so the native player kept
  // playing with no screen. init() disposes every native player left over.
  // Windows/Linux have no implementation — that throw is fine to ignore.
  try {
    await VideoPlayerPlatform.instance.init();
  } catch (_) {}

  // Storage first — the theme controller reads it during construction.
  await GetStorage.init();

  // Never throws: a Firebase that will not start sets `notConfigured`, and the
  // sign-in screen says so instead of spinning forever.
  await AppFirebase.initialize();

  // Debug only, and only with --dart-define=SUPER_ADMIN_PASSWORD=…: creates
  // the super admin account on first launch (super_admin_bootstrap.dart).
  await SuperAdminBootstrap.run();

  Get.put(ThemeController(), permanent: true);
  Get.put(HapticController(), permanent: true);
  Get.put(SessionController(), permanent: true);
  Get.put(AppFeatures(), permanent: true);
  // Screenshot block on / off, following the Control centre switch.
  ScreenProtection.start();
  // Release builds refuse to run with developer options, a debugger, root /
  // jailbreak or hooking tools (lib/core/settings/app_integrity.dart).
  AppIntegrity.start();
  // No internet (phone, tablet, Mac, Windows) → the app closes to the unit converter
  // until the connection is back (lib/core/settings/app_connectivity.dart).
  AppConnectivity.start();

  runApp(const AsecApp());
}

class AsecApp extends StatelessWidget {
  const AsecApp({super.key});

  @override
  Widget build(BuildContext context) {
    // NOT a LayoutBuilder. See the note above `_designSizeFor`: a LayoutBuilder
    // here is a layout boundary the whole app rebuilds inside, and a language
    // switch with an overlay alive then mutates it mid-layout and throws.
    // `MediaQuery.fromView` answers the same question — the window's size —
    // rebuilds on resize, and is not a layout boundary.
    return MediaQuery.fromView(
      view: View.of(context),
      child: Builder(
        builder: (BuildContext context) {
          final Size size = MediaQuery.sizeOf(context);
          final double width = size.width > 0 ? size.width : 1440;
          final double height = size.height > 0 ? size.height : 900;

          return _buildApp(_designSizeFor(width, height));
        },
      ),
    );
  }

  /// The ScreenUtil canvas, per device kind:
  ///
  ///  * Desktop / macOS window (>= 1100 wide) — the live window size, so the
  ///    scale is exactly 1 and `.sp` text matches the raw-pixel layout.
  ///  * Phone (< 600 wide, or a real phone) — the 390x844 canvas every `.sp`
  ///    in core/custom was drawn on. THIS IS WHAT MAKES A NARROW WINDOW READ
  ///    AS A PHONE rather than as a squeezed desktop.
  ///  * Tablet — a real tablet gets the window shrunk by 1.3 (everything 30%
  ///    larger than on a desktop). A DESKTOP WINDOW at tablet width keeps 1:1:
  ///    the window is a viewport, not a device, and the tablet LAYOUT is
  ///    chosen by `PlatformHelper.isTabletLayout`, not by the canvas.
  static Size _designSizeFor(double width, double height) {
    if (PlatformHelper.kindForWidth(width) == DeviceKind.desktop) {
      return Size(width, height);
    }
    if (width >= PlatformHelper.tabletBreakpoint) {
      return PlatformHelper.isMobilePlatform
          ? Size(width / 1.3, height / 1.3)
          : Size(width, height);
    }
    return AppConstants.designSize;
  }

  Widget _buildApp(Size designSize) {
    final ThemeController theme = ThemeController.to;

    return ScreenUtilInit(
      designSize: designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (BuildContext context, Widget? child) {
        return Obx(() {
          final bool isDark = theme.isDarkMode.value;
          final String language = theme.languageCode.value;

          AppTheme.isDark = isDark;
          AppColors.currentThemeColors =
              isDark ? AppTheme.darkThemeColors : AppTheme.lightThemeColors;

          return GetMaterialApp(
            onGenerateTitle: (BuildContext context) => S.of(context).appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            locale: Locale(language),
            fallbackLocale: const Locale('en'),
            localizationsDelegates: const <LocalizationsDelegate<Object>>[
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.supportedLocales,
            builder: (BuildContext context, Widget? widget) => Directionality(
              textDirection:
                  language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
              // TAP OUTSIDE = KEYBOARD AWAY. A tap on empty space anywhere
              // (converter, calculators, forms) closes the keyboard. Buttons
              // and fields still get their own taps first.
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: AppIntegrity.gate(
                  AppConnectivity.gate(widget ?? const SizedBox.shrink()),
                ),
              ),
            ),
            home: const SplashScreen(),
          );
        });
      },
    );
  }
}
