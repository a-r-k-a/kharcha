import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/domain/date_range.dart';
import '../../../../core/domain/money.dart';
import '../../../../core/formatting/date_labels.dart';
import '../../../../core/formatting/money_format_scope.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../ledger/domain/services/ledger_analytics.dart';

/// Spending per bucket as thin columns. One series, so no legend: the
/// section title names it. The bucket containing [now] is drawn in the
/// accent; the rest recede.
class SpendingChart extends StatelessWidget {
  const SpendingChart({
    super.key,
    required this.buckets,
    required this.kind,
    required this.now,
    this.height = 168,
  });

  final List<CashFlowBucket> buckets;
  final PeriodKind kind;
  final DateTime now;
  final double height;

  String _bucketLabel(DateRange range) => switch (kind) {
    PeriodKind.year => DateLabels.shortMonth(range.start),
    _ => DateLabels.dayMonth(range.start),
  };

  /// Sparse axis labels so they never collide.
  String? _axisLabel(int index) {
    final range = buckets[index].range;
    return switch (kind) {
      PeriodKind.year => DateLabels.shortMonth(range.start).substring(0, 1),
      PeriodKind.day || PeriodKind.week => const [
        'M',
        'T',
        'W',
        'T',
        'F',
        'S',
        'S',
      ][range.start.weekday - 1],
      PeriodKind.month =>
        index == 0 || (index + 1) % 7 == 0 ? '${range.start.day}' : null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final formatter = MoneyFormatScope.of(context);
    if (buckets.isEmpty) return SizedBox(height: height);

    final values = [for (final b in buckets) b.expense.major];
    final peak = values.fold<double>(0, math.max);
    final maxY = peak <= 0 ? 1.0 : _niceCeiling(peak);
    final currency = buckets.first.expense.currency;
    final peakIndex = values.indexOf(peak);
    final total = buckets.fold(
      Money.zero(currency: currency),
      (sum, b) => sum + b.expense,
    );

    return Semantics(
      label: peak <= 0
          ? 'No spending in this period'
          : 'Spending chart. Total ${formatter.format(total)}. Highest on '
                '${_bucketLabel(buckets[peakIndex].range)}, '
                '${formatter.format(buckets[peakIndex].expense)}.',
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slot = constraints.maxWidth / buckets.length;
              final barWidth = math.min(24.0, math.max(3.0, slot * 0.55));
              return BarChart(
                duration: context.motionDuration(context.motion.slow),
                curve: context.motion.enter,
                BarChartData(
                  maxY: maxY,
                  minY: 0,
                  alignment: BarChartAlignment.spaceAround,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 2,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: colors.line, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        interval: maxY / 2,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            value == 0
                                ? '0'
                                : formatter.compact(
                                    Money.fromMajor(value, currency: currency),
                                  ),
                            style: context.typeScale.label.copyWith(
                              color: colors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          final label = index >= 0 && index < buckets.length
                              ? _axisLabel(index)
                              : null;
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              label ?? '',
                              style: context.typeScale.label.copyWith(
                                color: colors.textTertiary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => colors.textPrimary,
                      tooltipBorderRadius: context.radii.card,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                          BarTooltipItem(
                            '${_bucketLabel(buckets[groupIndex].range)}\n',
                            context.typeScale.label.copyWith(
                              color: colors.canvas,
                            ),
                            children: [
                              TextSpan(
                                text: formatter.format(
                                  buckets[groupIndex].expense,
                                ),
                                style: context.typeScale.moneySmall.copyWith(
                                  color: colors.canvas,
                                ),
                              ),
                            ],
                          ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < buckets.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: values[i],
                            width: barWidth,
                            color: buckets[i].range.contains(now)
                                ? colors.accentStrong
                                : colors.lineStrong,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(math.min(4, barWidth / 2)),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Rounds up to 1, 2 or 5 × a power of ten for clean axis ticks.
  static double _niceCeiling(double value) {
    final exponent = (math.log(value) / math.ln10).floor();
    final base = math.pow(10, exponent).toDouble();
    for (final step in const [1, 2, 5, 10]) {
      if (step * base >= value) return step * base;
    }
    return 10 * base;
  }
}
