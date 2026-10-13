import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_utils.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen>
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
    final now = DateTime.now();
    final expenses = context.watch<ExpenseProvider>();
    final categories = context.watch<CategoryProvider>();
    final settings = context.watch<SettingsProvider>();
    final symbol = settings.currencySymbol;

    final catTotals = expenses.getCategoryTotals(now.year, now.month);
    final dailyTotals = expenses.getDailyTotals(now.year, now.month);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        title: const Text('Charts'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'By Category'),
            Tab(text: 'By Day'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pie chart - by category
          _buildCategoryChart(context, catTotals, categories, symbol, isDark),
          // Bar chart - by day
          _buildDailyChart(context, dailyTotals, symbol, isDark, now),
        ],
      ),
    );
  }

  Widget _buildCategoryChart(BuildContext context, Map<String, double> totals,
      CategoryProvider cats, String symbol, bool isDark) {
    if (totals.isEmpty) {
      return const Center(child: Text('No data yet'));
    }

    final entries = totals.entries.toList();
    final total = totals.values.fold(0.0, (a, b) => a + b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06), blurRadius: 12)
              ],
            ),
            child: Column(
              children: [
                const Text('Spending by Category',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 24),
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      sections: entries.map((e) {
                        final cat = cats.getById(e.key);
                        final color =
                            cat != null ? Color(cat.colorValue) : Colors.grey;
                        final pct = (e.value / total * 100).round();
                        return PieChartSectionData(
                          color: color,
                          value: e.value,
                          title: '$pct%',
                          radius: 80,
                          titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                        );
                      }).toList(),
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Legend
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: entries.map((e) {
                    final cat = cats.getById(e.key);
                    final color =
                        cat != null ? Color(cat.colorValue) : Colors.grey;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${cat?.icon ?? ''} ${cat?.name ?? 'Uncategorized'}: ${AppUtils.formatAmount(e.value, symbol)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChart(BuildContext context, Map<int, double> dailyTotals,
      String symbol, bool isDark, DateTime now) {
    if (dailyTotals.isEmpty) {
      return const Center(child: Text('No data yet'));
    }

    final days = dailyTotals.keys.toList()..sort();
    final maxVal = dailyTotals.values.reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)
          ],
        ),
        child: Column(
          children: [
            Text(
              'Daily Spending — ${AppUtils.formatMonthYear(now)}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 260,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                          BarTooltipItem(
                        '${AppUtils.formatAmount(rod.toY, symbol)}\nDay ${group.x}',
                        const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) => Text(
                          '${val.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        reservedSize: 20,
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    horizontalInterval: maxVal / 4,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: days.map((day) {
                    final val = dailyTotals[day] ?? 0;
                    return BarChartGroupData(
                      x: day,
                      barRods: [
                        BarChartRodData(
                          toY: val,
                          color: Theme.of(context).colorScheme.primary,
                          width: 10,
                          borderRadius: BorderRadius.circular(6),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxVal * 1.2,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
