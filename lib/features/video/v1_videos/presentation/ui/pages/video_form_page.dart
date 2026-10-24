/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_form_page.dart
/// Purpose: Declares `VideoFormPage` — the admin adds or edits a lesson and
///          watches the upload.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/constants/app_constants.dart';
import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/2-custom_textfield.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/features/video/v1_videos/presentation/controller/video_form_cubit.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/admin_permission.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/custom/114-app_messenger.dart';

class VideoFormPage extends StatelessWidget {
  const VideoFormPage({
    super.key,
    this.video,
    required this.adminUid,
    this.category = '',
  });

  /// Null = a new video.
  final VideoItem? video;
  final String adminUid;

  /// The category a NEW video starts in (the one the admin had open).
  final String category;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VideoFormCubit>(
      create: (_) => VideoFormCubit(
        existing: video,
        adminUid: adminUid,
        category: category,
      ),
      child: const _VideoFormView(),
    );
  }
}

class _VideoFormView extends StatefulWidget {
  const _VideoFormView();

  @override
  State<_VideoFormView> createState() => _VideoFormViewState();
}

class _VideoFormViewState extends State<_VideoFormView> {
  late final VideoFormCubit _cubit = context.read<VideoFormCubit>();
  late final TextEditingController _title =
      TextEditingController(text: _cubit.state.video.title);
  late final TextEditingController _description =
      TextEditingController(text: _cubit.state.video.description);
  late final TextEditingController _category =
      TextEditingController(text: _cubit.state.video.category);

