/// Module: core/network
///
///*************************** FILE INFO ****************************///
/// File Name: app_firebase.dart
/// Purpose: Declares `AppFirebase` — one place that owns Firebase startup and
///          hands out the Firestore / Auth / Storage instances.
/// Author: Manger Plus team
/// Created: 18/9/2026 - Ported from wash_application; Storage and the
///          secondary "account factory" app added, Functions removed.

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:asec/firebase_options.dart';

/// Startup and access for everything Firebase.
///
/// Every data source goes through `AppFirebase.db` / `.auth` / `.storage`
/// rather than calling `FirebaseFirestore.instance` itself, so settings are
/// configured exactly once.
abstract final class AppFirebase {
  const AppFirebase._();

  static bool _ready = false;

  /// True when Firebase could not start at all. The UI shows a setup message
  /// instead of a spinner that never resolves.
  static bool notConfigured = false;

  /// Why it could not start, for the banner. Empty when all is well.
  static String startupError = '';

  static FirebaseFirestore get db => FirebaseFirestore.instance;
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;

  /// The signed-in uid, or null.
  static String? get uid => auth.currentUser?.uid;

  static bool get isReady => _ready;

  /// Call once from `main` before `runApp`. Never throws.
  static Future<void> initialize() async {
    if (_ready) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // AUTH BEFORE FIRESTORE. On Windows (and Linux) Firebase runs on the
      // C++ SDK, where Firestore only picks up the signed-in user's token if
      // the Auth instance already exists when Firestore is created. Touching
      // `db` first leaves every request unauthenticated (`request.auth ==
      // null`), so the rules refuse even a member reading their own profile.
      auth;

      // Bounded offline cache — a classroom tablet left on for a term should
      // not grow its cache without limit.
      db.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: 40 * 1024 * 1024,
      );

      _ready = true;
    } catch (error) {
      notConfigured = true;
      startupError = error.toString();
    }
  }

  // ── Account factory ──────────────────────────────────────────────────────
  //
  // The admin creates teacher, student and parent accounts from the console.
  // `createUserWithEmailAndPassword` on the DEFAULT auth instance would sign
  // the admin out and sign the new user in. So accounts are created on a
  // second, named Firebase app that shares the same project: the new user is
  // signed in THERE, the admin stays signed in here, and the secondary session
  // is thrown away straight after.
  //
  // This needs no Cloud Functions, so it works on the free Spark plan.

  static const String _factoryAppName = 'account-factory';

  static Future<FirebaseAuth> _factoryAuth() async {
    FirebaseApp app;
    try {
      app = Firebase.app(_factoryAppName);
    } catch (_) {
      app = await Firebase.initializeApp(
        name: _factoryAppName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    return FirebaseAuth.instanceFor(app: app);
  }

  /// Creates a Firebase Auth account without touching the current session.
  /// Returns the new uid. Throws [FirebaseAuthException] as usual.
  static Future<String> createAccount({
    required String email,
    required String password,
  }) async {
    final FirebaseAuth factory = await _factoryAuth();
    final UserCredential credential =
        await factory.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final String uid = credential.user!.uid;
    await factory.signOut();
    return uid;
  }

  /// Like [createAccount], but an email that already exists is signed in to
  /// (with the same password) instead of failing. Used by the demo-data
  /// button so pressing it twice reuses the demo accounts.
  static Future<String> createOrFindAccount({
    required String email,
    required String password,
  }) async {
    final FirebaseAuth factory = await _factoryAuth();
    UserCredential credential;
    try {
      credential = await factory.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      if (error.code != 'email-already-in-use') rethrow;
      credential = await factory.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    }
    final String uid = credential.user!.uid;
    await factory.signOut();
    return uid;
  }

  // ── Emulators ────────────────────────────────────────────────────────────

  /// Points the SDK at a locally running emulator suite. Android emulators
  /// reach the host on 10.0.2.2, everything else on localhost.
  static Future<void> useEmulators({
    int firestorePort = 8080,
    int authPort = 9099,
    int storagePort = 9199,
  }) async {
    final String host = _isAndroidDevice ? '10.0.2.2' : 'localhost';
    db.useFirestoreEmulator(host, firestorePort);
    await auth.useAuthEmulator(host, authPort);
    await storage.useStorageEmulator(host, storagePort);
  }

  static bool get _isAndroidDevice {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  static CollectionReference<Map<String, dynamic>> collection(String name) =>
      db.collection(name);

  /// Server timestamp helper, so no data source has to import FieldValue.
  static FieldValue get now => FieldValue.serverTimestamp();
}
