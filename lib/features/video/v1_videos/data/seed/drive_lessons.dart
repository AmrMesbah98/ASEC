/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: drive_lessons.dart
/// Purpose: Declares `DriveVideoSync` — the lessons come from ONE shared
///          Google Drive folder, automatically. No button: every time an
///          admin opens the app, the `videos` collection is brought in line
///          with the folder.
/// Author: ASEC team
/// Created: 30/9/2026
///
/// THE FOLDER
/// ----------
/// Its id is NOT in the app (anyone could pull it out of the app file):
/// it is read from Firestore `admin_config/drive` → `folder_id`, which only
/// admins with the Videos permission may read.
/// ("ASEC"). Every SUB-FOLDER of it is a CATEGORY (e.g. "GENERAL NOTES",
/// "Reals"): the app shows the categories first, then the videos of the one
/// opened. A folder INSIDE a category (e.g. AutoCAD → "Introduction-01",
/// "Draw and Modify-02") is a SUB-CATEGORY: the app shows those folders when
/// the category is opened, then the videos of the one opened. Folders nested
/// deeper still belong to their sub-category. Videos placed straight in ASEC
/// go to the "General" category.
/// Add a video to a folder → it appears in the app. Delete it from the
/// folder → it leaves the app. Add a folder → a new category. Files must be shared "Anyone with the link" (the folder
/// already is), or members cannot play them.
///
/// WHAT A SYNC DOES (AdminVideosPage.initState → DriveVideoSync.run)
/// ------------------------------------------------------------------
///  1. Lists the folder's videos with the Drive API (v3, the app's Firebase
///     API key). Needs the Google Drive API ENABLED in the Google Cloud
///     project asec-a811b — see SETUP below. Until it is, the sync falls back
///     to the ten videos known today ([DriveLessons.all]), so the app still
///     shows them.
///  2. For each video: document `drive_{fileId}`. A NEW one gets its title
///     and description from [DriveLessons] when we wrote one, else the
///     file's Drive description, else its file name. An EXISTING one keeps
///     whatever an admin edited (title, description, published) — only its
///     link, size and place in the order are refreshed.
///  3. Removes `drive_…` documents whose file left the folder (only when the
///     folder was really listed — never on the fallback).
///  4. Removes the old data: the demo sample videos (`demo_v_…`) and every
///     video added before the Drive folder took over (1 Oct 2026). Videos an
///     admin uploads after that are left alone.
///
/// ORDER
/// -----
/// By file name (T01, T02, …), with any name containing "final" last. The
/// app lists newest first, so each lesson's `created_at` is a fixed stamp one
/// minute older than the one before — lesson 1 on top, and the order stays
/// the same on every sync.
///
/// SETUP (once, for new files to appear by themselves)
/// ---------------------------------------------------
/// Google Cloud console → project asec-a811b → "APIs & Services" → Library →
/// "Google Drive API" → Enable. If the API key has "API restrictions", add
/// Google Drive API to its list.

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import 'package:asec/core/constants/firebase_collections.dart';
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/core/security/content_crypto.dart';
import 'package:asec/features/video/v1_videos/data/models/video_model.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/firebase_options.dart';

class DriveLesson {
  const DriveLesson({
    required this.hidden,
    required this.title,
    required this.description,
    required this.sizeBytes,
  });

  /// The Drive file id, hidden (ContentCrypto.reveal) so the app's code
  /// carries no readable Drive id.
  final String hidden;
  String get fileId => ContentCrypto.reveal(hidden);
  final String title;
  final String description;
  final int sizeBytes;

  String get shareUrl => 'https://drive.google.com/file/d/$fileId/view';
  String get docId => 'drive_$fileId';
}

/// Titles and descriptions written for the videos in the folder today, from
/// each video's own speech. A new file without an entry here uses its Drive
/// description / file name until an admin edits it in the app.
abstract final class DriveLessons {
  static const int _mb = 1024 * 1024;

