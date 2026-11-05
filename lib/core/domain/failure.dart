import 'package:equatable/equatable.dart';

/// Expected failures, mapped from implementation errors at repository
/// boundaries. Presentation turns these into user-facing copy; [cause] is
/// for logs only and must never be shown to users.
sealed class Failure extends Equatable {
  const Failure({this.cause});

  final Object? cause;

  @override
  List<Object?> get props => [runtimeType];
}

/// No connectivity or the backend could not be reached.
final class NetworkFailure extends Failure {
  const NetworkFailure({super.cause});
}

/// Reading or writing the on-device store failed.
final class StorageFailure extends Failure {
  const StorageFailure({super.cause});
}

/// The signed-in user may not perform this operation.
final class PermissionFailure extends Failure {
  const PermissionFailure({super.cause});
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure({super.cause});
}

/// Input violated a business rule. [reason] is a stable machine-readable key.
final class ValidationFailure extends Failure {
  const ValidationFailure(this.reason, {super.cause});

  final String reason;

  @override
  List<Object?> get props => [runtimeType, reason];
}

/// Anything we did not anticipate. Always logged.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.cause});
}
