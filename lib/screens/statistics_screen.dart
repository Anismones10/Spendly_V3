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
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
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
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
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

class _OverviewTab extends StatefulWidget {
  final ExpenseProvider expenses;
  final SettingsProvider settings;
  final DateTime now;

  const _OverviewTab({
    required this.expenses,
    required this.settings,
    required this.now,
  });

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    // Start at current month
    _selectedMonth = DateTime(widget.now.year, widget.now.month);
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.month == 1 ? _selectedMonth.year - 1 : _selectedMonth.year,
        _selectedMonth.month == 1 ? 12 : _selectedMonth.month - 1,
      );
    });
  }

  void _nextMonth() {
    final now = widget.now;
    final isCurrentMonth = _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;
    if (!isCurrentMonth) {
      setState(() {
        _selectedMonth = DateTime(
          _selectedMonth.month == 12 ? _selectedMonth.year + 1 : _selectedMonth.year,
          _selectedMonth.month == 12 ? 1 : _selectedMonth.month + 1,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = widget.now;
    final expenses = widget.expenses;
    final settings = widget.settings;
    final symbol = settings.currencySymbol;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final incomeProvider = context.watch<IncomeProvider>();
    final categories = context.watch<CategoryProvider>();

    // Use _selectedMonth for all calculations
    final selYear  = _selectedMonth.year;
    final selMonth = _selectedMonth.month;

    final isCurrentMonth = selYear == now.year && selMonth == now.month;

    final thisMonth = expenses.getTotalForMonth(selYear, selMonth);
    final lastMonth = expenses.getTotalForMonth(
      selMonth == 1 ? selYear - 1 : selYear,
      selMonth == 1 ? 12 : selMonth - 1,
    );
    final thisWeek = expenses.getTotalForWeek();
    final today    = expenses.getTotalForDay(now);
    final thisMonthIncome = incomeProvider.getTotalForMonth(selYear, selMonth);
    final balance  = thisMonthIncome - thisMonth;

    final dailyTotals = expenses.getDailyTotals(selYear, selMonth);
    final maxVal = dailyTotals.isEmpty
        ? 1.0
        : dailyTotals.values.reduce((a, b) => a > b ? a : b);

    // Average daily spend
    final daysWithExpense = dailyTotals.values.where((v) => v > 0).length;
    final avgDaily = daysWithExpense > 0 ? thisMonth / daysWithExpense : 0.0;

    // Top 3 categories this month
    final catTotals = expenses.getCategoryTotals(selYear, selMonth);
    final topCats = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // vs last month
    final diff = thisMonth - lastMonth;
    final hasPrevData = lastMonth > 0;
    final pctStr = hasPrevData
        ? '${diff.abs() / lastMonth * 100 < 0.1 ? '0.0' : (diff.abs() / lastMonth * 100).toStringAsFixed(1)}%'
        : null;
    final isMore = diff > 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        // ── Month navigation ──────────────────────────────────────────
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: Icon(Icons.chevron_left_rounded,
                    color: theme.colorScheme.primary),
              ),
              Column(
                children: [
                  Text(
                    _monthName(selMonth),
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface),
                  ),
                  Text('$selYear',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withOpacity(0.45))),
                ],
              ),
              IconButton(
                onPressed: isCurrentMonth ? null : _nextMonth,
                icon: Icon(Icons.chevron_right_rounded,
                    color: isCurrentMonth
                        ? theme.colorScheme.onSurface.withOpacity(0.2)
                        : theme.colorScheme.primary),
              ),
            ],
          ),
        ),

        // ── 4 stat cards ──────────────────────────────────────────────
        Row(children: [
          Expanded(child: _StatCard(
            label: isCurrentMonth ? 'This Month' : _monthName(selMonth),
            value: AppUtils.formatAmount(thisMonth, symbol),
            icon: Icons.calendar_view_month_rounded, color: theme.colorScheme.primary,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2)),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(
            label: 'Last Month', value: AppUtils.formatAmount(lastMonth, symbol),
            icon: Icons.history_rounded, color: const Color(0xFF78909C),
          ).animate().fadeIn(delay: 80.ms, duration: 400.ms).slideY(begin: 0.2)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _StatCard(
            label: 'This Week', value: AppUtils.formatAmount(thisWeek, symbol),
            icon: Icons.date_range_rounded, color: const Color(0xFF26A69A),
          ).animate().fadeIn(delay: 160.ms, duration: 400.ms).slideY(begin: 0.2)),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(
            label: 'Today', value: AppUtils.formatAmount(today, symbol),
            icon: Icons.today_rounded, color: const Color(0xFFEF6C00),
          ).animate().fadeIn(delay: 240.ms, duration: 400.ms).slideY(begin: 0.2)),
        ]),

        const SizedBox(height: 16),

        // ── This month summary ─────────────────────────────────────────
        if (thisMonthIncome > 0)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This Month Summary',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                        color: theme.colorScheme.onSurface)),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _MiniStat(
                      label: 'Income', value: AppUtils.formatAmount(thisMonthIncome, symbol),
                      color: const Color(0xFF2ECC71))),
                  Expanded(child: _MiniStat(
                      label: 'Balance', align: TextAlign.center,
                      value: '${balance >= 0 ? '+' : ''}${AppUtils.formatAmount(balance.abs(), symbol)}',
                      color: balance >= 0 ? const Color(0xFF2ECC71) : const Color(0xFFE57373))),
                  Expanded(child: _MiniStat(
                      label: 'Expenses', align: TextAlign.end,
                      value: AppUtils.formatAmount(thisMonth, symbol),
                      color: const Color(0xFFE57373))),
                ]),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(children: [
                    Container(height: 8, color: const Color(0xFF2ECC71).withOpacity(0.12)),
                    FractionallySizedBox(
                      widthFactor: thisMonthIncome > 0
                          ? (thisMonth / thisMonthIncome).clamp(0.0, 1.0) : 0,
                      child: Container(height: 8,
                          decoration: BoxDecoration(
                              color: thisMonth > thisMonthIncome
                                  ? const Color(0xFFE57373) : const Color(0xFF2ECC71),
                              borderRadius: BorderRadius.circular(6))),
                    ),
                  ]),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '${(thisMonth / thisMonthIncome * 100).toStringAsFixed(1)}% of income spent',
                        style: TextStyle(fontSize: 11,
                            color: theme.colorScheme.onSurface.withOpacity(0.45))),
                    Text('Avg/day: ${AppUtils.formatAmount(avgDaily, symbol)}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary)),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 280.ms),

        const SizedBox(height: 16),

        // ── vs last month card ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isMore
                  ? [const Color(0xFFE57373).withOpacity(0.15), const Color(0xFFEF5350).withOpacity(0.05)]
                  : [const Color(0xFF2ECC71).withOpacity(0.15), const Color(0xFF27AE60).withOpacity(0.05)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isMore
                  ? const Color(0xFFE57373).withOpacity(0.3)
                  : const Color(0xFF2ECC71).withOpacity(0.3),
            ),
          ),
          child: Row(children: [
            Icon(
              isMore ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: isMore ? const Color(0xFFE57373) : const Color(0xFF2ECC71),
              size: 36,
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPrevData
                      ? (isMore
                      ? 'Spending up $pctStr vs last month'
                      : diff == 0
                      ? 'Same spending as last month'
                      : 'Spending down $pctStr vs last month')
                      : (thisMonth > 0
                      ? 'First month tracked — great start!'
                      : 'No expenses this month yet'),
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14,
                      color: isMore ? const Color(0xFFE57373) : const Color(0xFF2ECC71)),
                ),
                if (hasPrevData && diff != 0) ...[
                  const SizedBox(height: 4),
                  Text(
                      '${isMore ? '+' : '-'}${AppUtils.formatAmount(diff.abs(), symbol)} compared to last month',
                      style: TextStyle(fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.55))),
                ],
              ],
            )),
          ]),
        ).animate().fadeIn(delay: 320.ms),

        const SizedBox(height: 16),

        // ── Top categories ────────────────────────────────────────────
        if (topCats.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Top Categories',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 14),
                ...topCats.take(3).map((e) {
                  final cat = categories.getById(e.key);
                  final color = cat != null ? Color(cat.colorValue) : theme.colorScheme.primary;
                  final pct = thisMonth > 0 ? e.value / thisMonth : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [
                      Container(width: 36, height: 36,
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(CategoryIcons.resolve(cat?.icon ?? ''),
                              color: color, size: 18)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Falling back to e.key printed the raw category
                              // id for expenses with no category.
                              Text(cat?.name ?? 'Uncategorized',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              Text(AppUtils.formatAmount(e.value, symbol),
                                  style: TextStyle(fontWeight: FontWeight.w700,
                                      fontSize: 13, color: color)),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct, minHeight: 5,
                              backgroundColor: color.withOpacity(0.12),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ],
                      )),
                    ]),
                  );
                }),
              ],
            ),
          ).animate().fadeIn(delay: 360.ms),
          const SizedBox(height: 16),
        ],

        // ── Daily bar chart ────────────────────────────────────────────
        if (dailyTotals.isNotEmpty) ...[
          Row(children: [
            const Text('Daily Spending',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(width: 8),
            Text(AppUtils.formatMonthYear(_selectedMonth),
                style: TextStyle(fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.45))),
          ]),
          const SizedBox(height: 12),
          Builder(builder: (ctx) {
            final daysInMonth = DateTime(selYear, selMonth + 1, 0).day;
            final chartMax = maxVal > 0
                ? (maxVal * 1.25).ceilToDouble()
                : 100.0;
            // Round up to a clean interval
            final rawInterval = chartMax / 4;
            final yInterval = rawInterval <= 50
                ? (rawInterval / 10).ceil() * 10.0
                : rawInterval <= 500
                ? (rawInterval / 50).ceil() * 50.0
                : rawInterval <= 5000
                ? (rawInterval / 500).ceil() * 500.0
                : (rawInterval / 5000).ceil() * 5000.0;
            const double barWidth = 14.0;
            const double barSpacing = 8.0;
            const double leftAxisWidth = 44.0;
            final chartWidth = leftAxisWidth + (daysInMonth * (barWidth + barSpacing)) + 16;
            final hScrollController = ScrollController();

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12)],
              ),
              child: Scrollbar(
                controller: hScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: hScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: chartWidth, height: 240,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                      child: BarChart(BarChartData(
                        maxY: chartMax,
                        groupsSpace: barSpacing,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => theme.colorScheme.primary.withOpacity(0.9),
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            tooltipMargin: 6,
                            getTooltipItem: (g, gi, rod, ri) => BarTooltipItem(
                              'Day ${g.x}  ${AppUtils.formatAmount(rod.toY, symbol)}',
                              const TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w700, fontSize: 11),
                            ),
                          ),
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(sideTitles: SideTitles(
                            showTitles: true, reservedSize: 26,
                            getTitlesWidget: (v, meta) {
                              final d = v.toInt();
                              final isToday = isCurrentMonth && d == now.day;
                              final hasExpense = dailyTotals.containsKey(d);
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text('$d',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: isToday || hasExpense ? FontWeight.w800 : FontWeight.w400,
                                      color: isToday
                                          ? theme.colorScheme.primary
                                          : hasExpense
                                          ? theme.colorScheme.primary.withOpacity(0.7)
                                          : theme.colorScheme.onSurface.withOpacity(0.3),
                                    )),
                              );
                            },
                          )),
                          leftTitles: AxisTitles(sideTitles: SideTitles(
                            showTitles: true, reservedSize: leftAxisWidth,
                            interval: yInterval,
                            getTitlesWidget: (v, meta) {
                              if (v == 0) return const SizedBox.shrink();
                              // Skip if too close to chartMax to avoid duplicate
                              if (v > chartMax - yInterval * 0.5) return const SizedBox.shrink();
                              final label = v >= 1000
                                  ? '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}k'
                                  : v.toStringAsFixed(0);
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Text(label, style: TextStyle(fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurface.withOpacity(0.4))),
                              );
                            },
                          )),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true, drawVerticalLine: false,
                          horizontalInterval: yInterval,
                          getDrawingHorizontalLine: (v) => FlLine(
                              color: theme.colorScheme.onSurface.withOpacity(0.06), strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(daysInMonth, (i) {
                          final day = i + 1;
                          final value = dailyTotals[day] ?? 0.0;
                          final isToday = isCurrentMonth && day == now.day;
                          return BarChartGroupData(x: day, barRods: [
                            BarChartRodData(
                              toY: value,
                              color: isToday
                                  ? theme.colorScheme.primary
                                  : value > 0
                                  ? theme.colorScheme.primary.withOpacity(0.55)
                                  : Colors.transparent,
                              width: barWidth,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: value > 0,
                                toY: chartMax,
                                color: theme.colorScheme.primary.withOpacity(0.07),
                              ),
                            ),
                          ]);
                        }),
                      )),
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

  String _monthName(int m) {
    const names = ['January','February','March','April','May','June',
      'July','August','September','October','November','December'];
    return names[m - 1];
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final TextAlign align;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    this.align = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align == TextAlign.end
          ? CrossAxisAlignment.end
          : align == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            textAlign: align),
        Text(value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color),
            textAlign: align, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

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
      return const Center(child: EmptyState(
        icon: Icons.pie_chart_outline_rounded,
        title: 'No Expenses Yet',
        subtitle: 'Add expenses to see category breakdown.',
      ));
    }

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold(0.0, (s, e) => s + e.value);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Donut + right-side legend — same layout as By Source
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            children: [
              const Text('Expenses by Category',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Donut — constrained, hold to highlight, info in center
                  SizedBox(
                    width: 170, height: 170,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 45,
                          pieTouchData: PieTouchData(
                            longPressDuration: const Duration(milliseconds: 150),
                            touchCallback: (event, response) {
                              if (event is FlLongPressStart ||
                                  event is FlLongPressMoveUpdate) {
                                onTouch(response?.touchedSection
                                    ?.touchedSectionIndex ?? -1);
                              } else if (event is FlLongPressEnd ||
                                  event is FlPointerExitEvent ||
                                  event is FlTapUpEvent) {
                                onTouch(-1);
                              }
                            },
                          ),
                          sections: entries.asMap().entries.map((e) {
                            final isTouched = e.key == touchedIndex;
                            final cat = categories.getById(e.value.key);
                            final color = cat != null
                                ? Color(cat.colorValue)
                                : theme.colorScheme.primary;
                            return PieChartSectionData(
                              color: color,
                              value: e.value.value,
                              radius: isTouched ? 65 : 50,
                              title: '',
                              borderSide: isTouched
                                  ? BorderSide(color: color, width: 3)
                                  : BorderSide.none,
                            );
                          }).toList(),
                        )),
                        // Center overlay — shows when holding
                        if (touchedIndex >= 0 && touchedIndex < entries.length) ...[
                          Builder(builder: (_) {
                            final e = entries[touchedIndex];
                            final cat = categories.getById(e.key);
                            final color = cat != null
                                ? Color(cat.colorValue)
                                : theme.colorScheme.primary;
                            final pct = (e.value / total * 100);
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${pct.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w800,
                                        color: color)),
                                Text(AppUtils.formatAmount(e.value, symbol),
                                    style: TextStyle(
                                        fontSize: 10, fontWeight: FontWeight.w600,
                                        color: color.withOpacity(0.8))),
                              ],
                            );
                          }),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Right-side legend
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: entries.take(6).toList().asMap().entries.map((indexed) {
                        final i = indexed.key;
                        final e = indexed.value;
                        final cat = categories.getById(e.key);
                        final color = cat != null
                            ? Color(cat.colorValue)
                            : theme.colorScheme.primary;
                        final pct = (e.value / total * 100);
                        final isTouched = i == touchedIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: EdgeInsets.symmetric(
                              horizontal: isTouched ? 8 : 0,
                              vertical: isTouched ? 6 : 0),
                          decoration: BoxDecoration(
                            color: isTouched
                                ? color.withOpacity(0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: isTouched
                                ? Border.all(color: color.withOpacity(0.4))
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10, height: 10,
                                decoration: BoxDecoration(
                                    color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cat?.name ?? 'Uncategorized',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isTouched
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: isTouched
                                              ? color
                                              : theme.colorScheme.onSurface,
                                        ),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text(
                                        '${pct.toStringAsFixed(1)}% · ${AppUtils.formatAmount(e.value, symbol)}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isTouched
                                              ? color.withOpacity(0.8)
                                              : theme.colorScheme.onSurface.withOpacity(0.5),
                                        )),
                                  ],
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
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 16),

        // Breakdown list — same style as By Source list
        ...entries.asMap().entries.map((e) {
          final cat = categories.getById(e.value.key);
          final color = cat != null
              ? Color(cat.colorValue)
              : theme.colorScheme.primary;
          final pct = (e.value.value / total * 100);
          final isHeld = e.key == touchedIndex;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isHeld
                  ? color.withOpacity(isDark ? 0.15 : 0.10)
                  : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: isHeld
                  ? Border.all(color: color.withOpacity(0.5), width: 1.5)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: isHeld
                      ? color.withOpacity(0.25)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: isHeld ? 14 : 8,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(CategoryIcons.resolve(cat?.icon ?? ''),
                      color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat?.name ?? 'Uncategorized',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          )),
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
          ).animate().fadeIn(delay: (e.key * 60).ms).slideX(begin: 0.1);
        }),
      ],
    );
  }
}



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
    final color = theme.colorScheme.primary;

    final List<_PeriodData> data = [];
    if (period == 'month') {
      for (int i = 11; i >= 0; i--) {
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

    final maxVal = data.map((d) => d.total).fold(0.0, (a, b) => a > b ? a : b);
    final safeMax = maxVal == 0 ? 100.0 : maxVal * 1.25;

    // Quarter trend — safe with any data length
    final last3Start = (data.length - 3).clamp(0, data.length);
    final prev3Start = (data.length - 6).clamp(0, data.length);
    final prev3End = (data.length - 3).clamp(0, data.length);
    final last3 = data.sublist(last3Start).fold(0.0, (s, d) => s + d.total);
    final prev3 = prev3Start < prev3End
        ? data.sublist(prev3Start, prev3End).fold(0.0, (s, d) => s + d.total)
        : 0.0;
    final trend = prev3 > 0 ? ((last3 - prev3) / prev3 * 100) : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Period toggle
        Row(
          children: [
            Expanded(child: _ToggleBtn(
              label: 'Monthly', selected: period == 'month',
              onTap: () => onPeriodChanged('month'),
            )),
            const SizedBox(width: 12),
            Expanded(child: _ToggleBtn(
              label: 'Yearly', selected: period == 'year',
              onTap: () => onPeriodChanged('year'),
            )),
          ],
        ),
        const SizedBox(height: 16),

        // Trend summary card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: trend <= 0
                  ? [const Color(0xFF2ECC71), const Color(0xFF27AE60)]
                  : [const Color(0xFFE57373), const Color(0xFFEF5350)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (trend <= 0 ? const Color(0xFF2ECC71) : const Color(0xFFE57373))
                    .withOpacity(0.3),
                blurRadius: 16, offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                trend <= 0 ? Icons.trending_down_rounded : Icons.trending_up_rounded,
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
                      trend <= 0
                          ? 'Spending down vs last quarter 👍'
                          : 'Spending up vs last quarter ⚠️',
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 20),

        // Line chart
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
              Text(period == 'month' ? '12-Month Expense Trend' : '5-Year Expense Trend',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: maxVal == 0
                    ? Center(child: Text('No data yet',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4))))
                    : LineChart(LineChartData(
                  minY: 0, maxY: safeMax,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipRoundedRadius: 10,
                      getTooltipItems: (spots) => spots.map((s) =>
                          LineTooltipItem(
                            '${data[s.x.toInt()].label}\n$symbol${s.y.toStringAsFixed(0)}',
                            const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                      ).toList(),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true,
                      interval: period == 'month' ? 2 : 1,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= data.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(data[idx].label,
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
                      spots: data.asMap().entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.total))
                          .toList(),
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: FlDotData(
                        getDotPainter: (spot, pct, bar, idx) =>
                            FlDotCirclePainter(
                              radius: idx == data.length - 1 ? 5 : 3,
                              color: color,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.3),
                            color.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                )),
              ),
              const SizedBox(height: 16),
              // Monthly amounts below chart
              Wrap(
                spacing: 8, runSpacing: 8,
                children: data.asMap().entries.map((e) {
                  final isLatest = e.key == data.length - 1;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLatest
                          ? color.withOpacity(0.12)
                          : theme.colorScheme.onSurface.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: isLatest
                          ? Border.all(color: color.withOpacity(0.3))
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(e.value.label,
                            style: TextStyle(
                              fontSize: 10,
                              color: isLatest ? color : theme.colorScheme.onSurface.withOpacity(0.45),
                              fontWeight: FontWeight.w600,
                            )),
                        Text(AppUtils.formatAmount(e.value.total, symbol),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isLatest ? FontWeight.w800 : FontWeight.w600,
                              color: isLatest ? color : theme.colorScheme.onSurface.withOpacity(0.6),
                            )),
                      ],
                    ),
                  );
                }).toList(),
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
        // Donut + legend side by side
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
              Row(
                children: [
                  // Donut chart — hold to highlight, info in center
                  SizedBox(
                    width: 170, height: 170,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 45,
                          pieTouchData: PieTouchData(
                            longPressDuration: const Duration(milliseconds: 150),
                            touchCallback: (event, response) {
                              if (event is FlLongPressStart ||
                                  event is FlLongPressMoveUpdate) {
                                onTouch(response?.touchedSection
                                    ?.touchedSectionIndex ?? -1);
                              } else if (event is FlLongPressEnd ||
                                  event is FlPointerExitEvent ||
                                  event is FlTapUpEvent) {
                                onTouch(-1);
                              }
                            },
                          ),
                          sections: entries.asMap().entries.map((e) {
                            final isTouched = e.key == touchedIndex;
                            final color = colors[e.key % colors.length];
                            return PieChartSectionData(
                              color: color,
                              value: e.value.value,
                              radius: isTouched ? 65 : 50,
                              title: '',
                              borderSide: isTouched
                                  ? BorderSide(color: color, width: 3)
                                  : BorderSide.none,
                            );
                          }).toList(),
                        )),
                        // Center overlay
                        if (touchedIndex >= 0 && touchedIndex < entries.length) ...[
                          Builder(builder: (_) {
                            final e = entries[touchedIndex];
                            final color = colors[touchedIndex % colors.length];
                            final pct = total > 0 ? (e.value / total * 100) : 0.0;
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${pct.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w800,
                                        color: color)),
                                Text(AppUtils.formatAmount(e.value, symbol),
                                    style: TextStyle(
                                        fontSize: 10, fontWeight: FontWeight.w600,
                                        color: color.withOpacity(0.8))),
                              ],
                            );
                          }),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Legend — right side
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: entries.asMap().entries.map((e) {
                        final color = colors[e.key % colors.length];
                        final pct = total > 0 ? (e.value.value / total * 100) : 0.0;
                        final isTouched = e.key == touchedIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: EdgeInsets.symmetric(
                              horizontal: isTouched ? 8 : 0,
                              vertical: isTouched ? 6 : 0),
                          decoration: BoxDecoration(
                            color: isTouched
                                ? color.withOpacity(0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: isTouched
                                ? Border.all(color: color.withOpacity(0.4))
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10, height: 10,
                                decoration: BoxDecoration(
                                    color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.value.key,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isTouched
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: isTouched
                                              ? color
                                              : theme.colorScheme.onSurface,
                                        ),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text(
                                        '${pct.toStringAsFixed(1)}% · ${AppUtils.formatAmount(e.value.value, symbol)}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isTouched
                                              ? color.withOpacity(0.8)
                                              : theme.colorScheme.onSurface.withOpacity(0.5),
                                        )),
                                  ],
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
            ],
          ),
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 16),

        // Source progress list below
        ...entries.asMap().entries.map((e) {
          final color = colors[e.key % colors.length];
          final pct = total > 0 ? (e.value.value / total * 100) : 0.0;
          final isTouched = e.key == touchedIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isTouched
                  ? color.withOpacity(isDark ? 0.15 : 0.10)
                  : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: isTouched
                  ? Border.all(color: color.withOpacity(0.5), width: 1.5)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: isTouched
                      ? color.withOpacity(0.25)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: isTouched ? 14 : 8,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.value.key,
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          )),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct / 100, minHeight: 5,
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
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color)),
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
    // Safe quarter trend
    final last3Start = (months.length - 3).clamp(0, months.length);
    final prev3Start = (months.length - 6).clamp(0, months.length);
    final prev3End = (months.length - 3).clamp(0, months.length);
    final last3 = months.sublist(last3Start).fold(0.0, (s, m) => s + m.amount);
    final prev3 = prev3Start < prev3End
        ? months.sublist(prev3Start, prev3End).fold(0.0, (s, m) => s + m.amount)
        : 0.0;
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
              const SizedBox(height: 16),
              // Monthly amounts below chart
              Wrap(
                spacing: 8, runSpacing: 8,
                children: months.asMap().entries.map((e) {
                  final isLatest = e.key == months.length - 1;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLatest
                          ? const Color(0xFF2ECC71).withOpacity(0.12)
                          : theme.colorScheme.onSurface.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: isLatest
                          ? Border.all(color: const Color(0xFF2ECC71).withOpacity(0.3))
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(e.value.label,
                            style: TextStyle(
                              fontSize: 10,
                              color: isLatest
                                  ? const Color(0xFF2ECC71)
                                  : theme.colorScheme.onSurface.withOpacity(0.45),
                              fontWeight: FontWeight.w600,
                            )),
                        Text(
                            e.value.amount > 0
                                ? AppUtils.formatAmount(e.value.amount, symbol)
                                : '—',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isLatest ? FontWeight.w800 : FontWeight.w600,
                              color: isLatest
                                  ? const Color(0xFF2ECC71)
                                  : theme.colorScheme.onSurface.withOpacity(0.6),
                            )),
                      ],
                    ),
                  );
                }).toList(),
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