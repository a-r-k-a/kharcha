import '../../core/domain/date_range.dart';
import '../../features/ledger/domain/entities/transaction.dart';
import '../../features/ledger/domain/services/transaction_query.dart';
import 'app_route.dart';

/// Encodes and safely decodes Activity filters as URL query parameters, so
/// filtered views are deep-linkable. Unknown or malformed values are
/// ignored rather than guessed.
abstract final class ActivityLink {
  static Map<String, String> query({
    TransactionType? type,
    String? categoryId,
    String? accountId,
    DateRange? range,
  }) => {
    RouteQuery.type: ?type?.name,
    RouteQuery.category: ?categoryId,
    RouteQuery.account: ?accountId,
    if (range != null) ...{
      RouteQuery.since: _date(range.start),
      RouteQuery.until: _date(range.lastDay),
    },
  };

  static TransactionQuery parse(Map<String, String> parameters) {
    final type = TransactionType.values
        .where((t) => t.name == parameters[RouteQuery.type])
        .firstOrNull;
    final category = parameters[RouteQuery.category]?.trim();
    final account = parameters[RouteQuery.account]?.trim();
    final since = _parseDate(parameters[RouteQuery.since]);
    final until = _parseDate(parameters[RouteQuery.until]);
    final range = since != null && until != null && !until.isBefore(since)
        ? DateRange.days(since, until)
        : null;
    return TransactionQuery(
      types: {?type},
      categoryIds: {if (category != null && category.isNotEmpty) category},
      accountIds: {if (account != null && account.isNotEmpty) account},
      range: range,
    );
  }

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static final _datePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  static DateTime? _parseDate(String? value) {
    final match = _datePattern.firstMatch(value ?? '');
    if (match == null) return null;
    final year = int.parse(match.group(1) ?? '');
    final month = int.parse(match.group(2) ?? '');
    final day = int.parse(match.group(3) ?? '');
    final date = DateTime(year, month, day);
    // Reject impossible dates such as 2026-02-31 instead of rolling over.
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }
}
