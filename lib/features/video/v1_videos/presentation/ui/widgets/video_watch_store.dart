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

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

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
