import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_utils.dart';
import 'calendar_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _touchedPieIndex = -1;

  // Compare period: 'month' or 'year'
  String _comparePeriod = 'month';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final expenses = context.watch<ExpenseProvider>();
    final settings = context.watch<SettingsProvider>();
    final symbol = settings.currencySymbol;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        title: const Text('Statistics'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor:
              theme.colorScheme.onSurface.withOpacity(0.4),
          indicatorColor: theme.colorScheme.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Categories'),
            Tab(text: 'Compare'),
            Tab(text: 'Calendar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(expenses: expenses, settings: settings, now: now),
          _CategoriesTab(
              expenses: expenses,
              settings: settings,
              now: now,
              touchedIndex: _touchedPieIndex,
              onTouch: (i) => setState(() => _touchedPieIndex = i)),
          _CompareTab(
              expenses: expenses,
              settings: settings,
              now: now,
              period: _comparePeriod,
              onPeriodChanged: (p) => setState(() => _comparePeriod = p)),
          const CalendarScreen(embedded: true),
        ],
      ),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final ExpenseProvider expenses;
  final SettingsProvider settings;
  final DateTime now;

  const _OverviewTab(
      {required this.expenses,
      required this.settings,
      required this.now});

  @override
  Widget build(BuildContext context) {
    final symbol = settings.currencySymbol;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final thisMonth =
        expenses.getTotalForMonth(now.year, now.month);
    final lastMonth = expenses.getTotalForMonth(
        now.month == 1 ? now.year - 1 : now.year,
        now.month == 1 ? 12 : now.month - 1);
    final thisWeek = expenses.getTotalForWeek();
    final today = expenses.getTotalForDay(now);

    final dailyTotals =
        expenses.getDailyTotals(now.year, now.month);
    final maxVal = dailyTotals.isEmpty
        ? 1.0
        : dailyTotals.values.reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Summary cards ──────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'This Month',
                value: AppUtils.formatAmount(thisMonth, symbol),
                icon: Icons.calendar_view_month_rounded,
                color: theme.colorScheme.primary,
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Last Month',
                value: AppUtils.formatAmount(lastMonth, symbol),
                icon: Icons.history_rounded,
                color: const Color(0xFF78909C),
              )
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 400.ms)
                  .slideY(begin: 0.2),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'This Week',
                value: AppUtils.formatAmount(thisWeek, symbol),
                icon: Icons.date_range_rounded,
                color: const Color(0xFF26A69A),
              )
                  .animate()
                  .fadeIn(delay: 160.ms, duration: 400.ms)
                  .slideY(begin: 0.2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Today',
                value: AppUtils.formatAmount(today, symbol),
                icon: Icons.today_rounded,
                color: const Color(0xFFEF6C00),
              )
                  .animate()
                  .fadeIn(delay: 240.ms, duration: 400.ms)
                  .slideY(begin: 0.2),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ── Month vs last month comparison ─────────────────────
        _buildCompareCard(
            context, thisMonth, lastMonth, symbol, isDark),

        const SizedBox(height: 20),

        // ── Daily bar chart ────────────────────────────────────
        if (dailyTotals.isNotEmpty) ...[
          Text('Daily Spending — ${AppUtils.formatMonthYear(now)}',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12)
              ],
            ),
            child: BarChart(
              BarChartData(
                maxY: maxVal * 1.3,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        theme.colorScheme.primary.withOpacity(0.9),
                    getTooltipItem: (g, gi, rod, ri) =>
                        BarTooltipItem(
                      rod.toY.toStringAsFixed(0),
                      const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      getTitlesWidget: (v, _) {
                        final d = v.toInt();
                        if (d % 7 != 1 && d != 1) {
                          return const SizedBox.shrink();
                        }
                        return Text('$d',
                            style: TextStyle(
                                fontSize: 9,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.4)));
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color:
                        theme.colorScheme.onSurface.withOpacity(0.06),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: dailyTotals.entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value,
                        color: theme.colorScheme.primary,
                        width: 6,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxVal * 1.3,
                          color: theme.colorScheme.primary
                              .withOpacity(0.06),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ],
    );
  }

  Widget _buildCompareCard(BuildContext context, double thisMonth,
      double lastMonth, String symbol, bool isDark) {
    final theme = Theme.of(context);
    final diff = thisMonth - lastMonth;
    final pct = lastMonth > 0
        ? ((diff / lastMonth) * 100).abs().toStringAsFixed(1)
        : '—';
    final isMore = diff > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 12)
        ],
      ),
      child: Row(
        children: [
          Icon(
            isMore
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            color: isMore ? const Color(0xFFE57373) : const Color(0xFF2ECC71),
            size: 36,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMore
                      ? 'Spending up $pct% vs last month'
                      : 'Spending down $pct% vs last month',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Difference: ${AppUtils.formatAmount(diff.abs(), symbol)}',
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }
}

// ── Categories Tab ────────────────────────────────────────────────────────────

class _CategoriesTab extends StatelessWidget {
  final ExpenseProvider expenses;
  final SettingsProvider settings;
  final DateTime now;
  final int touchedIndex;
  final ValueChanged<int> onTouch;

  const _CategoriesTab({
    required this.expenses,
    required this.settings,
    required this.now,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>();
    final symbol = settings.currencySymbol;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totals =
        expenses.getCategoryTotals(now.year, now.month);
    if (totals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline_rounded,
                size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No data yet',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold(0.0, (s, e) => s + e.value);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Pie chart
        Container(
          height: 240,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05), blurRadius: 12)
            ],
          ),
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions ||
                      response?.touchedSection == null) {
                    onTouch(-1);
                  } else {
                    onTouch(response!
                        .touchedSection!.touchedSectionIndex);
                  }
                },
              ),
              sectionsSpace: 3,
              centerSpaceRadius: 50,
              sections: entries.asMap().entries.map((e) {
                final isTouched = e.key == touchedIndex;
                final cat = categories.getById(e.value.key);
                final color = cat != null
                    ? Color(cat.colorValue)
                    : theme.colorScheme.primary;
                final pct =
                    (e.value.value / total * 100).toStringAsFixed(1);
                return PieChartSectionData(
                  color: color,
                  value: e.value.value,
                  title: isTouched ? '$pct%' : '',
                  radius: isTouched ? 75 : 60,
                  titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                );
              }).toList(),
            ),
          ),
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 20),

        Text('Breakdown',
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 12),

        // Category breakdown list
        ...entries.asMap().entries.map((e) {
          final cat = categories.getById(e.value.key);
          final color = cat != null
              ? Color(cat.colorValue)
              : theme.colorScheme.primary;
          final pct = (e.value.value / total * 100);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8)
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(cat?.icon ?? '💰',
                        style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cat?.name ?? e.value.key,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                    ),
                    Text(
                      AppUtils.formatAmount(e.value.value, symbol),
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: color,
                          fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.4)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 6,
                    backgroundColor: color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: (e.key * 60).ms)
              .slideX(begin: 0.1);
        }),
      ],
    );
  }
}

