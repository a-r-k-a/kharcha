import 'dart:async';

import 'package:bloc/bloc.dart';

/// Waits for [duration] of quiet before handling the latest event; earlier
/// events in the burst are dropped. For search-as-you-type.
EventTransformer<E> debounce<E>(Duration duration) {
  return (events, mapper) =>
      events.transform(_Debounce<E>(duration)).asyncExpand(mapper);
}

final class _Debounce<E> extends StreamTransformerBase<E, E> {
  const _Debounce(this.duration);

  final Duration duration;

  @override
  Stream<E> bind(Stream<E> stream) {
    return Stream.multi((controller) {
      Timer? timer;
      final subscription = stream.listen(
        (event) {
          timer?.cancel();
          timer = Timer(duration, () => controller.add(event));
        },
        onError: controller.addError,
        onDone: () {
          timer?.cancel();
          controller.close();
        },
      );
      controller.onCancel = () {
        timer?.cancel();
        return subscription.cancel();
      };
    });
  }
}
