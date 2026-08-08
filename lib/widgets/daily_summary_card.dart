import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/category_provider.dart';
import '../utils/app_utils.dart';
import '../utils/category_icons.dart';

class DailySummaryCard extends StatelessWidget {
  const DailySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>();
    final settings = context.watch<SettingsProvider>();
    final wallets = context.watch<WalletProvider>();
    final categories = context.watch<CategoryProvider>();
    final now = DateTime.now();
    final symbol = settings.currencySymbol;

    final todayTotal = expenses.getTotalForDay(now);
    final yesterdayTotal =
        expenses.getTotalForDay(now.subtract(const Duration(days: 1)));
    final diff = todayTotal - yesterdayTotal;

    final allExpenses = expenses.allExpenses;
    final totalRemaining = wallets.wallets.isEmpty
        ? 0.0
        : wallets.getTotalRemaining(allExpenses);

    // 7-day spending data
    final weekDays = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return _DayData(
        label: _shortDay(day.weekday),
        amount: expenses.getTotalForDay(day),
        isToday: i == 6,
      );
    });
    final weekMax = weekDays.map((d) => d.amount).fold(0.0, (a, b) => a > b ? a : b);

    // Top category today
    final todayExpenses = expenses.allExpenses.where((e) =>
        e.date.year == now.year &&
        e.date.month == now.month &&
        e.date.day == now.day).toList();
    final catTotals = <String, double>{};
    for (final e in todayExpenses) {
      catTotals[e.categoryId] = (catTotals[e.categoryId] ?? 0) + e.amount;
    }
    String? topCatId;
    double topCatAmount = 0;
    catTotals.forEach((id, amt) {
      if (amt > topCatAmount) { topCatAmount = amt; topCatId = id; }
    });
    final topCat = topCatId != null ? categories.getById(topCatId!) : null;

    // Monthly spending pace
    final monthlyTotal = expenses.getTotalForMonth(now.year, now.month);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day;
    final projectedMonthly = daysPassed > 0
        ? (monthlyTotal / daysPassed) * daysInMonth
        : 0.0;
    final monthlyBudget = settings.monthlyBudget;
    final isOnTrack = monthlyBudget > 0
        ? projectedMonthly <= monthlyBudget
        : true;

    // Average per day so far this month, and how today compares to it.
    final avgPerDay = daysPassed > 0 ? monthlyTotal / daysPassed : 0.0;
    final vsAvg = todayTotal - avgPerDay;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    // Green when today is under the running average, red when over. With no
    // spending yet there is nothing to compare, so stay neutral.
    final avgColor = avgPerDay <= 0
        ? primary
        : vsAvg > 0
            ? const Color(0xFFE57373)
            : const Color(0xFF2ECC71);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.nights_stay_rounded, color: primary, size: 20),
              const SizedBox(width: 8),
              const Text('Daily Summary',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              Text(
                _todayLabel(now),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Top 3 stats ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _DailyStat(
                label: 'Spent Today',
                value: AppUtils.formatAmount(todayTotal, symbol),
                color: primary,
              ),
              Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.2)),
              _DailyStat(
                label: 'vs Yesterday',
                value: diff == 0
                    ? 'Same'
                    : '${diff > 0 ? '+' : ''}${AppUtils.formatAmount(diff.abs(), symbol)}',
                color: diff > 0
                    ? const Color(0xFFE57373)
                    : diff < 0
                        ? const Color(0xFF2ECC71)
                        : Colors.grey,
                icon: diff > 0
                    ? Icons.trending_up_rounded
                    : diff < 0
                        ? Icons.trending_down_rounded
                        : null,
              ),
              Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.2)),
              _DailyStat(
                label: wallets.wallets.isEmpty ? 'Wallets' : 'Remaining',
                value: wallets.wallets.isEmpty
                    ? 'Add wallets'
                    : AppUtils.formatAmount(totalRemaining, symbol),
                color: totalRemaining >= 0
                    ? const Color(0xFF2ECC71)
                    : const Color(0xFFE57373),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: Colors.grey.withOpacity(0.12)),
          const SizedBox(height: 12),

          // ── 7-day spending bars ─────────────────────────────────────
          Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  size: 14, color: theme.colorScheme.onSurface.withOpacity(0.4)),
              const SizedBox(width: 6),
              Text('This Week',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    letterSpacing: 0.5,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: weekDays.map((day) {
              final barHeight = weekMax > 0
                  ? (day.amount / weekMax * 48).clamp(3.0, 48.0)
                  : 3.0;
              return Column(
                children: [
                  // Amount tooltip on today
                  if (day.isToday && day.amount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AppUtils.formatAmount(day.amount, symbol),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 14),
                  const SizedBox(height: 4),
                  // Bar
                  AnimatedContainer(
                    duration: Duration(milliseconds: 400 + weekDays.indexOf(day) * 50),
                    curve: Curves.easeOut,
                    width: 28,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: day.isToday
                          ? primary
                          : day.amount > 0
                              ? primary.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Day label
                  Text(
                    day.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: day.isToday ? FontWeight.w800 : FontWeight.w500,
                      color: day.isToday
                          ? primary
                          : theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),

          // ── Top category today ──────────────────────────────────────
          if (topCat != null) ...[
            const SizedBox(height: 16),
            Divider(color: Colors.grey.withOpacity(0.12)),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Color(topCat.colorValue).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(CategoryIcons.resolve(topCat.icon),
                      color: Color(topCat.colorValue), size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Top category today',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withOpacity(0.45),
                          fontWeight: FontWeight.w500,
                        )),
                      Text(topCat.name,
                        style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Text(
                  AppUtils.formatAmount(topCatAmount, symbol),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(topCat.colorValue),
                  ),
                ),
              ],
            ),
          ],

          // ── Average per day ─────────────────────────────────────────
          const SizedBox(height: 12),
          Divider(color: Colors.grey.withOpacity(0.12)),
          const SizedBox(height: 12),
          Row(
            children: [
              // Same 32×32 tile as the category row above, so the two read as
              // one list instead of two unrelated styles.
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: avgColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.speed_rounded, color: avgColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Average per day',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withOpacity(0.45),
                        fontWeight: FontWeight.w500,
                      )),
                    Text(
                      avgPerDay <= 0
                          ? 'This month'
                          : vsAvg > 0
                              ? 'Today is ${AppUtils.formatAmount(vsAvg, symbol)} above'
                              : vsAvg < 0
                                  ? 'Today is ${AppUtils.formatAmount(-vsAvg, symbol)} below'
                                  : 'Today is right on it',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Text(
                AppUtils.formatAmount(avgPerDay, symbol),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: avgColor,
                ),
              ),
            ],
          ),

          // ── Monthly pace ────────────────────────────────────────────
          if (monthlyBudget > 0) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.grey.withOpacity(0.12)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isOnTrack ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                  size: 16,
                  color: isOnTrack ? const Color(0xFF2ECC71) : const Color(0xFFFF9800),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isOnTrack
                        ? 'On track — projected ${AppUtils.formatAmount(projectedMonthly, symbol)} this month'
                        : 'At this pace you\'ll spend ${AppUtils.formatAmount(projectedMonthly, symbol)} — ${AppUtils.formatAmount(projectedMonthly - monthlyBudget, symbol)} over budget',
                    style: TextStyle(
                      fontSize: 11,
                      color: isOnTrack
                          ? const Color(0xFF2ECC71)
                          : const Color(0xFFFF9800),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  String _shortDay(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _todayLabel(DateTime now) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday',
                  'Friday', 'Saturday', 'Sunday'];
    return days[now.weekday - 1];
  }
}

class _DayData {
  final String label;
  final double amount;
  final bool isToday;
  const _DayData({required this.label, required this.amount, required this.isToday});
}

class _DailyStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const _DailyStat({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, color: color, size: 14),
            if (icon != null) const SizedBox(width: 4),
            Text(value,
              style: TextStyle(
                fontWeight: FontWeight.w700, color: color, fontSize: 14),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        const SizedBox(height: 4),
        Text(label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
      ],
    );
  }
}
