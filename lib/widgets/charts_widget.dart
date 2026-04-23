import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_utils.dart';

class ChartsWidget extends StatefulWidget {
  const ChartsWidget({super.key});

  @override
  State<ChartsWidget> createState() => _ChartsWidgetState();
}

class _ChartsWidgetState extends State<ChartsWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Icon(Icons.bar_chart_rounded,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                const Text('Analytics',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor:
                theme.colorScheme.onSurface.withOpacity(0.5),
            indicatorColor: theme.colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'By Category'),
              Tab(text: 'By Day'),
            ],
          ),
          SizedBox(
            height: 260,
            child: TabBarView(
              controller: _tabController,
              children: const [
                _PieChartView(),
                _BarChartView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PieChartView extends StatefulWidget {
  const _PieChartView();

  @override
  State<_PieChartView> createState() => _PieChartViewState();
}

class _PieChartViewState extends State<_PieChartView> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final expenses = context.watch<ExpenseProvider>();
    final categories = context.watch<CategoryProvider>();
    final settings = context.watch<SettingsProvider>();
    final symbol = settings.currencySymbol;

    final totals = expenses.getCategoryTotals(now.year, now.month);
    if (totals.isEmpty) {
      return const _EmptyChart();
    }

    final entries = totals.entries.toList();
    final total = entries.fold(0.0, (s, e) => s + e.value);

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      _touchedIndex = -1;
                    } else {
                      _touchedIndex =
                          response.touchedSection!.touchedSectionIndex;
                    }
                  });
                },
              ),
              sectionsSpace: 3,
              centerSpaceRadius: 40,
              sections: entries.asMap().entries.map((e) {
                final isTouched = e.key == _touchedIndex;
                final cat = categories.getById(e.value.key);
                final color = cat != null
                    ? Color(cat.colorValue)
                    : Theme.of(context).colorScheme.primary;
                final pct = (e.value.value / total * 100).round();
                return PieChartSectionData(
                  color: color,
                  value: e.value.value,
                  title: '$pct%',
                  radius: isTouched ? 70 : 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.take(5).map((e) {
              final cat = categories.getById(e.key);
              final color = cat != null
                  ? Color(cat.colorValue)
                  : Theme.of(context).colorScheme.primary;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat?.name ?? e.key,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          AppUtils.formatAmount(e.value, symbol),
                          style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _BarChartView extends StatelessWidget {
  const _BarChartView();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final expenses = context.watch<ExpenseProvider>();
    final theme = Theme.of(context);

    final dailyTotals = expenses.getDailyTotals(now.year, now.month);
    if (dailyTotals.isEmpty) {
      return const _EmptyChart();
    }

    final maxVal = dailyTotals.values.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  theme.colorScheme.primary.withOpacity(0.9),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  rod.toY.toStringAsFixed(0),
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final day = value.toInt();
                  if (day % 5 != 0 && day != 1) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  );
                },
                reservedSize: 20,
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
              color: theme.colorScheme.onSurface.withOpacity(0.08),
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
                  width: 8,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxVal * 1.2,
                    color: theme.colorScheme.primary.withOpacity(0.08),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 8),
          Text(
            'No data yet',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
