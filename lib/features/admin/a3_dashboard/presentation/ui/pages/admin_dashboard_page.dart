/// Module: admin / a3_dashboard
///
///*************************** FILE INFO ****************************///
/// File Name: admin_dashboard_page.dart
/// Purpose: Declares `AdminDashboardPage` — the centre at a glance: the four
///          numbers, four charts, and the latest attempts as rows.
/// Author: ASEC team
/// Created: 19/9/2026
/// Updated: 20/9/2026 - Charts and a table, the way manger_plus's console
///          dashboard does it. The page was four tiles and a list before.
///
/// LAYOUT
/// ------
/// Tiles, charts, table — the same descent from "how are we doing" to "which
/// record" the manger_plus dashboard uses. The page scrolls as one column and
/// the table shrink-wraps, so there is never a scrollbar inside a scrollbar.
///
/// ONE READ, FOUR STREAMS. Members, videos, quizzes and attempts are combined
/// into a single snapshot ([DashboardData]) before anything is drawn: four
/// separate `StreamBuilder`s would each flash their own spinner, and two cards
/// could disagree about the same number mid-frame.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/69-cross_axis_count_helper.dart';
import 'package:asec/core/helper/main_helper/stream_combine.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/features/admin/a3_dashboard/presentation/ui/widgets/dashboard_charts.dart';
import 'package:asec/features/admin/a3_dashboard/presentation/ui/widgets/dashboard_data.dart';
import 'package:asec/features/admin/a3_dashboard/presentation/ui/widgets/dashboard_kpi_card.dart';
import 'package:asec/features/admin/a3_dashboard/presentation/ui/widgets/dashboard_table.dart';
import 'package:asec/features/onboarding/o2_authentication/data/repository/auth_repository.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/base_repository/auth_base_repository.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/quiz/q1_quizzes/data/repository/quiz_repository.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/base_repository/quiz_base_repository.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_attempt.dart';
import 'package:asec/features/video/v1_videos/data/repository/video_repository.dart';
import 'package:asec/features/video/v1_videos/domain/base_repository/video_base_repository.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/admin_permission.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/animation/app_animations.dart';
import 'package:asec/core/settings/app_features.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/network/shared_stream.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key, required this.admin});

  final AppUser admin;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  /// Sky blue: the videos card needs a colour of its own next to the
  /// primary, orange and green cards.
  final UsersBaseRepository _users = UsersRepository();
  final VideoBaseRepository _videos = VideoRepository();
  final QuizBaseRepository _quizzes = QuizRepository();

  late final Stream<DashboardData> _stream = shared(() => combineLatest<Object, DashboardData>(
    <Stream<Object>>[
      _users.watchMembers(),
      _videos.watchAll(),
      _quizzes.watchAll(),
      _quizzes.watchAllAttempts(),
    ],
    (List<Object> values) => DashboardData(
      members: values[0] as List<AppUser>,
      videos: values[1] as List<VideoItem>,
      quizzes: values[2] as List<Quiz>,
      attempts: values[3] as List<QuizAttempt>,
    ),
  ));

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<DashboardData>(
        stream: _stream,
        builder: (BuildContext context, AsyncSnapshot<DashboardData> snapshot) {
          if (snapshot.hasError) return AppErrorView(message: s.errUnknown, error: snapshot.error, stackTrace: snapshot.stackTrace);
          if (!snapshot.hasData) return const AppLoading();

          final DashboardData data = snapshot.data!;

          return ConsolePage(
            title: s.helloName(widget.admin.firstName),
            subtitle: s.dashboardAsecSub,
            child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool phone = constraints.maxWidth < 600;
              return ListView(
                padding: EdgeInsets.only(bottom: 16.h),
                children: <Widget>[
                  // ── The four numbers ─────────────────────────────────────
                  // PHONES: four small tiles, two by two, instead of four
                  // tall cards stacked down the whole screen.
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: phone
                        ? SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisExtent: 148,
                            crossAxisSpacing: 10.w,
                            mainAxisSpacing: 10.h,
                          )
                        : CrossAxisCountHelper.gridDelegate(
                            context,
                            mainAxisExtent: 196,
                            minCellWidth: 250,
                            availableWidth: constraints.maxWidth,
                          ),
                    children: <Widget>[
                      FadeSlideIn(
                        delay: staggerDelay(0, stepMs: 90),
                        child: KpiCard(
                        compact: phone,
                        icon: Icons.groups_2_rounded,
                        accent: AppColors.primary,
                        label: s.totalMembers,
                        value: '${data.members.length}',
                        badge: data.newMembersThisWeek > 0
                            ? s.kpiNewThisWeek(data.newMembersThisWeek)
                            : null,
                        sparkline: data.membersGrowth(),
                        facts: <KpiFact>[
                          KpiFact(s.active, '${data.activeMembers}'),
                          KpiFact(s.inactive, '${data.inactiveMembers}'),
                          KpiFact(s.kpiCvAccess, '${data.cvMembers}'),
                        ],
                      ),
                      ),
                      FadeSlideIn(
                        delay: staggerDelay(1, stepMs: 90),
                        child: KpiCard(
                        compact: phone,
                        icon: Icons.video_library_rounded,
                        accent: AppColors.primary,
                        label: s.totalVideos,
                        value: '${data.videos.length}',
                        badge: data.newVideosThisMonth > 0
                            ? s.kpiNewThisMonth(data.newVideosThisMonth)
                            : null,
                        sparkline: data.videosGrowth(),
                        facts: <KpiFact>[
                          KpiFact(s.published, '${data.publishedVideos}'),
                          KpiFact(s.kpiDrafts, '${data.draftVideos}'),
                          KpiFact(s.kpiLibrarySize, data.librarySize),
                        ],
                      ),
                      ),
                      FadeSlideIn(
                        delay: staggerDelay(2, stepMs: 90),
                        child: KpiCard(
                        compact: phone,
                        icon: Icons.quiz_outlined,
                        accent: AppColors.primary,
                        label: s.totalQuizzes,
                        value: '${data.quizzes.length}',
                        badge: data.openQuizzes > 0
                            ? s.kpiOpenNow(data.openQuizzes)
                            : null,
                        badgeIcon: Icons.bolt_rounded,
                        sparkline: data.quizzesGrowth(),
                        facts: <KpiFact>[
                          KpiFact(s.open, '${data.openQuizzes}'),
                          KpiFact(s.quizClosed, '${data.closedQuizzes}'),
                          KpiFact(s.questions, '${data.totalQuestions}'),
                        ],
                      ),
                      ),
                      FadeSlideIn(
                        delay: staggerDelay(3, stepMs: 90),
                        child: KpiCard(
                        compact: phone,
                        icon: Icons.fact_check_rounded,
                        accent: AppColors.primary,
                        label: s.totalAttempts,
                        value: '${data.attempts.length}',
                        badge: data.attemptsThisWeek > 0
                            ? s.kpiNewThisWeek(data.attemptsThisWeek)
                            : null,
                        sparkline: data
                            .attemptsByDay(days: 14)
                            .map((Series e) => e.value)
                            .toList(),
                        facts: <KpiFact>[
                          KpiFact(s.average, '${data.averagePercent}%'),
                          KpiFact(s.passRate, '${data.passRatePercent}%'),
                          KpiFact(s.kpiTimedOut, '${data.autoSubmittedAttempts}'),
                        ],
                      ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  if (AppFeatures.to.isOn(AppFeature.dashboardCharts) &&
                      widget.admin.canDo(AdminAction.dashboardCharts)) ...<Widget>[
                  // ── The charts ───────────────────────────────────────────
                  AppSectionHeader(
                    title: s.charts,
                    caption: data.hasAttempts ? null : s.nothingToChartAsec,
                  ),
                  SizedBox(height: 12.h),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 380),
                    child: DashboardCharts(data: data),
                  ),
                  SizedBox(height: 20.h),

                  ],
                  if (AppFeatures.to.isOn(AppFeature.dashboardTable) &&
                      widget.admin.canDo(AdminAction.dashboardTable)) ...<Widget>[
                  // ── The records ──────────────────────────────────────────
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 520),
                    child: DashboardTable(data: data),
                  ),
                  ],
                  SizedBox(height: 24.h),
                ],
              );
            },
          ),
          );
        },
      ),
    );
  }
}

/// One number with its icon. Public so the charts row and the tiles row can
/// never drift apart in padding or type scale.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
  });

  final IconData icon;
  final String label;
  final String value;

  /// A second line under the label — "Average 72%", say.
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 42.r,
            height: 42.r,
            decoration: BoxDecoration(
              color: AppColors.chip,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: AppIcon(icon, size: 22.sp, color: AppColors.primary),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(FormatHelper.capitalize(value), style: StyleText.fontSize22Weight700),
                Text(
                  FormatHelper.capitalize(label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StyleText.fontSize12Weight400
                      .copyWith(color: AppColors.secondaryText),
                ),
                if (caption != null)
                  Text(
                    FormatHelper.capitalize(caption!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StyleText.fontSize11Weight600
                        .copyWith(color: AppColors.primary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
