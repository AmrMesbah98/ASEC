/// Module: engagement / e1_engagement
///
///*************************** FILE INFO ****************************///
/// File Name: engagement_entities.dart
/// Purpose: Declares the plain objects behind the admin's engagement tools:
///          `AppNotice` (a notification), `AppTip` (tips & tricks),
///          `LibraryFile` (a file in the member library), `CourseEntry`
///          (a folder or a file inside a course's "Files") and
///          `MemberProgress` (one member's watch progress, for stars).
/// Author: ASEC team
/// Created: 15/10/2026

/// A text the admin sends to every member — shown under the bell.
class AppNotice {
  const AppNotice({
    required this.id,
    required this.title,
    this.body = '',
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime? createdAt;
}

/// "Tips & tricks" — pops up as a layer on the home page; a member may save it.
class AppTip {
  const AppTip({
    required this.id,
    required this.title,
    this.body = '',
    this.active = true,
    this.savedBy = const <String>[],
    this.seenBy = const <String>[],
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;

  /// Off = kept for the record but no longer popped up.
  final bool active;

  /// The uids of the members who saved it — its length is the admin's count.
  final List<String> savedBy;

  /// The uids of the members it already popped up for — it never pops up
  /// for them again, on any device.
  final List<String> seenBy;
  final DateTime? createdAt;

  int get saveCount => savedBy.length;

  bool isSavedBy(String uid) => savedBy.contains(uid);

  bool isSeenBy(String uid) => seenBy.contains(uid);
}

/// One uploaded file: the member library, or a file inside a course folder.
class LibraryFile {
  const LibraryFile({
    required this.id,
    required this.title,
    this.url = '',
    this.storagePath = '',
    this.fileName = '',
    this.sizeBytes = 0,
    this.createdAt,
  });

  final String id;
  final String title;
  final String url;
  final String storagePath;
  final String fileName;
  final int sizeBytes;
  final DateTime? createdAt;

  /// "pdf", "docx", … — picks the icon.
  String get extension {
    final int dot = fileName.lastIndexOf('.');
    return dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
  }

  String get sizeLabel {
    if (sizeBytes <= 0) return '';
    final double kb = sizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  /// A copy with [url] swapped (a freshly signed address).
  LibraryFile withUrl(String url) => LibraryFile(
        id: id,
        title: title,
        url: url,
        storagePath: storagePath,
        fileName: fileName,
        sizeBytes: sizeBytes,
        createdAt: createdAt,
      );
}

enum CourseEntryKind { folder, file }

/// A folder, or a file inside a folder, in a course's "Files".
///
/// `course_files/{id}` — `course` is the video category name; a file
/// carries the id of its folder in [folderId].
class CourseEntry {
  const CourseEntry({
    required this.id,
    required this.course,
    required this.kind,
    required this.name,
    this.folderId = '',
    this.file,
    this.createdAt,
  });

  final String id;
  final String course;
  final CourseEntryKind kind;

  /// The folder's name, or the file's title.
  final String name;
  final String folderId;

  /// The file itself (kind == file).
  final LibraryFile? file;
  final DateTime? createdAt;

  bool get isFolder => kind == CourseEntryKind.folder;
}

/// `progress/{uid}` — how far a member got in each video (0..1), written by
/// their app so the admin and the leaderboard can see their stars.
class MemberProgress {
  const MemberProgress({
    required this.uid,
    this.name = '',
    this.videos = const <String, double>{},
    this.updatedAt,
  });

  final String uid;
  final String name;
  final Map<String, double> videos;
  final DateTime? updatedAt;

  double of(String videoId) => videos[videoId] ?? 0;
}

/// A member's question and the admin's answer (03/11/2026) — shown like a
/// post with its reply: on the home page (the 3 newest answered) and on the
/// Questions page. `questions/{id}`.
class AppQuestion {
  const AppQuestion({
    required this.id,
    required this.uid,
    required this.userName,
    required this.text,
    this.answer = '',
    this.answeredBy = '',
    this.createdAt,
    this.answeredAt,
  });

  final String id;

  /// Who asked.
  final String uid;
  final String userName;
  final String text;

  /// '' = still waiting for the admin.
  final String answer;
  final String answeredBy;
  final DateTime? createdAt;
  final DateTime? answeredAt;

  bool get answered => answer.trim().isNotEmpty;
}