  /// Prefilled only when the saved video is a link, not an uploaded file.
  late final TextEditingController _link = TextEditingController(
    text: _cubit.state.video.storagePath.isEmpty ? _cubit.state.video.url : '',
  );

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _category.dispose();
    _link.dispose();
    super.dispose();
  }

  String _formMessage(BuildContext context, VideoFormError error) {
    final S s = S.of(context);
    switch (error) {
      case VideoFormError.titleEmpty:
        return s.enterTitle;
      case VideoFormError.noFile:
        return s.chooseVideoFile;
      case VideoFormError.tooLarge:
        return s.fileTooLarge('${AppConstants.maxUploadMb}');
      case VideoFormError.badLink:
        return s.videoLinkInvalid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return BlocConsumer<VideoFormCubit, VideoFormState>(
      listenWhen: (VideoFormState a, VideoFormState b) => a.status != b.status,
      listener: (BuildContext context, VideoFormState state) {
        if (state.status == VideoFormStatus.saved) {
          // Keep the messenger, then pop: the message lives on the app's
          // overlay, so it stays after this page has closed.
          final AppMessenger messenger = AppMessenger.of(context);
          Navigator.of(context).pop(true);
          messenger.show(AppMessage(content: Text(FormatHelper.capitalize(s.videoSaved))));
        }
      },
      builder: (BuildContext context, VideoFormState state) {
        return PopScope(
          // An upload in flight is real work; leaving cancels it, so ask.
          canPop: state.status != VideoFormStatus.uploading,
          onPopInvokedWithResult: (bool didPop, Object? _) {
            if (!didPop) {
              AppMessenger.of(context)
                  .show(AppMessage(content: Text(FormatHelper.capitalize(s.videoStillUploading))));
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(
                FormatHelper.capitalize(_cubit.isNew ? s.addVideo : s.editVideo),
                style: StyleText.fontSize18Weight600,
              ),
              actions: <Widget>[
                Padding(
                  padding: EdgeInsetsDirectional.only(end: AppPadding.h),
                  child: AppButton(
                    label: s.save,
                    icon: Icons.check_rounded,
                    dense: true,
                    loading: state.isBusy,
                    onPressed: _cubit.save,
                  ),
                ),
              ],
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 760.w),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppPadding.h,
                    vertical: 16.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (state.formError != null) ...<Widget>[
                        InfoBanner.error(
                          _formMessage(context, state.formError!),
                        ),
                        SizedBox(height: 14.h),
                      ],
                      if (state.failure != null) ...<Widget>[
                        InfoBanner.error(state.failure!.message(context)),
                        SizedBox(height: 14.h),
                      ],
                      AppCard(
                        title: s.title,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            CustomTextField(
                              controller: _title,
                              label: s.title,
                              required: true,
                              onChanged: _cubit.setTitle,
                            ),
                            SizedBox(height: 12.h),
                            CustomTextField(
                              controller: _description,
                              label: s.description,
                              hint: s.descriptionHint,
                              maxLines: 3,
                              onChanged: _cubit.setDescription,
                            ),
                            SizedBox(height: 12.h),
                            CustomTextField(
                              controller: _category,
                              label: s.videoCategory,
                              hint: s.videoCategoryHint,
                              onChanged: _cubit.setCategory,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // The link and the file — where a video comes from —
                      // only amrmesbah33@gmail.com may set. Other admins edit
                      // the title, description, category and publishing.
                      if (SessionController.to.current.isSuperAdmin) ...<Widget>[
                      AppCard(
                        title: s.videoLinkTitle,
                        caption: s.videoLinkCaption,
                        child: CustomTextField(
                          controller: _link,
                          label: s.videoLinkLabel,
                          hint: 'https://example.com/lesson.mp4',
                          onChanged: _cubit.setLink,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      AppCard(
                        title: s.file,
                        caption: '${s.videoOrUpload} · ${AppConstants.maxUploadMb} MB max',
                        child: _FileSection(state: state),
                      ),
                      SizedBox(height: 16.h),
                      ],
                      AppCard(
                        child: Material(
                          color: AppColors.transparent,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              FormatHelper.capitalize(s.published),
                              style: StyleText.fontSize14Weight600,
                            ),
                            subtitle: Text(
                              FormatHelper.capitalize(s.publishedHint),
                              style: StyleText.fontSize12Weight400
                                  .copyWith(color: AppColors.secondaryText),
                            ),
                            trailing: Switch.adaptive(
                              value: state.video.published,
                              activeTrackColor: AppColors.secondaryPrimary,
                              // Videos → Publish / hide.
                              onChanged: SessionController.to.current
                                      .canDo(AdminAction.videosPublish)
                                  ? _cubit.setPublished
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Choose / replace the file, and the progress bar while it goes up.
class _FileSection extends StatelessWidget {
  const _FileSection({required this.state});

  final VideoFormState state;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final VideoFormCubit cubit = context.read<VideoFormCubit>();
    final bool uploading = state.status == VideoFormStatus.uploading;
    final String label = state.fileLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.field,
            borderRadius: AppRadius.fieldR,
          ),
          child: Row(
            children: <Widget>[
              AppIcon(
                Icons.video_library_rounded,
                size: 20.sp,
                color: AppColors.primary,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  FormatHelper.capitalize(label.isEmpty ? s.noFileChosen : label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: label.isEmpty
                      ? StyleText.fontSize13Weight400
                          .copyWith(color: AppColors.secondaryText)
                      : StyleText.fontSize13Weight600,
                ),
              ),
              if (state.file != null && !uploading)
                IconButton(
                  onPressed: cubit.clearFile,
                  icon: AppIcon(
                    Icons.close_rounded,
                    size: 18.sp,
                    color: AppColors.secondaryText,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        if (uploading) ...<Widget>[
          Text(
            FormatHelper.capitalize(s.uploadingPercent('${(state.progress * 100).round()}')),
            style: StyleText.fontSize13Weight600
                .copyWith(color: AppColors.primary),
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: AppRadius.buttonR,
            child: LinearProgressIndicator(
              value: state.progress == 0 ? null : state.progress,
              minHeight: 6.h,
              backgroundColor: AppColors.chip,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          SizedBox(height: 12.h),
          AppButton(
            label: s.uploadCancel,
            icon: Icons.close_rounded,
            kind: AppButtonKind.danger,
            onPressed: cubit.cancelUpload,
          ),
        ] else
          AppButton(
            label: label.isEmpty ? s.chooseVideoFile : s.replace,
            icon: Icons.cloud_upload_outlined,
            kind: AppButtonKind.subtle,
            onPressed: state.isBusy ? null : cubit.pickFile,
          ),
      ],
    );
  }
}
