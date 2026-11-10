/// Settings → Cloudflare lessons (07/11/2026, from ENGX): copies every Drive
/// lesson that is not in Cloudflare yet (already copied ones are skipped).
/// Read with the app's Drive API key, so it works for the lessons folder
/// as it is shared now. Keep the page open until it finishes.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;

import 'package:asec/core/constants/firebase_collections.dart';
import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/security/secure_video_server_io.dart';
import 'package:asec/features/video/v1_videos/data/cloud/cloud_lessons.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_link.dart';
import 'package:asec/firebase_options.dart';

class CloudLessonsCard extends StatefulWidget {
  const CloudLessonsCard({super.key});

  @override
  State<CloudLessonsCard> createState() => _CloudLessonsCardState();
}

class _CloudLessonsCardState extends State<CloudLessonsCard> {
  bool _copying = false;
  bool _stop = false;
  int _done = 0;
  int _skipped = 0;
  int _failed = 0;
  int _total = 0;
  String _now = '';
  final List<String> _log = <String>[];

  @override
  void dispose() {
    _stop = true;
    super.dispose();
  }

  void _say(String line) {
    if (!mounted) return;
    setState(() {
      _log.insert(0, line);
      if (_log.length > 200) _log.removeLast();
    });
  }

  /// The Drive file's bytes, read with the Firebase project's API key.
  Future<http.StreamedResponse> _driveFile(String id) async {
    final String key = DefaultFirebaseOptions.currentPlatform.apiKey;
    final Uri uri = Uri.https('www.googleapis.com', '/drive/v3/files/$id', <String, String>{
      'alt': 'media',
      'acknowledgeAbuse': 'true',
      'supportsAllDrives': 'true',
      'key': key,
    });
    final http.StreamedResponse r = await http.Client().send(http.Request('GET', uri));
    if (r.statusCode != 200) {
      final String body = await r.stream.bytesToString();
      throw StateError('Drive ${r.statusCode}: ${body.length > 160 ? body.substring(0, 160) : body}');
    }
    return r;
  }

  /// The lesson's bytes: with the
  /// Drive API key, else from Drive's public link (07/11/2026).
  Future<Stream<List<int>>> _source(String id) async {
    final List<String> why = <String>[];
    try {
      return (await _driveFile(id)).stream;
    } catch (e) {
      why.add('API key: $e');
    }
    try {
      final HttpClientResponse r = await PinnedFetch.get(Uri.parse(VideoLink.playable('https://drive.google.com/file/d/$id/view')));
      final String type = r.headers.contentType?.mimeType ?? '';
      if (r.statusCode == 200 && type != 'text/html') return r;
      await r.drain<void>();
      why.add('public link: HTTP ${r.statusCode} $type');
    } catch (e) {
      why.add('public link: $e');
    }
    throw StateError(why.join(' · '));
  }

  Future<void> _copyAll() async {
    setState(() {
      _copying = true;
      _stop = false;
      _done = 0;
      _skipped = 0;
      _failed = 0;
      _log.clear();
    });
    try {
      final Set<String> ids = <String>{};
      final List<(String, String)> lessons = <(String, String)>[];
      final docs = await AppFirebase.db.collection(FirebaseCollections.videos).get();
      for (final d in docs.docs) {
        final String url = '${d.data()['url'] ?? ''}';
        final String? id = VideoLink.driveId(url);
        if (id != null && ids.add(id)) lessons.add((id, '${d.data()['title'] ?? id}'));
      }
      setState(() => _total = lessons.length);
      for (final (String id, String title) in lessons) {
        if (_stop) break;
        setState(() => _now = title);
        try {
          if (await CloudLessons.has('lessons/$id')) {
            _skipped++;
            continue;
          }
          await CloudLessons.upload('lessons/$id', await _source(id), cancelled: () => _stop);
          _done++;
          _say('✓ $title');
        } catch (e) {
          _failed++;
          _say('✗ $title — $e');
        }
        if (mounted) setState(() {});
      }
    } catch (e) {
      _say('Stopped: $e');
    } finally {
      if (mounted) {
        setState(() {
          _copying = false;
          _now = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Cloudflare lessons',
      caption: 'Copies every Drive lesson that is not in Cloudflare yet (already copied ones are skipped). '
          'Then switch on Control centre → "Play lessons from Cloudflare". Keep this page open while copying.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Server: ${CloudLessons.baseUrl}', style: TextStyle(fontSize: 11.sp, color: AppColors.secondaryText)),
          SizedBox(height: 10.h),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  label: _copying ? 'Copying…' : 'Copy lessons',
                  icon: Icons.cloud_upload_rounded,
                  loading: _copying,
                  onPressed: _copying ? null : _copyAll,
                ),
              ),
              if (_copying) ...<Widget>[
                SizedBox(width: 8.w),
                AppButton(
                  label: 'Stop',
                  kind: AppButtonKind.outlined,
                  onPressed: () => setState(() => _stop = true),
                ),
              ],
            ],
          ),
          if (_total > 0) ...<Widget>[
            SizedBox(height: 10.h),
            Text('Copied $_done · already there $_skipped · failed $_failed · of $_total'),
          ],
          if (_copying && _now.isNotEmpty) ...<Widget>[
            SizedBox(height: 6.h),
            Text('Now: $_now', maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 6.h),
            const LinearProgressIndicator(),
          ],
          SizedBox(height: 8.h),
          for (final String line in _log.take(60))
            Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: Text(line,
                  style: TextStyle(
                      fontSize: 11.sp, color: line.startsWith('✗') ? Colors.redAccent : AppColors.secondaryText)),
            ),
        ],
      ),
    );
  }
}
