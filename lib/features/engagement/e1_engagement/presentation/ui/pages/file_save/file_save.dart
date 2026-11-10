/// Module: engagement / e1_engagement
///
///*************************** FILE INFO ****************************///
/// File Name: file_save.dart
/// Purpose: Saves a course file into the computer's Downloads folder.
///          `dart:io` does not exist on the web, so the two implementations
///          are picked at compile time (same as video_file.dart).
/// Author: ASEC team
/// Created: 05/11/2026

export 'file_save_io.dart' if (dart.library.js_interop) 'file_save_web.dart';
