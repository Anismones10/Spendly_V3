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
import '../widgets/empty_state.dart';
import 'calendar_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with TickerProviderStateMixin {
  late TabController _mainTabController;   // Expense | Income
  late TabController _expenseTabController; // Overview | Categories | Compare | Calendar
  late TabController _incomeTabController;  // Overview | By Source | Trend

  int _touchedPieIndex = -1;
  int _touchedIncomePieIndex = -1;
  String _comparePeriod = 'month';

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _expenseTabController = TabController(length: 4, vsync: this);
    _incomeTabController = TabController(length: 3, vsync: this);

    _mainTabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _expenseTabController.dispose();
    _incomeTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final expenses = context.watch<ExpenseProvider>();
    final income = context.watch<IncomeProvider>();
    final settings = context.watch<SettingsProvider>();
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        title: const Text('Statistics',
            style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              // ── Top: Expense | Income ───────────────────────────────
              TabBar(
                controller: _mainTabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.4),
                indicatorColor: theme.colorScheme.primary,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: 'Expense'),
                  Tab(text: 'Income'),
                ],
              ),
              // ── Sub tabs ────────────────────────────────────────────
              if (_mainTabController.index == 0)
                TabBar(
                  controller: _expenseTabController,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.4),
                  indicatorColor: theme.colorScheme.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Categories'),
                    Tab(text: 'Compare'),
                    Tab(text: 'Calendar'),
                  ],
                )
              else
                TabBar(
                  controller: _incomeTabController,
                  labelColor: const Color(0xFF2ECC71),
                  unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.4),
                  indicatorColor: const Color(0xFF2ECC71),
                  indicatorSize: TabBarIndicatorSize.label,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'By Source'),
                    Tab(text: 'Trend'),
                  ],
                ),
            ],
          ),
        ),
      ),
      body: _mainTabController.index == 0
          // ── Expense sub-tabs ────────────────────────────────────────
          ? TabBarView(
              controller: _expenseTabController,
              children: [
                _OverviewTab(expenses: expenses, settings: settings, now: now),
                _CategoriesTab(
                  expenses: expenses, settings: settings, now: now,
                  touchedIndex: _touchedPieIndex,
                  onTouch: (i) => setState(() => _touchedPieIndex = i),
                ),
                _CompareTab(
                  expenses: expenses, settings: settings, now: now,
                  period: _comparePeriod,
                  onPeriodChanged: (p) => setState(() => _comparePeriod = p),
                ),
                const CalendarScreen(embedded: true),
              ],
            )
          // ── Income sub-tabs ─────────────────────────────────────────
          : TabBarView(
              controller: _incomeTabController,
              children: [
                _IncomeOverviewTab(income: income, expenses: expenses, settings: settings, now: now),
                _IncomeBySourceTab(
                  income: income, settings: settings, now: now,
                  touchedIndex: _touchedIncomePieIndex,
                  onTouch: (i) => setState(() => _touchedIncomePieIndex = i),
                ),
                _IncomeTrendTab(income: income, settings: settings, now: now),
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

  const _OverviewTab({
    required this.expenses,
    required this.settings,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = settings.currencySymbol;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final incomeProvider = context.watch<IncomeProvider>();

    final thisMonth = expenses.getTotalForMonth(now.year, now.month);
    final lastMonth = expenses.getTotalForMonth(
      now.month == 1 ? now.year - 1 : now.year,
      now.month == 1 ? 12 : now.month - 1,
    );
    final thisWeek = expenses.getTotalForWeek();
    final today = expenses.getTotalForDay(now);
    final thisMonthIncome =
        incomeProvider.getTotalForMonth(now.year, now.month);
    final balance = thisMonthIncome - thisMonth;

    final dailyTotals = expenses.getDailyTotals(now.year, now.month);
    final maxVal = dailyTotals.isEmpty
        ? 1.0
        : dailyTotals.values.reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Summary cards ──────────────────────────────────────────────────
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
              ).animate().fadeIn(delay: 80.ms, duration: 400.ms).slideY(begin: 0.2),
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
              ).animate().fadeIn(delay: 160.ms, duration: 400.ms).slideY(begin: 0.2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Today',
                value: AppUtils.formatAmount(today, symbol),
                icon: Icons.today_rounded,
                color: const Color(0xFFEF6C00),
              ).animate().fadeIn(delay: 240.ms, duration: 400.ms).slideY(begin: 0.2),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Income vs Expense this month ───────────────────────────────────
        if (thisMonthIncome > 0)
          Container(
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
                Text('This Month Summary',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.7))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Income',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5))),
                            Text(AppUtils.formatAmount(thisMonthIncome, symbol),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2ECC71))),
                          ]),
                    ),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Balance',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5))),
                            Text(
                              '${balance >= 0 ? '+' : ''}${AppUtils.formatAmount(balance.abs(), symbol)}',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: balance >= 0
                                      ? const Color(0xFF2ECC71)
                                      : const Color(0xFFE57373)),
                            ),
                          ]),
                    ),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Expenses',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5))),
                            Text(AppUtils.formatAmount(thisMonth, symbol),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFE57373))),
                          ]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(children: [
                    Container(
                        height: 10,
                        color:
                            const Color(0xFF2ECC71).withOpacity(0.12)),
                    FractionallySizedBox(
                      widthFactor: thisMonthIncome > 0
                          ? (thisMonth / thisMonthIncome).clamp(0.0, 1.0)
                          : 0,
                      child: Container(
                          height: 10,
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
                  style: TextStyle(
                      fontSize: 11,
                      color:
                          theme.colorScheme.onSurface.withOpacity(0.4)),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 280.ms),

        const SizedBox(height: 20),

        // ── Month vs last month ────────────────────────────────────────────
        _buildCompareCard(context, thisMonth, lastMonth, symbol, isDark),

        const SizedBox(height: 20),

        // ── Daily bar chart ────────────────────────────────────────────────
        if (dailyTotals.isNotEmpty) ...[
          Text('Daily Spending — ${AppUtils.formatMonthYear(now)}',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          Builder(builder: (context) {
            final daysInMonth =
                DateTime(now.year, now.month + 1, 0).day;
            final chartMax = maxVal * 1.3;
            final double yInterval =
                maxVal > 0 ? (maxVal / 4).ceilToDouble() : 100.0;
            const double barWidth = 14.0;
            const double barSpacing = 8.0;
            const double leftAxisWidth = 52.0;
            final double chartWidth = leftAxisWidth +
                (daysInMonth * (barWidth + barSpacing)) +
                16;

            final hScrollController = ScrollController();

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
              child: Scrollbar(
                controller: hScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: hScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 12),
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
                              getTooltipColor: (_) => theme
                                  .colorScheme.primary
                                  .withOpacity(0.9),
                              getTooltipItem: (g, gi, rod, ri) =>
                                  BarTooltipItem(
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
                                  final hasExpense =
                                      dailyTotals.containsKey(d);
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(top: 6),
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
                                reservedSize: leftAxisWidth,
                                interval: yInterval,
                                getTitlesWidget: (v, meta) {
                                  if (v == 0) {
                                    return const SizedBox.shrink();
                                  }
                                  final label = v >= 1000
                                      ? '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}k'
                                      : v.toStringAsFixed(0);
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(right: 4),
                                    child: Text(label,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.45),
                                        )),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: yInterval,
                            getDrawingHorizontalLine: (v) => FlLine(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.06),
                              strokeWidth: 1,
                            ),
                          ),
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
                                      ? theme.colorScheme.primary
                                      : Colors.transparent,
                                  width: barWidth,
                                  borderRadius:
                                      const BorderRadius.vertical(
                                          top: Radius.circular(4)),
                                  backDrawRodData:
                                      BackgroundBarChartRodData(
                                    show: value > 0,
                                    toY: chartMax,
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.07),
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
            color: isMore
                ? const Color(0xFFE57373)
                : const Color(0xFF2ECC71),
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
                      final pct = (e.value.value / total * 100)
                          .toStringAsFixed(1);
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
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(cat?.name ?? e.key,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text('$pct%',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: color)),
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
            style:
                TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 12),

        ...entries.asMap().entries.map((e) {
          final cat = categories.getById(e.value.key);
          final color = cat != null
              ? Color(cat.colorValue)
              : theme.colorScheme.primary;
          final pct = (e.value.value / total * 100);
          final isHighlighted = e.key == touchedIndex;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.all(isHighlighted ? 16 : 14),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? color.withOpacity(0.12)
                  : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isHighlighted
                    ? color.withOpacity(0.5)
                    : Colors.transparent,
                width: 1.5,
              ),
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
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(CategoryIcons.resolve(cat?.icon ?? ''),
                          color: color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
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
                    Text('${pct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: isHighlighted
                              ? color
                              : theme.colorScheme.onSurface
                                  .withOpacity(0.4),
                        )),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: isHighlighted ? 8 : 6,
                    backgroundColor: color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
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

    final List<_PeriodData> data = [];
    if (period == 'month') {
      for (int i = 5; i >= 0; i--) {
        final d = DateTime(now.year, now.month - i, 1);
        final total = expenses.getTotalForMonth(d.year, d.month);
        data.add(_PeriodData(label: _shortMonth(d.month), total: total));
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
                        color: theme.colorScheme.onSurface.withOpacity(0.06),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: data.asMap().entries.map((e) {
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

        ...data.asMap().entries.map((e) {
          final isLatest = e.key == data.length - 1;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isLatest
                  ? theme.colorScheme.primary.withOpacity(0.08)
                  : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
              borderRadius: BorderRadius.circular(14),
              border: isLatest
                  ? Border.all(
                      color:
                          theme.colorScheme.primary.withOpacity(0.3))
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
                    color: isLatest ? theme.colorScheme.primary : null,
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
      {required this.label, required this.selected, required this.onTap});

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
            color: selected ? Colors.white : theme.colorScheme.primary,
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

// ── Income Overview Tab ───────────────────────────────────────────────────────

class _IncomeOverviewTab extends StatelessWidget {
  final IncomeProvider income;
  final ExpenseProvider expenses;
  final SettingsProvider settings;
  final DateTime now;

  const _IncomeOverviewTab({
    required this.income,
    required this.expenses,
    required this.settings,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final symbol = settings.currencySymbol;

    final monthlyIncome = income.getTotalForMonth(now.year, now.month);
    final monthlyExpenses = expenses.getTotalForMonth(now.year, now.month);
    final saved = monthlyIncome - monthlyExpenses;
    final savingsRate = monthlyIncome > 0
        ? ((saved / monthlyIncome) * 100).clamp(0.0, 100.0)
        : 0.0;

    // Last 6 months bar data
    final barData = List.generate(6, (i) {
      final date = DateTime(now.year, now.month - 5 + i);
      return _IncomeBar(
        month: _shortMonth(date.month),
        income: income.getTotalForMonth(date.year, date.month),
        expense: expenses.getTotalForMonth(date.year, date.month),
      );
    });

    final maxY = barData.fold(0.0, (max, b) {
      final m = b.income > b.expense ? b.income : b.expense;
      return m > max ? m : max;
    });
    final safeMax = maxY == 0 ? 100.0 : maxY * 1.25;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary cards row
        Row(
          children: [
            Expanded(child: _StatMiniCard(
              label: 'Income', value: AppUtils.formatAmount(monthlyIncome, symbol),
              icon: Icons.arrow_downward_rounded, color: const Color(0xFF2ECC71),
              isDark: isDark,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatMiniCard(
              label: 'Expenses', value: AppUtils.formatAmount(monthlyExpenses, symbol),
              icon: Icons.arrow_upward_rounded, color: const Color(0xFFE57373),
              isDark: isDark,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatMiniCard(
              label: 'Saved', value: AppUtils.formatAmount(saved.abs(), symbol),
              icon: saved >= 0 ? Icons.savings_rounded : Icons.warning_rounded,
              color: saved >= 0 ? const Color(0xFF4A90E2) : const Color(0xFFFF9800),
              isDark: isDark,
            )),
          ],
        ),

        const SizedBox(height: 20),

        // Savings rate
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Savings Rate',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text('${savingsRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 20,
                        color: savingsRate >= 20
                            ? const Color(0xFF2ECC71)
                            : savingsRate >= 10
                                ? const Color(0xFFFF9800)
                                : const Color(0xFFE57373),
                      )),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: savingsRate / 100,
                  minHeight: 10,
                  backgroundColor: Colors.grey.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    savingsRate >= 20
                        ? const Color(0xFF2ECC71)
                        : savingsRate >= 10
                            ? const Color(0xFFFF9800)
                            : const Color(0xFFE57373),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                savingsRate >= 20
                    ? '🎉 Excellent! You save more than 20% of income.'
                    : savingsRate >= 10
                        ? '👍 Good. Aim for 20%+ savings rate.'
                        : savingsRate > 0
                            ? '⚠️ Low savings rate. Try reducing expenses.'
                            : '❌ Spending exceeds income this month.',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 20),

        // Income vs Expense bar chart
        Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Income vs Expenses',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: BarChart(BarChartData(
                  maxY: safeMax,
                  minY: 0,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 10,
                      getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                        '$symbol${rod.toY.toStringAsFixed(0)}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(barData[v.toInt()].month,
                          style: TextStyle(fontSize: 11,
                            color: theme.colorScheme.onSurface.withOpacity(0.5))),
                      ),
                    )),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true, drawVerticalLine: false,
                    horizontalInterval: safeMax / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: theme.colorScheme.onSurface.withOpacity(0.07), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: barData.asMap().entries.map((e) =>
                    BarChartGroupData(x: e.key, barRods: [
                      BarChartRodData(
                        toY: e.value.income, width: 10,
                        borderRadius: BorderRadius.circular(6),
                        color: const Color(0xFF2ECC71),
                      ),
                      BarChartRodData(
                        toY: e.value.expense, width: 10,
                        borderRadius: BorderRadius.circular(6),
                        color: const Color(0xFFE57373),
                      ),
                    ]),
                  ).toList(),
                )),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ChartLegend(color: const Color(0xFF2ECC71), label: 'Income'),
                  const SizedBox(width: 20),
                  _ChartLegend(color: const Color(0xFFE57373), label: 'Expenses'),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  String _shortMonth(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }
}

// ── Income By Source Tab ──────────────────────────────────────────────────────

class _IncomeBySourceTab extends StatelessWidget {
  final IncomeProvider income;
  final SettingsProvider settings;
  final DateTime now;
  final int touchedIndex;
  final ValueChanged<int> onTouch;

  const _IncomeBySourceTab({
    required this.income,
    required this.settings,
    required this.now,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final symbol = settings.currencySymbol;
    final sourceTotals = income.getSourceTotals(now.year, now.month);
    final total = sourceTotals.values.fold(0.0, (a, b) => a + b);

    const colors = [
      Color(0xFF2ECC71), Color(0xFF4A90E2), Color(0xFFFF9800),
      Color(0xFF9C27B0), Color(0xFFE57373), Color(0xFF00BCD4),
      Color(0xFF6C63FF), Color(0xFFFFBE76),
    ];

    final entries = sourceTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return const Center(child: EmptyState(
        icon: Icons.pie_chart_rounded,
        title: 'No Income This Month',
        subtitle: 'Add income to see breakdown by source.',
      ));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Donut chart
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            children: [
              const Text('Income by Source',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: PieChart(PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 55,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) => onTouch(
                      response?.touchedSection?.touchedSectionIndex ?? -1),
                  ),
                  sections: entries.asMap().entries.map((e) {
                    final isTouched = e.key == touchedIndex;
                    final color = colors[e.key % colors.length];
                    final pct = total > 0 ? (e.value.value / total * 100) : 0;
                    return PieChartSectionData(
                      color: color,
                      value: e.value.value,
                      radius: isTouched ? 65 : 55,
                      title: '${pct.round()}%',
                      titleStyle: TextStyle(
                        fontSize: isTouched ? 14 : 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                )),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 16),

        // Source list
        ...entries.asMap().entries.map((e) {
          final color = colors[e.key % colors.length];
          final pct = total > 0 ? (e.value.value / total * 100) : 0.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
            ),
            child: Row(
              children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.value.key,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct / 100,
                          minHeight: 5,
                          backgroundColor: color.withOpacity(0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(AppUtils.formatAmount(e.value.value, symbol),
                        style: TextStyle(fontWeight: FontWeight.w700,
                            fontSize: 14, color: color)),
                    Text('${pct.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 11,
                            color: theme.colorScheme.onSurface.withOpacity(0.4))),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: ((e.key + 1) * 60).ms).slideX(begin: 0.1);
        }),
      ],
    );
  }
}

// ── Income Trend Tab ──────────────────────────────────────────────────────────

class _IncomeTrendTab extends StatelessWidget {
  final IncomeProvider income;
  final SettingsProvider settings;
  final DateTime now;

  const _IncomeTrendTab({
    required this.income,
    required this.settings,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final symbol = settings.currencySymbol;

    // Last 12 months
    final months = List.generate(12, (i) {
      final date = DateTime(now.year, now.month - 11 + i);
      return _MonthIncome(
        label: _shortMonth(date.month),
        amount: income.getTotalForMonth(date.year, date.month),
      );
    });

    final maxY = months.fold(0.0, (max, m) => m.amount > max ? m.amount : max);
    final safeMax = maxY == 0 ? 100.0 : maxY * 1.25;

    // Totals
    final last3 = months.sublist(9).fold(0.0, (s, m) => s + m.amount);
    final prev3 = months.sublist(6, 9).fold(0.0, (s, m) => s + m.amount);
    final trend = prev3 > 0 ? ((last3 - prev3) / prev3 * 100) : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Trend summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: trend >= 0
                  ? [const Color(0xFF2ECC71), const Color(0xFF27AE60)]
                  : [const Color(0xFFE57373), const Color(0xFFEF5350)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (trend >= 0 ? const Color(0xFF2ECC71) : const Color(0xFFE57373))
                    .withOpacity(0.3),
                blurRadius: 16, offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                trend >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: Colors.white, size: 36,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${trend >= 0 ? '+' : ''}${trend.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      trend >= 0
                          ? 'Income up vs last quarter'
                          : 'Income down vs last quarter',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 20),

        // 12-month line chart
        Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('12-Month Income Trend',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: LineChart(LineChartData(
                  minY: 0, maxY: safeMax,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipRoundedRadius: 10,
                      getTooltipItems: (spots) => spots.map((s) =>
                        LineTooltipItem(
                          '${months[s.x.toInt()].label}\n$symbol${s.y.toStringAsFixed(0)}',
                          const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ).toList(),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true, interval: 2,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= months.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(months[idx].label,
                            style: TextStyle(fontSize: 10,
                              color: theme.colorScheme.onSurface.withOpacity(0.5))),
                        );
                      },
                    )),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true, drawVerticalLine: false,
                    horizontalInterval: safeMax / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: theme.colorScheme.onSurface.withOpacity(0.07), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: months.asMap().entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.amount))
                          .toList(),
                      isCurved: true,
                      color: const Color(0xFF2ECC71),
                      barWidth: 3,
                      dotData: FlDotData(
                        getDotPainter: (spot, pct, bar, idx) =>
                          FlDotCirclePainter(
                            radius: idx == months.length - 1 ? 5 : 3,
                            color: const Color(0xFF2ECC71),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF2ECC71).withOpacity(0.3),
                            const Color(0xFF2ECC71).withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                )),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 150.ms),
      ],
    );
  }

  String _shortMonth(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _IncomeBar {
  final String month;
  final double income;
  final double expense;
  const _IncomeBar({required this.month, required this.income, required this.expense});
}

class _MonthIncome {
  final String label;
  final double amount;
  const _MonthIncome({required this.label, required this.amount});
}

class _StatMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatMiniCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label,
            style: TextStyle(fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 12, height: 12,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 11,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
    ]);
  }
}