  /// In lesson order.
  static const List<DriveLesson> all = <DriveLesson>[
    DriveLesson(
      hidden: '1GC511mQizj15ghmihbwnBG2z_S-yROKhdrehDemIASP', // T01
      title: 'لماذا نحتاج الهواء النقي؟ مدخل إلى التكييف والتهوية',
      description:
          'ما درجة الحرارة المريحة للإنسان؟ حوالي 24°م. لكن في غرفة مغلقة الشبابيك لا تكفي درجة الحرارة وحدها: '
          'نحن نسحب الأكسجين ونُخرج ثاني أكسيد الكربون، فتقل نسبة الأكسجين مع الوقت. '
          'لذلك يُعد إدخال الهواء النقي (Fresh Air) إلى المكان من أهم عوامل تصميم أنظمة التكييف.',
      sizeBytes: 57622971,
    ),
    DriveLesson(
      hidden: '1CSg0mewlzLX3yZEizWatBPm7uuP4yqTtOLemz_jG0us', // T02
      title: 'خطوات تصميم مجاري الهواء: من الأحمال إلى ضغط المروحة (ESP)',
      description:
          'كيف ترتبط خطوات التصميم ببعضها: حساب الأحمال ← كمية الهواء (CFM) ← اختيار المخارج ومعرفة الـ Pressure Drop '
          'لكل منها ← تصميم الصاج بطريقة الفقد المتساوي في الضغط (Equal Friction Method) ← وصف المروحة بالـ CFM والـ ESP '
          '← عزل الصاج ← حساب وزنه. دورة متصلة؛ إذا فاتتك خطوة منها ستتعثر في الباقي.',
      sizeBytes: 66 * _mb + 410 * 1024,
    ),
    DriveLesson(
      hidden: '1HDI0WeemQ__vS5a1T_JrSm1kq6syjCjr-Lv_imTBTen', // T03
      title: 'رسم مجاري الهواء: ضبط المقاسات والمسلوب (Transition)',
      description:
          'تطبيق عملي على برنامج الرسم: إدخال مقاس المجرى بالملّيمتر وتحويل البوصة (20 بوصة = 500 مم، 12 بوصة = 300 مم)، '
          'ثم تعديل الأبعاد بـ Modify Dimension، وعمل المسلوب من ناحية واحدة أو من الناحيتين، '
          'واختيار محاذاته من أعلى أو من المنتصف أو من أسفل.',
      sizeBytes: 14 * _mb,
    ),
    DriveLesson(
      hidden: '1EfGtEmToSjn6w146FvlijaPwoCh6U2bpsrsqxehYQ6R', // T04
      title: 'سوق المقاولات والـ MEP: لماذا الآن وقت الفرص؟',
      description:
          'الفرق بين الركود والموت في سوق العمل، ولماذا يعيش مجال الـ MEP والمقاولات الآن مرحلة ازدهار (Booming): '
          'مشروعات رأس الحكمة والعاصمة الإدارية والعلمين وتجديد المستشفيات في مصر، ونيوم والقدية واستعدادات كأس العالم في السعودية، '
          'وإعادة الإعمار في ليبيا والعراق والسودان.',
      sizeBytes: 31 * _mb + 922 * 1024,
    ),
    DriveLesson(
      hidden: '1EXb0gCnuCjn-iwJ5UL6p2nm_7-AwAaP1dv-h2KZJgvU', // T05
      title: 'قائمة Visibility/Graphics في Revit',
      description:
          'القائمة المسؤولة عن إظهار وإخفاء عناصر الرسم. Model Categories: كل ما يُرسم مثل الدكت والحوائط والشبابيك والمعدات '
          'والـ Flex Pipe والأجهزة الصحية والـ Cable Tray. Annotation Categories: كل ما يُكتب مثل الـ Tags والنصوص، '
          'وكذلك الـ Levels والـ Sections — أزل العلامة من أمام أي بند فيختفي من المنظور.',
      sizeBytes: 9 * _mb + 512 * 1024,
    ),
    DriveLesson(
      hidden: '1FPH61mymzjwsTpg9CyWiAG4xKC93iTZt9neiwLsJwiJ', // T06
      title: 'اختيار مضخة الحريق: قراءة منحنى الأداء',
      description:
          'مضخة كهرباء أو ديزل مطلوب منها 500 GPM عند 9 بار: هل يكفي أن تحقق نقطة التشغيل؟ لا. '
          'من شروط قبولها أن تنظر إلى منحنى المضخة عند 150% من التصرف (750 GPM) فلا يقل الضغط (Head) عن 65% من المطلوب. '
          'شرح عملي لكيفية التحقق من هذا الشرط على المنحنى.',
      sizeBytes: 68 * _mb + 102 * 1024,
    ),
    DriveLesson(
      hidden: '1CT991OgnBPm-Dx1jBjiqACpyo6riRLQrsvPoxW8KT6z', // T07
      title: 'تشخيص وحدة تكييف: انسداد الملف (Coil) من فرق الضغط',
      description:
          'حالة حقيقية: الوحدة تعطي حوالي 62% فقط من كمية الهواء المطلوبة، بينما السرعة (RPM) والتيار (الأمبير) مضبوطان. '
          'فرق الضغط على الملف (ΔP) مرتفع جدًا، والسبب ملف مسدود بالأتربة بعد خمس إلى سبع سنوات تشغيل، '
          'والحل تنظيفه أو تغييره. ومن العلامات: تفريغ عالٍ في قسم السحب وباب وحدة يصعب فتحه.',
      sizeBytes: 77 * _mb + 410 * 1024,
    ),
    DriveLesson(
      hidden: '1E6guEGvhg365jx60xzZpyzv77WU9SbVsaLipTiPNwmT', // T08
      title: 'السيكرومتري: إعادة التسخين للوصول إلى خط Room Sensible Heat',
      description:
          'على الخريطة السيكرومترية: المروحة وحدها ترفع حرارة الهواء درجة أو درجة ونصف فقط، وهذا لا يكفي. '
          'نضيف سخانًا حتى تقع حرارة هواء الإمداد على خط الـ Room Sensible Heat، فيشيل الهواء الحمل المحسوس والكامن للغرفة كما هو مطلوب، '
          'مع شرح ما يحدث لو أُرسل الهواء بميل مختلف عن هذا الخط.',
      sizeBytes: 63 * _mb,
    ),
    DriveLesson(
      hidden: '1EPg-HunpD_O3yhUyQTPthOxk5ig0jCoovLnljqmaSaM', // T09
      title: 'المكتب الفني: أقسامه ودوره في المشروع',
      description:
          'المكتب الفني هو "مايسترو" المشروع. ينقسم إلى جزء الدراسات وجزء التنفيذ: دراسة العقود ومستندات المشروع، '
          'والتسعير، والرسومات (Shop Drawings وAs-Built)، ومتابعة أعمال التنفيذ في الموقع — وكيف يختلف دوره عن مهندس الموقع. '
          'لكل مهندس يريد العمل في المكتب الفني.',
      sizeBytes: 87 * _mb + 819 * 1024,
    ),
    DriveLesson(
      hidden: '1H296mHOhyTusExxkDruqnyI75KQ3gvXs-aZlSbhaQqW', // FINAL TOPICS
      title: 'الملخص الكامل: كل الموضوعات في فيديو واحد',
      description:
          'الدروس التسعة متتالية في فيديو واحد (حوالي 10 دقائق): الهواء النقي، تصميم مجاري الهواء والـ ESP، رسم الدكت والمسلوب، '
          'سوق المقاولات والـ MEP، قائمة Visibility/Graphics في Revit، مضخة الحريق، تشخيص انسداد الملف، '
          'إعادة التسخين على الخريطة السيكرومترية، وأقسام المكتب الفني.',
      sizeBytes: 522 * _mb + 717 * 1024,
    ),
  ];

