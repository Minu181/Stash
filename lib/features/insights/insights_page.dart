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
            if (goals.isEmpty) {
              return _EmptyInsights(reduceMotion: reduceMotion);
            }
            final total = goals.fold<double>(0, (s, g) => s + g.savedAmount);
            final target = goals.fold<double>(0, (s, g) => s + g.targetAmount);
            final overall = (target > 0 ? total / target : 0.0).clamp(0.0, 1.0).toDouble();
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                EnterTransition(
                  animate: !reduceMotion,
                  child: GradientContainer(
                    borderRadius: BorderRadius.circular(22),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Total Savings',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                        ),
                        const SizedBox(height: 6),
                        CountUpText(
                          value: total,
                          animate: !reduceMotion,
                          format: (v) => formatCurrency(v, currency),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: overall,
                            minHeight: 8,
                            color: Colors.white,
                            backgroundColor: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(overall * 100).toInt()}% of ${formatCurrency(target, currency)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                slideFadeIn(
                  index: 1,
                  animate: !reduceMotion,
                  child: _SavingsChart(txs: txs, currency: currency, animate: !reduceMotion),
                ),
                const SizedBox(height: 18),
                slideFadeIn(
                  index: 2,
                  animate: !reduceMotion,
                  child: _GoalBreakdown(goals: goals, currency: currency, animate: !reduceMotion),
                ),
                const SizedBox(height: 18),
                slideFadeIn(
                  index: 3,
                  animate: !reduceMotion,
                  child: _CategoryChart(txs: txs, currency: currency, animate: !reduceMotion),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primaryContainer,
              ),
              child: Icon(Icons.insights_rounded, size: 40, color: cs.primary),
            )
                .animate(autoPlay: !reduceMotion)
                .scale(duration: 500.ms, curve: Curves.easeOutBack)
                .then(delay: 200.ms)
                .shimmer(duration: 800.ms, color: cs.primary.withValues(alpha: 0.15)),
            const SizedBox(height: 20),
            Text(
              'No data yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add goals and transactions to see your savings insights here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Combined Savings Chart with Time Range Selector ---

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
      _TimeRange.week => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1],
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
    // Month / 3M / 6M → bucket by week
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
      // Find which bucket this falls into
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up_rounded, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text(_showCumulative ? 'Savings over time' : 'Net savings',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _showCumulative = !_showCumulative),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _showCumulative ? 'Cumulative' : 'Per period',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onPrimaryContainer),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Time range selector
            SizedBox(
              height: 34,
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
                        color: selected ? cs.primary : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? cs.onPrimary : cs.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
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
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            curveSmoothness: 0.35,
                            barWidth: 3,
                            color: _showCumulative ? Colors.green : cs.primary,
                            dotData: FlDotData(
                              show: spots.length <= 12,
                              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                                radius: 3,
                                color: _showCumulative ? Colors.green : cs.primary,
                                strokeColor: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  (_showCumulative ? Colors.green : cs.primary).withValues(alpha: 0.25),
                                  (_showCumulative ? Colors.green : cs.primary).withValues(alpha: 0.02),
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
                                // Show fewer labels if too many buckets
                                final step = (buckets.length / 6).ceil();
                                if (idx % step != 0 && idx != buckets.length - 1) return const SizedBox();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(_labelForSpot(idx, buckets),
                                      style: Theme.of(context).textTheme.labelSmall),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: needsNegativeAxis,
                              reservedSize: 40,
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
                          show: needsNegativeAxis,
                          drawVerticalLine: false,
                          horizontalInterval: (maxVal - minVal).abs() / 4,
                          getDrawingHorizontalLine: (v) => FlLine(
                            color: v == 0 ? cs.outlineVariant : cs.outlineVariant.withValues(alpha: 0.3),
                            strokeWidth: v == 0 ? 1.5 : 0.5,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touched) => touched.map((t) {
                              return LineTooltipItem(
                                formatCurrency(t.y, widget.currency),
                                TextStyle(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      duration: widget.animate ? const Duration(milliseconds: 600) : Duration.zero,
                      curve: Curves.easeOutCubic,
                    ),
            ),
            // Summary row
            const SizedBox(height: 10),
            Row(
              children: [
                _summaryChip(context, 'Deposits',
                    formatCurrency(deposits.fold(0.0, (a, b) => a + b), widget.currency), Colors.green),
                const SizedBox(width: 12),
                _summaryChip(context, 'Withdrawals',
                    formatCurrency(withdrawals.fold(0.0, (a, b) => a + b), widget.currency), Colors.red),
                const SizedBox(width: 12),
                _summaryChip(context, 'Net',
                    formatCurrency(
                        deposits.fold(0.0, (a, b) => a + b) - withdrawals.fold(0.0, (a, b) => a + b),
                        widget.currency),
                    cs.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(BuildContext context, String label, String value, Color color) {
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
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
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

// --- Goal Breakdown (horizontal bar list) ---

class _GoalBreakdown extends StatelessWidget {
  final List<Goal> goals;
  final String currency;
  final bool animate;

  const _GoalBreakdown({required this.goals, required this.currency, required this.animate});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = goals.fold<double>(0, (s, g) => s + g.savedAmount);
    final sorted = List<Goal>.from(goals)..sort((a, b) => b.savedAmount.compareTo(a.savedAmount));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart_rounded, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text('Saved by goal', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < sorted.length; i++) ...[
              _GoalBar(
                goal: sorted[i],
                total: total,
                currency: currency,
                animate: animate,
                index: i,
              ),
              if (i < sorted.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _GoalBar extends StatelessWidget {
  final Goal goal;
  final double total;
  final String currency;
  final bool animate;
  final int index;

  const _GoalBar({
    required this.goal,
    required this.total,
    required this.currency,
    required this.animate,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(goal.color);
    final pct = total > 0 ? goal.savedAmount / total : 0.0;
    final goalPct = goal.targetAmount > 0
        ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;

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
            Text(
              formatCurrency(goal.savedAmount, currency),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            Text(
              '${(pct * 100).toInt()}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Two-layer progress bar: outer = share of total, inner = goal progress
        Stack(
          children: [
              // Background: total share
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 10,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  color: color.withValues(alpha: 0.25),
                ),
              ),
            // Foreground: goal progress
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
        const SizedBox(height: 2),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${(goalPct * 100).toInt()}% of goal · ${(pct * 100).toInt()}% of total',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ),
      ],
    );
  }
}

// --- Category Chart (withdrawals only = spending) ---

class _CategoryChart extends StatelessWidget {
  final List<Transaction> txs;
  final String currency;
  final bool animate;

  const _CategoryChart({required this.txs, required this.currency, required this.animate});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final spending = <String, double>{};
    final income = <String, double>{};

    for (final t in txs) {
      if (t.type == 'withdrawal') {
        spending[t.category] = (spending[t.category] ?? 0) + t.amount;
      } else {
        income[t.category] = (income[t.category] ?? 0) + t.amount;
      }
    }

    final sortedSpending = spending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sortedSpending.take(8).toList();
    final maxVal = top.isNotEmpty ? top.first.value : 1.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_rounded, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text('Spending by category', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Withdrawals only',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: 14),
            if (top.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('No withdrawals yet',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline)),
                ),
              )
            else
              ...top.map((entry) {
                final cat = GoalOptions.categoryByName(entry.key);
                final fraction = maxVal > 0 ? entry.value / maxVal : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(cat.icon, size: 16, color: cat.color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(entry.key,
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                          ),
                          Text(
                            formatCurrency(entry.value, currency),
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 6,
                          color: cat.color,
                          backgroundColor: cat.color.withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
