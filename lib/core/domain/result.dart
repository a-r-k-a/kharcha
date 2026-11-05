import 'failure.dart';

/// Outcome of an operation that can fail in an expected way.
///
/// Consume with an exhaustive `switch`:
/// ```dart
/// switch (await repository.load()) {
///   case Ok(:final value): ...
///   case Err(:final failure): ...
/// }
/// ```
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
