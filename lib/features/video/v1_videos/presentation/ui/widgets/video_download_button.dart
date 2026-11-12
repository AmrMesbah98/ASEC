/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_download_button.dart
/// Purpose: Declares `VideoDownloadButton` — the download icon on a lesson
///          card: download → progress ring (tap to cancel) → ✓ (tap to
///          remove). Saves into the app only (VideoDownloads), never to the
///          phone's Downloads.
/// Author: ASEC team
/// Created: 1/10/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/57-custom_dialog_manager.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/video/v1_videos/data/download/video_downloads.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/custom/114-app_messenger.dart';

class VideoDownloadButton extends StatefulWidget {
  const VideoDownloadButton({super.key, required this.video});

  final VideoItem video;

  @override
  State<VideoDownloadButton> createState() => _VideoDownloadButtonState();
}

class _VideoDownloadButtonState extends State<VideoDownloadButton> {
  @override
  void initState() {
    super.initState();
    // The ✓ must be right the first time the card is drawn.
    VideoDownloads.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _confirmRemove() async {
    final S s = S.of(context);
    await CustomDialogManager.showConfirm(
      context: context,
      title: s.downloadRemoveQuestion(widget.video.title),
      subtitle: s.downloadRemoveBody,
      confirmLabel: s.downloadRemove,
      cancelLabel: s.cancel,
      onConfirm: () => VideoDownloads.remove(widget.video.id),
    );
  }

  void _start() {
    final S s = S.of(context);
    VideoDownloads.start(widget.video);
    AppMessenger.of(context)
      ..hide()
      ..show(AppMessage(content: Text(FormatHelper.capitalize(s.downloadStarted))));
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final String id = widget.video.id;

    return Obx(() {
      final double? progress = VideoDownloads.active[id];
      VideoDownloads.items.length; // tracked: ✓ appears when it finishes
      final bool done = VideoDownloads.isDownloaded(id);
      final bool failed = VideoDownloads.failed.contains(id);
      // Waiting its turn in a "Download all" (12/11/2026).
      if (VideoDownloads.queued.contains(id) && progress == null) {
        return _Tap(
          tooltip: Localizations.localeOf(context).languageCode == 'ar'
              ? 'في انتظار التحميل — اضغط للتخطي'
              : 'Waiting to download — tap to skip',
          onTap: () => VideoDownloads.cancel(id),
          child: AppIcon(Icons.schedule_rounded, size: 22.sp, color: AppColors.secondaryText),
        );
      }

      if (progress != null) {
        return _Tap(
          tooltip: s.downloadCancel,
          onTap: () => VideoDownloads.cancel(id),
          child: SizedBox(
            width: 22.r,
            height: 22.r,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                CircularProgressIndicator(
                  // Unknown size yet → spinning.
                  value: progress > 0 ? progress : null,
                  strokeWidth: 2.4,
                  color: AppColors.primary,
                  backgroundColor: AppColors.secondaryText.withOpacity(0.2),
                ),
                AppIcon(Icons.close_rounded, size: 12.sp, color: AppColors.text),
              ],
            ),
          ),
        );
      }
      if (done) {
        return _Tap(
          tooltip: s.downloadDone,
          onTap: _confirmRemove,
          child: AppIcon(Icons.download_done_rounded,
              size: 22.sp, color: AppColors.green),
        );
      }
      if (failed) {
        return _Tap(
          tooltip: s.downloadFailed,
          onTap: _start,
          child: AppIcon(Icons.error_outline_rounded,
              size: 22.sp, color: AppColors.red),
        );
      }
      return _Tap(
        tooltip: s.downloadVideo,
        onTap: _start,
        child: AppIcon(Icons.download_rounded,
            size: 22.sp, color: AppColors.secondaryText),
      );
    });
  }
}

class _Tap extends StatelessWidget {
  const _Tap({required this.tooltip, required this.onTap, required this.child});

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: Padding(
          padding: EdgeInsets.all(4.r),
          child: Center(child: child),
        ),
      ),
    );
  }
}
