import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/core/domain/date_range.dart';

void main() {
  group('Period.range', () {
    test('week starts on Monday and spans 7 days', () {
      // 2026-11-04 is a Wednesday.
      final range = Period(PeriodKind.week, DateTime(2026, 11, 4, 15)).range;
      expect(range.start, DateTime(2026, 11, 2));
      expect(range.end, DateTime(2026, 11, 9));
      expect(range.dayCount, 7);
    });

    test('week across a month boundary', () {
      final range = Period(PeriodKind.week, DateTime(2026, 12, 31)).range;
      expect(range.start, DateTime(2026, 12, 28));
      expect(range.end, DateTime(2027, 1, 4));
    });

    test('month handles February in a leap year', () {
      final range = Period(PeriodKind.month, DateTime(2028, 2, 10)).range;
      expect(range.start, DateTime(2028, 2));
      expect(range.end, DateTime(2028, 3));
      expect(range.dayCount, 29);
    });

    test('year spans the calendar year', () {
      final range = Period(PeriodKind.year, DateTime(2026, 6)).range;
      expect(range.start, DateTime(2026));
      expect(range.end, DateTime(2027));
      expect(range.dayCount, 365);
    });
  });

  test('previous and next step by one period', () {
    final march = Period(PeriodKind.month, DateTime(2026, 3, 31));
    expect(march.previous.range.start, DateTime(2026, 2));
    expect(march.next.range.start, DateTime(2026, 4));
    final january = Period(PeriodKind.month, DateTime(2026, 1, 15));
    expect(january.previous.range.start, DateTime(2025, 12));
    final monday = Period(PeriodKind.day, DateTime(2026, 11, 2));
    expect(monday.previous.range.start, DateTime(2026, 11));
  });

  group('DateRange', () {
    test('is half-open', () {
      final day = DateRange.day(DateTime(2026, 5, 10));
      expect(day.contains(DateTime(2026, 5, 10)), isTrue);
      expect(day.contains(DateTime(2026, 5, 10, 23, 59, 59)), isTrue);
      expect(day.contains(DateTime(2026, 5, 11)), isFalse);
      expect(day.contains(DateTime(2026, 5, 9, 23, 59)), isFalse);
    });

    test('compares UTC instants in local time', () {
      final local = DateTime(2026, 5, 10, 12);
      expect(DateRange.day(local).contains(local.toUtc()), isTrue);
    });

    test('days() is inclusive of both ends', () {
      final range = DateRange.days(DateTime(2026), DateTime(2026, 1, 3));
      expect(range.dayCount, 3);
      expect(range.lastDay, DateTime(2026, 1, 3));
    });

    test('rejects an end before the start', () {
      expect(
        () => DateRange(DateTime(2026, 2), DateTime(2026)),
        throwsArgumentError,
      );
    });
  });
}
