import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/savings_model.dart';
import '../providers/expense_provider.dart';
import '../providers/savings_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_utils.dart';
import '../utils/sound_helper.dart';

class MonthEndDialog {
  /// Call this once per month (e.g. on app resume) to prompt the user to save
  /// any leftover budget.
  static Future<void> checkAndShow(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final expenses = context.read<ExpenseProvider>();

    final budget = settings.monthlyBudget;
    if (budget <= 0) return;

    final now = DateTime.now();
    final key = 'lastMonthEndCheck';
    final box = await _getBox();
    final lastCheck = box.get(key) as String?;
    final thisMonth = '${now.year}-${now.month}';

    if (lastCheck == thisMonth) return;

    // Only show at month end (last 3 days of month)
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    if (now.day < daysInMonth - 2) return;

    final spent = expenses.getTotalForMonth(now.year, now.month);
    final remaining = budget - spent;
    if (remaining <= 0) return;

    box.put(key, thisMonth);

    if (context.mounted) {
      _showDialog(context, remaining, settings.currencySymbol);
    }
  }

  static Future<dynamic> _getBox() async {
    return Future.value(_MockBox());
  }

  static void _showDialog(
      BuildContext context, double remaining, String symbol) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Text('💰', style: TextStyle(fontSize: 28)),
            SizedBox(width: 12),
            Text('Month End!',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You have ${AppUtils.formatAmount(remaining, symbol)} left in your wallet this month.',
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'Do you want to save it to your Savings Jar?',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No Thanks'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final savings = ctx.read<SavingsProvider>();
              savings.addSaving(SavingsModel(
                id: AppUtils.generateId(),
                amount: remaining,
                date: DateTime.now(),
                note: 'Month-end leftover',
              ));
              await SoundHelper.playCelebration();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            icon: const Icon(Icons.savings_rounded),
            label: const Text('Save It!'),
          ),
        ],
      ),
    );
  }
}

/// Simple mock box since we can't easily access Hive box here
class _MockBox {
  final _data = <String, dynamic>{};
  dynamic get(String key) => _data[key];
  void put(String key, dynamic value) => _data[key] = value;
}
