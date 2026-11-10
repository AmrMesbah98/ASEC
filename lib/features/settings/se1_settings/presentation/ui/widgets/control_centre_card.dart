/// Module: settings / se1_settings
///
///*************************** FILE INFO ****************************///
/// File Name: control_centre_card.dart
/// Purpose: Declares `ControlCentreCard` — the super admin's switchboard:
///          one switch per part of the app, grouped, saved live to
///          Firestore `settings/app` so every open app follows at once.
/// Author: ASEC team
/// Created: 25/9/2026
/// Updated: 23/10/2026 - Calculators group (a switch per calculator).
/// Updated: 23/10/2026 - Screenshot exception switch, indented under
///          "Block screenshots".

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/settings/app_features.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/custom/114-app_messenger.dart';

class ControlCentreCard extends StatelessWidget {
  const ControlCentreCard({super.key});

  static String groupTitle(S s, AppFeatureGroup g) {
    switch (g) {
      case AppFeatureGroup.sections:
        return s.ctlGroupSections;
      case AppFeatureGroup.videos:
        return s.ctlGroupVideos;
      case AppFeatureGroup.calculators:
        return s.ctlGroupCalculators;
      case AppFeatureGroup.general:
        return s.ctlGroupGeneral;
      case AppFeatureGroup.dashboard:
        return s.ctlGroupDashboard;
    }
  }

  static (String, String) texts(S s, AppFeature f) {
    switch (f) {
      case AppFeature.sectionVideos:
        return (s.ctlSectionVideos, s.ctlSectionVideosHint);
      case AppFeature.sectionQuizzes:
        return (s.ctlSectionQuizzes, s.ctlSectionQuizzesHint);
      case AppFeature.sectionCvDirectory:
        return (s.ctlSectionCvDirectory, s.ctlSectionCvDirectoryHint);
      case AppFeature.sectionMyCv:
        return (s.ctlSectionMyCv, s.ctlSectionMyCvHint);
      case AppFeature.videoSequential:
        return (s.ctlVideoSequential, s.ctlVideoSequentialHint);
      case AppFeature.videoBlockSkip:
        return (s.ctlVideoBlockSkip, s.ctlVideoBlockSkipHint);
      case AppFeature.videoAutoplay:
        return (s.ctlVideoAutoplay, s.ctlVideoAutoplayHint);
      case AppFeature.videoUpNext:
        return (s.ctlVideoUpNext, s.ctlVideoUpNextHint);
      case AppFeature.videoOptionsBar:
        return (s.ctlVideoOptionsBar, s.ctlVideoOptionsBarHint);
      case AppFeature.videoSpeed:
        return (s.ctlVideoSpeed, s.ctlVideoSpeedHint);
      case AppFeature.videoResume:
        return (s.ctlVideoResume, s.ctlVideoResumeHint);
      case AppFeature.videoSearch:
        return (s.ctlVideoSearch, s.ctlVideoSearchHint);
      case AppFeature.videoCourseProgress:
        return (s.ctlVideoCourseProgress, s.ctlVideoCourseProgressHint);
      case AppFeature.videoDownloads:
        return (s.ctlVideoDownloads, s.ctlVideoDownloadsHint);
      case AppFeature.videoCloud:
        return (
          'Play lessons from Cloudflare',
          'ON = lessons come only from your Cloudflare lesson server — no Google Drive download limit. '
              'Copy the lessons first (Settings → Cloudflare lessons). OFF = Google Drive.',
        );
      case AppFeature.calcConverter:
        return (s.unitConverter, s.ctlCalcHint);
      case AppFeature.calcEngineering:
        return (s.engineeringCalc, s.ctlCalcEngHint);
      case AppFeature.calcDuct:
        return (s.ductCalc, s.ctlCalcHint);
      case AppFeature.calcPipe:
        return (s.pipeCalc, s.ctlCalcHint);
      case AppFeature.calcPlumbing:
        return (s.plumbingFireCalc, s.ctlCalcHint);
      case AppFeature.calcFire:
        return (s.fireCalc, s.ctlCalcHint);
      case AppFeature.animations:
        return (s.ctlAnimations, s.ctlAnimationsHint);
      case AppFeature.registration:
        return (s.ctlRegistration, s.ctlRegistrationHint);
      case AppFeature.screenProtection:
        return (s.ctlScreenProtection, s.ctlScreenProtectionHint);
      case AppFeature.screenshotException:
        return (s.ctlScreenshotException, s.ctlScreenshotExceptionHint);
      case AppFeature.dashboardCharts:
        return (s.ctlDashboardCharts, s.ctlDashboardChartsHint);
      case AppFeature.dashboardTable:
        return (s.ctlDashboardTable, s.ctlDashboardTableHint);
    }
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final AppFeatures features = AppFeatures.to;

    return AppCard(
      title: s.controlCentre,
      caption: s.controlCentreHint,
      actions: <Widget>[
        AppButton(
          label: s.ctlTurnAllOn,
          icon: Icons.restart_alt_rounded,
          kind: AppButtonKind.subtle,
          dense: true,
          onPressed: features.resetAll,
        ),
      ],
      child: Obx(() {
        // Touch the map so Obx tracks it.
        features.values.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final AppFeatureGroup g in AppFeatureGroup.values) ...<Widget>[
              Padding(
                padding: EdgeInsets.only(top: 10.h, bottom: 6.h),
                child: Text(
                  FormatHelper.capitalize(groupTitle(s, g).toUpperCase()),
                  style: StyleText.fontSize11Weight700.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.chip,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: <Widget>[
                    for (final AppFeature f in AppFeature.values
                        .where((AppFeature f) => f.group == g)) ...<Widget>[
                      _FeatureRow(
                        feature: f,
                        // The exception sits indented under "Block screenshots".
                        indent: f == AppFeature.screenshotException,
                        title: texts(s, f).$1,
                        hint: texts(s, f).$2,
                        value: features.isOn(f),
                        onChanged: (bool v) async {
                          try {
                            await features.set(f, v);
                          } catch (_) {
                            if (context.mounted) {
                              AppMessenger.of(context).show(
                                AppMessage(content: Text(FormatHelper.capitalize(s.errUnknown))),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.feature,
    required this.title,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.indent = false,
  });

  final AppFeature feature;
  final bool indent;
  final String title;
  final String hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: indent ? 36.w : 12.w,
            end: 12.w,
            top: 10.h,
            bottom: 10.h,
          ),
          child: Row(
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 34.r,
                height: 34.r,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: AppIcon(
                    feature.icon,
                    size: 18.sp,
                    color: value ? AppColors.primary : AppColors.secondaryText,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(FormatHelper.capitalize(title), style: StyleText.fontSize14Weight600),
                    Text(
                      FormatHelper.capitalize(hint),
                      style: StyleText.fontSize12Weight400
                          .copyWith(color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                activeTrackColor: AppColors.secondaryPrimary,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
