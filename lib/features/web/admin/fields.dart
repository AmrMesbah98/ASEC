/// The panel edits every kind of content with ONE form builder: a list of
/// `FieldSpec`s describes the document, `DocForm` draws it and returns the
/// map to save. Services, projects, articles, partners, testimonials,
/// features and the site settings are all just different lists of specs.
///
/// LANGUAGE: every Arabic text field (text, multiline, HTML, list of lines)
/// gets an English twin saved as `{key}_en`, drawn right under it. The site
/// shows the twin when it is visiting in English and falls back to the Arabic
/// while it is empty (core/doc.dart). The counters get an English label
/// column (`label_en`). Save code must write [storedKeys], not just the
/// spec keys, or the English is lost.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/features/web/core/i18n.dart';
import 'package:asec/features/web/core/theme.dart';
import 'package:asec/features/web/core/widgets.dart';
import 'package:asec/features/web/data/site_repo.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/custom/114-app_messenger.dart';

enum FieldType {
  /// A heading that groups the fields after it. No value.
  section,
  text,
  multiline,
  html,
  url,
  image,
  imageList,
  stringList,

  /// A list of {label, value} — the counters.
  pairs,
  boolean,
  number,
  select,
  date,
}

class FieldSpec {
  const FieldSpec(
    this.key,
    this.label,
    this.type, {
    this.hint,
    this.options = const <String, L>{},
    this.isRequired = false,
    this.rtl = true,
  });

  const FieldSpec.section(this.label)
      : key = '',
        type = FieldType.section,
        hint = null,
        options = const <String, L>{},
        isRequired = false,
        rtl = true;

  final String key;
  final L label;
  final FieldType type;
  final L? hint;

  /// For `select`: stored value → label.
  final Map<String, L> options;
  final bool isRequired;

  /// Content fields are Arabic; URLs and e-mails are not.
  final bool rtl;

  /// Arabic content that also has an English version (`{key}_en`).
  bool get translatable =>
      rtl &&
      key.isNotEmpty &&
      (type == FieldType.text ||
          type == FieldType.multiline ||
          type == FieldType.html ||
          type == FieldType.stringList);

  String get enKey => '${key}_en';

  FieldSpec _copy({String? key, L? label, bool? rtl, bool? isRequired}) => FieldSpec(
        key ?? this.key,
        label ?? this.label,
        type,
        hint: hint,
        options: options,
        isRequired: isRequired ?? this.isRequired,
        rtl: rtl ?? this.rtl,
      );

  /// The Arabic side of a translatable field, labelled as such.
  FieldSpec get arabicSide => _copy(label: L('${label.ar} (عربي)', '${label.en} (Arabic)'));

  /// The English twin: `{key}_en`, left-to-right, never required.
  FieldSpec get englishSide =>
      _copy(key: enKey, label: L('${label.ar} (English)', '${label.en} (English)'), rtl: false, isRequired: false);

  Object? emptyValue() {
    switch (type) {
      case FieldType.section:
        return null;
      case FieldType.imageList:
      case FieldType.stringList:
      case FieldType.pairs:
        return <dynamic>[];
      case FieldType.boolean:
        return true;
      case FieldType.number:
        return 0;
      case FieldType.date:
        return null;
      case FieldType.select:
        return options.isEmpty ? '' : options.keys.first;
      case FieldType.text:
      case FieldType.multiline:
      case FieldType.html:
      case FieldType.url:
      case FieldType.image:
        return '';
    }
  }
}

/// Every key a list of specs saves: each field, plus the English twin of
/// each translatable one.
Iterable<String> storedKeys(List<FieldSpec> specs) sync* {
  for (final FieldSpec f in specs) {
    if (f.type == FieldType.section) continue;
    yield f.key;
    if (f.translatable) yield f.enKey;
  }
}

/// Empty values for every stored key (new documents, missing fields).
Map<String, dynamic> blankValues(List<FieldSpec> specs) => <String, dynamic>{
      for (final FieldSpec f in specs)
        if (f.type != FieldType.section) ...<String, dynamic>{
          f.key: f.emptyValue(),
          if (f.translatable) f.enKey: f.emptyValue(),
        },
    };

/// Draws the specs, keeps the values, validates. `values` is edited in place.
class DocForm extends StatefulWidget {
  const DocForm({super.key, required this.specs, required this.values, required this.folder, this.formKey});

  final List<FieldSpec> specs;
  final Map<String, dynamic> values;

  /// Storage folder for uploads: `site/{folder}/…`.
  final String folder;
  final GlobalKey<FormState>? formKey;

  @override
  State<DocForm> createState() => _DocFormState();
}

