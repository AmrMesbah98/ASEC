/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: quiz_editor_page.dart
/// Purpose: Declares `QuizEditorPage` — the admin writes a quiz: questions,
///          the countdown, and the window it is open in.
/// Author: ASEC team
/// Created: 19/9/2026

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/constants/app_constants.dart';
import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/1-custom_dropdown.dart';
import 'package:asec/core/custom/2-custom_textfield.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_question.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/controller/quiz_editor_cubit.dart';
import 'package:asec/features/quiz/q1_quizzes/data/quiz_draft_store.dart';
import 'package:asec/features/quiz/q1_quizzes/data/quiz_file_import.dart';
import 'package:asec/features/quiz/q1_quizzes/data/quiz_import_parser.dart';
import 'package:asec/core/custom/57-custom_dialog_manager.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/widgets/date_time_field.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/widgets/question_editor_card.dart';
import 'package:asec/features/video/v1_videos/data/repository/video_repository.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/admin_permission.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/custom/114-app_messenger.dart';
import 'package:asec/core/network/shared_stream.dart';

class QuizEditorPage extends StatelessWidget {
  const QuizEditorPage({
    super.key,
    this.quiz,
    required this.adminUid,
    this.certificate = false,
    this.course = '',
    this.section = '',
  });

  /// Null = a new quiz.
  final Quiz? quiz;
  final String adminUid;

  /// A NEW quiz starts as a certificate quiz (a course's final exam).
  final bool certificate;

  /// A NEW quiz linked to this course section (opened from the section in
  /// the Videos page). Empty = a general quiz.
  final String course;
  final String section;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QuizEditorCubit>(
      create: (_) => QuizEditorCubit(
        existing: quiz,
        adminUid: adminUid,
        certificate: certificate,
        course: course,
        section: section,
      ),
      child: _DraftKeeper(slot: quiz?.id ?? ''),
    );
  }
}

/// 13/11/2026 — SAVE FOR LATER on this device: every change is kept (see
/// QuizDraftStore), and opening the quiz again offers to continue. Also the
/// home of "Import from file".
class _DraftKeeper extends StatefulWidget {
  const _DraftKeeper({required this.slot});

  /// '' for a new quiz, else the quiz id.
  final String slot;

  @override
  State<_DraftKeeper> createState() => _DraftKeeperState();
}

