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
import 'package:asec/core/custom/8-custom_filter_app.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/features/cv/c1_cv/data/repository/cv_repository.dart';
import 'package:asec/features/cv/c1_cv/domain/base_repository/cv_base_repository.dart';
import 'package:asec/features/cv/c1_cv/domain/constants/cv_options.dart';
import 'package:asec/features/cv/c1_cv/domain/entities/cv_profile.dart';
import 'package:asec/features/cv/c1_cv/presentation/ui/pages/cv_detail_page.dart';
import 'package:asec/features/cv/c1_cv/presentation/ui/widgets/cv_card.dart';
import 'package:asec/generated/l10n.dart';
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

          // The three positions are always shown, in a fixed order, each
          // with how many CVs it holds — even when that is zero, so a reader
          // sees at a glance which positions have members.
          final Map<String, int> roleCounts = <String, int>{
            for (final String role in CvOptions.roles) role: 0,
          };
          for (final CvProfile cv in all) {
            if (!roleCounts.containsKey(cv.role)) continue;
            roleCounts[cv.role] = roleCounts[cv.role]! + 1;
          }

          // 09/11/2026: search and filters the same as Members (admin):
          // the search field in the header, the status chips under it.
          return ConsolePage(
            title: s.cvs,
            subtitle: widget.isAdmin ? s.cvAdminSub : s.cvDirectorySub,
            actions: <Widget>[
              ConsoleSearchField(
                hint: s.searchCv,
                onChanged: (String value) => setState(() {
                  _search.text = value;
                }),
              ),
            ],
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                // Cards sit in rows of equal height, as many per row as fit at
                // 300+ wide. No fixed cell height — a card is as tall as what
                // it holds, so short CVs no longer leave an empty box.
                const double gap = 10;
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
                          ConsoleFilters(
                            compact: true,
                            selectedKey: _roleFilter,
                            onSelected: (String key) =>
                                setState(() => _roleFilter = key),
                            items: <StatusChipItem>[
                              StatusChipItem(
                                key: _allRoles,
                                label: s.all,
                                count: all.length,
                              ),
                              for (final MapEntry<String, int> e in roleCounts.entries)
                                StatusChipItem(
                                  key: e.key,
                                  label: e.key,
                                  count: e.value,
                                ),
                            ],
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
