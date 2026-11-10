/// Module: engagement / e1_engagement
///
///*************************** FILE INFO ****************************///
/// File Name: file_save_io.dart
/// Purpose: Desktop / mobile side of file_save.dart — downloads [url] and
///          writes it into Downloads (the app's Documents folder when the
///          platform has no Downloads folder).
/// Author: ASEC team
/// Created: 05/11/2026

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Writes the file at [url] as [fileName] and returns where it went.
/// Never overwrites: "notes.pdf" becomes "notes (1).pdf" when taken.
Future<String> saveUrlToDownloads(String url, String fileName) async {
  final http.Response res = await http.get(Uri.parse(url));
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw HttpException('HTTP ${res.statusCode}', uri: Uri.parse(url));
  }
  Directory? dir;
  try {
    dir = await getDownloadsDirectory();
  } catch (_) {
    dir = null;
  }
  dir ??= await getApplicationDocumentsDirectory();

  final String clean = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  final String name = clean.isEmpty ? 'file' : clean;
  final int dot = name.lastIndexOf('.');
  final String base = dot > 0 ? name.substring(0, dot) : name;
  final String ext = dot > 0 ? name.substring(dot) : '';
  String path = '${dir.path}${Platform.pathSeparator}$name';
  for (int i = 1; await File(path).exists(); i++) {
    path = '${dir.path}${Platform.pathSeparator}$base ($i)$ext';
  }
  await File(path).writeAsBytes(res.bodyBytes, flush: true);
  return path;
}