  static DriveLesson? byId(String fileId) {
    for (final DriveLesson l in all) {
      if (l.fileId == fileId) return l;
    }
    return null;
  }
}

/// One video file in the Drive folder.
class _DriveFile {
  const _DriveFile(
    this.id,
    this.name,
    this.description,
    this.size, {
    this.category = '',
    this.categoryOrder = 0,
    this.subcategory = '',
    this.subcategoryOrder = 0,
  });

  final String id;
  final String name;
  final String description;
  final int size;

  /// The top sub-folder's name ('' = straight in the root folder).
  final String category;
  final int categoryOrder;

  /// The sub-folder inside the category ('' = straight in the category).
  final String subcategory;
  final int subcategoryOrder;
}

/// One child of a Drive folder — a video or a sub-folder.
class _DriveEntry {
  const _DriveEntry(this.id, this.name, this.description, this.size, this.isFolder,
      [this.mimeType = '']);

  final String id;
  final String name;
  final String description;
  final int size;
  final bool isFolder;
  final String mimeType;

  bool get isVideo => mimeType.startsWith('video/');
}

abstract final class DriveVideoSync {
  /// The ASEC folder's id — from `admin_config/drive`, admins only.
  static Future<String?> _folderId() async {
    final DocumentSnapshot<Map<String, dynamic>> d = await AppFirebase.db
        .collection('admin_config')
        .doc('drive')
        .get();
    final Object? id = d.data()?['folder_id'];
    return id is String && id.trim().isNotEmpty ? id.trim() : null;
  }

