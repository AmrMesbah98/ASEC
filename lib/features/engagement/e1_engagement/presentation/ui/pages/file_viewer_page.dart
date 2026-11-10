/// Module: engagement / e1_engagement
///
///*************************** FILE INFO ****************************///
/// File Name: file_viewer_page.dart
/// Purpose: Declares `FileViewerPage` — a course file opened INSIDE the app
///          (never handed to another app): PDFs, pictures, videos / sound
///          and plain text are shown right here; the other files of the
///          same folder stay listed on the right so the member can move
///          between them. Types the app cannot draw (Word, Excel, DWG, ZIP…)
///          get a card with "Save to Downloads" and "Open with another app".
///          `FilePreview` is the preview on its own, for other pages.
/// Author: ASEC team
/// Created: 05/11/2026

import 'dart:convert';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:pdfrx/pdfrx.dart';
import 'package:video_player/video_player.dart';

import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_watermark.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/engagement/e1_engagement/domain/entities/engagement_entities.dart';
import 'package:asec/features/video/v1_videos/data/cloud/cloud_lessons.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/office/file_type_icon.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/office/office_previews.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/pages/file_save/file_save.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/engagement_widgets.dart';
import 'package:asec/generated/l10n.dart';

/// English or Arabic, by the app's language.
String _tr(BuildContext context, String en, String ar) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;


/// Opens [files] in the app at [index]; the others are listed beside it.
Future<void> openFilesInApp(BuildContext context, List<LibraryFile> files, {int index = 0}) {
  if (files.isEmpty) return Future<void>.value();
  // Files on the cloud drive are stored as `r2:<key>`: sign a fresh address
  // now, when they are opened (it stays valid for this visit).
  final List<LibraryFile> ready = <LibraryFile>[
    for (final LibraryFile f in files)
      CloudLessons.isDirect(f.url) ? f.withUrl(CloudLessons.signedUrl(CloudLessons.keyFor(f.url)!)) : f,
  ];
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => FileViewerPage(files: ready, initialIndex: index.clamp(0, ready.length - 1)),
    ),
  );
}

/// What the app can draw for a file.
enum FilePreviewKind { pdf, image, media, text, excel, word, slides, none }

FilePreviewKind previewKindOf(String extension) {
  switch (extension) {
    case 'pdf':
      return FilePreviewKind.pdf;
    case 'png':
    case 'jpg':
    case 'jpeg':
    case 'gif':
    case 'webp':
    case 'bmp':
      return FilePreviewKind.image;
    case 'mp4':
    case 'mov':
    case 'm4v':
    case 'webm':
    case 'mkv':
    case 'mp3':
    case 'm4a':
    case 'wav':
    case 'aac':
      return FilePreviewKind.media;
    case 'txt':
    case 'csv':
    case 'md':
    case 'json':
    case 'log':
    case 'xml':
      return FilePreviewKind.text;
    case 'xlsx':
    case 'xlsm':
      return FilePreviewKind.excel;
    case 'docx':
      return FilePreviewKind.word;
    case 'pptx':
      return FilePreviewKind.slides;
    default:
      return FilePreviewKind.none;
  }
}

class FileViewerPage extends StatefulWidget {
  const FileViewerPage({super.key, required this.files, this.initialIndex = 0});

  final List<LibraryFile> files;
  final int initialIndex;

  @override
  State<FileViewerPage> createState() => _FileViewerPageState();
}

class _FileViewerPageState extends State<FileViewerPage> {
  late int _index = widget.initialIndex;
  bool _saving = false;

  LibraryFile get _file => widget.files[_index];