// ── Compare Tab ───────────────────────────────────────────────────────────────

class _CompareTab extends StatelessWidget {
  final ExpenseProvider expenses;
  final SettingsProvider settings;
  final DateTime now;
  final String period;
  final ValueChanged<String> onPeriodChanged;

  const _CompareTab({
    required this.expenses,
    required this.settings,
    required this.now,
    required this.period,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = settings.currencySymbol;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Build 6 periods to compare
    final List<_PeriodData> data = [];
    if (period == 'month') {
      for (int i = 5; i >= 0; i--) {
        final d = DateTime(now.year, now.month - i, 1);
        final total =
            expenses.getTotalForMonth(d.year, d.month);
        data.add(_PeriodData(
          label: _shortMonth(d.month),
          total: total,
        ));
      }
    } else {
      for (int i = 4; i >= 0; i--) {
        final year = now.year - i;
        double total = 0;
        for (int m = 1; m <= 12; m++) {
          total += expenses.getTotalForMonth(year, m);
        }
        data.add(_PeriodData(label: '$year', total: total));
      }
    }

    final maxVal =
        data.map((d) => d.total).reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Period toggle
        Row(
          children: [
            Expanded(
              child: _ToggleBtn(
                label: 'Monthly',
                selected: period == 'month',
                onTap: () => onPeriodChanged('month'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ToggleBtn(
                label: 'Yearly',
                selected: period == 'year',
                onTap: () => onPeriodChanged('year'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Bar chart comparison
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05), blurRadius: 12)
            ],
          ),
          child: maxVal == 0
              ? Center(
                  child: Text('No data to compare',
                      style: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.4))))
              : BarChart(
                  BarChartData(
                    maxY: maxVal * 1.3,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) =>
                            theme.colorScheme.primary.withOpacity(0.9),
                        getTooltipItem: (g, gi, rod, ri) =>
                            BarTooltipItem(
                          AppUtils.formatAmount(rod.toY, symbol),
                          const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11),
                        ),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i < 0 || i >= data.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(data[i].label,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.5))),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: theme.colorScheme.onSurface
                            .withOpacity(0.06),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups:
                        data.asMap().entries.map((e) {
                      final isLatest = e.key == data.length - 1;
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.total,
                            color: isLatest
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary
                                    .withOpacity(0.4),
                            width: 28,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 20),

        // Period summary list
        ...data.asMap().entries.map((e) {
          final isLatest = e.key == data.length - 1;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isLatest
                  ? theme.colorScheme.primary.withOpacity(0.08)
                  : (isDark
                      ? const Color(0xFF1E1E1E)
                      : Colors.white),
              borderRadius: BorderRadius.circular(14),
              border: isLatest
                  ? Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3))
                  : null,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6)
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  e.value.label + (isLatest ? ' (current)' : ''),
                  style: TextStyle(
                    fontWeight: isLatest
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 14,
                    color: isLatest
                        ? theme.colorScheme.primary
                        : null,
                  ),
                ),
                Text(
                  AppUtils.formatAmount(e.value.total, symbol),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isLatest
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (e.key * 50).ms).slideX(begin: 0.1);
        }),
      ],
    );
  }

  String _shortMonth(int m) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return months[(m - 1) % 12];
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.5))),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleBtn(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: selected
                ? Colors.white
                : theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _PeriodData {
  final String label;
  final double total;
  const _PeriodData({required this.label, required this.total});
}
