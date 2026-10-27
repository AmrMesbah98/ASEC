/// Module: admin / a4_results
///
///*************************** FILE INFO ****************************///
/// File Name: admin_results_page.dart
/// Purpose: Declares `AdminResultsPage` — every attempt by every member, in
///          one table the admin can search, filter and sort.
/// Author: ASEC team
/// Created: 20/9/2026
///
/// WHY THIS PAGE EXISTS SEPARATELY FROM THE PER-QUIZ RESULTS.
/// `QuizAttemptsPage` answers "how did this quiz go". This one answers "how is
/// everybody doing" — the question you cannot ask by opening quizzes one at a
/// time. Same rows, same detail screen behind them; one is scoped to a quiz,
/// the other to the whole centre.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/100-custom_data_table.dart';
import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/8-custom_filter_app.dart';
import 'package:asec/core/helper/main_helper/stream_combine.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/quiz/q1_quizzes/data/repository/quiz_repository.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/base_repository/quiz_base_repository.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_attempt.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/pages/attempt_detail_page.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/network/shared_stream.dart';

/// The quizzes and every attempt, as one value.
class _Results {
  const _Results(this.quizzes, this.attempts);

  final List<Quiz> quizzes;
  final List<QuizAttempt> attempts;
}

class AdminResultsPage extends StatefulWidget {
  const AdminResultsPage({super.key});

  @override
  State<AdminResultsPage> createState() => _AdminResultsPageState();
}

class _AdminResultsPageState extends State<AdminResultsPage> {
  final QuizBaseRepository _repository = QuizRepository();
  final TextEditingController _search = TextEditingController();

  /// `_allQuizzes` or a quiz id.
  static const String _allQuizzes = '__all__';
  String _quizFilter = _allQuizzes;

  String _sortKey = 'date';
  bool _ascending = false;

  late final Stream<_Results> _stream = shared(() => combineLatest<Object, _Results>(
    <Stream<Object>>[
      _repository.watchAll(),
      _repository.watchAllAttempts(),
    ],
    (List<Object> values) => _Results(
      values[0] as List<Quiz>,
      values[1] as List<QuizAttempt>,
    ),
  ));

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Search matches the name OR the email: the admin knows one or the other,
  /// rarely both.
  List<QuizAttempt> _visible(_Results data) {
    final String query = _search.text.trim().toLowerCase();

    final List<QuizAttempt> rows = data.attempts.where((QuizAttempt a) {
      if (_quizFilter != _allQuizzes && a.quizId != _quizFilter) return false;
      if (query.isEmpty) return true;
      return a.userName.toLowerCase().contains(query) ||
          a.userEmail.toLowerCase().contains(query) ||
          a.quizTitle.toLowerCase().contains(query);
    }).toList();

    int compare(QuizAttempt a, QuizAttempt b) {
      switch (_sortKey) {
        case 'member':
          return a.userName.toLowerCase().compareTo(b.userName.toLowerCase());
        case 'quiz':
          return a.quizTitle.toLowerCase().compareTo(b.quizTitle.toLowerCase());
        case 'score':
          return a.percent.compareTo(b.percent);
        case 'date':
        default:
          return (a.submittedAt ?? DateTime(0))
              .compareTo(b.submittedAt ?? DateTime(0));
      }
    }

    rows.sort((QuizAttempt a, QuizAttempt b) =>
        _ascending ? compare(a, b) : compare(b, a));
    return rows;
  }