  Future<void> _save() async {
    final S s = S.of(context);
    setState(() => _saving = true);
    try {
      final LibraryFile f = _file;
      final String name = f.fileName.isNotEmpty ? f.fileName : f.title;
      final String path = await saveUrlToDownloads(f.url, name);
      if (mounted) showEngagementToast(context, _tr(context, 'Saved to Downloads: ', 'تم الحفظ في التنزيلات: ') + path.split(RegExp(r'[\\/]')).last);
    } catch (_) {
      if (mounted) showEngagementToast(context, s.engFileOpenFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LibraryFile file = _file;
    final bool many = widget.files.length > 1;
    final FilePreviewKind kind = previewKindOf(file.extension);

    // THE SAME PAGE AS A LESSON: the file where the video plays, its name
    // and details under it, and the folder's other files on the right
    // where the lessons are listed.
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leadingWidth: 44,
        titleSpacing: 0,
        title: Text(
          FormatHelper.capitalize(file.title),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: StyleText.fontSize16Weight600,
        ),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final bool side = many && c.maxWidth >= 1100;
          final double pad = AppPadding.h;
          final double mainWidth = side
              ? c.maxWidth - pad * 2 - 24.w - 400
              : (c.maxWidth - pad * 2).clamp(0, 960.w).toDouble();
          // A video or a picture: the player's 16:9. A document: taller,
          // so a page can be read.
          final double tall = c.maxHeight * 0.78;
          final double height = kind == FilePreviewKind.media || kind == FilePreviewKind.image
              ? mainWidth * 9 / 16
              : (mainWidth * 9 / 16 > tall ? mainWidth * 9 / 16 : tall);

          final Widget main = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                height: height < 260 ? 260 : height,
                child: ClipRRect(
                  borderRadius: AppRadius.containerR,
                  child: ColoredBox(
                    color: kind == FilePreviewKind.media ? Colors.black : AppColors.card,
                    child: FilePreview(key: ValueKey<String>(file.id), file: file),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              _FileDetails(
                file: file,
                saving: _saving,
                onSave: _saving ? null : _save,
                downloadLabel: _tr(context, 'Save to Downloads', 'حفظ في التنزيلات'),
              ),
            ],
          );
          final Widget list = _SideFiles(
            files: widget.files,
            current: _index,
            onOpen: (int i) => setState(() => _index = i),
          );

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: pad, vertical: 16.h),
            child: side
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: main),
                      SizedBox(width: 24.w),
                      SizedBox(width: 400, child: list),
                    ],
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 960.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          main,
                          if (many) ...<Widget>[
                            SizedBox(height: 24.h),
                            list,
                          ],
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

/// Under the file, like the lesson's details: its name, type and size, and
/// "Download".
class _FileDetails extends StatelessWidget {
  const _FileDetails({
    required this.file,
    required this.saving,
    required this.onSave,
    required this.downloadLabel,
  });

  final LibraryFile file;
  final bool saving;
  final VoidCallback? onSave;
  final String downloadLabel;

  @override
  Widget build(BuildContext context) {
    final String meta = <String>[
      if (file.extension.isNotEmpty) file.extension.toUpperCase(),
      if (file.sizeLabel.isNotEmpty) file.sizeLabel,
    ].join(' · ');
    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Row(
        children: <Widget>[
          FileTypeIcon(extension: file.extension, size: 34),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  FormatHelper.capitalize(file.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StyleText.fontSize16Weight600.copyWith(color: AppColors.text),
                ),
                if (meta.isNotEmpty)
                  Text(meta, style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText)),
              ],
            ),
          ),
          AppButton(
            label: downloadLabel,
            icon: Icons.download_rounded,
            kind: AppButtonKind.subtle,
            dense: true,
            loading: saving,
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}

/// The folder's files beside the preview; the open one is highlighted.
class _SideFiles extends StatelessWidget {
  const _SideFiles({required this.files, required this.current, required this.onOpen});

  final List<LibraryFile> files;
  final int current;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // The same chip as "Lessons · N" beside a video.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: AppColors.primary),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppIcon(Icons.folder_rounded, size: 16.sp, color: AppColors.primary),
                SizedBox(width: 6.w),
                Text(
                  '${FormatHelper.capitalize(s.engFilesTab)} · ${files.length}',
                  style: StyleText.fontSize13Weight600.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 10.h),
        for (int i = 0; i < files.length; i++) ...<Widget>[
          FileRow(file: files[i], selected: i == current, onTap: () => onOpen(i)),
          SizedBox(height: 8.h),
        ],
      ],
    );
  }
}

/// One compact file row for side lists; [selected] = the one on screen.
class FileRow extends StatefulWidget {
  const FileRow({super.key, required this.file, required this.onTap, this.selected = false});

  final LibraryFile file;
  final VoidCallback onTap;
  final bool selected;

  @override
  State<FileRow> createState() => _FileRowState();
}

