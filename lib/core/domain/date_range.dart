import 'package:equatable/equatable.dart';

/// A half-open span of local time, `[start, end)`.
final class DateRange extends Equatable {
  DateRange(this.start, this.end) {
    if (end.isBefore(start)) {
      throw ArgumentError('end ($end) is before start ($start)');
    }
  }

  /// The local calendar day containing [day].
  factory DateRange.day(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    return DateRange(start, DateTime(day.year, day.month, day.day + 1));
  }

  /// Inclusive local calendar days [first]..[last].
  factory DateRange.days(DateTime first, DateTime last) => DateRange(
    DateTime(first.year, first.month, first.day),
    DateTime(last.year, last.month, last.day + 1),
  );

  final DateTime start;
  final DateTime end;

  bool contains(DateTime instant) {
    final local = instant.toLocal();
    return !local.isBefore(start) && local.isBefore(end);
  }

  /// Calendar days covered, at least 1.
  int get dayCount {
    // Build from dates (not Duration) so DST shifts don't skew the count.
    final days = DateTime.utc(
      end.year,
      end.month,
      end.day,
    ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
    return days < 1 ? 1 : days;
  }

  /// The last day included in the range.
  DateTime get lastDay => DateTime(end.year, end.month, end.day - 1);

  @override
  List<Object?> get props => [start, end];

  @override
  String toString() => 'DateRange($start – $end)';
}

/// Reporting periods offered across the app.
enum PeriodKind { day, week, month, year }

/// A calendar period anchored on a day: weeks start on Monday (ISO 8601).
final class Period extends Equatable {
  const Period(this.kind, this.anchor);

  final PeriodKind kind;

  /// Any instant inside the period.
  final DateTime anchor;

  DateRange get range {
    final a = anchor.toLocal();
    return switch (kind) {
      PeriodKind.day => DateRange.day(a),
      PeriodKind.week => () {
        final monday = DateTime(a.year, a.month, a.day - (a.weekday - 1));
        return DateRange(
          monday,
          DateTime(monday.year, monday.month, monday.day + 7),
        );
      }(),
      PeriodKind.month => DateRange(
        DateTime(a.year, a.month),
        DateTime(a.year, a.month + 1),
      ),
      PeriodKind.year => DateRange(DateTime(a.year), DateTime(a.year + 1)),
    };
  }

  /// The period immediately before this one, of the same kind.
  Period get previous {
    final start = range.start;
    return Period(kind, switch (kind) {
      PeriodKind.day => DateTime(start.year, start.month, start.day - 1),
      PeriodKind.week => DateTime(start.year, start.month, start.day - 7),
      PeriodKind.month => DateTime(start.year, start.month - 1),
      PeriodKind.year => DateTime(start.year - 1),
    });
  }

  Period get next => Period(kind, range.end);

  @override
  List<Object?> get props => [kind, range];
}
