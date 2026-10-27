/// Module: core/network
///
///*************************** FILE INFO ****************************///
/// File Name: cold_start_retry.dart
/// Purpose: `retryingSnapshots` — a Firestore stream that survives the cold
///          start. On the first launch a query can fire a moment before
///          Firebase has confirmed the sign-in; Firestore answers that one
///          query with 'permission-denied' and STOPS the listener for good
///          (it never retries itself), so the page stays broken until the app
///          is restarted. This re-subscribes a transient refusal a few times,
///          with a growing delay, before giving up — so a cold start heals
///          itself. A real block (expired / paused account) still surfaces
///          after the retries.
/// Author: ASEC team
/// Created: 26/10/2026

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Wraps [build] (a function that starts the snapshot stream) so a transient
/// Firestore error re-subscribes instead of ending the stream.
Stream<T> retryingSnapshots<T>(
  Stream<T> Function() build, {
  int maxRetries = 6,
}) {
  late StreamController<T> out;
  StreamSubscription<T>? sub;
  Timer? timer;
  int retries = 0;

  void listen() {
    sub = build().listen(
      (T value) {
        retries = 0; // a good answer: the session is ready.
        if (!out.isClosed) out.add(value);
      },
      onError: (Object e, StackTrace st) {
        if (out.isClosed) return;
        final bool transient = e is FirebaseException &&
            (e.code == 'permission-denied' ||
                e.code == 'unavailable' ||
                e.code == 'deadline-exceeded');
        if (transient && retries < maxRetries) {
          retries++;
          sub?.cancel();
          timer?.cancel();
          timer = Timer(Duration(milliseconds: 300 * retries), () {
            if (!out.isClosed) listen();
          });
          return;
        }
        out.addError(e, st);
      },
    );
  }

  out = StreamController<T>(
    onListen: listen,
    onCancel: () {
      timer?.cancel();
      return sub?.cancel();
    },
  );
  return out.stream;
}
