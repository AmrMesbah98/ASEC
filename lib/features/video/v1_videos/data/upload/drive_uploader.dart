/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: drive_uploader.dart
/// Purpose: Declares `DriveUploader` — an admin uploads lessons from the app
///          STRAIGHT INTO the ASEC lessons folder on Google Drive (the same
///          folder DriveVideoSync reads), into the category / sub-category
///          folder picked. Ported from ENGX (09/11/2026).
/// Author: ASEC team
/// Created: 09/11/2026
///
/// SIGN-IN
/// -------
/// Google's "installed app" flow: the first upload opens the browser, the
/// admin signs in with the Google account that owns the folder and allows
/// Drive, and the browser hands the answer back to the app on a local port.
/// The credentials are kept on this computer (GetStorage) and refreshed by
/// themselves, so it is asked only once. DESKTOP ONLY (macOS, Windows,
/// Linux) — see [supported].
///
/// SETUP (once) — Google Cloud console, project asec-a811b:
///   1. APIs & Services → OAuth consent screen: External, app name "ASEC",
///      add the Google account that owns the lessons folder under Test users.
///   2. Credentials → Create credentials → OAuth client ID → "Desktop app".
///   3. Paste the Client ID and secret in Upload lessons → "Server sign-in
///      settings" (saved to Firestore `admin_config/drive`, next to
///      `folder_id`).

import 'dart:async';
import 'dart:io';

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:asec/core/network/app_firebase.dart';

/// Thrown when `admin_config/drive` lacks the folder or the OAuth client.
class DriveSetupMissing implements Exception {
  const DriveSetupMissing(this.what);

  /// 'folder' or 'oauth'.
  final String what;

  @override
  String toString() => 'Drive setup missing: $what';
}

/// One folder of the lessons tree: a course (top level, [parentName] empty)
/// or a section inside one. The root itself has an empty [name].
class DriveFolder {
  const DriveFolder({required this.id, required this.name, this.parentName = ''});

  final String id;
  final String name;

  /// The course this section is in; empty for a course or the root.
  final String parentName;

  bool get isRoot => name.isEmpty;
  bool get isCourse => name.isNotEmpty && parentName.isEmpty;
}

/// Thrown from inside the upload stream when the admin cancels.
class DriveUploadCancelled implements Exception {
  const DriveUploadCancelled();
}

