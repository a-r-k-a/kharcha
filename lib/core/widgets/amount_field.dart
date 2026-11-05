import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/money.dart';
import '../formatting/money_format_scope.dart';
import '../theme/theme_context.dart';

/// Allows only plain decimals with at most [decimals] fraction digits and
/// 13 integer digits: exactly what `Money.tryParse` accepts.
class AmountInputFormatter extends TextInputFormatter {
  AmountInputFormatter(int decimals)
    : _pattern = RegExp(
        decimals == 0 ? r'^\d{0,13}$' : '^\\d{0,13}(\\.\\d{0,$decimals})?\$',
      );

  final RegExp _pattern;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Accept a comma typed as the decimal key on some keyboards.
    final text = newValue.text.replaceAll(',', '.');
    if (!_pattern.hasMatch(text)) return oldValue;
    return newValue.copyWith(text: text);
  }
}

/// Large amount entry: currency symbol, tabular display figures, numeric
/// keyboard.
class AmountField extends StatefulWidget {
  const AmountField({
    super.key,
    required this.currency,
    required this.value,
    required this.onChanged,
    this.label = 'Amount',
    this.errorText,
    this.autofocus = false,
    this.size = AmountFieldSize.large,
  });

  final Currency currency;
  final String value;
  final ValueChanged<String> onChanged;
  final String label;
  final String? errorText;
  final bool autofocus;
  final AmountFieldSize size;

  @override
  State<AmountField> createState() => _AmountFieldState();
}

enum AmountFieldSize { large, compact }

class _AmountFieldState extends State<AmountField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(AmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync external changes (e.g. a reset) without fighting the cursor.
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.typeScale;
    final large = widget.size == AmountFieldSize.large;
    final style = (large ? type.moneyLarge : type.moneySmall).copyWith(
      color: colors.textPrimary,
    );
    final symbol = MoneyFormatScope.of(context).symbolOf(widget.currency);

    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      keyboardType: TextInputType.numberWithOptions(
        decimal: widget.currency.decimals > 0,
      ),
      textInputAction: TextInputAction.done,
      inputFormatters: [AmountInputFormatter(widget.currency.decimals)],
      style: style,
      cursorColor: colors.accentStrong,
      decoration: InputDecoration(
        labelText: widget.label.toUpperCase(),
        errorText: widget.errorText,
        hintText: '0',
        hintStyle: style.copyWith(color: colors.textTertiary),
        prefixText: symbol,
        prefixStyle: style.copyWith(
          color: colors.textSecondary,
          fontSize: (style.fontSize ?? 16) * (large ? 0.6 : 1),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.space.lg,
          vertical: large ? context.space.lg : context.space.md,
        ),
      ),
    );
  }
}
