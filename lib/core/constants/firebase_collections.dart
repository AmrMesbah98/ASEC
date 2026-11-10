/// Module: core/constants
///
///*************************** FILE INFO ****************************///
/// File Name: firebase_collections.dart
/// Purpose: Single source of truth for Firestore collection, field and Storage
///          folder names.
/// Author: ASEC team
/// Created: 19/9/2026
///
/// Never type a collection name at a call site. A name typed inline is a name
/// that eventually drifts — `quiz_attempts` in one screen and `attempts` in
/// another, and one of them quietly reads nothing.
///
/// Layout is FLAT and top-level:
///
///   users/{uid}                 every account (the one admin + the members)
///   videos/{id}                 a lesson video in Cloud Storage
///   quizzes/{id}                title, timer, window and the questions
///   attempts/{quizId}_{uid}     one member's answers and score for one quiz
///   notifications/{id}          texts the admin sends (the bell)
///   tips/{id}                   tips & tricks (home-page pop-up, saved_by[])
///   library/{id}                files in the member Library
///   course_files/{id}           folders + files inside a course
///   course_settings/{id}        per-course switches (watch in order)
///   progress/{uid}              a member's watch progress → stars

abstract final class FirebaseCollections {
  const FirebaseCollections._();

  // ── Collections ──────────────────────────────────────────────────────────
  static const String users = 'users';
  static const String videos = 'videos';
  static const String quizzes = 'quizzes';
  static const String attempts = 'attempts';

  /// `cvs/{uid}` — one CV per account, the document id IS the owner's uid.
  static const String cvs = 'cvs';

  /// `attempts/{quizId}_{uid}` — the id IS the pair, so one member can only
  /// ever hold one attempt per quiz and the rules can check ownership from
  /// the path alone.
  static String attemptId(String quizId, String uid) => '${quizId}_$uid';

  // ── Engagement (lib/features/engagement) ─────────────────────────────────
  /// `notifications/{id}` — texts the admin sends to every member (the bell).
  static const String notifications = 'notifications';

  /// `tips/{id}` — tips & tricks, popped up on the home page; `saved_by`
  /// holds the uids of the members who saved one.
  static const String tips = 'tips';

  /// `questions/{id}` — members ask, admins answer (home page Q&A).
  static const String questions = 'questions';

  /// `library/{id}` — files in the member library (home → Library).
  static const String library = 'library';

  /// `course_files/{id}` — folders and files inside a course ("Files" chip).
  static const String courseFiles = 'course_files';

  /// `course_settings/{id}` — per-course switches (watch in order or not).
  static const String courseSettings = 'course_settings';

  /// `video_catalog/{videoId}` — every published lesson's title and course,
  /// WITHOUT its file link. Every member reads it, so courses they were not
  /// given still show, locked. Kept in line with `videos` by the admin app
  /// (VideoCatalog.startAdminSync).
  static const String videoCatalog = 'video_catalog';

  /// `certificates/{course}_{uid}` — a certificate the admin issued to a
  /// member by hand (Members → Edit access → Certificates), no exam needed.
  static const String certificates = 'certificates';

  /// `progress/{uid}` — each member's watch progress per video (0..1),
  /// the source of the stars the admin and the leaderboard show.
  static const String progress = 'progress';

  /// On `videos/{id}`: true = a "default" video every member sees, whatever
  /// courses the admin opened for them. False / missing = "custom".
  static const String freeField = 'free';

  // ── Shared field names (only fields that are queried / ordered by) ───────
  static const String createdAtField = 'created_at';
  static const String updatedAtField = 'updated_at';
  static const String roleField = 'role';
  static const String activeField = 'active';
  static const String publishedField = 'published';

  /// On `users/{uid}`: the admin's switch that lets this member write a CV.
  static const String canCreateCvField = 'can_create_cv';

  /// The admin's switch: has this member bought the engineering calculators?
  static const String canUseCalcsField = 'can_use_calcs';
  static const String quizIdField = 'quiz_id';
  static const String userIdField = 'user_id';
  static const String submittedAtField = 'submitted_at';

  /// On EVERY document the demo-data button writes: `demo: true`.
  ///
  /// It is what makes "remove the demo data" a query instead of a list of ids
  /// somebody has to keep in sync — and what lets `firestore.rules` allow the
  /// admin to write a member's document only while it carries this flag, so
  /// the demo tool can never be turned into a way to forge a real record.
  static const String demoField = 'demo';

  // ── Storage folders ──────────────────────────────────────────────────────
  /// `videos/{adminUid}/{timestamp}_{fileName}`
  static const String storageVideos = 'videos';

  /// `cvs/{uid}/{timestamp}_{fileName}` — the CV photo.
  static const String storageCvs = 'cvs';

  /// `cvs/{uid}/doc/{timestamp}_{fileName}` — the CV document (PDF or Word).
  /// A segment of its own because the Storage rules accept only `image/*`
  /// directly under `cvs/{uid}/`.
  static const String storageCvDocs = 'doc';

  /// `files/{library|course}/{timestamp}_{fileName}` — library and course files.
  static const String storageFiles = 'files';
}