class _DocFormState extends State<DocForm> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final FieldSpec f in widget.specs)
            Padding(
              padding: EdgeInsets.only(bottom: f.type == FieldType.section ? 8 : 18, top: f.type == FieldType.section ? 14 : 0),
              child: _field(f),
            ),
        ],
      ),
    );
  }

  void _set(String k, Object? v) => setState(() => widget.values[k] = v);

  Widget _field(FieldSpec f) {
    if (!f.translatable) return _single(f);
    return Container(
      padding: const EdgeInsetsDirectional.only(start: 12),
      decoration: const BoxDecoration(
        border: BorderDirectional(start: BorderSide(color: WebColors.blue, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _single(f.arabicSide),
          const SizedBox(height: 12),
          _single(f.englishSide),
        ],
      ),
    );
  }

  Widget _single(FieldSpec f) {
    final Object? v = widget.values[f.key];
    switch (f.type) {
      case FieldType.section:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(FormatHelper.capitalize(f.label.t), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: WebColors.navy)),
            const SizedBox(height: 6),
            const Divider(),
          ],
        );
      case FieldType.text:
      case FieldType.url:
      case FieldType.multiline:
      case FieldType.html:
        return _TextSpecField(
          key: ValueKey<String>('t_${f.key}'),
          spec: f,
          initial: v?.toString() ?? '',
          onChanged: (String s) => widget.values[f.key] = s,
        );
      case FieldType.number:
        return TextFormField(
          initialValue: '${v ?? 0}',
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: f.label.t, helperText: f.hint?.t),
          onChanged: (String s) => widget.values[f.key] = int.tryParse(s.trim()) ?? 0,
        );
      case FieldType.boolean:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(FormatHelper.capitalize(f.label.t), style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: f.hint == null ? null : Text(FormatHelper.capitalize(f.hint!.t)),
          value: v is bool ? v : true,
          onChanged: (bool b) => _set(f.key, b),
        );
      case FieldType.select:
        final String cur = f.options.containsKey(v) ? v! as String : (f.options.keys.isEmpty ? '' : f.options.keys.first);
        return DropdownButtonFormField<String>(
          initialValue: cur.isEmpty ? null : cur,
          icon: const AppIcon(Icons.keyboard_arrow_down_rounded),
          decoration: InputDecoration(labelText: f.label.t),
          items: <DropdownMenuItem<String>>[
            for (final MapEntry<String, L> e in f.options.entries)
              DropdownMenuItem<String>(value: e.key, child: Text(FormatHelper.capitalize(e.value.t))),
          ],
          onChanged: (String? s) => _set(f.key, s ?? ''),
        );
      case FieldType.date:
        final DateTime? d = v is Timestamp ? v.toDate() : (v is DateTime ? v : null);
        return InputDecorator(
          decoration: InputDecoration(labelText: f.label.t),
          child: Row(
            children: <Widget>[
              Expanded(child: Text(FormatHelper.capitalize(d == null ? '—' : '${d.year}/${d.month}/${d.day}'))),
              TextButton(
                onPressed: () async {
                  final DateTime? p = await showDatePicker(
                    context: context,
                    initialDate: d ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(DateTime.now().year + 5),
                  );
                  if (p != null) _set(f.key, Timestamp.fromDate(p));
                },
                child: Text(FormatHelper.capitalize(const L('اختيار', 'Pick').t)),
              ),
            ],
          ),
        );
      case FieldType.image:
        return ImageField(
          label: f.label.t,
          url: v?.toString() ?? '',
          folder: widget.folder,
          onChanged: (String u) => _set(f.key, u),
        );
      case FieldType.imageList:
        final List<String> list = v is List ? v.map((Object? e) => '$e').toList() : <String>[];
        return _ImageListField(
          label: f.label.t,
          urls: list,
          folder: widget.folder,
          onChanged: (List<String> l) => _set(f.key, l),
        );
      case FieldType.stringList:
        final List<String> list = v is List ? v.map((Object? e) => '$e').toList() : <String>[];
        return _StringListField(
          key: ValueKey<String>('l_${f.key}'),
          label: f.label.t,
          initial: list,
          rtl: f.rtl,
          onChanged: (List<String> l) => widget.values[f.key] = l,
        );
      case FieldType.pairs:
        final List<Map<String, dynamic>> list = v is List
            ? <Map<String, dynamic>>[for (final Object? e in v) if (e is Map) Map<String, dynamic>.from(e)]
            : <Map<String, dynamic>>[];
        return _PairsField(
          key: ValueKey<String>('p_${f.key}'),
          label: f.label.t,
          initial: list,
          onChanged: (List<Map<String, dynamic>> l) => widget.values[f.key] = l,
        );
    }
  }
}

class _TextSpecField extends StatefulWidget {
  const _TextSpecField({super.key, required this.spec, required this.initial, required this.onChanged});

  final FieldSpec spec;
  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<_TextSpecField> createState() => _TextSpecFieldState();
}

