/// Module: user / u1_shell
///
///*************************** FILE INFO ****************************///
/// File Name: member_links.dart
/// Purpose: Declares `MemberLink`, `MemberLinks` and `PushedSectionPage` —
///          the member pages that live in Settings → "My space" (My CV,
///          certificate quiz, downloads, engineering calculators) instead of
///          the side menu, and the frame they open in.
/// Author: ASEC team
/// Created: 13/10/2026
///
/// WHY NOT IN THE MENU. The member menu is kept to what is used every day —
/// Home, Videos, the converter, quizzes, CVs. The rest is one tap away in
/// Settings and on the home page, opened ON TOP of the shell with a back
/// arrow.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/settings/app_features.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/cv/c1_cv/presentation/ui/pages/cv_form_page.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/member_bar_actions.dart' show SavedTipsPage;
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/quiz/q2_certificates/presentation/ui/pages/certificate_quizzes_page.dart';
import 'package:asec/features/video/v1_videos/data/download/video_downloads.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/downloads_page.dart';
import 'package:asec/generated/l10n.dart';

/// Settings → My space is two groups (03/11/2026).
enum MemberLinkGroup { learning, resources }

class MemberLink {
  const MemberLink({
    required this.id,
    required this.icon,
    required this.label,
    required this.page,
    this.hint,
    this.group = MemberLinkGroup.resources,
    this.svg,
    this.locked = false,
    this.lockedHint,
  });

  final String id;
  final IconData icon;
  final String label;

  /// The line under the title.
  final String? hint;
  final MemberLinkGroup group;

  /// Its own outline SVG (assets/icons_assets/settings_assets/my_space_*.svg).
  final String? svg;

  /// Shown but not usable yet (My CV until the admin allows it).
  final bool locked;
  final String? lockedHint;
  final Widget Function() page;

  /// Opens the page on top of the shell, with a back arrow.
  Future<void> open(BuildContext context) => PushedSectionPage.open(context, page());
}

abstract final class MemberLinks {
  /// The "My space" pages [user] may open right now, in display order.
  static const String _svg = 'assets/icons_assets/settings_assets/';

  /// The "My space" pages, in display order:
  ///   My Learning   — Saved · Quizzes & Results · My Certificates
  ///   My Resources  — My CV · Downloads · Engineering Tools (CV locked
  ///                   until the admin allows it; tools: coming soon)
  static List<MemberLink> forUser(BuildContext context, AppUser user) {
    final S s = S.of(context);
    final AppFeatures f = AppFeatures.to;
    final bool videos = f.isOn(AppFeature.sectionVideos);
    return <MemberLink>[
      // ── My Learning ──
      // Everything the member saved (the tips & tricks they bookmarked).
      MemberLink(
        id: 'saved',
        icon: Icons.bookmark_border_rounded,
        svg: '${_svg}my_space_saved.svg',
        group: MemberLinkGroup.learning,
        label: s.mySpaceSaved,
        hint: s.mySpaceSavedSub,
        page: () => SavedTipsPage(user: user),
      ),
      if (videos)
        MemberLink(
          id: 'certificate',
          icon: Icons.quiz_rounded,
          svg: '${_svg}my_space_quizzes.svg',
          group: MemberLinkGroup.learning,
          label: s.mySpaceQuizzes,
          hint: s.mySpaceQuizzesSub,
          page: () => CertificateQuizzesPage(user: user),
        ),
      if (videos)
        MemberLink(
          id: 'myCertificates',
          icon: Icons.workspace_premium_rounded,
          svg: '${_svg}my_space_certificate.svg',
          group: MemberLinkGroup.learning,
          label: s.mySpaceCertificates,
          hint: s.mySpaceCertificatesSub,
          page: () => CertificateQuizzesPage(user: user, earnedOnly: true),
        ),
      // ── My Resources ──
      // Always listed; usable once the admin gives this member CV rights.
      if (f.isOn(AppFeature.sectionMyCv))
        MemberLink(
          id: 'myCv',
          icon: Icons.description_outlined,
          svg: '${_svg}my_space_cv.svg',
          label: s.mySpaceCv,
          hint: s.mySpaceCvSub,
          locked: !user.mayWriteCv,
          lockedHint: s.mySpaceCvLocked,
          page: () => CvFormPage(user: user),
        ),
      if (videos && VideoDownloads.enabled)
        MemberLink(
          id: 'downloads',
          icon: Icons.download_for_offline_rounded,
          svg: '${_svg}my_space_downloads.svg',
          label: s.mySpaceDownloads,
          hint: s.mySpaceDownloadsSub,
          page: () => const DownloadsPage(),
        ),
      // 09/11/2026: the "engineering calculators" link is removed — HVAC
      // lives in the Calculations menu (load estimation only).
    ];
  }
}

/// A shell page opened on its own: the shell's bar look, with a back arrow.
class PushedSectionPage extends StatelessWidget {
  const PushedSectionPage({super.key, required this.child, this.title});

  final Widget child;

  /// Shown in the app bar beside the back arrow (09/11/2026). Null keeps
  /// the bar empty — for pages that draw their own title.
  final String? title;

  static Future<void> open(BuildContext context, Widget page, {String? title}) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PushedSectionPage(title: title, child: page),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final String? t = title;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.text),
        // Start-aligned, about 10 from the back arrow — not centred
        // (macOS / iOS centre AppBar titles by default).
        centerTitle: false,
        titleSpacing: 10.w,
        title: t == null || t.isEmpty
            ? const SizedBox.shrink()
            : Text(
                FormatHelper.capitalize(t),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StyleText.fontSize18Weight600.copyWith(color: AppColors.text),
              ),
      ),
      body: child,
    );
  }
}