  void _sort(String key) => setState(() {
        if (_sortKey == key) {
          _ascending = !_ascending;
        } else {
          _sortKey = key;
          // A new column starts the way that column is usually read: names
          // A→Z, everything else biggest / newest first.
          _ascending = key == 'member' || key == 'quiz';
        }
      });

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<_Results>(
        stream: _stream,
        builder: (BuildContext context, AsyncSnapshot<_Results> snapshot) {
          if (snapshot.hasError) return AppErrorView(message: s.errUnknown, error: snapshot.error, stackTrace: snapshot.stackTrace);
          if (!snapshot.hasData) return const AppLoading();

          final _Results data = snapshot.data!;
          final List<QuizAttempt> rows = _visible(data);

          if (data.attempts.isEmpty) {
            return ConsolePage(
              title: s.results,
              subtitle: s.resultsAdminSub,
              child: AppEmptyView(
                title: s.noAttemptsYet,
                subtitle: s.noAttemptsYetSub,
              ),
            );
          }

          return ConsolePage(
            title: s.results,
            subtitle: s.resultsAdminSub,
            scrollable: true,
            actions: <Widget>[
              // The search box belongs in the header with the title, not in
              // the scrolling body where it disappears on the way down.
              ConsoleSearchField(
                hint: s.searchMember,
                onChanged: (String value) => setState(() {
                  _search.text = value;
                }),
              ),
            ],
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _Summary(attempts: data.attempts),
              SizedBox(height: 16.h),
              StatusChipFilter(
                selectedKey: _quizFilter,
                onSelected: (String key) => setState(() => _quizFilter = key),
                items: <StatusChipItem>[
                  StatusChipItem(
                    key: _allQuizzes,
                    label: s.allQuizzes,
                    count: data.attempts.length,
                  ),
                  for (final Quiz quiz in data.quizzes)
                    StatusChipItem(
                      key: quiz.id,
                      label: quiz.title,
                      count: data.attempts
                          .where((QuizAttempt a) => a.quizId == quiz.id)
                          .length,
                    ),
                ],
              ),
              SizedBox(height: 14.h),

              AppCard(
                title: s.results,
                caption: s.rowsShown(
                  '${rows.length}',
                  '${data.attempts.length}',
                ),
                child: AppDataTable<QuizAttempt>(
                  shrinkWrap: true,
                  showRowNumbers: true,
                  rows: rows,
                  sortKey: _sortKey,
                  sortAscending: _ascending,
                  onSort: _sort,
                  emptyState: AppEmptyView(
                    title: s.noAttemptsMatch,
                    subtitle: s.noAttemptsMatchSub,
                    size: 130,
                  ),
                  onRowTap: (QuizAttempt attempt) {
                    // A quiz deleted since the sitting has nothing to open,
                    // so that row is inert rather than crashing.
                    Quiz? quiz;
                    for (final Quiz q in data.quizzes) {
                      if (q.id == attempt.quizId) {
                        quiz = q;
                        break;
                      }
                    }
                    if (quiz == null) return;
                    final Quiz found = quiz;
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            AttemptDetailPage(quiz: found, attempt: attempt),
                      ),
                    );
                  },
                  columns: <AppTableColumn<QuizAttempt>>[
                    AppTableColumn<QuizAttempt>(
                      label: s.member,
                      flex: 3,
                      sortKey: 'member',
                      cell: (BuildContext context, QuizAttempt a) =>
                          AppTableCellText(
                        a.userName.isEmpty ? a.userId : a.userName,
                        emphasis: true,
                      ),
                    ),
                    AppTableColumn<QuizAttempt>(
                      label: s.email,
                      flex: 3,
                      cell: (BuildContext context, QuizAttempt a) =>
                          AppTableCellText(a.userEmail),
                    ),
                    AppTableColumn<QuizAttempt>(
                      label: s.quizLabel,
                      flex: 3,
                      sortKey: 'quiz',
                      cell: (BuildContext context, QuizAttempt a) =>
                          AppTableCellText(a.quizTitle),
                    ),
                    AppTableColumn<QuizAttempt>(
                      label: s.score,
                      flex: 1,
                      sortKey: 'score',
                      cell: (BuildContext context, QuizAttempt a) =>
                          AppTableCellText('${a.score}/${a.totalPoints}'),
                    ),
                    AppTableColumn<QuizAttempt>(
                      label: '%',
                      fixedWidth: 64.w,
                      alignment: Alignment.center,
                      cell: (BuildContext context, QuizAttempt a) =>
                          _PercentChip(percent: a.percent),
                    ),
                    AppTableColumn<QuizAttempt>(
                      label: s.timeTaken,
                      flex: 1,
                      cell: (BuildContext context, QuizAttempt a) =>
                          AppTableCellText(
                        a.timeTaken == null
                            ? '—'
                            : s.minutesSeconds(
                                '${a.timeTaken!.inMinutes}',
                                '${a.timeTaken!.inSeconds.remainder(60)}',
                              ),
                      ),
                    ),
                    AppTableColumn<QuizAttempt>(
                      label: s.finishedAt,
                      flex: 2,
                      sortKey: 'date',
                      cell: (BuildContext context, QuizAttempt a) =>
                          AppTableCellText(
                        AppDates.dateTime(context, a.submittedAt),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
          );
        },
      ),
    );
  }
}

/// Four numbers about EVERY attempt — they do not follow the filter on
/// purpose: the summary is the centre, the table is the question being asked.
class _Summary extends StatelessWidget {
  const _Summary({required this.attempts});

  final List<QuizAttempt> attempts;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    final int count = attempts.length;
    final int people =
        attempts.map((QuizAttempt a) => a.userId).toSet().length;
    final int average = count == 0
        ? 0
        : (attempts.fold<double>(
                  0,
                  (double total, QuizAttempt a) => total + a.percent,
                ) /
                count)
            .round();
    final int passed =
        attempts.where((QuizAttempt a) => a.percent >= 50).length;
    final int passRate = count == 0 ? 0 : ((passed / count) * 100).round();

    return AppCard(
      child: Row(
        children: <Widget>[
          Expanded(child: _Stat(label: s.attempts, value: '$count')),
          Expanded(child: _Stat(label: s.membersWhoTook, value: '$people')),
          Expanded(child: _Stat(label: s.average, value: '$average%')),
          Expanded(child: _Stat(label: s.passRate, value: '$passRate%')),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(FormatHelper.capitalize(value), style: StyleText.fontSize20Weight600),
        SizedBox(height: 2.h),
        Text(
          FormatHelper.capitalize(label),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: StyleText.fontSize12Weight400
              .copyWith(color: AppColors.secondaryText),
        ),
      ],
    );
  }
}

class _PercentChip extends StatelessWidget {
  const _PercentChip({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final Color color = AppColors.onChip;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: AppRadius.buttonR,
      ),
      child: Text(
        FormatHelper.capitalize('${percent.round()}%'),
        textAlign: TextAlign.center,
        style: StyleText.fontSize12Weight700.copyWith(color: color),
      ),
    );
  }
}
