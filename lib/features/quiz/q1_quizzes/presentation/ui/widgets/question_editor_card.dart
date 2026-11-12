/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: question_editor_card.dart
/// Purpose: Declares `QuestionEditorCard` — one question in the admin's quiz
///          form.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/widgets/quiz_text_direction.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/constants/app_constants.dart';
import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/2-custom_textfield.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_question.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

/// THE CONTROLLERS LIVE HERE, NOT IN THE CUBIT.
///
/// The cubit holds the question list as data and rebuilds on every keystroke;
/// controllers owned by the cubit would have to be rebuilt with it and the
/// caret would jump to the end of the line. This card keeps its own, seeded
/// once from [question] and pushed outward — so give it a `ValueKey(id)` and
/// the field keeps its caret while the list around it changes.
class QuestionEditorCard extends StatefulWidget {
  const QuestionEditorCard({
    super.key,
    required this.index,
    required this.question,
    required this.onTextChanged,
    required this.onOptionChanged,
    required this.onCorrectChanged,
    required this.onPointsChanged,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onRemove,
    this.canRemove = true,
  });

  final int index;
  final QuizQuestion question;
  final ValueChanged<String> onTextChanged;
  final void Function(int index, String value) onOptionChanged;
  final ValueChanged<int> onCorrectChanged;
  final ValueChanged<int> onPointsChanged;
  final VoidCallback onAddOption;
  final ValueChanged<int> onRemoveOption;
  final VoidCallback onRemove;
  final bool canRemove;

  @override
  State<QuestionEditorCard> createState() => _QuestionEditorCardState();
}

class _QuestionEditorCardState extends State<QuestionEditorCard> {
  late final TextEditingController _text =
      TextEditingController(text: widget.question.text);
  late final TextEditingController _points =
      TextEditingController(text: widget.question.points.toString());
  final List<TextEditingController> _options = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    _syncOptions();
  }

  @override
  void didUpdateWidget(QuestionEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncOptions();
  }

  /// Adds or removes controllers when the option COUNT changes. The text is
  /// never written back — that would fight whoever is typing.
  void _syncOptions() {
    while (_options.length < widget.question.options.length) {
      _options.add(TextEditingController(
        text: widget.question.options[_options.length],
      ));
    }
    while (_options.length > widget.question.options.length) {
      _options.removeLast().dispose();
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _points.dispose();
    for (final TextEditingController c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final QuizQuestion q = widget.question;

    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 26.r,
                  height: 26.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.chip,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    FormatHelper.capitalize('${widget.index + 1}'),
                    style: StyleText.fontSize12Weight700
                        .copyWith(color: AppColors.onChip),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(FormatHelper.capitalize(s.questionText), style: StyleText.fontSize14Weight600),
                ),
                SizedBox(
                  width: 92.w,
                  child: CustomTextField(
                    controller: _points,
                    label: s.points,
                    keyboardType: TextInputType.number,
                    onChanged: (String value) =>
                        widget.onPointsChanged(int.tryParse(value.trim()) ?? 1),
                  ),
                ),
                if (widget.canRemove)
                  IconButton(
                    onPressed: widget.onRemove,
                    tooltip: s.delete,
                    icon: AppIcon(
                      Icons.delete_outline_rounded,
                      color: AppColors.red,
                      size: 20.sp,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 10.h),
            CustomTextField(
              controller: _text,
              hint: s.questionText,
              maxLines: 2,
              // Arabic reads right to left, English left to right.
              textDirection: quizTextDirection(_text.text),
              onChanged: widget.onTextChanged,
            ),
            SizedBox(height: 12.h),
            Text(
              q.correctIndex < 0
                  // Imported without an answer key: pick the right option.
                  ? (Localizations.localeOf(context).languageCode == 'ar'
                      ? 'اختر الإجابة الصحيحة — اضغط الدائرة بجانبها'
                      : 'Choose the correct answer — tap its circle')
                  : FormatHelper.capitalize(s.markCorrectHint),
              style: StyleText.fontSize12Weight400.copyWith(
                  color: q.correctIndex < 0 ? AppColors.statusPending : AppColors.secondaryText),
            ),
            SizedBox(height: 8.h),
            for (int i = 0; i < _options.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: <Widget>[
                    // The marker IS the answer key: one tap says "this is
                    // the right one", which is the whole marking rule. Drawn
                    // by hand rather than with Radio, whose groupValue API is
                    // being replaced by RadioGroup.
                    IconButton(
                      tooltip: s.markCorrectHint,
                      onPressed: () => widget.onCorrectChanged(i),
                      icon: AppIcon(
                        q.correctIndex == i
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: q.correctIndex == i
                            ? AppColors.green
                            : AppColors.secondaryText,
                      ),
                    ),
                    Expanded(
                      child: CustomTextField(
                        controller: _options[i],
                        hint: s.optionN('${i + 1}'),
                        textDirection: quizTextDirection(_options[i].text),
                        onChanged: (String value) =>
                            widget.onOptionChanged(i, value),
                      ),
                    ),
                    if (_options.length > AppConstants.minOptions)
                      IconButton(
                        onPressed: () => widget.onRemoveOption(i),
                        icon: AppIcon(
                          Icons.remove_circle_outline,
                          size: 18.sp,
                          color: AppColors.secondaryText,
                        ),
                      ),
                  ],
                ),
              ),
            if (_options.length < AppConstants.maxOptions)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: widget.onAddOption,
                  icon: AppIcon(
                    Icons.add_rounded,
                    size: 16.sp,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    FormatHelper.capitalize(s.addOption),
                    style: StyleText.fontSize13Weight600
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
