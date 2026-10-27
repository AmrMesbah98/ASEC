/// Module: cv / c1_cv
///
///*************************** FILE INFO ****************************///
/// File Name: cv_directory_page.dart
/// Purpose: Declares `CvDirectoryPage` — every CV in the centre, searchable.
/// Author: ASEC team
/// Created: 20/9/2026
///
/// ONE PAGE, TWO AUDIENCES. Members browse each other's CVs here; the admin
/// sees the same list with the review state on every card and delete inside.
/// [isAdmin] is the only difference, and it changes what is SHOWN, never what
/// is read — the rules let every signed-in account read the directory.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/features/cv/c1_cv/data/repository/cv_repository.dart';
import 'package:asec/features/cv/c1_cv/domain/base_repository/cv_base_repository.dart';
import 'package:asec/features/cv/c1_cv/domain/entities/cv_profile.dart';
import 'package:asec/features/cv/c1_cv/presentation/ui/pages/cv_detail_page.dart';
import 'package:asec/features/cv/c1_cv/presentation/ui/widgets/cv_card.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/network/shared_stream.dart';

class CvDirectoryPage extends StatefulWidget {
  const CvDirectoryPage({super.key, this.isAdmin = false});

  final bool isAdmin;

  @override
  State<CvDirectoryPage> createState() => _CvDirectoryPageState();
}

class _CvDirectoryPageState extends State<CvDirectoryPage> {
  final CvBaseRepository _repository = CvRepository();
  final TextEditingController _search = TextEditingController();
  late final Stream<List<CvProfile>> _cvs = shared(() => _repository.watchAll());

  static const String _allRoles = '__all__';
  String _roleFilter = _allRoles;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Search covers name, email, role, specialization, location and every
  /// skill — one box, because the reader does not know which field holds the
  /// word they remember.
  List<CvProfile> _visible(List<CvProfile> all) {
    final String query = _search.text.trim().toLowerCase();
    return all.where((CvProfile cv) {
      if (_roleFilter != _allRoles && cv.role != _roleFilter) return false;
      if (query.isEmpty) return true;
      return cv.searchIndex.contains(query);
    }).toList();
  }

  Widget _card(BuildContext context, CvProfile cv) {
    return CvCard(
      cv: cv,
      showStatus: widget.isAdmin,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CvDetailPage(cv: cv, isAdmin: widget.isAdmin),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<CvProfile>>(
        stream: _cvs,
        builder: (BuildContext context, AsyncSnapshot<List<CvProfile>> snap) {
          if (snap.hasError) return AppErrorView(message: s.errUnknown, error: snap.error, stackTrace: snap.stackTrace);
          if (!snap.hasData) return const AppLoading();

          final List<CvProfile> all = snap.data!;
          if (all.isEmpty) {
            return ConsolePage(
              title: s.cvs,
              subtitle: widget.isAdmin ? s.cvAdminSub : s.cvDirectorySub,
              child: AppEmptyView(
                title: s.noCvsTitle,
                subtitle: widget.isAdmin ? s.noCvsSubAdmin : s.noCvsSubUser,
              ),
            );
          }

          final List<CvProfile> rows = _visible(all);

          // The roles are taken from the CVs that exist, not from the full
          // role list: a choice that filters to nothing is a dead end.
          final Map<String, int> roleCounts = <String, int>{};
          for (final CvProfile cv in all) {
            if (cv.role.isEmpty) continue;
            roleCounts[cv.role] = (roleCounts[cv.role] ?? 0) + 1;
          }

          return ConsolePage(
            title: s.cvs,
            subtitle: widget.isAdmin ? s.cvAdminSub : s.cvDirectorySub,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                // Cards sit in rows of equal height, as many per row as fit at
                // 300+ wide. No fixed cell height — a card is as tall as what
                // it holds, so short CVs no longer leave an empty box.
                const double gap = 14;
                final int perRow = ((constraints.maxWidth + gap) / (300 + gap))
                    .floor()
                    .clamp(1, 4);
                final int rowCount = (rows.length / perRow).ceil();

                return CustomScrollView(
                  slivers: <Widget>[
                    // Search + role chips scroll with the list.
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 560),
                              child: ConsoleSearchField(
                                hint: s.searchCv,
                                width: double.infinity,
                                onChanged: (String value) => setState(() {
                                  _search.text = value;
                                }),
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          // Chips scroll sideways, so many roles never run
                          // off a phone screen.
                          SizedBox(
                            height: 36.h,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: <Widget>[
                                _RoleChip(
                                  label: s.all,
                                  count: all.length,
                                  selected: _roleFilter == _allRoles,
                                  onTap: () =>
                                      setState(() => _roleFilter = _allRoles),
                                ),
                                for (final MapEntry<String, int> e
                                    in roleCounts.entries)
                                  _RoleChip(
                                    label: e.key,
                                    count: e.value,
                                    selected: _roleFilter == e.key,
                                    onTap: () =>
                                        setState(() => _roleFilter = e.key),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                        ],
                      ),
                    ),
                    if (rows.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: AppEmptyView(
                          title: s.noRowsMatch,
                          subtitle: s.noAttemptsMatchSub,
                          size: 130,
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.only(bottom: 24.h),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int r) {
                              final List<Widget> cells = <Widget>[];
                              for (int c = 0; c < perRow; c++) {
                                final int index = r * perRow + c;
                                if (c > 0) cells.add(const SizedBox(width: gap));
                                cells.add(
                                  Expanded(
                                    child: index < rows.length
                                        ? _card(context, rows[index])
                                        : const SizedBox.shrink(),
                                  ),
                                );
                              }
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: r == rowCount - 1 ? 0 : gap,
                                ),
                                child: perRow == 1
                                    ? _card(context, rows[r])
                                    : IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: cells,
                                        ),
                                      ),
                              );
                            },
                            childCount: rowCount,
                          ),
                        ),
                      ),
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

/// One role filter: name + how many CVs it has. Filled when selected.
class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fg = selected ? AppColors.textButton : AppColors.text;
    return Padding(
      padding: EdgeInsetsDirectional.only(end: 8.w),
      child: Material(
        color: selected ? AppColors.primary : AppColors.card,
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : AppColors.secondaryText.withOpacity(0.18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  FormatHelper.capitalize(label),
                  style: StyleText.fontSize12Weight600.copyWith(color: fg),
                ),
                SizedBox(width: 6.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.textButton.withOpacity(0.22)
                        : AppColors.chip,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    FormatHelper.capitalize('$count'),
                    style: StyleText.fontSize10Weight600.copyWith(
                      color: selected ? AppColors.textButton : AppColors.onChip,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
