import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/app_utils.dart';

class DailySummaryCard extends StatelessWidget {
  const DailySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>();
    final settings = context.watch<SettingsProvider>();
    final wallets = context.watch<WalletProvider>();
    final now = DateTime.now();
    final symbol = settings.currencySymbol;

    final todayTotal = expenses.getTotalForDay(now);
    final yesterdayTotal =
        expenses.getTotalForDay(now.subtract(const Duration(days: 1)));
    final diff = todayTotal - yesterdayTotal;

    // Total remaining across all wallets
    final allExpenses = expenses.allExpenses;
    final totalRemaining = wallets.wallets.isEmpty
        ? 0.0
        : wallets.getTotalRemaining(allExpenses);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06), blurRadius: 12)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.nights_stay_rounded,
                  color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Daily Summary',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _DailyStat(
                label: 'Spent Today',
                value: AppUtils.formatAmount(todayTotal, symbol),
                color: theme.colorScheme.primary,
              ),
              Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.withOpacity(0.2)),
              _DailyStat(
                label: 'vs Yesterday',
                value: diff == 0
                    ? 'Same'
                    : '${diff > 0 ? '+' : ''}${AppUtils.formatAmount(diff.abs(), symbol)}',
                color: diff > 0
                    ? Colors.red
                    : diff < 0
                        ? Colors.green
                        : Colors.grey,
                icon: diff > 0
                    ? Icons.trending_up_rounded
                    : diff < 0
                        ? Icons.trending_down_rounded
                        : null,
              ),
              Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.withOpacity(0.2)),
              _DailyStat(
                label: wallets.wallets.isEmpty ? 'Wallets' : 'Remaining',
                value: wallets.wallets.isEmpty
                    ? 'Add wallets'
                    : AppUtils.formatAmount(totalRemaining, symbol),
                color: totalRemaining >= 0 ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
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
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.5))),
      ],
    );
  }
}
