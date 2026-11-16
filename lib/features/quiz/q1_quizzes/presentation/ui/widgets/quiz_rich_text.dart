/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: quiz_rich_text.dart
/// Purpose: Word-style question text and pictures for quizzes (16/11/2026).
///
///   * [QuizQuestionTextEditor] — the admin's editor: a toolbar (bold,
///     italic, underline, strike, font, size, colour, highlight, headings,
///     lists, alignment, right-to-left, indent, undo / redo, clear format).
///   * [QuizQuestionText] — what members see: the same formatting, read only.
///     A question saved before this (plain text) shows as before.
///   * [QuizPicturesEditor] / [QuizPictures] — pictures with the question,
///     kept in Cloudflare R2 (`lessons/quiz_…`). Tap one to zoom.
///
/// Ported from ENGX (16/11/2026).
///
/// The formatted text is a Quill delta in `text_rich`; the plain words stay
/// in `text` for exports, search and older app versions.

import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'package:http/http.dart' as http;

import 'package:asec/core/custom/114-app_messenger.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/video/v1_videos/data/cloud/cloud_lessons.dart';

Document _documentOf(List<dynamic> rich, String plain) {
  if (rich.isNotEmpty) {
    try {
      return Document.fromJson(rich);
    } catch (e) {
      debugPrint('[QuizText] bad formatted text, showing plain: $e');
    }
  }
  final Document d = Document();
  if (plain.trim().isNotEmpty) d.insert(0, plain.trim());
  return d;
}

// ───────────────────────────── admin: editor ─────────────────────────────

class QuizQuestionTextEditor extends StatefulWidget {
  const QuizQuestionTextEditor({
    super.key,
    required this.text,
    required this.rich,
    required this.onChanged,
  });

  final String text;
  final List<dynamic> rich;

  /// (plain text, formatted delta)
  final void Function(String text, List<dynamic> rich) onChanged;

  @override
  State<QuizQuestionTextEditor> createState() => _QuizQuestionTextEditorState();
}

