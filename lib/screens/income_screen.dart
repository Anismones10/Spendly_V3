import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/income_model.dart';
import '../providers/income_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_utils.dart';
import '../widgets/empty_state.dart';
import 'add_income_screen.dart';

class IncomeScreen extends StatefulWidget {
  final VoidCallback? onMoreTap;
  const IncomeScreen({super.key, this.onMoreTap});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  bool _showCharts = true;
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final income = context.watch<IncomeProvider>();
    final expenses = context.watch<ExpenseProvider>();
    final settings = context.watch<SettingsProvider>();
    final symbol = settings.currencySymbol;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();

    final monthlyIncome = income.getTotalForMonth(now.year, now.month);
    final monthlyExpenses = expenses.getTotalForMonth(now.year, now.month);
    final balance = monthlyIncome - monthlyExpenses;
    final monthIncomeList = income.getIncomeForMonth(now.year, now.month);

    // Last 6 months for bar chart
    final barData = List.generate(6, (i) {
      final date = DateTime(now.year, now.month - 5 + i);
      return _MonthBar(
        month: _shortMonth(date.month),
        amount: income.getTotalForMonth(date.year, date.month),
      );
    });

    // Income by source for donut
    final sourceTotals = income.getSourceTotals(now.year, now.month);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        title: const Text('Income'),
        actions: [
          // ••• More button
          if (widget.onMoreTap != null)
            GestureDetector(
              onTap: widget.onMoreTap,
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.more_horiz_rounded,
                    color: theme.colorScheme.primary, size: 20),
              ),
            ),
          // Charts / List toggle
          GestureDetector(
            onTap: () => setState(() => _showCharts = !_showCharts),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(_showCharts ? Icons.list_rounded : Icons.bar_chart_rounded,
                    size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(_showCharts ? 'List' : 'Charts',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _buildSummaryCard(context, symbol, monthlyIncome, monthlyExpenses, balance, isDark, theme),
          const SizedBox(height: 20),

          if (_showCharts) ...[
            _SectionTitle(title: 'Monthly Trend', icon: Icons.bar_chart_rounded),
            const SizedBox(height: 12),
            _buildBarChart(context, barData, symbol, isDark, theme)
                .animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),

            if (sourceTotals.isNotEmpty) ...[
              _SectionTitle(title: 'Income by Source', icon: Icons.pie_chart_rounded),
              const SizedBox(height: 12),
              _buildDonutChart(context, sourceTotals, symbol, isDark, theme)
                  .animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
              const SizedBox(height: 24),
            ],
          ],

          _SectionTitle(
            title: AppUtils.formatMonthYear(now),
            icon: Icons.calendar_today_rounded,
          ),
          const SizedBox(height: 12),

          if (monthIncomeList.isEmpty)
            const EmptyState(
              icon: Icons.account_balance_wallet_rounded,
              title: 'No Income Yet',
              subtitle: 'Add your first income source using the + button below.',
            )
          else
            ...monthIncomeList.asMap().entries.map(
              (e) => _IncomeTile(income: e.value, symbol: symbol)
                  .animate().fadeIn(delay: (e.key * 50).ms).slideX(begin: 0.08),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AddIncomeScreen())),
        backgroundColor: const Color(0xFF2ECC71),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Income',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, List<_MonthBar> data,
      String symbol, bool isDark, ThemeData theme) {
    final maxY = data.map((d) => d.amount).fold(0.0, (a, b) => a > b ? a : b);
    final safeMax = maxY == 0 ? 100.0 : maxY * 1.25;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2ECC71).withOpacity(0.12),
            blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: BarChart(BarChartData(
              maxY: safeMax,
              minY: 0,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipRoundedRadius: 10,
                  getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                    '$symbol${rod.toY.toStringAsFixed(0)}',
                    const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(data[v.toInt()].month,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withOpacity(0.5))),
                    ),
                  ),
                ),
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
              barGroups: data.asMap().entries.map((e) {
                final isCurrentMonth = e.key == data.length - 1;
                return BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(
                    toY: e.value.amount, width: 22,
                    borderRadius: BorderRadius.circular(8),
                    color: isCurrentMonth
                        ? const Color(0xFF2ECC71)
                        : const Color(0xFF2ECC71).withOpacity(0.35),
                  ),
                ]);
              }).toList(),
            )),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: const Color(0xFF2ECC71), label: 'This month'),
              const SizedBox(width: 16),
              _Legend(color: const Color(0xFF2ECC71).withOpacity(0.35), label: 'Previous'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(BuildContext context, Map<String, double> sourceTotals,
      String symbol, bool isDark, ThemeData theme) {
    final colors = [
      const Color(0xFF2ECC71), const Color(0xFF4A90E2),
      const Color(0xFFFF9800), const Color(0xFF9C27B0),
      const Color(0xFFE57373), const Color(0xFF00BCD4),
    ];
    final entries = sourceTotals.entries.toList();
    final total = entries.fold(0.0, (sum, e) => sum + e.value);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF4A90E2).withOpacity(0.12),
            blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          // Donut
          SizedBox(
            width: 160, height: 160,
            child: PieChart(PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 45,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    _touchedPieIndex = response?.touchedSection
                        ?.touchedSectionIndex ?? -1;
                  });
                },
              ),
              sections: entries.asMap().entries.map((e) {
                final isTouched = e.key == _touchedPieIndex;
                final color = colors[e.key % colors.length];
                final pct = total > 0 ? (e.value.value / total * 100) : 0;
                return PieChartSectionData(
                  color: color,
                  value: e.value.value,
                  radius: isTouched ? 55 : 45,
                  title: '${pct.round()}%',
                  titleStyle: TextStyle(
                    fontSize: isTouched ? 13 : 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            )),
          ),
          const SizedBox(width: 20),
          // Legend
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.asMap().entries.map((e) {
                final color = colors[e.key % colors.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.value.key,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(AppUtils.formatAmount(e.value.value, symbol),
                              style: TextStyle(fontSize: 11, color: color,
                                fontWeight: FontWeight.w700)),
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
    );
  }

  Widget _buildSummaryCard(BuildContext context, String symbol, double income,
      double expenses, double balance, bool isDark, ThemeData theme) {
    final isPositive = balance >= 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [const Color(0xFF2ECC71), const Color(0xFF27AE60)]
              : [const Color(0xFFE57373), const Color(0xFFEF5350)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? const Color(0xFF2ECC71) : const Color(0xFFE57373))
                .withOpacity(0.3),
            blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _SummaryItem(label: 'Income',
                value: AppUtils.formatAmount(income, symbol),
                icon: Icons.arrow_downward_rounded, color: Colors.white)),
              Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
              Expanded(child: _SummaryItem(label: 'Expenses',
                value: AppUtils.formatAmount(expenses, symbol),
                icon: Icons.arrow_upward_rounded, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('${isPositive ? '+' : ''}${AppUtils.formatAmount(balance, symbol)} balance',
                style: const TextStyle(color: Colors.white, fontSize: 18,
                  fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isPositive ? 'Great! You\'re saving money this month'
                : 'Spending more than you earn this month',
            style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  String _shortMonth(int month) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[month - 1];
  }
}

class _MonthBar {
  final String month;
  final double amount;
  const _MonthBar({required this.month, required this.amount});
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

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

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(children: [
      Icon(icon, size: 18, color: theme.colorScheme.primary),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
    ]);
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem({required this.label, required this.value,
    required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: color.withOpacity(0.8), size: 18),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700),
        maxLines: 1, overflow: TextOverflow.ellipsis),
      Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
    ]);
  }
}

class _IncomeTile extends StatelessWidget {
  final IncomeModel income;
  final String symbol;
  const _IncomeTile({required this.income, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = incomeSourceColor(income.source);
    final icon = incomeSourceIcon(income.source);
    final label = incomeSourceLabel(income.source);

    return Dismissible(
      key: ValueKey(income.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Income', style: TextStyle(fontWeight: FontWeight.w700)),
          content: Text('Delete "${income.name}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
          ],
        ),
      ),
      onDismissed: (_) => context.read<IncomeProvider>().deleteIncome(income.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => AddIncomeScreen(existing: income))),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
          ),
          child: Row(children: [
            Container(width: 48, height: 48,
              decoration: BoxDecoration(color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 22)),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(income.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(children: [
                  Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  Text(AppUtils.formatDate(income.date),
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.4))),
                ]),
                if (income.note != null && income.note!.isNotEmpty)
                  Text(income.note!, style: TextStyle(fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.4)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            )),
            Text('+${AppUtils.formatAmount(income.amount, symbol)}',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: color)),
          ]),
        ),
      ),
    );
  }
}