abstract final class DriveUploader {
  /// Where the installed-app sign-in works.
  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);

  static const String _credKey = 'drive_oauth_credentials_v1';
  static const String _folderMime = 'application/vnd.google-apps.folder';

  /// `admin_config/drive` (admins only): `folder_id` — the ASEC lessons
  /// folder DriveVideoSync reads — and the OAuth client.
  static DocumentReference<Map<String, dynamic>> get _doc =>
      AppFirebase.db.collection('admin_config').doc('drive');

  static Future<Map<String, dynamic>> _config() async {
    final DocumentSnapshot<Map<String, dynamic>> d = await _doc.get();
    return <String, dynamic>{...?d.data()};
  }

  static String _str(Map<String, dynamic> m, String k) {
    final Object? v = m[k];
    return v is String ? v.trim() : '';
  }

  static AutoRefreshingAuthClient? _client;

  /// A signed-in Drive client: the saved credentials, else the browser
  /// sign-in (once).
  static Future<AutoRefreshingAuthClient> _signedIn(Map<String, dynamic> cfg) async {
    if (_client != null) return _client!;
    final String id = _str(cfg, 'oauth_client_id');
    final String secret = _str(cfg, 'oauth_client_secret');
    if (id.isEmpty) throw const DriveSetupMissing('oauth');
    final ClientId clientId = ClientId(id, secret.isEmpty ? null : secret);
    final GetStorage box = GetStorage();

    AutoRefreshingAuthClient client;
    final String? saved = box.read<String>(_credKey);
    if (saved != null && saved.isNotEmpty) {
      final AccessCredentials creds =
          AccessCredentials.fromJson(Map<String, dynamic>.from(jsonDecode(saved) as Map));
      client = autoRefreshingClient(clientId, creds, http.Client());
    } else {
      debugPrint('🟡 [DriveUpload] opening the browser for Google sign-in…');
      client = await clientViaUserConsent(
        clientId,
        <String>[drive.DriveApi.driveScope],
        (String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      );
    }
    await box.write(_credKey, jsonEncode(client.credentials.toJson()));
    client.credentialUpdates.listen((AccessCredentials c) => box.write(_credKey, jsonEncode(c.toJson())));
    _client = client;
    return client;
  }

  /// The saved OAuth client (for the settings dialog): (id, secret).
  static Future<(String, String)> oauthClient() async {
    final Map<String, dynamic> c = await _config();
    return (_str(c, 'oauth_client_id'), _str(c, 'oauth_client_secret'));
  }

  /// Saves the "Desktop app" OAuth client into `admin_config/drive`
  /// (Upload lessons → Server sign-in), so nobody has to open Firestore.
  static Future<void> saveOAuthClient(String id, String secret) async {
    await _doc.set(<String, dynamic>{
      'oauth_client_id': id.trim(),
      'oauth_client_secret': secret.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await signOut(); // the next upload signs in with the new client
  }

  /// Forget the Google account on this computer (the next upload asks again).
  static Future<void> signOut() async {
    _client?.close();
    _client = null;
    await GetStorage().remove(_credKey);
  }

  /// The sub-folder [name] of [rootId], made when missing. Empty name = the
  /// root (the "General" category).
  static Future<String> _folderFor(drive.DriveApi api, String rootId, String name) async {
    final String n = name.trim();
    if (n.isEmpty) return rootId;
    final String q = "'$rootId' in parents and mimeType = '$_folderMime' "
        "and name = '${n.replaceAll(r'\', r'\\').replaceAll("'", r"\'")}' and trashed = false";
    final drive.FileList found = await api.files.list(
      q: q,
      $fields: 'files(id,name)',
      supportsAllDrives: true,
      includeItemsFromAllDrives: true,
    );
    final List<drive.File> files = found.files ?? <drive.File>[];
    if (files.isNotEmpty && files.first.id != null) return files.first.id!;
    final drive.File made = await api.files.create(
      drive.File()
        ..name = n
        ..mimeType = _folderMime
        ..parents = <String>[rootId],
      $fields: 'id',
      supportsAllDrives: true,
    );
    return made.id!;
  }

  /// The file, read in pieces. [gate] runs before every piece: it waits
  /// while paused / offline and throws [DriveUploadCancelled] on cancel.
  static Stream<List<int>> _pieces(
    PlatformFile file,
    void Function(int bytes) onBytes,
    Future<void> Function() gate,
  ) async* {
    const int piece = 256 * 1024;
    final String? path = file.path;
    if (path != null) {
      final RandomAccessFile raf = await File(path).open();
      try {
        while (true) {
          await gate();
          final List<int> b = await raf.read(piece);
          if (b.isEmpty) break;
          onBytes(b.length);
          yield b;
        }
      } finally {
        await raf.close();
      }
    } else {
      final Uint8List all = file.bytes!;
      for (int i = 0; i < all.length; i += piece) {
        await gate();
        final List<int> b = all.sublist(i, i + piece > all.length ? all.length : i + piece);
        onBytes(b.length);
        yield b;
      }
    }
  }

  // ── Folders ──────────────────────────────────────────────────────────────

  static Future<(drive.DriveApi, String)> _api() async {
    final Map<String, dynamic> cfg = await _config();
    final String rootId = _str(cfg, 'folder_id');
    if (rootId.isEmpty) throw const DriveSetupMissing('folder');
    final AutoRefreshingAuthClient client = await _signedIn(cfg);
    return (drive.DriveApi(client), rootId);
  }

  static Future<List<drive.File>> _subFolders(drive.DriveApi api, String parentId) async {
    final List<drive.File> out = <drive.File>[];
    String? page;
    do {
      final drive.FileList l = await api.files.list(
        q: "'$parentId' in parents and mimeType = '$_folderMime' and trashed = false",
        $fields: 'nextPageToken,files(id,name)',
        pageSize: 200,
        pageToken: page,
        supportsAllDrives: true,
        includeItemsFromAllDrives: true,
      );
      out.addAll(l.files ?? <drive.File>[]);
      page = l.nextPageToken;
    } while (page != null);
    out.sort((drive.File a, drive.File b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()));
    return out;
  }

  /// The root, every course, and the sections inside each course — empty
  /// ones too (the app only shows a folder once it has a video).
  static Future<List<DriveFolder>> folders() async {
    final (drive.DriveApi api, String rootId) = await _api();
    final List<DriveFolder> out = <DriveFolder>[DriveFolder(id: rootId, name: '')];
    for (final drive.File c in await _subFolders(api, rootId)) {
      if (c.id == null) continue;
      out.add(DriveFolder(id: c.id!, name: c.name ?? ''));
      for (final drive.File sub in await _subFolders(api, c.id!)) {
        if (sub.id == null) continue;
        out.add(DriveFolder(id: sub.id!, name: sub.name ?? '', parentName: c.name ?? ''));
      }
    }
    return out;
  }

  /// A new folder [name]: a course, or a section inside the course
  /// [inCourse]. Returns its id (an existing folder of that name is reused).
  static Future<String> createFolder(String name, {String inCourse = ''}) async {
    final (drive.DriveApi api, String rootId) = await _api();
    final String parent =
        inCourse.trim().isEmpty ? rootId : await _folderFor(api, rootId, inCourse);
    debugPrint('🟡 [DriveUpload] new folder "$name" in ${inCourse.isEmpty ? 'root' : inCourse}');
    return _folderFor(api, parent, name);
  }

  /// Moves the Drive file [fileId] into [toFolderId]. The next sync moves the
  /// lesson to that category / sub-category in the app.
  static Future<void> moveFile(String fileId, String toFolderId) async {
    final (drive.DriveApi api, _) = await _api();
    final drive.File f = await api.files.get(
      fileId,
      $fields: 'parents',
      supportsAllDrives: true,
    ) as drive.File;
    final String remove = (f.parents ?? <String>[]).join(',');
    debugPrint('🟡 [DriveUpload] move $fileId → $toFolderId (from $remove)');
    await api.files.update(
      drive.File(),
      fileId,
      addParents: toFolderId,
      removeParents: remove.isEmpty ? null : remove,
      $fields: 'id,parents',
      supportsAllDrives: true,
    );
  }

  /// Uploads [file] into the folder's [category] sub-folder and returns the
  /// new Drive file id. [onBytes] gets each piece's size as it is sent.
  static Future<String> upload({
    required PlatformFile file,
    required String category,
    required String description,
    required String contentType,
    required void Function(int bytes) onBytes,
    required Future<void> Function() gate,
    String? folderId,
  }) async {
    final Map<String, dynamic> cfg = await _config();
    final String rootId = _str(cfg, 'folder_id');
    if (rootId.isEmpty) throw const DriveSetupMissing('folder');

    final AutoRefreshingAuthClient client = await _signedIn(cfg);
    final drive.DriveApi api = drive.DriveApi(client);
    // A folder picked from the tree wins; else the category's sub-folder.
    final String parent = folderId ?? await _folderFor(api, rootId, category);
    debugPrint('🟡 [DriveUpload] uploading ${file.name} → folder $parent');

    final drive.File created = await api.files.create(
      drive.File()
        ..name = file.name
        ..description = description.trim().isEmpty ? null : description.trim()
        ..parents = <String>[parent],
      uploadMedia: drive.Media(
        _pieces(file, onBytes, gate),
        file.size,
        contentType: contentType,
      ),
      uploadOptions: drive.ResumableUploadOptions(),
      $fields: 'id,name,size',
      supportsAllDrives: true,
    );
    debugPrint('🟡 [DriveUpload] done: ${created.id}');
    return created.id!;
  }
}