class _FileRowState extends State<FileRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final LibraryFile f = widget.file;
    final bool on = widget.selected;
    final String meta = <String>[
      if (f.extension.isNotEmpty) f.extension.toUpperCase(),
      if (f.sizeLabel.isNotEmpty) f.sizeLabel,
    ].join(' · ');
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: on
                ? AppColors.primary.withOpacity(0.12)
                : _hover
                    ? AppColors.card.withOpacity(0.7)
                    : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: on ? AppColors.primary.withOpacity(0.7) : AppColors.border),
          ),
          child: Row(
            children: <Widget>[
              FileTypeIcon(extension: f.extension, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      FormatHelper.capitalize(f.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StyleText.fontSize13Weight600
                          .copyWith(color: on ? AppColors.primary : AppColors.text),
                    ),
                    if (meta.isNotEmpty)
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StyleText.fontSize11Weight400.copyWith(color: AppColors.secondaryText),
                      ),
                  ],
                ),
              ),
              if (on) Icon(Icons.visibility_rounded, size: 16, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

// ── The preview ─────────────────────────────────────────────────────────────

/// Draws [file] inside the app, whatever room it is given.
class FilePreview extends StatelessWidget {
  const FilePreview({super.key, required this.file});

  final LibraryFile file;

  @override
  Widget build(BuildContext context) {
    if (file.url.isEmpty) return _NoPreview(file: file);
    switch (previewKindOf(file.extension)) {
      case FilePreviewKind.pdf:
        return PdfViewer.uri(
          Uri.parse(file.url),
          params: PdfViewerParams(
            loadingBannerBuilder: (BuildContext context, int done, int? total) => Center(
              child: CircularProgressIndicator(
                value: total != null && total > 0 ? done / total : null,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        );
      case FilePreviewKind.image:
        return InteractiveViewer(
          maxScale: 6,
          child: Center(
            child: Image.network(
              file.url,
              fit: BoxFit.contain,
              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? p) =>
                  p == null ? child : const AppLoading(),
              errorBuilder: (BuildContext context, Object e, StackTrace? st) =>
                  _Failed(onRetry: null, error: e),
            ),
          ),
        );
      case FilePreviewKind.media:
        return _MediaPreview(url: file.url);
      case FilePreviewKind.text:
        return _TextPreview(url: file.url);
      case FilePreviewKind.excel:
        return ExcelPreview(url: file.url);
      case FilePreviewKind.word:
        return WordPreview(url: file.url);
      case FilePreviewKind.slides:
        return SlidesPreview(url: file.url);
      case FilePreviewKind.none:
        return _NoPreview(file: file);
    }
  }
}

class _MediaPreview extends StatefulWidget {
  const _MediaPreview({required this.url});

  final String url;

  @override
  State<_MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<_MediaPreview> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final VideoPlayerController v = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await v.initialize();
      if (!mounted) {
        await v.dispose();
        return;
      }
      setState(() {
        _video = v;
        _chewie = ChewieController(
          videoPlayerController: v,
          autoPlay: true,
          aspectRatio: v.value.aspectRatio > 0 ? v.value.aspectRatio : 16 / 9,
          overlay: const VideoWatermark(),
        );
      });
    } catch (e) {
      await v.dispose();
      if (mounted) setState(() => _error = e);
    }
  }

  void _retry() {
    setState(() => _error = null);
    _open();
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return _Failed(onRetry: _retry, error: _error);
    final ChewieController? c = _chewie;
    if (c == null) return const AppLoading();
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: AspectRatio(aspectRatio: c.aspectRatio ?? 16 / 9, child: Chewie(controller: c)),
      ),
    );
  }
}

class _TextPreview extends StatefulWidget {
  const _TextPreview({required this.url});

  final String url;

  @override
  State<_TextPreview> createState() => _TextPreviewState();
}

class _TextPreviewState extends State<_TextPreview> {
  late Future<String> _text = _load();

  Future<String> _load() async {
    final http.Response r = await http.get(Uri.parse(widget.url));
    if (r.statusCode < 200 || r.statusCode >= 300) throw Exception('HTTP ${r.statusCode}');
    return utf8.decode(r.bodyBytes, allowMalformed: true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _text,
      builder: (BuildContext context, AsyncSnapshot<String> snap) {
        if (snap.hasError) {
          return _Failed(onRetry: () => setState(() => _text = _load()), error: snap.error);
        }
        if (!snap.hasData) return const AppLoading();
        return Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: SelectableText(
              snap.data!,
              style: StyleText.fontSize13Weight400.copyWith(
                color: AppColors.text,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.onRetry, this.error});

  final VoidCallback? onRetry;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Center(child: AppErrorView(message: S.of(context).fvLoadFailed, onRetry: onRetry, error: error));
  }
}

/// Word, Excel, PowerPoint, DWG, ZIP…: nothing to draw, so offer the file.
class _NoPreview extends StatelessWidget {
  const _NoPreview({required this.file});

  final LibraryFile file;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FileTypeIcon(extension: file.extension, size: 72),
            const SizedBox(height: 16),
            Text(
              FormatHelper.capitalize(file.title),
              textAlign: TextAlign.center,
              style: StyleText.fontSize16Weight600.copyWith(color: AppColors.text),
            ),
            const SizedBox(height: 6),
            Text(
              FormatHelper.capitalize(_tr(context, "This file type can't be shown inside the app", 'لا يمكن عرض هذا النوع من الملفات داخل التطبيق')),
              textAlign: TextAlign.center,
              style: StyleText.fontSize14Weight500.copyWith(color: AppColors.text),
            ),
            const SizedBox(height: 4),
            Text(
              FormatHelper.capitalize(_tr(context, 'Save it to your Downloads folder, or open it with another app.', 'احفظه في مجلد التنزيلات، أو افتحه بتطبيق آخر.')),
              textAlign: TextAlign.center,
              style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 18),
            AppButton(
              label: _tr(context, 'Open with another app', 'فتح بتطبيق آخر'),
              icon: Icons.open_in_new_rounded,
              kind: AppButtonKind.outlined,
              dense: true,
              onPressed: file.url.isEmpty ? null : () => openFileUrl(context, file.url),
            ),
          ],
        ),
      ),
    );
  }
}
