import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:stash/data/database.dart';
import 'package:stash/features/goals/goal_options.dart';
import 'package:stash/providers/data_providers.dart';
import 'package:stash/providers/settings_provider.dart';
import 'package:stash/widgets/animated_widgets.dart';
import 'package:stash/widgets/ui.dart';

enum _TimeRange { week, month, threeMonths, sixMonths, year }

class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final currency = settings.currency;
    final reduceMotion = settings.reduceMotion;
    final goalsAsync = ref.watch(goalsProvider);
    final txAsync = ref.watch(allTransactionsProvider);

    return Scaffold(
      appBar: const GradientAppBar(title: 'Insights', subtitle: 'Track your progress'),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (goals) => txAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (txs) {
            if (goals.isEmpty) return _EmptyInsights(reduceMotion: reduceMotion);

            final total = goals.fold<double>(0, (s, g) => s + g.savedAmount);
            final target = goals.fold<double>(0, (s, g) => s + g.targetAmount);
            final overall = (target > 0 ? total / target : 0.0).clamp(0.0, 1.0).toDouble();
            final completed = goals.where((g) => g.targetAmount > 0 && g.savedAmount >= g.targetAmount).length;
            final deposits = txs.where((t) => t.type == 'deposit').fold<double>(0, (s, t) => s + t.amount);
            final withdrawals = txs.where((t) => t.type == 'withdrawal').fold<double>(0, (s, t) => s + t.amount);

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(goalsProvider);
                ref.invalidate(allTransactionsProvider);
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // ── Hero card ──
                  EnterTransition(
                    animate: !reduceMotion,
                    child: _HeroCard(total: total, target: target, overall: overall, currency: currency),
                  ),
                  const SizedBox(height: 16),

                  // ── Quick stats ──
                  slideFadeIn(
                    index: 1,
                    animate: !reduceMotion,
                    child: _QuickStats(
                      goalsCount: goals.length,
                      completed: completed,
                      txCount: txs.length,
                      net: deposits - withdrawals,
                      currency: currency,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Savings chart ──
                  slideFadeIn(
                    index: 2,
                    animate: !reduceMotion,
                    child: _SavingsChart(txs: txs, currency: currency, animate: !reduceMotion),
                  ),
                  const SizedBox(height: 16),

                  // ── Goal breakdown ──
                  slideFadeIn(
                    index: 3,
                    animate: !reduceMotion,
                    child: _GoalBreakdown(goals: goals, total: total, currency: currency, animate: !reduceMotion),
                  ),
                  const SizedBox(height: 16),

                  // ── Category spending ──
                  slideFadeIn(
                    index: 4,
                    animate: !reduceMotion,
                    child: _CategoryDonut(txs: txs, currency: currency),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Empty state
// ══════════════════════════════════════════════════════════════════════════════

class _EmptyInsights extends StatelessWidget {
  final bool reduceMotion;
  const _EmptyInsights({required this.reduceMotion});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle, color: cs.primaryContainer),
              child: Icon(Icons.insights_rounded, size: 40, color: cs.primary),
            )
                .animate(autoPlay: !reduceMotion)
                .scale(duration: 500.ms, curve: Curves.easeOutBack)
                .then(delay: 200.ms)
                .shimmer(duration: 800.ms, color: cs.primary.withValues(alpha: 0.15)),
            const SizedBox(height: 20),
            Text('No data yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Add goals and transactions to see your savings insights here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.outline),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Hero card — total savings + progress ring
// ══════════════════════════════════════════════════════════════════════════════

class _HeroCard extends StatelessWidget {
  final double total;
  final double target;
  final double overall;
  final String currency;

  const _HeroCard({required this.total, required this.target, required this.overall, required this.currency});

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Saved',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                CountUpText(
                  value: total,
                  animate: true,
                  format: (v) => formatCurrency(v, currency),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: overall,
                    minHeight: 6,
                    color: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(overall * 100).toInt()}% of ${formatCurrency(target, currency)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          AnimatedProgressRing(
            progress: overall,
            size: 80,
            strokeWidth: 8,
            color: Colors.white,
            animate: true,
            center: Text(
              '${(overall * 100).toInt()}%',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Quick stats row
// ══════════════════════════════════════════════════════════════════════════════

class _QuickStats extends StatelessWidget {
  final int goalsCount;
  final int completed;
  final int txCount;
  final double net;
  final String currency;

  const _QuickStats({
    required this.goalsCount,
    required this.completed,
    required this.txCount,
    required this.net,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        _StatTile(
          icon: Icons.savings_rounded,
          label: 'Goals',
          value: '$goalsCount',
          color: cs.primary,
          detail: '$completed done',
        ),
        const SizedBox(width: 10),
        _StatTile(
          icon: Icons.receipt_long_rounded,
          label: 'Transactions',
          value: '$txCount',
          color: cs.tertiary,
        ),
        const SizedBox(width: 10),
        _StatTile(
          icon: net >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          label: 'Net',
          value: formatCurrency(net, currency),
          color: net >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? detail;

  const _StatTile({required this.icon, required this.label, required this.value, required this.color, this.detail});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
            if (detail != null)
              Text(
                detail!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10, color: Theme.of(context).colorScheme.outline),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Savings line chart
// ══════════════════════════════════════════════════════════════════════════════

class _SavingsChart extends StatefulWidget {
  final List<Transaction> txs;
  final String currency;
  final bool animate;
  const _SavingsChart({required this.txs, required this.currency, required this.animate});
  @override
  State<_SavingsChart> createState() => _SavingsChartState();
}

class _SavingsChartState extends State<_SavingsChart> {
  _TimeRange _range = _TimeRange.sixMonths;
  bool _showCumulative = true;

  DateTime _rangeStart() {
    final now = DateTime.now();
    return switch (_range) {
      _TimeRange.week => now.subtract(const Duration(days: 7)),
      _TimeRange.month => DateTime(now.year, now.month - 1, now.day),
      _TimeRange.threeMonths => DateTime(now.year, now.month - 3, now.day),
      _TimeRange.sixMonths => DateTime(now.year, now.month - 6, now.day),
      _TimeRange.year => DateTime(now.year - 1, now.month, now.day),
    };
  }

  String _labelForSpot(int index, List<DateTime> buckets) {
    if (index < 0 || index >= buckets.length) return '';
    final d = buckets[index];
    return switch (_range) {
      _TimeRange.week => ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d.weekday - 1],
      _TimeRange.month => '${d.day}',
      _TimeRange.threeMonths || _TimeRange.sixMonths => '${d.month}/${d.year.toString().substring(2)}',
      _TimeRange.year => switch (d.month) {
          1 => 'Jan', 2 => 'Feb', 3 => 'Mar', 4 => 'Apr', 5 => 'May', 6 => 'Jun',
          7 => 'Jul', 8 => 'Aug', 9 => 'Sep', 10 => 'Oct', 11 => 'Nov', 12 => 'Dec',
          _ => '',
        },
    };
  }

  List<DateTime> _buildBuckets() {
    final start = _rangeStart();
    final now = DateTime.now();
    if (_range == _TimeRange.week) {
      return List.generate(7, (i) => DateTime(now.year, now.month, now.day - (6 - i)));
    }
    if (_range == _TimeRange.year) {
      return List.generate(12, (i) => DateTime(now.year, now.month - (11 - i), 1));
    }
    final days = now.difference(start).inDays + 1;
    final weeks = (days / 7).ceil().clamp(1, 26);
    return List.generate(weeks, (i) {
      final d = start.add(Duration(days: i * 7));
      return DateTime(d.year, d.month, d.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final buckets = _buildBuckets();
    final start = _rangeStart();
    final deposits = List<double>.filled(buckets.length, 0);
    final withdrawals = List<double>.filled(buckets.length, 0);

    for (final t in widget.txs) {
      if (t.date.isBefore(start)) continue;
      int idx = buckets.length - 1;
      for (var i = 0; i < buckets.length; i++) {
        final next = i + 1 < buckets.length ? buckets[i + 1] : DateTime.now();
        if (!t.date.isBefore(buckets[i]) && t.date.isBefore(next)) {
          idx = i;
          break;
        }
      }
      if (t.type == 'deposit') {
        deposits[idx] += t.amount;
      } else {
        withdrawals[idx] += t.amount;
      }
    }

    final spots = <FlSpot>[];
    if (_showCumulative) {
      double cum = 0;
      for (var i = 0; i < buckets.length; i++) {
        cum += deposits[i] - withdrawals[i];
        spots.add(FlSpot(i.toDouble(), cum));
      }
    } else {
      for (var i = 0; i < buckets.length; i++) {
        spots.add(FlSpot(i.toDouble(), deposits[i] - withdrawals[i]));
      }
    }

    final maxVal = spots.fold<double>(0, (m, s) => s.y > m ? s.y : m);
    final minVal = spots.fold<double>(0, (m, s) => s.y < m ? s.y : m);
    final needsNegativeAxis = minVal < 0;
    final lineColor = _showCumulative ? const Color(0xFF16A34A) : cs.primary;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: lineColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.show_chart_rounded, size: 18, color: lineColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _showCumulative ? 'Cumulative Savings' : 'Net per Period',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showCumulative = !_showCumulative),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: lineColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _showCumulative ? 'Cumulative' : 'Per period',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: lineColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Time range selector
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _TimeRange.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final r = _TimeRange.values[index];
                final selected = _range == r;
                final label = switch (r) {
                  _TimeRange.week => '1W',
                  _TimeRange.month => '1M',
                  _TimeRange.threeMonths => '3M',
                  _TimeRange.sixMonths => '6M',
                  _TimeRange.year => '1Y',
                };
                return GestureDetector(
                  onTap: () => setState(() => _range = r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: selected ? cs.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: selected ? null : Border.all(color: cs.outlineVariant, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Chart
          SizedBox(
            height: 200,
            child: spots.isEmpty
                ? Center(
                    child: Text('No data in this range',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline)),
                  )
                : LineChart(
                    LineChartData(
                      minY: needsNegativeAxis ? minVal * 1.2 : null,
                      lineTouchData: LineTouchData(
                        enabled: true,
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => cs.inverseSurface,
                          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          getTooltipItems: (touched) => touched.map((t) {
                            return LineTooltipItem(
                              formatCurrency(t.y, widget.currency),
                              TextStyle(
                                color: cs.onInverseSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            );
                          }).toList(),
                        ),
                        getTouchedSpotIndicator: (data, spots) => spots.map((s) {
                          return TouchedSpotIndicatorData(
                            FlLine(color: lineColor.withValues(alpha: 0.3), strokeWidth: 1, dashArray: [4, 4]),
                            FlDotData(
                              show: true,
                              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                                radius: 5,
                                color: lineColor,
                                strokeColor: cs.surface,
                                strokeWidth: 2.5,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.35,
                          barWidth: 3,
                          color: lineColor,
                          dotData: FlDotData(
                            show: spots.length <= 12,
                            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                              radius: 3,
                              color: lineColor,
                              strokeColor: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                lineColor.withValues(alpha: 0.25),
                                lineColor.withValues(alpha: 0.02),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (v, _) {
                              final idx = v.toInt();
                              if (idx < 0 || idx >= buckets.length) return const SizedBox();
                              final step = (buckets.length / 6).ceil();
                              if (idx % step != 0 && idx != buckets.length - 1) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(_labelForSpot(idx, buckets),
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10)),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: needsNegativeAxis,
                            reservedSize: 44,
                            getTitlesWidget: (v, _) {
                              if (v == 0) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(formatCurrency(v, widget.currency),
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9)),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: cs.outlineVariant.withValues(alpha: 0.3),
                          strokeWidth: 0.5,
                          dashArray: [4, 4],
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                    duration: widget.animate ? const Duration(milliseconds: 600) : Duration.zero,
                    curve: Curves.easeOutCubic,
                  ),
          ),

          // Summary chips
          const SizedBox(height: 14),
          Row(
            children: [
              _SummaryChip(
                label: 'Deposits',
                value: formatCurrency(deposits.fold(0.0, (a, b) => a + b), widget.currency),
                color: const Color(0xFF16A34A),
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                label: 'Withdrawals',
                value: formatCurrency(withdrawals.fold(0.0, (a, b) => a + b), widget.currency),
                color: const Color(0xFFDC2626),
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                label: 'Net',
                value: formatCurrency(
                    deposits.fold(0.0, (a, b) => a + b) - withdrawals.fold(0.0, (a, b) => a + b),
                    widget.currency),
                color: lineColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontSize: 10)),
            const SizedBox(height: 2),
            Text(value,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold, color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Goal breakdown (horizontal bars)
// ══════════════════════════════════════════════════════════════════════════════

class _GoalBreakdown extends StatelessWidget {
  final List<Goal> goals;
  final double total;
  final String currency;
  final bool animate;
  const _GoalBreakdown({required this.goals, required this.total, required this.currency, required this.animate});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sorted = List<Goal>.from(goals)..sort((a, b) => b.savedAmount.compareTo(a.savedAmount));

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.pie_chart_rounded, size: 18, color: cs.primary),
              ),
              const SizedBox(width: 10),
              Text('Saved by Goal', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < sorted.length; i++) ...[
            _GoalBar(goal: sorted[i], total: total, currency: currency, index: i),
            if (i < sorted.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _GoalBar extends StatelessWidget {
  final Goal goal;
  final double total;
  final String currency;
  final int index;
  const _GoalBar({required this.goal, required this.total, required this.currency, required this.index});

  @override
  Widget build(BuildContext context) {
    final color = Color(goal.color);
    final pct = total > 0 ? goal.savedAmount / total : 0.0;
    final goalPct = goal.targetAmount > 0
        ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final completed = goalPct >= 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4)],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                goal.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (completed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9A825).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Done', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFF9A825))),
              ),
            const SizedBox(width: 6),
            Text(
              formatCurrency(goal.savedAmount, currency),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 10,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                color: color.withValues(alpha: 0.25),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: goalPct.toDouble(),
                minHeight: 10,
                backgroundColor: Colors.transparent,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Text(
              '${(goalPct * 100).toInt()}% of goal',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const Spacer(),
            Text(
              '${(pct * 100).toInt()}% of total',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Category donut chart
// ══════════════════════════════════════════════════════════════════════════════

class _CategoryDonut extends StatelessWidget {
  final List<Transaction> txs;
  final String currency;
  const _CategoryDonut({required this.txs, required this.currency});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final spending = <String, double>{};
    for (final t in txs) {
      if (t.type == 'withdrawal') {
        spending[t.category] = (spending[t.category] ?? 0) + t.amount;
      }
    }

    final sorted = spending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();
    final totalSpending = spending.values.fold<double>(0, (a, b) => a + b);

    if (top.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cs.tertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.donut_large_rounded, size: 18, color: cs.tertiary),
                ),
                const SizedBox(width: 10),
                Text('Spending Breakdown', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 24),
            Icon(Icons.receipt_long_rounded, size: 40, color: cs.outline.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No withdrawals yet', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline)),
          ],
        ),
      );
    }

    final colors = top.map((e) => GoalOptions.categoryByName(e.key).color).toList();

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cs.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.donut_large_rounded, size: 18, color: cs.tertiary),
              ),
              const SizedBox(width: 10),
              Text('Spending Breakdown', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                // Donut
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 36,
                      startDegreeOffset: -90,
                      sections: [
                        for (var i = 0; i < top.length; i++)
                          PieChartSectionData(
                            value: top[i].value,
                            color: colors[i],
                            radius: 22,
                            title: '${((top[i].value / totalSpending) * 100).toInt()}%',
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                  ),
                ),
                const SizedBox(width: 16),
                // Legend
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < top.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: colors[i],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  top[i].key,
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                formatCurrency(top[i].value, currency),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors[i],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
