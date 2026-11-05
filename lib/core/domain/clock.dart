/// Source of the current time. Inject this instead of calling
/// `DateTime.now()` so date-dependent rules stay deterministic in tests.
abstract interface class Clock {
  DateTime now();
}

final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// A clock frozen at a fixed instant, advanced manually. For tests.
final class FixedClock implements Clock {
  FixedClock(this._now);

  DateTime _now;

  void advance(Duration by) => _now = _now.add(by);

  @override
  DateTime now() => _now;
}
