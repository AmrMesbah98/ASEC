/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: download_all_bar.dart
/// Purpose: Declares `DownloadAllBar` — above a folder's lessons (12/11/2026,
///          ported from ENGX):
///            [⤓ Download all (12)]                 nothing saved yet
///            Downloading 3 / 12  ━━━━━──── [✕ Stop]  while it runs
///            ✓ All 12 lessons saved for offline     when done
///          Saves INSIDE the app only, one lesson after another
///          (VideoDownloads.downloadAll). Hidden when the admin switched off
///          "Download inside the app" or "Download a whole folder".
/// Author: Amr Mesbah
/// Created: 12/11/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:asec/core/custom/5-custom_button.dart';
import 'package:asec/core/custom/57-custom_dialog_manager.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/114-app_messenger.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/video/v1_videos/data/download/video_downloads.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';

class DownloadAllBar extends StatefulWidget {
  const DownloadAllBar({super.key, required this.videos, this.folderName = ''});

  /// The folder's lessons the member may download now (locked ones left out).
  final List<VideoItem> videos;

  /// Shown in the confirmation.
  final String folderName;

  @override
  State<DownloadAllBar> createState() => _DownloadAllBarState();
}

class _DownloadAllBarState extends State<DownloadAllBar> {
  @override
  void initState() {
    super.initState();
    VideoDownloads.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
  }

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  String _t(String en, String ar) => _ar ? ar : en;

  List<VideoItem> get _savable => <VideoItem>[
        for (final VideoItem v in widget.videos)
          if (v.hasFile) v,
      ];

  static String _size(int bytes) {
    final double mb = bytes / (1024 * 1024);
    return mb >= 1024 ? '${(mb / 1024).toStringAsFixed(1)} GB' : '${mb.toStringAsFixed(0)} MB';
  }

  Future<void> _start() async {
    final List<VideoItem> missing = VideoDownloads.missing(_savable);
    if (missing.isEmpty) return;
    final int bytes = missing.fold<int>(0, (int s, VideoItem v) => s + v.sizeBytes);
    final String name = widget.folderName.trim();
    final String size = bytes > 0 ? ' (${_size(bytes)})' : '';
    await CustomDialogManager.showConfirm(
      context: context,
      title: name.isEmpty
          ? _t('Download all lessons?', 'تحميل كل الدروس؟')
          : _t('Download all of "$name"?', 'تحميل كل دروس "$name"؟'),
      subtitle: _t(
        '${missing.length} lesson${missing.length == 1 ? '' : 's'}$size will be saved inside the app, '
            'one after another, to watch without internet.',
        'سيتم حفظ ${missing.length} درس$size داخل التطبيق واحدًا بعد الآخر للمشاهدة بدون إنترنت.',
      ),
      confirmLabel: _t('Download all', 'تحميل الكل'),
      cancelLabel: _t('Cancel', 'إلغاء'),
      onConfirm: () async {
        final int queued = await VideoDownloads.downloadAll(_savable);
        if (!mounted) return;
        final String msg = queued < 0
            ? _t('Too many downloads in one hour. Try again later.', 'تحميلات كثيرة خلال ساعة. حاول لاحقًا.')
            : _t('Downloading $queued lesson${queued == 1 ? '' : 's'} inside the app…',
                'جارٍ تحميل $queued درس داخل التطبيق…');
        if (queued != 0) {
          AppMessenger.of(context)
            ..hide()
            ..show(AppMessage(content: Text(msg)));
        }
      },
    );
  }

  void _stop() => VideoDownloads.cancelAll(<String>[for (final VideoItem v in widget.videos) v.id]);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Tracked so the bar follows every download.
      VideoDownloads.items.length;
      VideoDownloads.active.length;
      VideoDownloads.queued.length;
      final List<VideoItem> savable = _savable;
      if (!VideoDownloads.bulkEnabled || savable.length < 2) return const SizedBox.shrink();

      final int total = savable.length;
      final int done = savable.where((VideoItem v) => VideoDownloads.isDownloaded(v.id)).length;
      final List<VideoItem> busy = <VideoItem>[
        for (final VideoItem v in savable)
          if (VideoDownloads.isDownloading(v.id) || VideoDownloads.isQueued(v.id)) v,
      ];
      double partial = 0;
      for (final VideoItem v in busy) {
        partial += VideoDownloads.active[v.id] ?? 0;
      }
      final double progress = ((done + partial) / total).clamp(0.0, 1.0);

      final Widget content;
      if (busy.isNotEmpty) {
        final int n = done + 1 > total ? total : done + 1;
        content = Row(
          children: <Widget>[
            AppIcon(Icons.download_rounded, size: 20.sp, color: AppColors.primary),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(_t('Downloading $n / $total', 'جارٍ التحميل $n / $total'),
                      style: StyleText.fontSize13Weight600.copyWith(color: AppColors.text)),
                  SizedBox(height: 6.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6.h,
                      color: AppColors.primary,
                      backgroundColor: AppColors.secondaryText.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            customButton(
              title: _t('Stop', 'إيقاف'),
              function: _stop,
              wrapContent: true,
              color: AppColors.transparent,
              textColor: AppColors.red,
              borderColor: AppColors.red,
            ),
          ],
        );
      } else if (done >= total) {
        content = Row(
          children: <Widget>[
            AppIcon(Icons.download_done_rounded, size: 20.sp, color: AppColors.green),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(_t('All $total lessons saved for offline', 'كل الدروس ($total) محفوظة للمشاهدة بدون إنترنت'),
                  style: StyleText.fontSize13Weight600.copyWith(color: AppColors.text)),
            ),
          ],
        );
      } else {
        final int left = total - done;
        content = Row(
          children: <Widget>[
            AppIcon(Icons.download_rounded, size: 20.sp, color: AppColors.secondaryText),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                done == 0
                    ? _t('$total lessons in this folder', '$total درس في هذا المجلد')
                    : _t('$done of $total saved for offline', '$done من $total محفوظة بدون إنترنت'),
                style: StyleText.fontSize13Weight400.copyWith(color: AppColors.secondaryText),
              ),
            ),
            SizedBox(width: 10.w),
            customButton(
              title: done == 0 ? _t('Download all ($left)', 'تحميل الكل ($left)') : _t('Download the rest ($left)', 'تحميل الباقي ($left)'),
              function: _start,
              wrapContent: true,
            ),
          ],
        );
      }

      return Container(
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.containerR,
        ),
        child: content,
      );
    });
  }
}