class _TextSpecFieldState extends State<_TextSpecField> {
  late final TextEditingController _c = TextEditingController(text: widget.initial);
  bool _preview = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FieldSpec f = widget.spec;
    final bool multi = f.type == FieldType.multiline || f.type == FieldType.html;
    final bool ltr = f.type == FieldType.url || !f.rtl;
    final Widget field = TextFormField(
      controller: _c,
      minLines: multi ? (f.type == FieldType.html ? 10 : 4) : 1,
      maxLines: multi ? (f.type == FieldType.html ? 30 : 14) : 1,
      textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
      style: f.type == FieldType.html ? const TextStyle(fontFamily: 'monospace', fontSize: 13) : null,
      decoration: InputDecoration(
        labelText: f.label.t + (f.isRequired ? ' *' : ''),
        helperText: f.hint?.t,
        alignLabelWithHint: multi,
      ),
      validator: f.isRequired
          ? ((String? s) => (s == null || s.trim().isEmpty) ? const L('مطلوب', 'Required').t : null)
          : null,
      onChanged: widget.onChanged,
    );
    if (f.type != FieldType.html) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(FormatHelper.capitalize('${f.label.t} — HTML'),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            SegmentedButton<bool>(
              segments: <ButtonSegment<bool>>[
                ButtonSegment<bool>(value: false, label: Text(FormatHelper.capitalize(const L('تحرير', 'Edit').t)), icon: const AppIcon(Icons.code)),
                ButtonSegment<bool>(value: true, label: Text(FormatHelper.capitalize(const L('معاينة', 'Preview').t)), icon: const AppIcon(Icons.visibility)),
              ],
              selected: <bool>{_preview},
              onSelectionChanged: (Set<bool> s) => setState(() => _preview = s.first),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_preview)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border.all(color: WebColors.border), borderRadius: BorderRadius.circular(10)),
            child: Directionality(
              textDirection: f.rtl ? TextDirection.rtl : TextDirection.ltr,
              child: HtmlWidget(_c.text, textStyle: const TextStyle(fontSize: 15, height: 1.9)),
            ),
          )
        else
          field,
        const SizedBox(height: 4),
        Text(
          FormatHelper.capitalize(const L('تقبل وسوم HTML مثل <h2> و<p> و<ul><li> و<img src="…">. يمكن كتابة نص عادي أيضًا.',
                  'HTML tags such as <h2>, <p>, <ul><li>, <img src="…"> are allowed. Plain text works too.')
              .t),
          style: TextStyle(fontSize: 12, color: WebColors.muted),
        ),
      ],
    );
  }
}

/// Preview + URL box + Upload button (Firebase Storage).
class ImageField extends StatefulWidget {
  const ImageField({
    super.key,
    required this.label,
    required this.url,
    required this.folder,
    required this.onChanged,
    this.onRemove,
  });

  final String label;
  final String url;
  final String folder;
  final ValueChanged<String> onChanged;
  final VoidCallback? onRemove;

  @override
  State<ImageField> createState() => _ImageFieldState();
}

class _ImageFieldState extends State<ImageField> {
  late final TextEditingController _c = TextEditingController(text: widget.url);
  bool _busy = false;

