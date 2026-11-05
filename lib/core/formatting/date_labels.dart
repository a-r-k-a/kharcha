import 'package:intl/intl.dart';

/// Human date labels, relative to [now] where that reads better.
abstract final class DateLabels {
  static final _weekdayDayMonth = DateFormat('EEE, d MMM');
  static final _dayMonthYear = DateFormat('d MMM yyyy');
  static final _dayMonth = DateFormat('d MMM');
  static final _monthYear = DateFormat('MMMM yyyy');
  static final _shortMonth = DateFormat('MMM');
  static final _time = DateFormat('h:mm a');

  /// "Today", "Yesterday", "Mon, 3 Nov", or "3 Nov 2025" in another year.
  static String day(DateTime date, DateTime now) {
    final local = date.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(local.year, local.month, local.day);
    final difference = today.difference(that).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference == -1) return 'Tomorrow';
    return local.year == now.year
        ? _weekdayDayMonth.format(local)
        : _dayMonthYear.format(local);
  }

  static String dayMonth(DateTime date) => _dayMonth.format(date.toLocal());

  static String fullDate(DateTime date) => _dayMonthYear.format(date.toLocal());

  static String monthYear(DateTime date) => _monthYear.format(date.toLocal());

  static String shortMonth(DateTime date) => _shortMonth.format(date.toLocal());

  static String time(DateTime date) => _time.format(date.toLocal());

  /// Morning / afternoon / evening greeting for the hour of [now].
  static String greeting(DateTime now) {
    final hour = now.hour;
    if (hour < 5) return 'Good evening';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