  static const String _folderMime = 'application/vnd.google-apps.folder';

  /// Videos added before this belong to the old data and are removed once.
  static final DateTime _driveEra = DateTime(2026, 10, 1);

  /// Lesson 1's `created_at`; each later lesson is one minute older.
  static final DateTime _orderBase = DateTime(2026, 10, 1);

  static bool _running = false;

  /// Why some Drive folders / files do NOT show in the app, from the last
  /// listing: folders with no video inside (the app builds its sections from
  /// videos, so an empty folder has nothing to show), and files that are not
  /// videos (Drive does not see them as `video/*` — still uploading, a .zip,
  /// a shortcut, …).
  static final List<String> _emptyFolders = <String>[];
  static final List<String> _skippedFiles = <String>[];

  /// The last sync's report, for the admin. Null when everything showed.
  static String? lastReport;

  /// Safe to call often: one sync at a time, and documents are only written
  /// when something actually changed. Never throws — a failed sync leaves
  /// the videos as they were.
  ///
  /// Returns null when the folder was read, else why it could not be (shown
  /// to the admin, so a private folder or a blocked API key is visible
  /// instead of silently leaving the old lessons in place).
  static Future<String?> run({required String adminUid}) async {
    if (_running) return null;
    _running = true;
    String? problem;
    try {
      List<_DriveFile>? listed;
      _emptyFolders.clear();
      _skippedFiles.clear();
      try {
        listed = await _listFolder();
        if (listed.isEmpty) {
          // A private folder is not an error for the Drive API — it just
          // answers with no files.
          problem = 'Drive sync: no videos found in the ASEC folder. Share it '
              'as "Anyone with the link" (Viewer).';
        }
      } catch (e) {
        problem = 'Drive sync failed: $e';
      }
      if (problem == null && listed != null) {
        problem = _report();
        lastReport = problem;
      }
      final bool fromDrive = listed != null && listed.isNotEmpty;
      // Already in order: categories in folder order, lessons in each.
      final List<_DriveFile> files = fromDrive
          ? listed!
          : <_DriveFile>[
              // The catalogue is already in lesson order.
              for (final DriveLesson l in DriveLessons.all)
                _DriveFile(l.fileId, l.title, l.description, l.sizeBytes),
            ];

      final CollectionReference<Map<String, dynamic>> col =
          AppFirebase.db.collection(FirebaseCollections.videos);
      final QuerySnapshot<Map<String, dynamic>> current = await col.get();

      // THE FALLBACK ONLY SEEDS AN EMPTY APP. The built-in list has no
      // folders, so using it on a failed sync (no internet, Drive API
      // refused on that device) moved every lesson out of its course into
      // "General" and re-added lessons that had left the folder — the same
      // course showing twice. Once Drive has filled the app, a failed sync
      // changes nothing.
      if (!fromDrive &&
          current.docs.any((DocumentSnapshot<Map<String, dynamic>> d) =>
              d.id.startsWith('drive_'))) {
        return problem;
      }
      final Map<String, DocumentSnapshot<Map<String, dynamic>>> byId =
          <String, DocumentSnapshot<Map<String, dynamic>>>{
        for (final DocumentSnapshot<Map<String, dynamic>> d in current.docs) d.id: d,
      };

      WriteBatch batch = AppFirebase.db.batch();
      int pending = 0;
      Future<void> flushIfFull() async {
        if (pending < 400) return;
        await batch.commit();
        batch = AppFirebase.db.batch();
        pending = 0;
      }

      // 1–2. Add or refresh every video in the folder.
      final Set<String> keep = <String>{};
      for (int i = 0; i < files.length; i++) {
        final _DriveFile f = files[i];
        final String docId = 'drive_${f.id}';
        keep.add(docId);
        final String url = 'https://drive.google.com/file/d/${f.id}/view';
        final Timestamp order = Timestamp.fromDate(_orderBase.subtract(Duration(minutes: i)));
        final DocumentSnapshot<Map<String, dynamic>>? existing = byId[docId];

        if (existing == null) {
          final DriveLesson? known = DriveLessons.byId(f.id);
          final VideoItem video = VideoItem(
            id: docId,
            title: known?.title ?? _titleFromName(f.name),
            description: known?.description ?? f.description,
            url: url,
            sizeBytes: f.size,
            category: f.category,
            categoryOrder: f.categoryOrder,
            subcategory: f.subcategory,
            subcategoryOrder: f.subcategoryOrder,
            createdBy: adminUid,
          );
          batch.set(col.doc(docId), <String, dynamic>{
            ...VideoModel.toMap(video),
            _driveNameField: f.name,
            FirebaseCollections.createdAtField: order,
          });
          pending++;
        } else {
          final Map<String, dynamic> d = existing.data() ?? <String, dynamic>{};
          // THE TITLE FOLLOWS THE DRIVE NAME. A file renamed in Drive is
          // renamed in the app — unless an admin edited the title in the app
          // since (it no longer matches the old Drive name). Videos synced
          // before the name was kept take the Drive name once.
          final String? oldName = d[_driveNameField] as String?;
          final String title = '${d[VideoModel.title] ?? ''}';
          final bool renamed = fromDrive &&
              oldName != f.name &&
              (oldName == null || title == _titleFromName(oldName));
          final bool changed = renamed ||
              d[VideoModel.url] != url ||
              (f.size > 0 && d[VideoModel.sizeBytes] != f.size) ||
              d[FirebaseCollections.createdAtField] != order ||
              // The folder decides the category — moving a file to another
              // folder moves it to that category in the app.
              (d[VideoModel.category] ?? '') != f.category ||
              (d[VideoModel.categoryOrder] ?? 0) != f.categoryOrder ||
              (d[VideoModel.subcategory] ?? '') != f.subcategory ||
              (d[VideoModel.subcategoryOrder] ?? 0) != f.subcategoryOrder;
          if (changed) {
            batch.update(col.doc(docId), <String, dynamic>{
              if (renamed) VideoModel.title: _titleFromName(f.name),
              if (fromDrive) _driveNameField: f.name,
              VideoModel.url: url,
              VideoModel.category: f.category,
              VideoModel.categoryOrder: f.categoryOrder,
              VideoModel.subcategory: f.subcategory,
              VideoModel.subcategoryOrder: f.subcategoryOrder,
              if (f.size > 0) VideoModel.sizeBytes: f.size,
              FirebaseCollections.createdAtField: order,
              FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
            });
            pending++;
          }
        }
        await flushIfFull();
      }

      // 3–4. Remove what no longer belongs.
      final List<String> storageToDelete = <String>[];
      for (final DocumentSnapshot<Map<String, dynamic>> d in current.docs) {
        if (keep.contains(d.id)) continue;
        final Map<String, dynamic> data = d.data() ?? <String, dynamic>{};
        final bool goneFromFolder = fromDrive && d.id.startsWith('drive_');
        final bool demo = d.id.startsWith('demo_v_') || data[FirebaseCollections.demoField] == true;
        final Object? created = data[FirebaseCollections.createdAtField];
        final bool old = !d.id.startsWith('drive_') &&
            (created is! Timestamp || created.toDate().isBefore(_driveEra));
        if (goneFromFolder || demo || old) {
          batch.delete(d.reference);
          pending++;
          final String path = '${data[VideoModel.storagePath] ?? ''}';
          if (path.isNotEmpty) storageToDelete.add(path);
          await flushIfFull();
        }
      }
      if (pending > 0) await batch.commit();

      // The uploaded files behind removed videos, so the bucket does not
      // keep what nobody can reach any more.
      for (final String path in storageToDelete) {
        try {
          await AppFirebase.storage.ref(path).delete();
        } catch (_) {/* already gone */}
      }
    } catch (e) {
      problem ??= 'Drive sync failed: $e';
    } finally {
      _running = false;
    }
    return problem;
  }

