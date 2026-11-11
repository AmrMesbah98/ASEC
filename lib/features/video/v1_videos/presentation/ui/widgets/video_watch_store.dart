/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_watch_store.dart
/// Purpose: Declares `VideoWatchStore` — where each lesson was left off and
///          how long it is, kept on this device (GetStorage). Feeds the red
///          progress bar and the duration badge on thumbnails, and the
///          player's "resume where you stopped".
/// Author: ASEC team
/// Created: 25/9/2026

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

import 'package:asec/core/constants/firebase_collections.dart';
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';

import 'package:asec/features/engagement/e1_engagement/presentation/controller/watch_sync.dart';
import 'package:asec/generated/l10n.dart';

abstract final class VideoWatchStore {
  const VideoWatchStore._();

  static final GetStorage _box = GetStorage();

  static String _posKey(String id) => 'video_pos_$id';
  static String _durKey(String id) => 'video_dur_$id';
  static String _doneKey(String id) => 'video_done_$id';

  static Duration? position(String id) {
    final int? s = _box.read<int>(_posKey(id));
    return s == null ? null : Duration(seconds: s);
  }

  static Duration? duration(String id) {
    final int? s = _box.read<int>(_durKey(id));
    return s == null || s <= 0 ? null : Duration(seconds: s);
  }

  static bool isWatched(String id) => _box.read<bool>(_doneKey(id)) ?? false;

  /// 0..1 — how far through the lesson this device got. 1 when finished.
  static double progress(String id) {
    if (isWatched(id)) return 1;
    final Duration? pos = position(id);
    final Duration? dur = duration(id);
    if (pos == null || dur == null || dur.inSeconds == 0) return 0;
    return (pos.inSeconds / dur.inSeconds).clamp(0.0, 1.0);
  }

  static String _maxKey(String id) => 'video_max_$id';

  /// The furthest point actually PLAYED (not jumped to). Seeking ahead of it
  /// is refused while the lesson is unfinished, and a lesson only counts as
  /// watched when this reaches the end.
  static Duration maxWatched(String id) =>
      Duration(seconds: _box.read<int>(_maxKey(id)) ?? 0);

  static void raiseMaxWatched(String id, Duration position) {
    if (position.inSeconds > maxWatched(id).inSeconds) {
      _box.write(_maxKey(id), position.inSeconds);
    }
  }

  // ── On the member's account too (ported from ENGX v1.0.57) ───────────────
  //
  // Progress lived only on this device, so after uninstalling / reinstalling
  // (or on another device) every lesson started from 0. Each lesson's resume
  // point, length, furthest point and done flag are also kept in
  // `progress/{uid}.watch` and merged back in when the Videos page opens.

  static String _atKey(String id) => 'video_at_$id';
  static final Set<String> _dirty = <String>{};
  static Timer? _cloudTimer;
  static String _pulledFor = '';

  static DocumentReference<Map<String, dynamic>>? _cloudDoc() {
    final AppUser me = SessionController.to.current;
    if (me.isEmpty || me.isAdmin) return null;
    return AppFirebase.db.collection(FirebaseCollections.progress).doc(me.uid);
  }

  static Map<String, int> _entry(String id) => <String, int>{
        'p': position(id)?.inSeconds ?? 0,
        'd': duration(id)?.inSeconds ?? 0,
        'm': maxWatched(id).inSeconds,
        'w': isWatched(id) ? 1 : 0,
        't': _box.read<int>(_atKey(id)) ?? 0,
      };

