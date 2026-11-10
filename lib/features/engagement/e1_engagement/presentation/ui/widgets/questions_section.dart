/// Module: engagement / e1_engagement
///
///*************************** FILE INFO ****************************///
/// File Name: questions_section.dart
/// Purpose: Questions & answers (03/11/2026). Members ask, an admin with
///          Engagement → Questions answers, and the pair shows like a
///          Facebook post with its reply:
///            * `QuestionsSection` — home page, above the partners: the 3
///              newest answered questions, "Ask a question", "See more".
///            * `QuestionsPage`    — every answered question, plus the
///              member's own questions still waiting.
///            * `AdminQuestionsTab` — Engagement → Questions: answer, edit,
///              delete.
/// Author: ASEC team
/// Created: 3/11/2026
///
/// Question and answer texts are shown AS WRITTEN (no title case).

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/constants/app_assets.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/2-custom_textfield.dart';
import 'package:asec/core/custom/57-custom_dialog_manager.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/helper/main_helper/text_direction_helper.dart';
import 'package:asec/core/network/shared_stream.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/features/engagement/e1_engagement/data/repository/engagement_repository.dart';
import 'package:asec/features/engagement/e1_engagement/domain/entities/engagement_entities.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/engagement_widgets.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/user/u1_shell/presentation/ui/widgets/member_links.dart';
import 'package:asec/generated/l10n.dart';

/// How many answered questions the home page shows.
const int kHomeQuestions = 3;

/// Max lines before "See more" (09/11/2026): long questions / answers are
/// cut to the same height, and a tap shows the whole text.
const int kQaQuestionLines = 3;
const int kQaAnswerLines = 4;

// ── Ask: one question at a time (03/11/2026) ──────────────────────────────

/// "Ask a question" — or, while this member's last question is still
/// waiting for an answer, a "Waiting for an answer" tag instead: a member
/// may ask again only once the admin has replied.
class _AskControl extends StatefulWidget {
  const _AskControl({required this.user});

  final AppUser user;

  @override
  State<_AskControl> createState() => _AskControlState();
}

class _AskControlState extends State<_AskControl> {
  late final Stream<List<AppQuestion>> _mine = shared(() => EngagementRepository().watchMyQuestions(widget.user.uid));

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return StreamBuilder<List<AppQuestion>>(
      stream: _mine,
      builder: (BuildContext context, AsyncSnapshot<List<AppQuestion>> snap) {
        // Until we know, nothing (no button that might be wrong).
        if (!snap.hasData) return const SizedBox.shrink();
        final bool waiting = snap.data!.any((AppQuestion q) => !q.answered);
        if (waiting) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.statusPending.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppIcon(Icons.hourglass_empty_rounded, size: 14.r, color: AppColors.statusPending),
                SizedBox(width: 6.w),
                Text(
                  FormatHelper.capitalize(s.qaWaiting),
                  style: StyleText.fontSize12Weight600.copyWith(color: AppColors.statusPending),
                ),
              ],
            ),
          );
        }
        return AppButton(
          label: s.qaAsk,
          icon: Icons.edit_note_rounded,
          dense: true,
          onPressed: () => showAskQuestionDialog(context, widget.user),
        );
      },
    );
  }
}

// ── Home page section ───────────────────────────────────────────────────────

class QuestionsSection extends StatefulWidget {
  const QuestionsSection({super.key, required this.user});

  final AppUser user;

  @override
  State<QuestionsSection> createState() => _QuestionsSectionState();
}

