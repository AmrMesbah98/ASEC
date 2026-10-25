/// Every Firestore / Storage call the website and the panel make.
///
/// Collections are FLAT and prefixed `site_` so they never collide with the
/// ASEC app's own (`users`, `videos`, `quizzes`, …):
///
///   site_settings/main            one document: texts, contact, switches
///   site_services/{id}            تصميم متكامل، لوحات تنفيذية، …
///   site_features/{id}            مميزات العمل معنا
///   site_projects/{id}            أعمالنا
///   site_articles/{id}            المقالات (imported from WordPress: wp_{id})
///   site_partners/{id}            شركاء النجاح
///   site_testimonials/{id}        أراء العملاء
///   site_messages/{id}            contact form            (public create)
///   site_service_requests/{id}    طلب خدمة                 (public create)
///   site_job_applications/{id}    طلب وظيفة                (public create)
///
/// And from the ASEC app, used by the control centre:
///   settings/app                  the app's on/off switches
///   users/{uid}                   admins (the `website` permission)
///
/// Every public query filters on ONE field (`published == true`) and sorts
/// on the client, so no composite index is needed — same rule as the app.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:asec/features/web/core/doc.dart';
import 'package:asec/features/web/core/seed_english.dart';

abstract final class Coll {
  static const String settings = 'site_settings';
  static const String services = 'site_services';
  static const String features = 'site_features';
  static const String projects = 'site_projects';
  static const String articles = 'site_articles';
  static const String partners = 'site_partners';
  static const String testimonials = 'site_testimonials';
  static const String messages = 'site_messages';
  static const String serviceRequests = 'site_service_requests';
  static const String jobApplications = 'site_job_applications';

  // ASEC app
  static const String appSettings = 'settings';
  static const String users = 'users';
}

enum SortBy { order, newest }

abstract final class SiteRepo {
  static FirebaseFirestore get db => FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> get settingsDoc =>
      db.collection(Coll.settings).doc('main');

  static DocumentReference<Map<String, dynamic>> get appSettingsDoc =>
      db.collection(Coll.appSettings).doc('app');

  // ── Reading ─────────────────────────────────────────────────────────────

  static List<Doc> sort(List<Doc> docs, SortBy by) {
    final List<Doc> out = List<Doc>.of(docs);
    switch (by) {
      case SortBy.order:
        out.sort((Doc a, Doc b) => a.i('order', 9999).compareTo(b.i('order', 9999)));
      case SortBy.newest:
        DateTime when(Doc d) =>
            d.t('published_at') ?? d.t('created_at') ?? DateTime.fromMillisecondsSinceEpoch(0);
        out.sort((Doc a, Doc b) => when(b).compareTo(when(a)));
    }
    return out;
  }

  /// What the public site shows.
  ///
  /// PERFORMANCE: one live query per collection for the whole visit, not
  /// one per rebuild. The SAME stream object comes back every call, so a
  /// StreamBuilder never re-subscribes (and never flashes its spinner) when
  /// its page rebuilds; a new listener gets the latest list at once, so going
  /// back to a page is instant.
  static Stream<List<Doc>> published(String coll, {SortBy by = SortBy.order}) =>
      _live.putIfAbsent('$coll|${by.name}', () {
        return _LiveList(db
            .collection(coll)
            .where('published', isEqualTo: true)
            .snapshots()
            .map((QuerySnapshot<Map<String, dynamic>> q) => sort(q.docs.map(Doc.of).toList(), by)));
      }).stream;

  static final Map<String, _LiveList> _live = <String, _LiveList>{};