  @override
  void didUpdateWidget(ImageField old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url && _c.text != widget.url) _c.text = widget.url;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    final FilePickerResult? r = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    final PlatformFile? file = r?.files.firstOrNull;
    if (file == null || file.bytes == null) return;
    if (file.size > 10 * 1024 * 1024) {
      _toast(const L('الصورة أكبر من 10 ميجابايت', 'Image is larger than 10 MB').t);
      return;
    }
    setState(() => _busy = true);
    try {
      final String url = await SiteRepo.uploadImage(folder: widget.folder, fileName: file.name, bytes: file.bytes!);
      _c.text = url;
      widget.onChanged(url);
    } catch (e) {
      _toast('${const L('فشل الرفع', 'Upload failed').t}: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    AppMessenger.of(context).show(AppMessage(content: Text(FormatHelper.capitalize(m))));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(border: Border.all(color: WebColors.border), borderRadius: BorderRadius.circular(8)),
          clipBehavior: Clip.antiAlias,
          child: NetImage(_c.text, fit: BoxFit.cover),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _c,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(labelText: widget.label, hintText: 'https://…'),
                onChanged: (String s) {
                  widget.onChanged(s.trim());
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _upload,
                    icon: _busy
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const AppIcon(Icons.upload_rounded, size: 18),
                    label: Text(FormatHelper.capitalize(const L('رفع صورة', 'Upload').t)),
                  ),
                  if (widget.onRemove != null) ...<Widget>[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: const L('حذف', 'Remove').t,
                      onPressed: widget.onRemove,
                      icon: const AppIcon(Icons.delete_outline_rounded, color: WebColors.red),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImageListField extends StatelessWidget {
  const _ImageListField({required this.label, required this.urls, required this.folder, required this.onChanged});

  final String label;
  final List<String> urls;
  final String folder;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(FormatHelper.capitalize(label), style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (int i = 0; i < urls.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ImageField(
              key: ValueKey<String>('img_${i}_${urls.length}'),
              label: '${i + 1}',
              url: urls[i],
              folder: folder,
              onChanged: (String u) {
                final List<String> next = List<String>.of(urls);
                next[i] = u;
                onChanged(next);
              },
              onRemove: () {
                final List<String> next = List<String>.of(urls)..removeAt(i);
                onChanged(next);
              },
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => onChanged(<String>[...urls, '']),
            icon: const AppIcon(Icons.add_photo_alternate_outlined),
            label: Text(FormatHelper.capitalize(const L('إضافة صورة', 'Add image').t)),
          ),
        ),
      ],
    );
  }
}

class _StringListField extends StatefulWidget {
  const _StringListField({super.key, required this.label, required this.initial, required this.onChanged, this.rtl = true});

  final String label;
  final List<String> initial;
  final ValueChanged<List<String>> onChanged;
  final bool rtl;

  @override
  State<_StringListField> createState() => _StringListFieldState();
}

class _StringListFieldState extends State<_StringListField> {
  late final List<TextEditingController> _cs =
      widget.initial.map((String s) => TextEditingController(text: s)).toList();

  void _emit() => widget.onChanged(_cs.map((TextEditingController c) => c.text.trim()).where((String s) => s.isNotEmpty).toList());

  @override
  void dispose() {
    for (final TextEditingController c in _cs) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(FormatHelper.capitalize(widget.label), style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (int i = 0; i < _cs.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _cs[i],
                    textDirection: widget.rtl ? TextDirection.rtl : TextDirection.ltr,
                    decoration: InputDecoration(prefixText: '${i + 1}.  '),
                    onChanged: (_) => _emit(),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _cs.removeAt(i).dispose();
                    _emit();
                  }),
                  icon: const AppIcon(Icons.remove_circle_outline, color: WebColors.red),
                ),
              ],
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => setState(() => _cs.add(TextEditingController())),
            icon: const AppIcon(Icons.add),
            label: Text(FormatHelper.capitalize(const L('إضافة سطر', 'Add line').t)),
          ),
        ),
      ],
    );
  }
}

class _PairsField extends StatefulWidget {
  const _PairsField({super.key, required this.label, required this.initial, required this.onChanged});

  final String label;
  final List<Map<String, dynamic>> initial;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  @override
  State<_PairsField> createState() => _PairsFieldState();
}

class _PairsFieldState extends State<_PairsField> {
  /// (label in Arabic, label in English, number)
  late final List<(TextEditingController, TextEditingController, TextEditingController)> _rows =
      <(TextEditingController, TextEditingController, TextEditingController)>[
    for (final Map<String, dynamic> m in widget.initial)
      (
        TextEditingController(text: '${m['label'] ?? ''}'),
        TextEditingController(text: '${m['label_en'] ?? ''}'),
        TextEditingController(text: '${m['value'] ?? ''}'),
      ),
  ];

  void _emit() => widget.onChanged(<Map<String, dynamic>>[
        for (final (TextEditingController ar, TextEditingController en, TextEditingController v) in _rows)
          if (ar.text.trim().isNotEmpty || en.text.trim().isNotEmpty)
            <String, dynamic>{'label': ar.text.trim(), 'label_en': en.text.trim(), 'value': v.text.trim()},
      ]);

  @override
  void dispose() {
    for (final (TextEditingController a, TextEditingController b, TextEditingController c) in _rows) {
      a.dispose();
      b.dispose();
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(FormatHelper.capitalize(widget.label), style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (int i = 0; i < _rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _rows[i].$1,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(labelText: const L('العنوان (عربي)', 'Label (Arabic)').t),
                    onChanged: (_) => _emit(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _rows[i].$2,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(labelText: const L('العنوان (English)', 'Label (English)').t),
                    onChanged: (_) => _emit(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _rows[i].$3,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: const L('الرقم', 'Number').t),
                    onChanged: (_) => _emit(),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    final (TextEditingController a, TextEditingController b, TextEditingController c) =
                        _rows.removeAt(i);
                    a.dispose();
                    b.dispose();
                    c.dispose();
                    _emit();
                  }),
                  icon: const AppIcon(Icons.remove_circle_outline, color: WebColors.red),
                ),
              ],
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => setState(
                () => _rows.add((TextEditingController(), TextEditingController(), TextEditingController()))),
            icon: const AppIcon(Icons.add),
            label: Text(FormatHelper.capitalize(const L('إضافة', 'Add').t)),
          ),
        ),
      ],
    );
  }
}