  /// Every video under the root folder, in app order: the videos straight
  /// in the root first (category ''), then each sub-folder (a category) by
  /// name, its videos — including those of folders nested inside it — in
  /// lesson order.
  static Future<List<_DriveFile>> _listFolder() async {
    final String? folderId = await _folderId();
    if (folderId == null) {
      throw 'the Drive folder id is not set. In the Firebase console add the '
          'document admin_config/drive with a text field folder_id = the ASEC '
          'folder\'s id.';
    }
    final List<_DriveEntry> root = await _listChildren(folderId);
    final List<_DriveFile> out = <_DriveFile>[];

    _noteSkipped(root, 'ASEC');
    final List<_DriveFile> loose = <_DriveFile>[
      for (final _DriveEntry e in root)
        if (e.isVideo) _DriveFile(e.id, e.name, e.description, e.size),
    ]..sort(_lessonOrder);
    out.addAll(loose);

    final List<_DriveEntry> folders = root.where((_DriveEntry e) => e.isFolder).toList()
      ..sort((_DriveEntry a, _DriveEntry b) =>
          _natural(a.name.toLowerCase(), b.name.toLowerCase()));
    for (int c = 0; c < folders.length; c++) {
      final String category = folders[c].name.trim();
      final List<_DriveEntry> children = await _listChildren(folders[c].id);
      _noteSkipped(children, category);
      final int before = out.length;

      // Videos straight in the category folder: no sub-category.
      final List<_DriveFile> loose = <_DriveFile>[
        for (final _DriveEntry e in children)
          if (e.isVideo)
            _DriveFile(e.id, e.name, e.description, e.size,
                category: category, categoryOrder: c + 1),
      ]..sort(_lessonOrder);
      out.addAll(loose);

      // Each folder inside the category is a sub-category, in folder order
      // ("…-01", "…-02"); videos nested deeper stay in it.
      final List<_DriveEntry> subs = children.where((_DriveEntry e) => e.isFolder).toList()
        ..sort(_folderOrder);
      for (int k = 0; k < subs.length; k++) {
        final List<_DriveFile> videos = <_DriveFile>[];
        await _collectVideos(subs[k].id, videos, category, c + 1,
            subcategory: subs[k].name.trim(), subcategoryOrder: k + 1, depth: 1);
        if (videos.isEmpty) _emptyFolders.add('$category › ${subs[k].name.trim()}');
        videos.sort(_lessonOrder);
        out.addAll(videos);
      }
      if (out.length == before) _emptyFolders.add(category);
    }
    return out;
  }

