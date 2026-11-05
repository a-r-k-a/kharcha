/// Creates unique record identifiers. Inject it so tests get stable ids.
abstract interface class IdGenerator {
  String next();
}

/// Deterministic ids (`prefix-1`, `prefix-2`, …). For tests.
final class SequentialIdGenerator implements IdGenerator {
  SequentialIdGenerator([this.prefix = 'id']);

  final String prefix;
  int _count = 0;

  @override
  String next() => '$prefix-${++_count}';
}
