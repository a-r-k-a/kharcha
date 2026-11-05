import 'package:flutter/widgets.dart';

import 'money_formatter.dart';

/// Provides the user's [MoneyFormatter] (locale-aware grouping) to the tree.
class MoneyFormatScope extends InheritedWidget {
  const MoneyFormatScope({
    super.key,
    required this.formatter,
    required super.child,
  });

  final MoneyFormatter formatter;

  static final MoneyFormatter _fallback = MoneyFormatter();

  /// The nearest formatter, or an `en_IN` default when none is provided
  /// (widget tests, previews).
  static MoneyFormatter of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<MoneyFormatScope>()
            ?.formatter ??
        _fallback;
  }

  @override
  bool updateShouldNotify(MoneyFormatScope oldWidget) =>
      oldWidget.formatter.locale != formatter.locale;
}
