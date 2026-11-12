/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: quiz_text_direction.dart
/// Purpose: Arabic questions and options read right to left, English ones
///          left to right — decided by which letters the text mostly has
///          ("وحدة قياس Air Flow" → right to left).
/// Created: 13/11/2026

import 'package:flutter/widgets.dart';

final RegExp _arabicLetters = RegExp(r'[؀-ۿݐ-ݿﭐ-﷿ﹰ-﻿]');
final RegExp _latinLetters = RegExp(r'[A-Za-z]');

TextDirection quizTextDirection(String text) =>
    _arabicLetters.allMatches(text).length > _latinLetters.allMatches(text).length
        ? TextDirection.rtl
        : TextDirection.ltr;
