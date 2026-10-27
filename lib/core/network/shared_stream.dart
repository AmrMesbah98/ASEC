/// Module: core/network
///
///*************************** FILE INFO ****************************///
/// File Name: shared_stream.dart
/// Purpose: Declares `shared()` — a Firestore stream that MANY widgets may
///          listen to, as often as they like.
///
///          `snapshots()` is a single-subscription stream. Pages keep one in
///          a `late final` field so it is not re-created on every build, but
///          then the SECOND StreamBuilder on it — two cards on the same
///          live document, or the same card rebuilt after a wide/narrow
///          layout switch (tablet rotation) — crashed with
///          "Bad state: Stream has already been listened to."
///
///          `shared(() => query.snapshots())` listens to Firestore ONCE while
///          anybody is listening, hands every listener the latest value at
///          once (so a re-mounted card does not flash a spinner), and lets
///          go of Firestore when the last listener leaves. The next listener
///          starts a fresh Firestore stream from the same builder.
/// Author: ASEC team
/// Created: 27/10/2026
library;

import 'dart:async';

/// A stream from [build] that any number of listeners may use, any number
/// of times. See the file comment.
Stream<T> shared<T>(Stream<T> Function() build) => _Shared<T>(build).stream;

class _Shared<T> {
  _Shared(this._build);

  final Stream<T> Function() _build;
  final Set<MultiStreamController<T>> _listeners = <MultiStreamController<T>>{};
  StreamSubscription<T>? _upstream;

  bool _hasValue = false;
  T? _last;
  Object? _error;
  StackTrace? _errorTrace;

  late final Stream<T> stream = Stream<T>.multi((MultiStreamController<T> c) {
    // The latest answer first, so the new listener has data at once.
    if (_hasValue) {
      c.add(_last as T);
    } else if (_error != null) {
      c.addError(_error!, _errorTrace);
    }
    _listeners.add(c);
    _upstream ??= _build().listen(
      (T value) {
        _hasValue = true;
        _last = value;
        _error = null;
        for (final MultiStreamController<T> l in _listeners.toList()) {
          l.add(value);
        }
      },
      onError: (Object e, StackTrace st) {
        _error = e;
        _errorTrace = st;
        for (final MultiStreamController<T> l in _listeners.toList()) {
          l.addError(e, st);
        }
      },
      onDone: () {
        _upstream = null;
        for (final MultiStreamController<T> l in _listeners.toList()) {
          l.close();
        }
        _listeners.clear();
      },
    );
    c.onCancel = () {
      _listeners.remove(c);
      if (_listeners.isEmpty) {
        final StreamSubscription<T>? up = _upstream;
        _upstream = null;
        _error = null; // a refusal is asked again next time
        return up?.cancel();
      }
      return null;
    };
  });
}
