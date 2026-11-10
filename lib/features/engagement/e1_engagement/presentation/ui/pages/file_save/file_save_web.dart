/// Module: engagement / e1_engagement
///
///*************************** FILE INFO ****************************///
/// File Name: file_save_web.dart
/// Purpose: Web side of file_save.dart — the browser downloads the file
///          itself, so this just hands it the link.
/// Author: ASEC team
/// Created: 05/11/2026

import 'package:url_launcher/url_launcher.dart';

Future<String> saveUrlToDownloads(String url, String fileName) async {
  await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
  return fileName;
}
