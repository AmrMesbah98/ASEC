/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: upload_kit.dart
/// Purpose: The "Upload lessons" page's constants and English texts
///          ([UpS]). Ported from ENGX (09/11/2026) — the shapes it used there
///          (AppCard, AppButton, AppMessenger, FormatHelper, the switch) are
///          ASEC's own, so the page uses ASEC's real ones.
/// Author: ASEC team
/// Created: 09/11/2026
library;

import 'package:flutter/widgets.dart';

/// Upload size limit, per file.
const int kMaxUploadMb = 2048;

/// Video files the upload accepts.
const Set<String> kVideoExtensions = <String>{'mp4', 'm4v', 'mov', 'webm', 'mkv', 'avi'};

/// The page's texts (Eduneers l10n, English).
class UpS {
  const UpS._();
  static UpS of(BuildContext _) => const UpS._();
  static const UpS of2 = UpS._();

  String get fldPickCategory => 'Choose a folder';
  String get videoCategory => 'Folder';
  String get uploadCancel => 'Cancel the upload';
  String get upTimeLeft => 'Time left';
  String get upSwitched => 'Signed out of the upload account. The next upload asks you to sign in.';
  String get upSwitchAccount => 'Use another upload account';
  String get upSpeed => 'Speed';
  String get upServerError => 'Something went wrong on the server. Please try again.';
  String get upResume => 'Resume';
  String get upPaused => 'Paused';
  String get upPause => 'Pause';
  String get upOnline => 'Internet connected';
  String get upOffline => 'No internet — upload paused, it resumes by itself';
  String get upNoInternet => 'No internet connection. Connect and try again.';
  String upFormats(String mb) => 'MP4, MOV, WebM, MKV · up to $mb MB';
  String get upDropRelease => 'Release to add the videos';
  String get upDriveOauthMissing => 'Server sign-in isn\'t set up yet — its settings are missing.';
  String get upDriveNotSet => 'The video server isn\'t set up yet — its settings are missing.';
  String get upDriveFull => 'The server storage is full. Free up space, then start again.';
  String get upCalculating => 'Calculating…';
  String get upBrowse => 'Browse files';
  String get publishedHint => 'Off keeps it a draft that only you can see.';
  String get published => 'Published';
  String get fldRoot => 'General (main folder)';
  String get fldNew => 'New folder';
  String bulkVideos(String n, String size) => '$n videos · $size';
  String get bulkUploading => 'Uploading';
  String get bulkTitleField => 'Lesson title';
  String get bulkTitle => 'Upload lessons';
  String get bulkSyncing => 'Adding the lessons to the app…';
  String get bulkStart => 'Start upload';
  String get bulkSettingsSub =>
      'The folder and publishing apply to all videos in this upload. Each title can be changed below.';
  String get bulkSettings => 'For every video';
  String get bulkRetry => 'Retry';
  String bulkRejected(String n) =>
      '$n file(s) left out — not a video, already in the list, or over the size limit.';
  String get bulkPending => 'Waiting';
  String get bulkLeaveQ => 'The upload is still running. Cancel it first.';
  String bulkFinishedSome(String ok, String failed) =>
      '$ok added, $failed failed — press Retry on them, then Start upload.';
  String bulkFinished(String n) => 'All done — $n lessons added.';
  String get bulkFailed => 'Failed';
  String get bulkDropTitle => 'Drag & drop your lesson videos';
  String get bulkDropSub => 'Pick as many as you like — they upload one after another straight to the server.';
  String get bulkDone => 'Uploaded';
  String bulkCount(String done, String total) => '$done of $total uploaded';
  String get bulkClear => 'Clear list';
  String get bulkAddMore => 'Add more videos';
  String get fldNewTop => 'A new category folder on the server.';
  String fldNewIn(String course) => 'A new sub-category inside “$course”.';
  String get fldName => 'Folder name';
  String get fldCreate => 'Create';
  String get cancel => 'Cancel';
  String fldCreated(String name) => 'Folder “$name” created. Choose it as the folder to upload into.';
  String get fldLoading => 'Loading folders…';
  String get fldCurrent => 'Current';
}