  static void _noteSkipped(List<_DriveEntry> entries, String where) {
    for (final _DriveEntry e in entries) {
      if (!e.isFolder && !e.isVideo) {
        _skippedFiles.add('$where › ${e.name} (${e.mimeType})');
      }
    }
  }

  /// Null when every folder and file made it into the app.
  static String? _report() {
    if (_emptyFolders.isEmpty && _skippedFiles.isEmpty) return null;
    final StringBuffer b = StringBuffer();
    if (_emptyFolders.isNotEmpty) {
      b.writeln('Not shown — no video inside (or videos not shared '
          '"Anyone with the link"): ${_emptyFolders.join(', ')}');
    }
    if (_skippedFiles.isNotEmpty) {
      b.write('Skipped — not a video file for Drive (still processing?): '
          '${_skippedFiles.join(', ')}');
    }
    return b.toString().trim();
  }

  /// Folders by the number their name ends with ("Introduction-01" before
  /// "Draw and Modify-02"), else by name in natural order.
  static int _folderOrder(_DriveEntry a, _DriveEntry b) {
    final int? sa = folderNumber(a.name);
    final int? sb = folderNumber(b.name);
    if (sa != null && sb != null && sa != sb) return sa.compareTo(sb);
    return _natural(a.name.toLowerCase(), b.name.toLowerCase());
  }

