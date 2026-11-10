/// `shareLatest` (07/11/2026) — one stream that any number of StreamBuilders
/// may listen to, one after another or at once.
///
/// WHY. A page kept a stream in a field (`late final Stream … = watch…()`)
/// and gave it to a StreamBuilder. When the layout changed (window resized
/// between phone and desktop width, a section rebuilt), a NEW StreamBuilder
/// listened to the SAME stream — and a single-listener stream (an `async*`
/// function, a controller) throws "Bad state: Stream has already been
/// listened to" → red error box on Home.
///
/// HOW. The source is made from [create] when the first listener comes and
/// shared by every listener; a new listener gets the latest value at once.
/// When the last listener leaves, the source is cancelled; the next listener
/// starts a fresh one (so nothing keeps listening after the page is gone).
library;

import 'dart:async';

Stream<T> shareLatest<T>(Stream<T> Function() create) => _Shared<T>(create).stream;

class _Shared<T> {
  _Shared(this._create);

  final Stream<T> Function() _create;
  final List<MultiStreamController<T>> _listeners = <MultiStreamController<T>>[];
  StreamSubscription<T>? _sub;
  bool _hasValue = false;
  late T _value;

  Stream<T> get stream => Stream<T>.multi((MultiStreamController<T> c) {
        _listeners.add(c);
        if (_hasValue) c.add(_value);
        _sub ??= _create().listen(
          (T v) {
            _hasValue = true;
            _value = v;
            for (final MultiStreamController<T> l in List<MultiStreamController<T>>.of(_listeners)) {
              l.add(v);
            }
          },
          onError: (Object e, StackTrace st) {
            for (final MultiStreamController<T> l in List<MultiStreamController<T>>.of(_listeners)) {
              l.addError(e, st);
            }
          },
          onDone: () {
            _sub = null;
            for (final MultiStreamController<T> l in List<MultiStreamController<T>>.of(_listeners)) {
              l.close();
            }
            _listeners.clear();
          },
        );
        c.onCancel = () {
          _listeners.remove(c);
          if (_listeners.isEmpty) {
            final StreamSubscription<T>? s = _sub;
            _sub = null;
            _hasValue = false;
            return s?.cancel();
          }
          return null;
        };
      });
}