class _QuizQuestionTextEditorState extends State<QuizQuestionTextEditor> {
  late final QuillController _c = QuillController(
    document: _documentOf(widget.rich, widget.text),
    selection: const TextSelection.collapsed(offset: 0),
  );
  StreamSubscription<DocChange>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = _c.document.changes.listen((_) {
      widget.onChanged(
        _c.document.toPlainText().trim(),
        _c.document.toDelta().toJson(),
      );
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderGrey),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            color: AppColors.primary.withValues(alpha: 0.06),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: QuillSimpleToolbar(
              controller: _c,
              config: const QuillSimpleToolbarConfig(
                multiRowsDisplay: true,
                showAlignmentButtons: true,
                showDirection: true,
                showCodeBlock: false,
                showInlineCode: false,
                showLink: false,
                showSearchButton: false,
                showListCheck: false,
                showQuote: false,
              ),
            ),
          ),
          Divider(height: 1, color: AppColors.borderGrey),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 90, maxHeight: 360),
            child: QuillEditor.basic(
              controller: _c,
              config: const QuillEditorConfig(
                placeholder: 'Write the question',
                padding: EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── members: view ─────────────────────────────

class QuizQuestionText extends StatefulWidget {
  const QuizQuestionText({
    super.key,
    required this.text,
    required this.rich,
    this.style,
    this.prefix = '',
  });

  final String text;
  final List<dynamic> rich;

  /// For a plain (old) question only.
  final TextStyle? style;

  /// e.g. "3. " in the results list — plain questions only.
  final String prefix;

  @override
  State<QuizQuestionText> createState() => _QuizQuestionTextState();
}

class _QuizQuestionTextState extends State<QuizQuestionText> {
  QuillController? _c;

  void _build() {
    _c?.dispose();
    _c = widget.rich.isEmpty
        ? null
        : QuillController(
            document: _documentOf(widget.rich, widget.text),
            selection: const TextSelection.collapsed(offset: 0),
            readOnly: true,
          );
  }

  @override
  void initState() {
    super.initState();
    _build();
  }

  @override
  void didUpdateWidget(QuizQuestionText old) {
    super.didUpdateWidget(old);
    if (!identical(old.rich, widget.rich) || old.text != widget.text) _build();
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final QuillController? c = _c;
    if (c == null) {
      return Text('${widget.prefix}${widget.text}', style: widget.style);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.prefix.isNotEmpty) Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(widget.prefix, style: widget.style),
        ),
        Expanded(
          child: QuillEditor.basic(
            key: ValueKey<int>(identityHashCode(c)),
            controller: c,
            config: const QuillEditorConfig(
              scrollable: false,
              showCursor: false,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────── pictures ─────────────────────────────

/// The pictures of a question, for members (and the admin's preview).
class QuizPictures extends StatelessWidget {
  const QuizPictures({super.key, required this.keys, this.height = 220});

  final List<String> keys;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (keys.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[for (final String k in keys) _Picture(k, height: height)],
    );
  }
}

class _Picture extends StatelessWidget {
  const _Picture(this.storageKey, {required this.height});

  final String storageKey;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: QuizPictureStore.load(storageKey),
      builder: (BuildContext context, AsyncSnapshot<Uint8List?> s) {
        final Uint8List? bytes = s.data;
        if (bytes == null) {
          return Container(
            width: height * 1.4,
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: s.connectionState == ConnectionState.done
                ? Icon(Icons.broken_image_outlined, color: AppColors.secondaryText)
                : const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => showDialog<void>(
            context: context,
            builder: (BuildContext ctx) => Dialog(
              backgroundColor: Colors.black,
              insetPadding: const EdgeInsets.all(16),
              child: Stack(
                children: <Widget>[
                  InteractiveViewer(maxScale: 6, child: Center(child: Image.memory(bytes))),
                  PositionedDirectional(
                    top: 6,
                    end: 6,
                    child: IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(bytes, height: height, fit: BoxFit.contain),
          ),
        );
      },
    );
  }
}

/// The admin's picture list for one question: add / remove.
class QuizPicturesEditor extends StatefulWidget {
  const QuizPicturesEditor({super.key, required this.keys, required this.onChanged});

  final List<String> keys;
  final ValueChanged<List<String>> onChanged;

  @override
  State<QuizPicturesEditor> createState() => _QuizPicturesEditorState();
}

class _QuizPicturesEditorState extends State<QuizPicturesEditor> {
  late List<String> _keys = List<String>.of(widget.keys);
  int _uploading = 0;

  Future<void> _add() async {
    final FilePickerResult? r = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (r == null || r.files.isEmpty || !mounted) return;
    for (final PlatformFile f in r.files) {
      final Uint8List? bytes = f.bytes;
      if (bytes == null) continue;
      if (bytes.length > 8 * 1024 * 1024) {
        AppMessenger.of(context).show(AppMessage(content: Text('"${f.name}" is over 8 MB — pick a smaller picture.')));
        continue;
      }
      setState(() => _uploading++);
      try {
        final String key = await QuizPictureStore.upload(bytes, f.name);
        if (!mounted) return;
        setState(() => _keys = <String>[..._keys, key]);
        widget.onChanged(_keys);
      } catch (e) {
        if (mounted) AppMessenger.of(context).show(AppMessage(content: Text('Could not upload "${f.name}": $e')));
      } finally {
        if (mounted) setState(() => _uploading--);
      }
    }
  }

  void _remove(String key) {
    setState(() => _keys = <String>[..._keys]..remove(key));
    widget.onChanged(_keys);
    // The file stays in R2: an attempt already made may still show it.
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        for (final String k in _keys)
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              _Picture(k, height: 110),
              PositionedDirectional(
                top: -8,
                end: -8,
                child: Material(
                  color: AppColors.red,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _remove(k),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        OutlinedButton.icon(
          onPressed: _uploading > 0 ? null : _add,
          icon: _uploading > 0
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.add_photo_alternate_outlined),
          label: Text(_uploading > 0 ? 'Uploading…' : 'Add picture'),
        ),
      ],
    );
  }
}

/// Quiz pictures in R2: uploaded once, fetched once per run.
abstract final class QuizPictureStore {
  static final Map<String, Future<Uint8List?>> _memo = <String, Future<Uint8List?>>{};

  static Future<Uint8List?> load(String key) => _memo[key] ??= _load(key);

  static Future<Uint8List?> _load(String key) async {
    for (final String b in CloudLessons.bases) {
      try {
        final http.Response r = await http
            .get(Uri.parse(CloudLessons.signedUrl(key, base: b)))
            .timeout(const Duration(seconds: 20));
        if (r.statusCode == 200 && r.bodyBytes.isNotEmpty) return r.bodyBytes;
      } catch (_) {}
    }
    _memo.remove(key); // try again next time
    return null;
  }

  /// Uploads a picture; returns its key (`lessons/quiz_…`, the only folder
  /// the ASEC Worker accepts).
  static Future<String> upload(Uint8List bytes, String fileName) async {
    final int dot = fileName.lastIndexOf('.');
    final String ext = dot > 0 ? fileName.substring(dot + 1).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') : 'jpg';
    final String key = 'lessons/quiz_${DateTime.now().millisecondsSinceEpoch}_${bytes.length}.$ext';
    await CloudLessons.upload(key, Stream<List<int>>.value(bytes));
    _memo[key] = Future<Uint8List?>.value(bytes);
    return key;
  }
}
