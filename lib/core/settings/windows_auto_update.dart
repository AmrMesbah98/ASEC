/// WINDOWS FORCED UPDATE (07/11/2026, from ENGX): every Windows release
/// that is published must be installed — no admin step. The newest version
/// is read from where the release build publishes it; an older app gets the
/// "Update required" dialog, and "Update now" downloads and installs it
/// INSIDE the app (WindowsUpdater). Off switch: Firestore
/// `settings/app_update.windows_auto_force = false`.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:asec/core/settings/windows_updater.dart';

abstract final class WindowsAutoUpdate {
  /// The newest installer the release build published (Firebase Storage
  /// downloads/latest.json): (version, installer link, notes).
  static Future<(String, String, String)?> latest() async {
    const String base = 'https://firebasestorage.googleapis.com/v0/b/asec-a811b.firebasestorage.app/o/';
    try {
      final http.Response r = await http
          .get(Uri.parse('${base}downloads%2Flatest.json?alt=media'))
          .timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return null;
      final Object? data = jsonDecode(r.body);
      if (data is! Map) return null;
      final String tag = '${data['version'] ?? ''}'.trim().replaceFirst(RegExp(r'^[vV]'), '');
      final String file = '${data['file'] ?? ''}'.trim();
      if (tag.isEmpty || file.isEmpty) return null;
      return (tag, '${base}downloads%2F${Uri.encodeComponent(file)}?alt=media', '');
    } catch (_) {
      return null;
    }
  }

  /// Downloads [url] with a progress bar, then starts the installer and
  /// closes the app. Errors are shown in the same window.
  static Future<void> installInApp(BuildContext context, String url) async {
    final ValueNotifier<double?> progress = ValueNotifier<double?>(null);
    final ValueNotifier<String> error = ValueNotifier<String>('');
    bool cancelled = false;
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Downloading the update'),
        content: ValueListenableBuilder<String>(
          valueListenable: error,
          builder: (BuildContext _, String err, Widget? __) => err.isNotEmpty
              ? Text(err)
              : ValueListenableBuilder<double?>(
                  valueListenable: progress,
                  builder: (BuildContext _, double? p, Widget? __) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      LinearProgressIndicator(value: p),
                      const SizedBox(height: 10),
                      Text(p == null ? 'Starting…' : '${(p * 100).round()}%'),
                    ],
                  ),
                ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              cancelled = true;
              Navigator.of(ctx, rootNavigator: true).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    ));
    try {
      final String path = await WindowsUpdater.download(
        url,
        onProgress: (double? p) => progress.value = p,
        cancelled: () => cancelled,
      );
      if (cancelled) return;
      await WindowsUpdater.runAndExit(path);
    } catch (e) {
      if (!cancelled) error.value = 'The update could not be downloaded. Check the internet and try again.\n($e)';
    }
  }
}
