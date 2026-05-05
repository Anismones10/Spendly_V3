import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_utils.dart';
import '../providers/income_provider.dart';
import '../utils/category_icons.dart';
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
        title: const Text('Statistics',
            style: TextStyle(fontWeight: FontWeight.w700)),
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
          _OverviewTab(expenses: expenses, settings: settings, now: now, monthlyBudget: settings.monthlyBudget),
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
  final double monthlyBudget;

  const _OverviewTab(
      {required this.expenses,
      required this.settings,
      required this.now,
      this.monthlyBudget = 0});

  @override
  Widget build(BuildContext context) {
    final symbol = settings.currencySymbol;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final incomeProvider = context.watch<IncomeProvider>();

    final thisMonth = expenses.getTotalForMonth(now.year, now.month);
    final lastMonth = expenses.getTotalForMonth(
        now.month == 1 ? now.year - 1 : now.year,
        now.month == 1 ? 12 : now.month - 1);
    final thisWeek = expenses.getTotalForWeek();
    final today = expenses.getTotalForDay(now);
    final thisMonthIncome = incomeProvider.getTotalForMonth(now.year, now.month);
    final lastMonthIncome = incomeProvider.getTotalForMonth(
        now.month == 1 ? now.year - 1 : now.year,
        now.month == 1 ? 12 : now.month - 1);
    final balance = thisMonthIncome - thisMonth;

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

        const SizedBox(height: 16),

        // ── Income vs Expense this month ───────────────────────
        if (thisMonthIncome > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This Month Summary',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.7))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Income', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                        Text(AppUtils.formatAmount(thisMonthIncome, symbol),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2ECC71))),
                      ]),
                    ),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        Text('Balance', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                        Text(
                          '${balance >= 0 ? '+' : ''}${AppUtils.formatAmount(balance.abs(), symbol)}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                              color: balance >= 0 ? const Color(0xFF2ECC71) : const Color(0xFFE57373)),
                        ),
                      ]),
                    ),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('Expenses', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                        Text(AppUtils.formatAmount(thisMonth, symbol),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFE57373))),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Income bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(children: [
                    Container(height: 10, color: const Color(0xFF2ECC71).withOpacity(0.12)),
                    FractionallySizedBox(
                      widthFactor: thisMonthIncome > 0
                          ? (thisMonth / thisMonthIncome).clamp(0.0, 1.0)
                          : 0,
                      child: Container(height: 10,
                          decoration: BoxDecoration(
                            color: thisMonth > thisMonthIncome
                                ? const Color(0xFFE57373)
                                : const Color(0xFF2ECC71),
                            borderRadius: BorderRadius.circular(6),
                          )),
                    ),
                  ]),
                ),
                const SizedBox(height: 4),
                Text(
                  thisMonthIncome > 0
                      ? '${(thisMonth / thisMonthIncome * 100).toStringAsFixed(1)}% of income spent'
                      : '',
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 280.ms),

        const SizedBox(height: 20),

        // ── Month vs last month comparison ─────────────────────
        _buildCompareCard(
            context, thisMonth, lastMonth, symbol, isDark),

        const SizedBox(height: 20),

        // ── Daily bar chart ────────────────────────────────────
        if (dailyTotals.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Spending — ${AppUtils.formatMonthYear(now)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              if (monthlyBudget > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Budget: ${AppUtils.formatAmount(monthlyBudget, symbol)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Builder(builder: (context) {
            // Y-axis: divide by monthly budget into 4 lines, or use maxVal
            final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
            final dailyLimit = monthlyBudget > 0 ? monthlyBudget / daysInMonth : 0.0;

            // Calculate smart Y-axis max and intervals
            final double chartMax;
            final double yInterval;
            if (monthlyBudget > 0) {
              // Use budget-based Y axis: 4 equal intervals up to budget/days*2
              final budgetStep = (monthlyBudget / 4).ceilToDouble();
              chartMax = budgetStep * 5;
              yInterval = budgetStep;
            } else {
              chartMax = maxVal * 1.3;
              yInterval = maxVal > 0 ? (maxVal / 4).ceilToDouble() : 100;
            }

            // Bar color based on daily limit
            Color barColor(double value) {
              if (dailyLimit <= 0) return theme.colorScheme.primary;
              if (value >= dailyLimit * 1.5) return const Color(0xFFE57373); // red
              if (value >= dailyLimit) return const Color(0xFFFF9800);       // orange
              if (value >= dailyLimit * 0.75) return const Color(0xFFF39C12); // amber
              return const Color(0xFF2ECC71);                                  // green
            }

            // Each bar is 18px wide + 4px gap = 22px per day
            // 31 days × 22 = 682px total chart width
            const double barWidth = 14.0;
            const double barSpacing = 8.0;
            const double leftAxisWidth = 52.0;
            final double chartWidth =
                leftAxisWidth + (daysInMonth * (barWidth + barSpacing)) + 16;

            final hScrollController = ScrollController();
            final vScrollController = ScrollController();

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Legend row ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Wrap(
                      spacing: 16,
                      children: [
                        _LegendDot(color: const Color(0xFF2ECC71), label: 'Safe'),
                        _LegendDot(color: const Color(0xFFF39C12), label: 'Near limit'),
                        _LegendDot(color: const Color(0xFFFF9800), label: 'Over limit'),
                        _LegendDot(color: const Color(0xFFE57373), label: 'High'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Scrollable chart area ─────────────────────
                  Scrollbar(
                    controller: hScrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: SingleChildScrollView(
                      controller: hScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Scrollbar(
                        controller: vScrollController,
                        thumbVisibility: false,
                        notificationPredicate: (n) => n.depth == 1,
                        child: SingleChildScrollView(
                          controller: vScrollController,
                          scrollDirection: Axis.vertical,
                          child: SizedBox(
                            width: chartWidth,
                            height: 240,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                              child: BarChart(
                                BarChartData(
                                  maxY: chartMax,
                                  groupsSpace: barSpacing,
                                  barTouchData: BarTouchData(
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipColor: (_) =>
                                          theme.colorScheme.primary.withOpacity(0.9),
                                      getTooltipItem: (g, gi, rod, ri) => BarTooltipItem(
                                        'Day ${g.x}\n${AppUtils.formatAmount(rod.toY, symbol)}',
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
                                        reservedSize: 26,
                                        getTitlesWidget: (v, meta) {
                                          final d = v.toInt();
                                          final hasExpense = dailyTotals.containsKey(d);
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Text(
                                              '$d',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: hasExpense
                                                    ? FontWeight.w700
                                                    : FontWeight.w400,
                                                color: hasExpense
                                                    ? theme.colorScheme.primary
                                                    : theme.colorScheme.onSurface
                                                        .withOpacity(0.35),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: leftAxisWidth.toInt().toDouble(),
                                        interval: yInterval,
                                        getTitlesWidget: (v, meta) {
                                          if (v == 0) return const SizedBox.shrink();
                                          final label = v >= 1000
                                              ? '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}k'
                                              : v.toStringAsFixed(0);
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 4),
                                            child: Text(
                                              label,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w500,
                                                color: theme.colorScheme.onSurface
                                                    .withOpacity(0.45),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    topTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: yInterval,
                                    getDrawingHorizontalLine: (v) {
                                      if (dailyLimit > 0 &&
                                          (v - dailyLimit).abs() < yInterval * 0.15) {
                                        return FlLine(
                                          color: const Color(0xFFFF9800).withOpacity(0.5),
                                          strokeWidth: 1.5,
                                          dashArray: [6, 4],
                                        );
                                      }
                                      return FlLine(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.06),
                                        strokeWidth: 1,
                                      );
                                    },
                                  ),
                                  extraLinesData: dailyLimit > 0
                                      ? ExtraLinesData(
                                          horizontalLines: [
                                            HorizontalLine(
                                              y: dailyLimit,
                                              color: const Color(0xFFFF9800)
                                                  .withOpacity(0.7),
                                              strokeWidth: 1.5,
                                              dashArray: [6, 4],
                                              label: HorizontalLineLabel(
                                                show: true,
                                                alignment: Alignment.topRight,
                                                padding: const EdgeInsets.only(
                                                    right: 4, bottom: 2),
                                                style: const TextStyle(
                                                  color: Color(0xFFFF9800),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                labelResolver: (_) => 'Daily limit',
                                              ),
                                            ),
                                          ],
                                        )
                                      : null,
                                  borderData: FlBorderData(show: false),
                                  barGroups: List.generate(daysInMonth, (i) {
                                    final day = i + 1;
                                    final value = dailyTotals[day] ?? 0.0;
                                    return BarChartGroupData(
                                      x: day,
                                      barRods: [
                                        BarChartRodData(
                                          toY: value,
                                          color: value > 0
                                              ? barColor(value)
                                              : Colors.transparent,
                                          width: barWidth,
                                          borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(4)),
                                          backDrawRodData: BackgroundBarChartRodData(
                                            show: value > 0,
                                            toY: chartMax,
                                            color: barColor(value).withOpacity(0.07),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
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

    final totals = expenses.getCategoryTotals(now.year, now.month);
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
        // ── Pie chart with legend beside it ──────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
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
              // Pie chart
              SizedBox(
                width: 160,
                height: 160,
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
                    sectionsSpace: 2,
                    centerSpaceRadius: 36,
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
                        radius: isTouched ? 65 : 52,
                        titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Legend beside pie chart
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: entries.take(6).map((e) {
                    final cat = categories.getById(e.key);
                    final color = cat != null
                        ? Color(cat.colorValue)
                        : theme.colorScheme.primary;
                    final pct =
                        (e.value / total * 100).toStringAsFixed(1);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cat?.name ?? e.key,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$pct%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 20),

        const Text('Breakdown',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 12),

        // ── Breakdown list — highlighted when pie slice is touched ────
        ...entries.asMap().entries.map((e) {
          final cat = categories.getById(e.value.key);
          final color = cat != null
              ? Color(cat.colorValue)
              : theme.colorScheme.primary;
          final pct = (e.value.value / total * 100);
          final isHighlighted = e.key == touchedIndex;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            margin: const EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.all(isHighlighted ? 16 : 14),
            decoration: BoxDecoration(
              // Highlighted row gets colored background
              color: isHighlighted
                  ? color.withOpacity(0.12)
                  : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isHighlighted ? color.withOpacity(0.5) : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                    color: isHighlighted
                        ? color.withOpacity(0.15)
                        : Colors.black.withOpacity(0.04),
                    blurRadius: isHighlighted ? 12 : 8)
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // ── Icon instead of emoji key ──────────────────
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        CategoryIcons.resolve(cat?.icon ?? ''),
                        color: color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        // ── Just the name, NO icon key prefix ──────
                        cat?.name ?? e.value.key,
                        style: TextStyle(
                          fontWeight: isHighlighted
                              ? FontWeight.w800
                              : FontWeight.w600,
                          fontSize: isHighlighted ? 15 : 14,
                          color: isHighlighted ? color : null,
                        ),
                      ),
                    ),
                    Text(
                      AppUtils.formatAmount(e.value.value, symbol),
                      style: TextStyle(
                        fontWeight: isHighlighted
                            ? FontWeight.w800
                            : FontWeight.w700,
                        color: color,
                        fontSize: isHighlighted ? 15 : 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isHighlighted
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isHighlighted
                            ? color
                            : theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: isHighlighted ? 8 : 6,
                      backgroundColor: color.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (e.key * 60).ms).slideX(begin: 0.1);
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

// ── Legend dot helper ─────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            )),
      ],
    );
  }
}