  /// Merges the account's progress into this device's, once per member per
  /// run (the newer resume point wins; the furthest point and "watched" are
  /// never lowered). Never throws.
  static Future<void> pullCloud() async {
    final DocumentReference<Map<String, dynamic>>? doc = _cloudDoc();
    if (doc == null || _pulledFor == doc.id) return;
    _pulledFor = doc.id;
    try {
      final DocumentSnapshot<Map<String, dynamic>> snap = await doc.get().timeout(const Duration(seconds: 10));
      final Object? raw = snap.data()?['watch'];
      if (raw is! Map) return;
      int n(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
      raw.forEach((Object? k, Object? v) {
        if (k is! String || v is! Map) return;
        final int at = n(v['t']);
        if (at > (_box.read<int>(_atKey(k)) ?? 0)) {
          if (n(v['d']) > 0) _box.write(_durKey(k), n(v['d']));
          if (n(v['p']) > 0) {
            _box.write(_posKey(k), n(v['p']));
          } else {
            _box.remove(_posKey(k));
          }
          _box.write(_atKey(k), at);
        }
        if (n(v['m']) > maxWatched(k).inSeconds) _box.write(_maxKey(k), n(v['m']));
        if (n(v['w']) == 1) _box.write(_doneKey(k), true);
      });
    } catch (_) {
      _pulledFor = ''; // offline: try again next time
    }
  }

  /// Sends the changed lessons to the account — at most every 20 s while a
  /// lesson plays, and at once when [flushCloud] is called (lesson closed).
  static void _queueCloud(String id) {
    _dirty.add(id);
    _cloudTimer ??= Timer(const Duration(seconds: 20), () => unawaited(flushCloud()));
  }

  static Future<void> flushCloud() async {
    _cloudTimer?.cancel();
    _cloudTimer = null;
    if (_dirty.isEmpty) return;
    final DocumentReference<Map<String, dynamic>>? doc = _cloudDoc();
    if (doc == null) return;
    final Map<String, Object> changed = <String, Object>{
      for (final String id in _dirty) id: _entry(id),
    };
    _dirty.clear();
    try {
      await doc.set(<String, dynamic>{
        'name': SessionController.to.current.displayName,
        'watch': changed,
        FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      _dirty.addAll(changed.keys); // try again with the next save
    }
  }

  static void save(String id, Duration position, Duration duration) {
    if (duration > Duration.zero) _box.write(_durKey(id), duration.inSeconds);
    final bool reachedEnd = duration > Duration.zero &&
        maxWatched(id) >= duration - const Duration(seconds: 3) &&
        position >= duration - const Duration(seconds: 2);
    if (reachedEnd) {
      _box.remove(_posKey(id));
      _box.write(_doneKey(id), true);
    } else {
      _box.write(_posKey(id), position.inSeconds);
    }
    _box.write(_atKey(id), DateTime.now().millisecondsSinceEpoch);
    _queueCloud(id);
    // Stars: every 20% watched is a point the admin can see.
    WatchSync.report(id, progress(id));
  }

  /// SEQUENTIAL UNLOCK. In a course ordered first-to-last, lesson N opens
  /// only once lesson N-1 is watched to the end. Returns the ids still
  /// locked.
  static Set<String> lockedIds(List<String> orderedIds) {
    final Set<String> locked = <String>{};
    for (int i = 1; i < orderedIds.length; i++) {
      if (!isWatched(orderedIds[i - 1])) {
        locked.addAll(orderedIds.sublist(i));
        break;
      }
    }
    return locked;
  }

  static void clearPosition(String id) => _box.remove(_posKey(id));
}

/// "04:32" / "1:02:10".
String videoClock(Duration d) {
  final String minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final String seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:$minutes:$seconds' : '$minutes:$seconds';
}

/// "8 Nov 2026 · 3:45 PM" — the exact day and time something was uploaded
/// or created, in the app's language (from Eduneers, 09/11/2026).
String videoDateTime(BuildContext context, DateTime? at) {
  if (at == null) return '';
  final String locale = Localizations.localeOf(context).languageCode;
  final DateTime t = at.toLocal();
  return '${DateFormat('d MMM yyyy', locale).format(t)} · '
      '${DateFormat('h:mm a', locale).format(t)}';
}

/// "3 days ago", the way a video site says it.
String videoTimeAgo(BuildContext context, DateTime? at) {
  if (at == null) return '';
  final S s = S.of(context);
  final Duration d = DateTime.now().difference(at);
  if (d.inMinutes < 1) return s.agoJustNow;
  if (d.inHours < 1) return s.agoMinutes(d.inMinutes);
  if (d.inDays < 1) return s.agoHours(d.inHours);
  if (d.inDays < 7) return s.agoDays(d.inDays);
  if (d.inDays < 30) return s.agoWeeks(d.inDays ~/ 7);
  if (d.inDays < 365) return s.agoMonths(d.inDays ~/ 30);
  return s.agoYears(d.inDays ~/ 365);
}