class _QuestionsSectionState extends State<QuestionsSection> {
  late final Stream<List<AppQuestion>> _answered = shared(() => EngagementRepository().watchAnsweredQuestions());

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                FormatHelper.capitalize(s.qaTitle),
                style: StyleText.fontSize18Weight600.copyWith(color: AppColors.text),
              ),
            ),
            _AskControl(user: widget.user),
          ],
        ),
        SizedBox(height: 10.h),
        StreamBuilder<List<AppQuestion>>(
          stream: _answered,
          builder: (BuildContext context, AsyncSnapshot<List<AppQuestion>> snap) {
            if (!snap.hasData) return const SizedBox.shrink();
            final List<AppQuestion> all = snap.data!;
            if (all.isEmpty) {
              return _Box(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Column(
                    children: <Widget>[
                      Text(FormatHelper.capitalize(s.qaEmpty),
                          style: StyleText.fontSize14Weight600.copyWith(color: AppColors.text)),
                      SizedBox(height: 4.h),
                      Text(s.qaEmptySub,
                          textAlign: TextAlign.center,
                          style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText)),
                    ],
                  ),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final AppQuestion q in all.take(kHomeQuestions))
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: QuestionPostCard(question: q),
                  ),
                // Always offered: the page also holds the member's own
                // questions still waiting for an answer.
                // Text only, on the LEFT (09/11/2026).
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => PushedSectionPage.open(context, QuestionsPage(user: widget.user)),
                    child: Text(
                      FormatHelper.capitalize(s.qaSeeMore),
                      style: StyleText.fontSize13Weight600.copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ── The full page ───────────────────────────────────────────────────────────

class QuestionsPage extends StatefulWidget {
  const QuestionsPage({super.key, required this.user});

  final AppUser user;

  @override
  State<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage> {
  final EngagementRepository _repo = EngagementRepository();
  late final Stream<List<AppQuestion>> _answered = shared(() => _repo.watchAnsweredQuestions());
  late final Stream<List<AppQuestion>> _mine = shared(() => _repo.watchMyQuestions(widget.user.uid));

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return ConsolePage(
      title: s.qaTitle,
      actions: <Widget>[
        _AskControl(user: widget.user),
      ],
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // The member's own questions still waiting.
          StreamBuilder<List<AppQuestion>>(
            stream: _mine,
            builder: (BuildContext context, AsyncSnapshot<List<AppQuestion>> snap) {
              final List<AppQuestion> waiting =
                  (snap.data ?? const <AppQuestion>[]).where((AppQuestion q) => !q.answered).toList();
              if (waiting.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _Heading(s.qaMine),
                  for (final AppQuestion q in waiting)
                    Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: QuestionPostCard(
                        question: q,
                        trailing: IconButton(
                          tooltip: s.delete,
                          icon: AppIcon(Icons.delete_outline_rounded, size: 18.r, color: AppColors.secondaryText),
                          onPressed: () => _confirmDelete(context, q),
                        ),
                      ),
                    ),
                  SizedBox(height: 8.h),
                ],
              );
            },
          ),
          _Heading(s.qaAll),
          StreamBuilder<List<AppQuestion>>(
            stream: _answered,
            builder: (BuildContext context, AsyncSnapshot<List<AppQuestion>> snap) {
              if (snap.hasError) return AppErrorView(message: s.errUnknown, error: snap.error);
              if (!snap.hasData) return const AppLoading();
              final List<AppQuestion> all = snap.data!;
              if (all.isEmpty) return AppEmptyView(title: s.qaEmpty, subtitle: s.qaEmptySub);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final AppQuestion q in all)
                    Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: QuestionPostCard(question: q),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Admin: Engagement → Questions ───────────────────────────────────────────

class AdminQuestionsTab extends StatefulWidget {
  const AdminQuestionsTab({super.key});

  @override
  State<AdminQuestionsTab> createState() => _AdminQuestionsTabState();
}

class _AdminQuestionsTabState extends State<AdminQuestionsTab> {
  late final Stream<List<AppQuestion>> _all = shared(() => EngagementRepository().watchAllQuestions());

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return StreamBuilder<List<AppQuestion>>(
      stream: _all,
      builder: (BuildContext context, AsyncSnapshot<List<AppQuestion>> snap) {
        if (snap.hasError) return AppErrorView(message: engErrorText(context, snap.error), error: snap.error);
        if (!snap.hasData) return const AppLoading();
        final List<AppQuestion> all = snap.data!;
        if (all.isEmpty) return AppEmptyView(title: s.qaNoQuestions);
        return ListView.separated(
          padding: EdgeInsets.only(bottom: 24.h),
          itemCount: all.length,
          separatorBuilder: (_, __) => SizedBox(height: 10.h),
          itemBuilder: (BuildContext context, int i) {
            final AppQuestion q = all[i];
            return QuestionPostCard(
              question: q,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AppButton(
                    label: q.answered ? s.qaEditAnswer : s.qaAnswer,
                    icon: Icons.edit_note_rounded,
                    dense: true,
                    kind: q.answered ? AppButtonKind.subtle : AppButtonKind.filled,
                    onPressed: () => showAnswerDialog(context, q),
                  ),
                  IconButton(
                    tooltip: s.delete,
                    icon: AppIcon(Icons.delete_outline_rounded, size: 18.r, color: AppColors.red),
                    onPressed: () => _confirmDelete(context, q),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

Future<void> _confirmDelete(BuildContext context, AppQuestion q) async {
  final S s = S.of(context);
  await CustomDialogManager.showConfirm(
    context: context,
    title: s.qaDeleteQuestion,
    subtitle: q.text,
    confirmLabel: s.delete,
    cancelLabel: s.cancel,
    onConfirm: () async {
      try {
        await EngagementRepository().deleteQuestion(q.id);
      } catch (e) {
        if (context.mounted) showEngagementToast(context, engErrorText(context, e));
      }
    },
  );
}

// ── The post card ───────────────────────────────────────────────────────────

/// A question as a post: who asked and when, the question, then the ASEC
/// team's reply under it (or "Waiting for an answer").
class QuestionPostCard extends StatelessWidget {
  const QuestionPostCard({super.key, required this.question, this.trailing});

  final AppQuestion question;

  /// Admin buttons / the member's delete, top-right.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final AppQuestion q = question;
    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppAvatar(name: q.userName, size: 36),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      FormatHelper.capitalize(q.userName.isEmpty ? '—' : q.userName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StyleText.fontSize14Weight600.copyWith(color: AppColors.text),
                    ),
                    Text(
                      AppDates.dateTime(context, q.createdAt),
                      style: StyleText.fontSize11Weight400.copyWith(color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          SizedBox(height: 10.h),
          // In the question's OWN direction (Arabic right-to-left, English
          // left-to-right), whatever the app's language.
          QaExpandableText(
            text: q.text,
            maxLines: kQaQuestionLines,
            style: StyleText.fontSize14Weight400.copyWith(color: AppColors.text, height: 1.5),
          ),
          SizedBox(height: 10.h),
          if (q.answered)
            // The reply, indented under the post like a comment — the whole
            // card (logo, "ASEC Team", text) in the ANSWER's direction, so an
            // Arabic answer reads right-to-left in the English app too.
            Directionality(
              textDirection: TextDirectionHelper.inContext(context, q.answer),
              child: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ClipOval(
                    child: Container(
                      width: 30.r,
                      height: 30.r,
                      color: AppColors.card,
                      padding: EdgeInsets.all(4.r),
                      // Dark mode: the logo all white, like the app bar and
                      // the splash (09/11/2026 — it kept its light-mode
                      // colours here and read wrong on the dark card).
                      child: Image.asset(
                        AppAssets.brandLogo,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : null,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                FormatHelper.capitalize(s.qaTeam),
                                style: StyleText.fontSize13Weight600.copyWith(color: AppColors.primary),
                              ),
                            ),
                            SizedBox(width: 4.w),
                            AppIcon(Icons.verified_rounded, size: 14.r, color: AppColors.primary),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        QaExpandableText(
                          text: q.answer,
                          maxLines: kQaAnswerLines,
                          style: StyleText.fontSize13Weight400.copyWith(color: AppColors.text, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            )
          else
            Row(
              children: <Widget>[
                AppIcon(Icons.hourglass_empty_rounded, size: 14.r, color: AppColors.statusPending),
                SizedBox(width: 6.w),
                Text(
                  FormatHelper.capitalize(s.qaWaiting),
                  style: StyleText.fontSize12Weight600.copyWith(color: AppColors.statusPending),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Question / answer text (09/11/2026):
///   * every line trimmed, so all lines start on the SAME edge (stray spaces
///     or direction marks pushed numbered lines in from the start);
///   * cut to [maxLines] with "…", and a "See more" / "Show less" toggle —
///     shown only when the text is really longer than that.
class QaExpandableText extends StatefulWidget {
  const QaExpandableText({super.key, required this.text, required this.maxLines, this.style});

  final String text;
  final int maxLines;
  final TextStyle? style;

  @override
  State<QaExpandableText> createState() => _QaExpandableTextState();
}

class _QaExpandableTextState extends State<QaExpandableText> {
  static final RegExp _bidiMarks = RegExp('[\u200E\u200F\u202A-\u202E\u2066-\u2069\uFEFF]');

  bool _expanded = false;

  /// Each line trimmed, empty lines at the ends dropped.
  static String _clean(String raw) => raw
      .split('\n')
      .map((String l) => l.replaceAll(_bidiMarks, '').trim())
      .join('\n')
      .trim();

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final String text = _clean(widget.text);
    final TextDirection dir = TextDirectionHelper.inContext(context, text);
    final TextStyle style = DefaultTextStyle.of(context).style.merge(widget.style);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final TextPainter painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: dir,
          maxLines: widget.maxLines,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: c.maxWidth);
        final bool long = painter.didExceedMaxLines;
        painter.dispose();
        return Directionality(
          textDirection: dir,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: AlignmentDirectional.topStart,
                child: Text(
                  text,
                  textDirection: dir,
                  textAlign: TextAlign.start,
                  style: style,
                  maxLines: _expanded ? null : widget.maxLines,
                  overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
              ),
              if (long)
                // Always on the LEFT (09/11/2026), whatever the text's direction.
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6.r),
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Text(
                        FormatHelper.capitalize(_expanded ? s.captureShowLess : s.qaSeeMore),
                        style: StyleText.fontSize12Weight600.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: child,
      );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 8.h, top: 4.h),
        child: Text(
          FormatHelper.capitalize(text),
          style: StyleText.fontSize16Weight600.copyWith(color: AppColors.text),
        ),
      );
}

// ── Dialogs ─────────────────────────────────────────────────────────────────

/// A member writes a question.
Future<void> showAskQuestionDialog(BuildContext context, AppUser user) async {
  final String? text = await showDialog<String>(
    context: context,
    builder: (_) => _TextDialog(
      title: S.of(context).qaAsk,
      hint: S.of(context).qaAskHint,
      submit: S.of(context).qaSend,
      icon: Icons.help_outline_rounded,
    ),
  );
  if (text == null || !context.mounted) return;
  try {
    await EngagementRepository().askQuestion(uid: user.uid, userName: user.displayName, text: text);
    if (context.mounted) showEngagementToast(context, S.of(context).qaSent);
  } catch (e) {
    if (context.mounted) showEngagementToast(context, engErrorText(context, e));
  }
}

/// An admin answers (or edits the answer).
Future<void> showAnswerDialog(BuildContext context, AppQuestion q) async {
  final S s = S.of(context);
  final String? text = await showDialog<String>(
    context: context,
    builder: (_) => _TextDialog(
      title: q.answered ? s.qaEditAnswer : s.qaAnswer,
      subtitle: q.text,
      hint: s.qaAnswerHint,
      submit: s.qaPost,
      icon: Icons.question_answer_rounded,
      initial: q.answer,
    ),
  );
  if (text == null || !context.mounted) return;
  try {
    await EngagementRepository().answerQuestion(q.id, answer: text, by: s.qaTeam);
    if (context.mounted) showEngagementToast(context, s.qaPosted);
  } catch (e) {
    if (context.mounted) showEngagementToast(context, engErrorText(context, e));
  }
}

class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.hint,
    required this.submit,
    required this.icon,
    this.subtitle,
    this.initial = '',
  });

  final String title;
  final String? subtitle;
  final String hint;
  final String submit;
  final IconData icon;
  final String initial;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final TextEditingController _text = TextEditingController(text: widget.initial);
  bool _submitted = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() {
    setState(() => _submitted = true);
    if (_text.text.trim().length < 3) return;
    Navigator.of(context).pop(_text.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return DialogShell(
      title: widget.title,
      subtitle: widget.subtitle,
      icon: widget.icon,
      // Cancel on the left, Send on the right, no ✕; title centred on the icon.
      showClose: false,
      spreadActions: true,
      centerTitle: true,
      actions: <Widget>[
        AppButton(
          label: s.cancel,
          kind: AppButtonKind.subtle,
          expand: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(label: widget.submit, icon: Icons.send_rounded, expand: true, onPressed: _send),
      ],
      child: CustomTextField(
        fillColor: AppColors.background,
        controller: _text,
        hint: widget.hint,
        maxLines: 6,
        minLines: 3,
        autoCapitalize: false,
        // Typing Arabic turns the box right-to-left, English left-to-right.
        textDirection: TextDirectionHelper.inContext(context, _text.text),
        errorText: _submitted && _text.text.trim().length < 3 ? s.engFieldRequired : null,
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}