class _DraftKeeperState extends State<_DraftKeeper> {
  /// Bumped when the whole quiz is replaced, so every text field restarts.
  int _epoch = 0;
  Timer? _autosave;
  bool _dirty = false;
  bool importing = false;
  late final QuizEditorCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<QuizEditorCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerDraft());
  }

  @override
  void dispose() {
    _autosave?.cancel();
    if (_dirty) {
      QuizDraftStore.save(widget.slot, _cubit.state.quiz);
    }
    super.dispose();
  }

  Future<void> _offerDraft() async {
    final QuizEditorCubit cubit = _cubit;
    final QuizLocalDraft? draft = QuizDraftStore.load(widget.slot, cubit.state.quiz);
    if (draft == null || !mounted) return;
    await QuizDraftStore.clear(widget.slot);
    if (!mounted) return;
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final Quiz q = draft.quiz;
    await CustomDialogManager.showConfirm(
      context: context,
      title: ar ? 'متابعة من حيث توقفت؟' : 'Continue where you stopped?',
      subtitle: ar
          ? 'لديك عمل غير محفوظ: "${q.title.isEmpty ? 'بدون عنوان' : q.title}" — ${q.questions.length} سؤال.'
          : 'You have unsaved work: "${q.title.isEmpty ? 'untitled' : q.title}" — ${q.questions.length} questions.',
      confirmLabel: ar ? 'متابعة' : 'Continue',
      cancelLabel: ar ? 'البدء من جديد' : 'Start over',
      onConfirm: () {
        cubit.restore(q);
        _dirty = true;
        if (mounted) setState(() => _epoch++);
      },
    );
  }

  void _changed() {
    _dirty = true;
    _autosave?.cancel();
    _autosave = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      QuizDraftStore.save(widget.slot, _cubit.state.quiz);
    });
  }

  /// Import from file: a PDF (e.g. a Google Forms printout) or .txt.
  Future<void> importFile() async {
    final QuizEditorCubit cubit = _cubit;
    final AppMessenger messenger = AppMessenger.of(context);
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    setState(() => importing = true);
    QuizImportResult? result;
    try {
      result = await QuizFileImport.pickAndParse();
    } on FormatException catch (e) {
      messenger.show(AppMessage(content: Text(ar ? 'لم يتم العثور على أسئلة في هذا الملف.' : e.message)));
    } catch (e) {
      // The PDF engine is native code: only there after a full rebuild.
      final bool noEngine = '$e'.contains('FPDF_');
      messenger.show(AppMessage(
        content: Text(noEngine
            ? (ar ? 'قارئ PDF غير موجود في هذا الإصدار — أوقف التطبيق وشغّله من جديد.'
                : 'The PDF reader is not in this build yet — stop the app and run it again.')
            : '${ar ? 'تعذّرت قراءة الملف' : 'Could not read the file'}: $e'),
      ));
    }
    if (!mounted) return;
    setState(() => importing = false);
    if (result == null) return;
    final QuizImportResult imported = result;

    final bool onlyBlank = cubit.state.quiz.questions.every(
        (QuizQuestion q) => q.text.trim().isEmpty && q.options.every((String o) => o.trim().isEmpty));
    bool replace = true;
    if (!onlyBlank) {
      bool? choice;
      await CustomDialogManager.showConfirm(
        context: context,
        title: ar ? 'تم العثور على ${imported.questions.length} سؤال' : '${imported.questions.length} questions found',
        subtitle: ar
            ? 'في الاختبار أسئلة بالفعل. استبدالها أم إضافة الجديدة بعدها؟'
            : 'This quiz already has questions. Replace them, or add the new ones after them?',
        confirmLabel: ar ? 'استبدال' : 'Replace',
        cancelLabel: ar ? 'إضافة بعدها' : 'Add after',
        onConfirm: () => choice = true,
        onCancel: () => choice = false,
      );
      if (choice == null || !mounted) return;
      replace = choice!;
    }
    cubit.importQuestions(imported.questions, replace: replace, title: imported.title);
    setState(() => _epoch++);
    _changed();
    final int pts = imported.questions.fold<int>(0, (int s, QuizQuestion q) => s + q.points);
    final int missing = imported.missingAnswers;
    messenger.show(AppMessage(
      content: Text(ar
          ? 'تم استيراد ${imported.questions.length} سؤال · $pts درجة'
              '${missing == 0 ? '' : ' · الملف بدون إجابات: اختر الإجابة الصحيحة في $missing سؤال'}'
          : '${imported.questions.length} questions imported · $pts pts'
              '${missing == 0 ? '' : ' · the file has no answer key: choose the correct answer on $missing questions'}'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<QuizEditorCubit, QuizEditorState>(
      listenWhen: (QuizEditorState a, QuizEditorState b) =>
          a.quiz != b.quiz || (a.status != b.status && b.status == QuizEditorStatus.saved),
      listener: (BuildContext context, QuizEditorState state) {
        if (state.status == QuizEditorStatus.saved) {
          // On the server now: the device copy is no longer needed.
          _autosave?.cancel();
          _dirty = false;
          QuizDraftStore.clear(widget.slot);
          return;
        }
        _changed();
      },
      child: _QuizEditorView(key: ValueKey<int>(_epoch)),
    );
  }
}

class _QuizEditorView extends StatelessWidget {
  const _QuizEditorView({super.key});

  /// From here the form is two columns: settings beside the questions.
  static const double _splitWidth = 1000;

  String _formMessage(BuildContext context, QuizFormError error) {
    final S s = S.of(context);
    switch (error) {
      case QuizFormError.titleEmpty:
        return s.enterTitle;
      case QuizFormError.noQuestions:
        return s.errNoQuestions;
      case QuizFormError.questionsIncomplete:
        return s.questionsIncomplete;
      case QuizFormError.windowBackwards:
        return s.errWindowBackwards;
      case QuizFormError.courseMissing:
        return s.errChooseCourse;
    }
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final QuizEditorCubit cubit = context.read<QuizEditorCubit>();

    return BlocConsumer<QuizEditorCubit, QuizEditorState>(
      listenWhen: (QuizEditorState a, QuizEditorState b) => a.status != b.status,
      listener: (BuildContext context, QuizEditorState state) {
        if (state.status == QuizEditorStatus.saved) {
          final AppMessenger messenger =
              AppMessenger.of(context);
          final bool ar = Localizations.localeOf(context).languageCode == 'ar';
          Navigator.of(context).pop(true);
          messenger.show(AppMessage(
            content: Text(cubit.savedAsDraft
                ? (ar
                    ? 'تم الحفظ كمسودة — لا يراها الأعضاء. افتحها من الاختبارات لمتابعتها.'
                    : 'Saved for later as a Draft — members can not see it. Open it from Quizzes to continue.')
                : FormatHelper.capitalize(s.quizSaved)),
          ));
        }
      },
      builder: (BuildContext context, QuizEditorState state) {
        final bool split = MediaQuery.sizeOf(context).width >= _splitWidth;

        final Widget settings = _SettingsColumn(state: state);
        final Widget questions = _QuestionsColumn(state: state);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              FormatHelper.capitalize(cubit.isNew ? s.newQuiz : s.editQuiz),
              style: StyleText.fontSize18Weight600,
            ),
            actions: <Widget>[
              // 13/11/2026: read a quiz from a PDF / .txt.
              Builder(
                builder: (BuildContext context) {
                  final _DraftKeeperState? keeper =
                      context.findAncestorStateOfType<_DraftKeeperState>();
                  final bool ar = Localizations.localeOf(context).languageCode == 'ar';
                  return AppButton(
                    label: ar ? 'استيراد من ملف' : 'Import from file',
                    icon: Icons.upload_file_rounded,
                    kind: AppButtonKind.subtle,
                    dense: true,
                    loading: keeper?.importing ?? false,
                    onPressed: keeper == null || state.isSaving ? null : keeper.importFile,
                  );
                },
              ),
              SizedBox(width: 8.w),
              // 13/11/2026: SAVE FOR LATER — an unfinished quiz kept as a
              // Draft. A published quiz just uses Save (it stays published).
              if (!state.quiz.published) ...<Widget>[
                AppButton(
                  label: Localizations.localeOf(context).languageCode == 'ar' ? 'حفظ لوقت لاحق' : 'Save for later',
                  icon: Icons.bookmark_border_rounded,
                  kind: AppButtonKind.outlined,
                  dense: true,
                  onPressed: state.isSaving ? null : cubit.saveForLater,
                ),
                SizedBox(width: 8.w),
              ],
              Padding(
                padding: EdgeInsetsDirectional.only(end: AppPadding.h),
                child: AppButton(
                  label: s.save,
                  icon: Icons.check_rounded,
                  dense: true,
                  loading: state.isSaving,
                  onPressed: cubit.save,
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppPadding.h,
              vertical: 16.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (state.formError != null) ...<Widget>[
                  InfoBanner.error(_formMessage(context, state.formError!)),
                  SizedBox(height: 14.h),
                ],
                if (state.failure != null) ...<Widget>[
                  InfoBanner.error(state.failure!.message(context)),
                  SizedBox(height: 14.h),
                ],
                if (split)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(flex: 4, child: settings),
                      SizedBox(width: 16.w),
                      Expanded(flex: 6, child: questions),
                    ],
                  )
                else ...<Widget>[
                  settings,
                  SizedBox(height: 16.h),
                  questions,
                ],
                SizedBox(height: 32.h),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Title, description, the countdown and the window.
class _SettingsColumn extends StatefulWidget {
  const _SettingsColumn({required this.state});

  final QuizEditorState state;

  @override
  State<_SettingsColumn> createState() => _SettingsColumnState();
}

class _SettingsColumnState extends State<_SettingsColumn> {
  late final TextEditingController _title =
      TextEditingController(text: widget.state.quiz.title);
  late final TextEditingController _description =
      TextEditingController(text: widget.state.quiz.description);
  late final TextEditingController _duration = TextEditingController(
    text: widget.state.quiz.durationMinutes == 0
        ? ''
        : widget.state.quiz.durationMinutes.toString(),
  );

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final QuizEditorCubit cubit = context.read<QuizEditorCubit>();
    final Quiz quiz = widget.state.quiz;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppCard(
          title: s.title,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CustomTextField(
                controller: _title,
                label: s.title,
                hint: s.quizTitleHint,
                required: true,
                onChanged: cubit.setTitle,
              ),
              SizedBox(height: 12.h),
              CustomTextField(
                controller: _description,
                label: s.description,
                hint: s.descriptionHint,
                maxLines: 3,
                onChanged: cubit.setDescription,
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        if (quiz.certificate) ...<Widget>[
          AppCard(
            title: s.courseLabel,
            caption: s.courseCaption,
            child: _CoursePicker(
              value: quiz.course,
              onChanged: cubit.setCourse,
            ),
          ),
          SizedBox(height: 16.h),
        ] else ...<Widget>[
          AppCard(
            title: s.sectionQuizLabel,
            caption: s.sectionQuizCaption,
            child: _SectionPicker(
              course: quiz.course,
              section: quiz.section,
              onChanged: cubit.setSection,
            ),
          ),
          SizedBox(height: 16.h),
        ],
        AppCard(
          title: s.timeLimit,
          caption: s.zeroUntimed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CustomTextField(
                controller: _duration,
                label: s.minutes,
                hint: '0',
                keyboardType: TextInputType.number,
                prefixIcon: const AppIcon(Icons.timer_outlined),
                onChanged: (String value) =>
                    cubit.setDuration(int.tryParse(value.trim()) ?? 0),
              ),
              SizedBox(height: 18.h),
              Text(FormatHelper.capitalize(s.availabilityWindow), style: StyleText.fontSize14Weight600),
              SizedBox(height: 4.h),
              Text(
                FormatHelper.capitalize(s.availabilityHint),
                style: StyleText.fontSize12Weight400
                    .copyWith(color: AppColors.secondaryText),
              ),
              SizedBox(height: 12.h),
              DateTimeField(
                label: s.opensAt,
                value: quiz.opensAt,
                onChanged: cubit.setOpensAt,
              ),
              SizedBox(height: 12.h),
              DateTimeField(
                label: s.closesAt,
                value: quiz.closesAt,
                icon: Icons.lock_outline_rounded,
                onChanged: cubit.setClosesAt,
              ),
              SizedBox(height: 16.h),
              Material(
                // See settings_page: a ListTile needs its own Material inside
                // a card that paints its own background.
                color: AppColors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(FormatHelper.capitalize(s.published), style: StyleText.fontSize14Weight600),
                  subtitle: Text(
                    FormatHelper.capitalize(s.publishedHint),
                    style: StyleText.fontSize12Weight400
                        .copyWith(color: AppColors.secondaryText),
                  ),
                  trailing: Switch.adaptive(
                    value: quiz.published,
                    activeTrackColor: AppColors.secondaryPrimary,
                    // Quizzes → Open / close.
                    onChanged: SessionController.to.current
                            .canDo(AdminAction.quizzesOpen)
                        ? cubit.setPublished
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The question list and the button that adds one.
class _QuestionsColumn extends StatelessWidget {
  const _QuestionsColumn({required this.state});

  final QuizEditorState state;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final QuizEditorCubit cubit = context.read<QuizEditorCubit>();
    final List<QuizQuestion> questions = state.quiz.questions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppSectionHeader(
          title: s.questions,
          caption: s.questionsTotal(
            '${questions.length}',
            '${state.quiz.totalPoints}',
          ),
        ),
        SizedBox(height: 12.h),
        for (int i = 0; i < questions.length; i++)
          QuestionEditorCard(
            // The id keeps this card's controllers with ITS question when the
            // list around it shifts.
            key: ValueKey<String>(questions[i].id),
            index: i,
            question: questions[i],
            canRemove: questions.length > 1,
            onTextChanged: (String value) =>
                cubit.setQuestionText(questions[i].id, value),
            onOptionChanged: (int index, String value) =>
                cubit.setOption(questions[i].id, index, value),
            onCorrectChanged: (int index) =>
                cubit.setCorrect(questions[i].id, index),
            onPointsChanged: (int points) =>
                cubit.setQuestionPoints(questions[i].id, points),
            onAddOption: () => cubit.addOption(questions[i].id),
            onRemoveOption: (int index) =>
                cubit.removeOption(questions[i].id, index),
            onRemove: () => cubit.removeQuestion(questions[i].id),
          ),
        AppButton(
          label: s.addQuestion,
          icon: Icons.add_rounded,
          kind: AppButtonKind.subtle,
          expand: true,
          onPressed: cubit.addQuestion,
        ),
        SizedBox(height: 8.h),
        Text(
          FormatHelper.capitalize('${s.minutes}: ${AppConstants.maxQuizMinutes} max'),
          textAlign: TextAlign.center,
          style: StyleText.fontSize11Weight400
              .copyWith(color: AppColors.secondaryText),
        ),
      ],
    );
  }
}

/// The course a certificate quiz closes: one of the video categories (Drive
/// sub-folders). A course that no longer has videos is still offered, so an
/// existing quiz never loses its value.
class _CoursePicker extends StatefulWidget {
  const _CoursePicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String?> onChanged;

  @override
  State<_CoursePicker> createState() => _CoursePickerState();
}

class _CoursePickerState extends State<_CoursePicker> {
  late final Stream<List<VideoItem>> _videos = shared(() => VideoRepository().watchAll());

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return StreamBuilder<List<VideoItem>>(
      stream: _videos,
      builder: (BuildContext context, AsyncSnapshot<List<VideoItem>> snap) {
        final Map<String, int> order = <String, int>{};
        for (final VideoItem v in snap.data ?? const <VideoItem>[]) {
          final String c = v.category.trim();
          if (c.isEmpty) continue;
          final int o = v.categoryOrder > 0 ? v.categoryOrder : 1 << 20;
          if (!order.containsKey(c) || o < order[c]!) order[c] = o;
        }
        final List<String> courses = order.keys.toList()
          ..sort((String a, String b) {
            final int c = order[a]!.compareTo(order[b]!);
            return c != 0 ? c : a.toLowerCase().compareTo(b.toLowerCase());
          });
        final String current = widget.value.trim();
        if (current.isNotEmpty && !courses.contains(current)) {
          courses.insert(0, current);
        }

        return CustomDropdown<String>(
          value: current.isEmpty ? null : current,
          hint: s.chooseCourse,
          required: true,
          prefixIcon: Icon(Icons.folder_rounded, color: AppColors.primary, size: 20),
          items: <DropdownItem<String>>[
            for (final String c in courses)
              DropdownItem<String>(value: c, label: c),
          ],
          onChanged: widget.onChanged,
        );
      },
    );
  }
}

/// The section an ordinary quiz closes: "Course › Section" for every video
/// sub-folder, plus each course itself (its lessons outside sub-folders), or
/// none for a general quiz. A pair that no longer has videos is still
/// offered, so an existing quiz never loses its value.
class _SectionPicker extends StatefulWidget {
  const _SectionPicker({
    required this.course,
    required this.section,
    required this.onChanged,
  });

  final String course;
  final String section;
  final void Function(String course, String section) onChanged;

  @override
  State<_SectionPicker> createState() => _SectionPickerState();
}

class _SectionPickerState extends State<_SectionPicker> {
  late final Stream<List<VideoItem>> _videos = shared(() => VideoRepository().watchAll());

  /// Course and section in one dropdown value; '' = no section.
  static const String _sep = '\u0001';

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return StreamBuilder<List<VideoItem>>(
      stream: _videos,
      builder: (BuildContext context, AsyncSnapshot<List<VideoItem>> snap) {
        // key -> (course order, section order, label)
        final Map<String, (int, int, String)> found = <String, (int, int, String)>{};
        for (final VideoItem v in snap.data ?? const <VideoItem>[]) {
          final String c = v.category.trim();
          if (c.isEmpty) continue;
          final String sec = v.subcategory.trim();
          final String key = '$c$_sep$sec';
          if (found.containsKey(key)) continue;
          found[key] = (
            v.categoryOrder > 0 ? v.categoryOrder : 1 << 20,
            sec.isEmpty ? 0 : (v.subcategoryOrder > 0 ? v.subcategoryOrder : 1 << 20),
            sec.isEmpty ? c : '$c › $sec',
          );
        }
        final List<String> keys = found.keys.toList()
          ..sort((String a, String b) {
            final (int, int, String) x = found[a]!;
            final (int, int, String) y = found[b]!;
            int r = x.$1.compareTo(y.$1);
            if (r == 0) r = x.$2.compareTo(y.$2);
            return r != 0 ? r : x.$3.toLowerCase().compareTo(y.$3.toLowerCase());
          });

        final String course = widget.course.trim();
        final String section = widget.section.trim();
        final String current = course.isEmpty ? '' : '$course$_sep$section';
        if (current.isNotEmpty && !found.containsKey(current)) {
          keys.insert(0, current);
          found[current] = (0, 0, section.isEmpty ? course : '$course › $section');
        }

        return CustomDropdown<String>(
          value: current,
          hint: s.sectionNone,
          prefixIcon: Icon(Icons.playlist_add_check_rounded, color: AppColors.primary, size: 20),
          items: <DropdownItem<String>>[
            DropdownItem<String>(value: '', label: s.sectionNone),
            for (final String k in keys)
              DropdownItem<String>(value: k, label: found[k]!.$3),
          ],
          onChanged: (String? value) {
            final String v = value ?? '';
            if (v.isEmpty) {
              widget.onChanged('', '');
            } else {
              final List<String> parts = v.split(_sep);
              widget.onChanged(parts.first, parts.length > 1 ? parts[1] : '');
            }
          },
        );
      },
    );
  }
}
