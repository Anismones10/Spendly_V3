import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/category_provider.dart';
import '../utils/app_utils.dart';
import '../utils/category_icons.dart';

class DailySummaryCard extends StatefulWidget {
  const DailySummaryCard({super.key});

  @override
  State<DailySummaryCard> createState() => _DailySummaryCardState();
}

class _DailySummaryCardState extends State<DailySummaryCard> {
  final Box _box = Hive.box('settings');

  // The detail rows can be folded away for a shorter dashboard. Default is
  // expanded, so nobody silently loses a row they were reading; the choice
  // sticks once it is made.
  bool get _collapsed =>
      _box.get('dailySummaryCollapsed', defaultValue: false) as bool;

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
              // Whole header is not tappable on purpose — a card this size
              // invites stray taps, and collapsing should be deliberate.
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  _box.put('dailySummaryCollapsed', !_collapsed);
                  setState(() {});
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: AnimatedRotation(
                    turns: _collapsed ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_up_rounded,
                        size: 20, color: primary.withOpacity(0.7)),
                  ),
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

          // ── Details ─────────────────────────────────────────────────
          // Three one-line facts. They used to be full-width rows with 32px
          // icon tiles and a divider each, which cost about as much height as
          // the week chart for a fraction of the information.
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeOut,
            crossFadeState: _collapsed
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            secondChild: const SizedBox(width: double.infinity),
            firstChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                Divider(color: Colors.grey.withOpacity(0.12)),
                const SizedBox(height: 10),

                if (topCat != null)
                  _DetailRow(
                    icon: CategoryIcons.resolve(topCat.icon),
                    color: Color(topCat.colorValue),
                    label: 'Top category',
                    hint: topCat.name,
                    value: AppUtils.formatAmount(topCatAmount, symbol),
                  ),

                _DetailRow(
                  icon: Icons.speed_rounded,
                  color: avgColor,
                  label: 'Average per day',
                  hint: avgPerDay <= 0
                      ? null
                      : vsAvg > 0
                          ? '${AppUtils.formatAmount(vsAvg, symbol)} above today'
                          : vsAvg < 0
                              ? '${AppUtils.formatAmount(-vsAvg, symbol)} below today'
                              : 'right on it',
                  value: AppUtils.formatAmount(avgPerDay, symbol),
                ),

                if (monthlyBudget > 0)
                  _DetailRow(
                    icon: isOnTrack
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    color: isOnTrack
                        ? const Color(0xFF2ECC71)
                        : const Color(0xFFFF9800),
                    label: isOnTrack ? 'On track' : 'Over budget',
                    hint: isOnTrack
                        ? 'projected this month'
                        : '${AppUtils.formatAmount(projectedMonthly - monthlyBudget, symbol)} over',
                    value: AppUtils.formatAmount(projectedMonthly, symbol),
                  ),
              ],
            ),
          ),
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

/// One line of the detail section: icon, label, muted hint, amount.
///
/// Deliberately flat — a bare 16px icon rather than a tinted 32px tile, so
/// three of these stack in less height than one of the old rows.
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  /// Secondary text after the label. Null when there is nothing to add.
  final String? hint;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          if (hint != null) ...[
            const SizedBox(width: 6),
            // Takes the squeeze so a long category name never pushes the
            // amount off the edge.
            Expanded(
              child: Text(
                hint!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11, color: onSurface.withOpacity(0.45)),
              ),
            ),
          ] else
            const Spacer(),
          const SizedBox(width: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
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
