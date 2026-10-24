/// Module: user / u1_shell
///
///*************************** FILE INFO ****************************///
/// File Name: user_shell.dart
/// Purpose: Declares `UserShell` — what a member sees: a home page, the
///          lessons, the unit converter, the quizzes, the CVs and their own
///          settings (with "My space" inside).
/// Author: ASEC team
/// Updated: 23/10/2026 - Each calculator follows its Control centre switch.
/// Updated: 23/10/2026 - Converter tab removed: every member gets the
///          Calculators menu, driven by the Control centre switches.
/// Updated: 23/10/2026 - Settings is the last item, and on a phone always
///          the last entry under "More".
/// Updated: 24/10/2026 - Calculators is the phone bar's centre button
///          (`phoneCenter`) on Android and iOS, same as the admin.
/// Updated: 24/10/2026 - "The Best" (CVs) out of the menu (it is in the
///          library); the website in the phone bar, Quizzes under "More".
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/app_shell.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/pages/user_quizzes_page.dart';
import 'package:asec/features/settings/se1_settings/presentation/ui/pages/settings_page.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/user_videos_page.dart';
import 'package:asec/features/tools/t1_unit_converter/presentation/ui/pages/unit_converter_page.dart';
import 'package:asec/features/tools/t2_engineering_calc/data/calc_access.dart';
import 'package:asec/features/tools/t2_engineering_calc/presentation/ui/pages/engineering_calc_page.dart';
import 'package:asec/features/tools/t3_duct_calc/presentation/ui/pages/duct_calc_page.dart';
import 'package:asec/features/tools/t4_pipe_calc/presentation/ui/pages/pipe_calc_page.dart';
import 'package:asec/features/tools/t5_plumbing_fire/presentation/ui/pages/plumbing_fire_page.dart';
import 'package:asec/features/tools/t5_plumbing_fire/presentation/ui/pages/fire_calc_page.dart';
import 'package:asec/features/user/u1_shell/presentation/ui/widgets/access_gate.dart';
import 'package:asec/features/user/u2_home/presentation/ui/pages/member_home_page.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/features/web/site_preview_page.dart';
import 'package:asec/core/settings/app_features.dart';

class UserShell extends StatelessWidget {
  const UserShell({super.key});

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return Obx(() {
      final AppUser user = SessionController.to.current;
      final AppFeatures f = AppFeatures.to;
      f.values.length; // tracked by Obx: a switch flipped live rebuilds the menu
      final List<ShellSection> calcs = <ShellSection>[
        if (f.calcOn(AppFeature.calcConverter))
          ShellSection(
            id: MemberSectionIds.converter,
            icon: Icons.swap_horiz_rounded,
            label: s.unitConverter,
            shortLabel: s.unitConverterShort,
            page: const UnitConverterPage(),
          ),
        if (f.calcOn(AppFeature.calcEngineering))
          ShellSection(
            id: 'engineeringCalc',
            icon: Icons.engineering_rounded,
            label: s.engineeringCalc,
            shortLabel: s.engineeringCalcShort,
            page: const EngineeringCalcPage(),
          ),
        if (f.calcOn(AppFeature.calcDuct))
          ShellSection(
            id: 'ductCalc',
            icon: Icons.air_rounded,
            label: s.ductCalc,
            shortLabel: s.ductCalcShort,
            page: const DuctCalcPage(),
          ),
        if (f.calcOn(AppFeature.calcPipe))
          ShellSection(
            id: 'pipeCalc',
            icon: Icons.plumbing_rounded,
            label: s.pipeCalc,
            shortLabel: s.pipeCalcShort,
            page: const PipeCalcPage(),
          ),
        if (f.calcOn(AppFeature.calcPlumbing))
          ShellSection(
            id: 'plumbingFireCalc',
            icon: Icons.water_drop_rounded,
            label: s.plumbingFireCalc,
            shortLabel: s.plumbingFireCalcShort,
            page: const PlumbingFirePage(),
          ),
        if (f.calcOn(AppFeature.calcFire))
          ShellSection(
            id: 'fireCalc',
            icon: Icons.local_fire_department_rounded,
            label: s.fireCalc,
            shortLabel: s.fireCalcShort,
            page: const FireCalcPage(),
          ),
      ];

      // The calculators' unlock is remembered on the device so they still
      // open on the offline screen (CalcAccess).
      CalcAccess.remember(user);

      // The admin's per-member access: paused / not started / ended /
      // wrong device keep the member out with a screen that says why.
      //
      // THE MENU IS KEPT TO THE EVERYDAY SECTIONS — Home, Videos, the unit
      // converter, quizzes, the website, Settings, and "The Best" (CVs) last,
      // inside "More" on a phone. My CV, the certificate quiz,
      // downloads and the engineering calculators (once bought) live in
      // Settings → "My space" and on the home page (member_links.dart).
      return AccessGate(
        user: user,
        child: AppShell(
          user: user,
          sections: <ShellSection>[
            ShellSection(
              id: MemberSectionIds.home,
              icon: Icons.home_rounded,
              label: s.home,
              page: const MemberHomePage(),
            ),
            if (f.isOn(AppFeature.sectionVideos))
              ShellSection(
                id: MemberSectionIds.videos,
                icon: Icons.video_library_rounded,
                label: s.typeVideos,
                page: const UserVideosPage(),
              ),
            // Works offline — no Firestore behind it. The converter keeps its
            // id inside the group, so AppShell.open still finds it.
            // EVERY member gets the Calculators menu (no separate converter
            // tab any more); each calculator follows its Control centre
            // switch — all on by default except Engineering.
            if (calcs.isNotEmpty)
              ShellSection.group(
                id: 'calculators',
                icon: Icons.calculate_rounded,
                label: s.engineeringCalcShort,
                children: calcs,
                // Phone (Android AND iOS): the raised centre button of the
                // bar, like the admin's; its calculators stack up above it.
                phoneCenter: true,
              ),
            if (f.isOn(AppFeature.sectionQuizzes))
              ShellSection(
                id: MemberSectionIds.quizzes,
                icon: Icons.quiz_outlined,
                label: s.quizzes,
                page: UserQuizzesPage(user: user),
                // On a phone: under "More", so the website gets the bar.
                phoneMore: true,
              ),
            // THE WEBSITE in the phone bar (Quizzes moved to "More").
            ShellSection(
              id: MemberSectionIds.web,
              icon: Icons.language_rounded,
              label: s.webTab,
              page: SitePreviewPage(title: s.webTab, closable: false),
            ),
            // "The Best" (the CVs) is not in the menu: it opens from its
            // tile in the home page's library.
            // SETTINGS LAST: the final item of the list, and on a phone
            // always under "More" (at the bottom of it).
            ShellSection(
              id: MemberSectionIds.settings,
              icon: Icons.settings_rounded,
              label: s.settings,
              page: SettingsPage(user: user),
              phoneMore: true,
            ),
          ],
        ),
      );
    });
  }
}