  /// Everything, for the panel.
  static Stream<List<Doc>> all(String coll, {SortBy by = SortBy.order}) => db
      .collection(coll)
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> q) => sort(q.docs.map(Doc.of).toList(), by));

  static Stream<Doc?> one(String coll, String id) => db
      .collection(coll)
      .doc(id)
      .snapshots()
      .map((DocumentSnapshot<Map<String, dynamic>> s) => s.exists ? Doc.of(s) : null);

  // ── Writing (panel) ─────────────────────────────────────────────────────

  static Future<String> save(String coll, String? id, Map<String, dynamic> data) async {
    final Map<String, dynamic> body = <String, dynamic>{
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (id == null || id.isEmpty) {
      body['created_at'] = FieldValue.serverTimestamp();
      final DocumentReference<Map<String, dynamic>> ref = await db.collection(coll).add(body);
      return ref.id;
    }
    await db.collection(coll).doc(id).set(body, SetOptions(merge: true));
    return id;
  }

  static Future<void> patch(String coll, String id, Map<String, dynamic> data) =>
      db.collection(coll).doc(id).update(<String, dynamic>{
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      });

  static Future<void> remove(String coll, String id) => db.collection(coll).doc(id).delete();

  // ── Public forms ────────────────────────────────────────────────────────

  /// Contact form, service request, job application. The rules accept only
  /// `status: 'new'` and a server `created_at`, and nobody but an admin can
  /// read them back.
  static Future<void> submit(String coll, Map<String, dynamic> data) =>
      db.collection(coll).add(<String, dynamic>{
        ...data,
        'status': 'new',
        'created_at': FieldValue.serverTimestamp(),
      });

  /// Where service requests are e-mailed. firestore.rules (`mail`) allows
  /// this address only, so the form cannot be used to mail anybody else.
  static const String requestsEmail = 'info@asecbim.com';

  /// Queues an e-mail of a service request to [requestsEmail] in `mail`,
  /// the collection the "Trigger Email from Firestore" extension sends.
  static Future<void> mailServiceRequest(Map<String, dynamic> d) {
    String esc(Object? v) => '${v ?? ''}'
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    final List<(String, Object?)> rows = <(String, Object?)>[
      ('Client name / اسم العميل', d['client_name']),
      ('Company / الشركة', d['company']),
      ('Phone / الهاتف', d['phone']),
      ('E-mail / البريد', d['email']),
      ('Project / المشروع', d['project_name']),
      ('Project type / نوع المشروع', d['project_type']),
      ('Services / الخدمات', (d['services'] as List<dynamic>? ?? const <dynamic>[]).join('، ')),
      ('Floors / الطوابق', d['floors']),
      ('Land area / المساحة', d['land_area']),
      ('Location / المكان', d['location']),
      ('Files / الملفات', d['files_link']),
    ];
    final StringBuffer table = StringBuffer();
    for (final (String label, Object? value) in rows) {
      table
        ..write('<tr><td style="border:1px solid #ddd"><b>')
        ..write(esc(label))
        ..write('</b></td><td style="border:1px solid #ddd">')
        ..write(esc(value))
        ..write('</td></tr>');
    }
    final String html = '<div dir="auto" style="font-family:Arial,sans-serif">'
        '<h2>New service request — طلب خدمة جديد</h2>'
        '<table cellpadding="6" style="border-collapse:collapse">$table</table></div>';
    final String client = (d['client_name'] ?? '').toString().trim();
    final String replyTo = (d['email'] ?? '').toString().trim();
    return db.collection('mail').add(<String, dynamic>{
      'to': <String>[requestsEmail],
      if (replyTo.isNotEmpty) 'replyTo': replyTo,
      'message': <String, dynamic>{
        'subject': 'طلب خدمة جديد — New service request${client.isEmpty ? '' : ' · $client'}',
        'html': html,
      },
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // ── Storage ─────────────────────────────────────────────────────────────

  /// `site/{folder}/{timestamp}_{name}` — public read, admins write.
  static Future<String> uploadImage({
    required String folder,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final String safe = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final String ext = safe.contains('.') ? safe.split('.').last.toLowerCase() : 'jpg';
    final String type = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'svg' => 'image/svg+xml',
      _ => 'image/jpeg',
    };
    final Reference ref = FirebaseStorage.instance
        .ref('site/$folder/${DateTime.now().millisecondsSinceEpoch}_$safe');
    await ref.putData(bytes, SettableMetadata(contentType: type));
    return ref.getDownloadURL();
  }
}

/// `site_settings/main`, read once and kept live for every page.
class SiteSettings extends ValueNotifier<Doc> {
  SiteSettings._() : super(Doc.empty) {
    // The English of the starter content, for fields not translated yet.
    SeedEnglish.load();
    _sub = SiteRepo.settingsDoc.snapshots().listen(
      (DocumentSnapshot<Map<String, dynamic>> s) {
        value = Doc('main', s.data() ?? <String, dynamic>{});
        loaded = true;
        notifyListeners();
      },
      onError: (Object _) {
        loaded = true;
        notifyListeners();
      },
    );
  }

  static final SiteSettings instance = SiteSettings._();

  bool loaded = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// A shared live query: subscribes once, remembers the latest value, and
/// hands every listener that value straight away, then the updates.
class _LiveList {
  _LiveList(Stream<List<Doc>> source) {
    stream = Stream<List<Doc>>.multi((MultiStreamController<List<Doc>> c) {
      final List<Doc>? now = _latest;
      if (now != null) c.add(now);
      if (now == null && _error != null) c.addError(_error!);
      final StreamSubscription<List<Doc>> sub = _updates.stream.listen(c.add, onError: c.addError);
      c.onCancel = sub.cancel;
    }, isBroadcast: true);
    source.listen(
      (List<Doc> v) {
        _latest = v;
        _updates.add(v);
      },
      onError: (Object e) {
        _error = e;
        _updates.addError(e);
      },
    );
  }

  final StreamController<List<Doc>> _updates = StreamController<List<Doc>>.broadcast();
  List<Doc>? _latest;
  Object? _error;
  late final Stream<List<Doc>> stream;
}