  static Future<void> _collectVideos(
    String parentId,
    List<_DriveFile> into,
    String category,
    int categoryOrder, {
    required String subcategory,
    required int subcategoryOrder,
    required int depth,
  }) async {
    for (final _DriveEntry e in await _listChildren(parentId)) {
      if (e.isFolder) {
        if (depth < 4) {
          await _collectVideos(e.id, into, category, categoryOrder,
              subcategory: subcategory,
              subcategoryOrder: subcategoryOrder,
              depth: depth + 1);
        }
      } else if (!e.isVideo) {
        _skippedFiles.add('$subcategory › ${e.name} (${e.mimeType})');
      } else {
        into.add(_DriveFile(e.id, e.name, e.description, e.size,
            category: category,
            categoryOrder: categoryOrder,
            subcategory: subcategory,
            subcategoryOrder: subcategoryOrder));
      }
    }
  }

  /// The videos and sub-folders directly inside [parentId] (Drive API v3,
  /// public files, API key).
  static Future<List<_DriveEntry>> _listChildren(String parentId) async {
    final String key = DefaultFirebaseOptions.currentPlatform.apiKey;
    final List<_DriveEntry> out = <_DriveEntry>[];
    String? pageToken;
    do {
      final Uri uri = Uri.https('www.googleapis.com', '/drive/v3/files', <String, String>{
        // Every child, so files the app cannot play are reported, not just
        // silently missing. Non-video files are filtered out by the caller.
        'q': "'$parentId' in parents and trashed = false",
        'fields': 'nextPageToken,files(id,name,description,size,mimeType)',
        'pageSize': '1000',
        'supportsAllDrives': 'true',
        'includeItemsFromAllDrives': 'true',
        'key': key,
        if (pageToken != null) 'pageToken': pageToken,
      });
      final http.Response r = await http.get(uri).timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) {
        throw http.ClientException('Drive API ${r.statusCode}: ${r.body}', uri);
      }
      final Map<String, dynamic> body = jsonDecode(r.body) as Map<String, dynamic>;
      for (final Object? f in (body['files'] as List<dynamic>? ?? <dynamic>[])) {
        if (f is! Map) continue;
        out.add(_DriveEntry(
          '${f['id']}',
          '${f['name'] ?? ''}',
          '${f['description'] ?? ''}',
          int.tryParse('${f['size'] ?? ''}') ?? 0,
          f['mimeType'] == _folderMime,
          '${f['mimeType'] ?? ''}',
        ));
      }
      pageToken = body['nextPageToken'] as String?;
    } while (pageToken != null);
    return out;
  }

  /// A number the file name ends with — "Intro.mp4-00" → 0,
  /// "CAD v.s BIM.mp4-01" → 1 — which is the lesson's place in its folder.
  static final RegExp _trailingNumber = RegExp(r'[-_ ]\s*(\d+)\s*$');

  /// The lesson number a file name ends with, dots allowed:
  /// "Out Interface.mp4-1.1" → [1, 1], "Reset Setting to-1.10" → [1, 10].
  static final RegExp _trailingLesson = RegExp(r'[-_ ]\s*(\d+(?:\.\d+)*)\s*$');

  /// The original Drive file name, kept on the video document so a rename in
  /// Drive can be told apart from a title the admin edited in the app.
  static const String _driveNameField = 'drive_name';

  static List<int>? _lessonNumber(String name) {
    final Match? m = _trailingLesson.firstMatch(name.trim());
    if (m == null) return null;
    return m[1]!.split('.').map(int.parse).toList();
  }

  /// 1.2 before 1.10, 1.9 before 2.

  /// A folder's place: the number it STARTS with ("03-Annotation and
  /// Layout" → 3) or ENDS with ("Introduction-01" → 1). Both styles are
  /// used in Drive, so both must count, or "03-…" sorts after "Draw…-02".
  static final RegExp _leadingNumber = RegExp(r'^\s*(\d+)\s*[-_. )]');

  static int? folderNumber(String name) {
    final Match? m = _leadingNumber.firstMatch(name);
    if (m != null) return int.tryParse(m[1]!);
    return _sequence(name);
  }

  static int? _sequence(String name) {
    final Match? m = _trailingNumber.firstMatch(name.trim());
    return m == null ? null : int.tryParse(m[1]!);
  }

  /// Anything named "final…" last; then by the number the name ends with
  /// when both have one ("…-00", "…-01"); else by name in natural order
  /// (T2 before T10).
  static int _lessonOrder(_DriveFile a, _DriveFile b) {
    final bool fa = a.name.toLowerCase().contains('final');
    final bool fb = b.name.toLowerCase().contains('final');
    if (fa != fb) return fa ? 1 : -1;
    final List<int>? sa = _lessonNumber(a.name);
    final List<int>? sb = _lessonNumber(b.name);
    if (sa != null && sb != null) {
      for (int i = 0; i < sa.length && i < sb.length; i++) {
        if (sa[i] != sb[i]) return sa[i].compareTo(sb[i]);
      }
      if (sa.length != sb.length) return sa.length.compareTo(sb.length);
    }
    return _natural(a.name.toLowerCase(), b.name.toLowerCase());
  }

  static int _natural(String a, String b) {
    final RegExp part = RegExp(r'(\d+|\D+)');
    final List<String> pa = part.allMatches(a).map((Match m) => m[0]!).toList();
    final List<String> pb = part.allMatches(b).map((Match m) => m[0]!).toList();
    for (int i = 0; i < pa.length && i < pb.length; i++) {
      final int? na = int.tryParse(pa[i]);
      final int? nb = int.tryParse(pb[i]);
      final int c = (na != null && nb != null) ? na.compareTo(nb) : pa[i].compareTo(pb[i]);
      if (c != 0) return c;
    }
    return pa.length.compareTo(pb.length);
  }

  /// AS IN DRIVE: the file name without its extension, its lesson number
  /// moved to the front — "AutoCAD … Out Interface.mp4-1.1" →
  /// "1.1 AutoCAD … Out Interface". "T10.mp4" → "T10",
  /// "fire_pump-basics.mp4" → "fire pump basics".
  static String _titleFromName(String name) {
    final Match? number = _trailingLesson.firstMatch(name.trim());
    final String base = name
        .trim()
        .replaceFirst(_trailingLesson, '')
        .replaceAll(RegExp(r'\.(mp4|mov|m4v|mkv|webm|avi)\b', caseSensitive: false), '')
        .replaceFirst(RegExp(r'\.[A-Za-z0-9]{2,4}$'), '');
    final String clean = base.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
    if (clean.isEmpty) return name;
    return number == null ? clean : '${number[1]} $clean';
  }
}
