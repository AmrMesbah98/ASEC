/// Module: core/helper/upload
///
///*************************** FILE INFO ****************************///
/// File Name: picked_upload_io.dart
/// Purpose: `startUpload` for phones, tablets and desktops — streams the file
///          from disk.
/// Author: ASEC team
/// Created: 19/9/2026

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Streams [file] from its path. Falls back to the in-memory bytes only if
/// the picker gave no path (it always does on these platforms, but a null
/// path must not throw).
UploadTask startUpload(
  Reference ref,
  PlatformFile file,
  SettableMetadata metadata,
) {
  final String? path = file.path;
  if (path != null) {
    return ref.putFile(File(path), metadata);
  }
  return ref.putData(file.bytes!, metadata);
}

/// The picked file as a byte stream — read from disk, or the in-memory
/// bytes when the picker gave no path. Used for uploads that do not go
/// through Firebase Storage (Cloudflare R2).
Stream<List<int>> pickedBytes(PlatformFile file) {
  final String? path = file.path;
  if (path != null) return File(path).openRead();
  return Stream<List<int>>.value(file.bytes!);
}
