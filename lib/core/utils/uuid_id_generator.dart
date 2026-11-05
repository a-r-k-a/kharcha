import 'package:uuid/uuid.dart';

import '../domain/id_generator.dart';

/// Random (v4) UUIDs.
final class UuidIdGenerator implements IdGenerator {
  const UuidIdGenerator();

  static const _uuid = Uuid();

  @override
  String next() => _uuid.v4();
}
