import 'dart:async';

Stream<R> combineLatest<A, B, R>(
  Stream<A> streamA,
  Stream<B> streamB,
  R Function(A a, B b) combiner,
) {
  late StreamController<R> controller;
  A? lastA;
  B? lastB;
  bool hasA = false;
  bool hasB = false;

  controller = StreamController<R>(
    onListen: () {
      streamA.listen((a) {
        lastA = a;
        hasA = true;
        if (hasB) {
          controller.add(combiner(lastA as A, lastB as B));
        }
      });
      streamB.listen((b) {
        lastB = b;
        hasB = true;
        if (hasA) {
          controller.add(combiner(lastA as A, lastB as B));
        }
      });
    },
  );

  return controller.stream;
}

StreamTransformer<T, (T?, T)> _pairwiseTransformer<T>() {
  T? previous;
  return StreamTransformer.fromHandlers(
    handleData: (current, sink) {
      if (previous != null) {
        sink.add((previous, current));
      }
      previous = current;
    },
  );
}

extension CombineLatestExtension<T> on Stream<T> {
  Stream<(T?, T)> pairwiseAndFirst() {
    return transform(_pairwiseTransformer<T>());
  }
}
