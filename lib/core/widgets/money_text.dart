import 'package:material_ui/material_ui.dart';

import '../domain/money.dart';
import '../formatting/money_format_scope.dart';
import '../formatting/money_formatter.dart';
import '../theme/theme_context.dart';

enum MoneySize { hero, large, medium, small }

/// Renders an amount with the split treatment from DESIGN.md §6: a small
/// raised currency symbol, the integer at full size and a dimmed fraction.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.money, {
    super.key,
    this.size = MoneySize.medium,
    this.color,
    this.precision = MoneyPrecision.auto,
    this.signed = false,
  });

  final Money money;
  final MoneySize size;
  final Color? color;
  final MoneyPrecision precision;

  /// Prefix positive amounts with `+`.
  final bool signed;

  @override
  Widget build(BuildContext context) {
    final parts = MoneyFormatScope.of(context)
        .parts(money, precision: precision, signed: signed);
    final colors = context.colors;
    final scale = context.typeScale;
    final baseColor = color ?? colors.textPrimary;
    final base = switch (size) {
      MoneySize.hero => scale.moneyHero,
      MoneySize.large => scale.moneyLarge,
      MoneySize.medium => scale.moneyMedium,
      MoneySize.small => scale.moneySmall,
    }.copyWith(color: baseColor);
    final isDisplay = size == MoneySize.hero || size == MoneySize.large;
    final fontSize = base.fontSize ?? 16;

    // Symbol and fraction shrink only at display sizes; at text sizes the
    // whole figure stays one size so columns align.
    final minor = isDisplay
        ? base.copyWith(fontSize: fontSize * 0.42, letterSpacing: 0)
        : base;
    final fractionColor = color == null
        ? colors.textSecondary
        : baseColor.withValues(alpha: 0.72);

    final text = Text.rich(
      TextSpan(
        children: [
          if (parts.sign.isNotEmpty) TextSpan(text: parts.sign, style: base),
          if (isDisplay)
            WidgetSpan(
              alignment: PlaceholderAlignment.top,
              child: Padding(
                padding: EdgeInsets.only(
                  top: fontSize * 0.08,
                  right: fontSize * 0.04,
                ),
                child: Text(parts.symbol, style: minor),
              ),
            )
          else
            TextSpan(text: parts.symbol, style: base),
          TextSpan(text: parts.integer, style: base),
          if (parts.fraction.isNotEmpty)
            TextSpan(
              text: parts.fraction,
              style: minor.copyWith(color: fractionColor),
            ),
        ],
      ),
      maxLines: 1,
      softWrap: false,
    );

    return Semantics(
      label: parts.toString(),
      excludeSemantics: true,
      child: isDisplay
          ? FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: text,
            )
          : text,
    );
  }
}

/// A [MoneyText] that rolls from its previous value to the new one.
class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney(
    this.money, {
    super.key,
    this.size = MoneySize.medium,
    this.color,
    this.precision = MoneyPrecision.auto,
    this.countUpOnMount = false,
  });

  final Money money;
  final MoneySize size;
  final Color? color;
  final MoneyPrecision precision;

  /// Roll up from zero on first build. Use for hero moments only.
  final bool countUpOnMount;

  @override
  Widget build(BuildContext context) {
    final target = money.minorUnits.toDouble();
    // Fix precision to the target's so the fraction doesn't flicker in and
    // out while intermediate values pass through.
    final stablePrecision = precision != MoneyPrecision.auto
        ? precision
        : (money.minorUnits % money.currency.minorPerMajor == 0
              ? MoneyPrecision.whole
              : MoneyPrecision.full);

    return Semantics(
      label: MoneyFormatScope.of(context).format(money, precision: precision),
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: countUpOnMount ? 0 : target, end: target),
        duration: context.motionDuration(context.motion.slow),
        curve: context.motion.enter,
        builder: (context, value, _) => MoneyText(
          Money(value.round(), currency: money.currency),
          size: size,
          color: color,
          precision: stablePrecision,
        ),
      ),
    );
  }
}
