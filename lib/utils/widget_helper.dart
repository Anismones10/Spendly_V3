import 'package:home_widget/home_widget.dart';
import 'package:hive/hive.dart';
import '../models/expense_model.dart';
import '../models/wallet_model.dart';

/// Writes all widget data to HomeWidget storage and triggers a UI refresh.
/// Call this whenever expenses or wallet balances change.
class WidgetHelper {
  static const String _appGroupId   = 'group.com.example.expense_tracker';
  static const String _androidClass = 'SpendlyWidgetProvider';

  /// Main entry point — reads from Hive directly (no Provider needed)
  /// so it can be called from anywhere including background callbacks.
  static Future<void> updateWidget() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);

      final settingsBox  = Hive.box('settings');
      final expenseBox   = Hive.box<ExpenseModel>('expenses');
      final walletBox    = Hive.box<WalletModel>('wallets');

      // ── Currency symbol ─────────────────────────────────────────────────
      final currency = settingsBox.get('currency', defaultValue: 'USD') as String;
      final symbol   = _currencySymbol(currency);

      // ── Wallet total balance ─────────────────────────────────────────────
      final totalBalance = walletBox.values
          .fold(0.0, (sum, w) => sum + w.balance);

      // ── Today's spending ─────────────────────────────────────────────────
      final now       = DateTime.now();
      final today     = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      double todaySpent = 0;
      double yesterdaySpent = 0;

      for (final e in expenseBox.values) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        if (d == today)     todaySpent     += e.amount;
        if (d == yesterday) yesterdaySpent += e.amount;
      }

      // ── Monthly spending vs budget ───────────────────────────────────────
      final monthlyBudget = (settingsBox.get(
          'monthlyBudget', defaultValue: 0.0) as num).toDouble();

      double monthSpent = 0;
      for (final e in expenseBox.values) {
        if (e.date.year == now.year && e.date.month == now.month) {
          monthSpent += e.amount;
        }
      }

      final remaining       = monthlyBudget > 0
          ? monthlyBudget - monthSpent : totalBalance;
      final hasBudget       = monthlyBudget > 0;
      final budgetPct       = hasBudget
          ? (monthSpent / monthlyBudget).clamp(0.0, 1.0) : 0.0;

      // ── Comparison arrow ─────────────────────────────────────────────────
      // +1 = spent more today, -1 = spent less, 0 = same
      final trend = todaySpent > yesterdaySpent
          ? 1 : todaySpent < yesterdaySpent ? -1 : 0;

      // ── Save to widget storage ───────────────────────────────────────────
      await Future.wait([
        HomeWidget.saveWidgetData<String>('symbol',          symbol),
        HomeWidget.saveWidgetData<String>('total_balance',   _fmt(totalBalance,  symbol)),
        HomeWidget.saveWidgetData<String>('today_spent',     _fmt(todaySpent,    symbol)),
        HomeWidget.saveWidgetData<String>('yesterday_spent', _fmt(yesterdaySpent, symbol)),
        HomeWidget.saveWidgetData<int>   ('trend',           trend),
        HomeWidget.saveWidgetData<String>('remaining',       _fmt(remaining,     symbol)),
        HomeWidget.saveWidgetData<bool>  ('has_budget',      hasBudget),
        HomeWidget.saveWidgetData<int>   ('budget_pct',      (budgetPct * 100).round()),
        HomeWidget.saveWidgetData<String>('last_updated',    _timeLabel(now)),
      ]);

      // ── Trigger widget refresh ───────────────────────────────────────────
      await HomeWidget.updateWidget(
        androidName: _androidClass,
        iOSName:     'SpendlyWidget',
      );
    } catch (_) {
      // Never crash the app due to widget update failure
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _fmt(double amount, String sym) {
    if (amount >= 1000000) {
      return '$sym${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '$sym${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '$sym${amount.toStringAsFixed(2)}';
  }

  static String _timeLabel(DateTime now) {
    final h   = now.hour;
    final m   = now.minute.toString().padLeft(2, '0');
    final per = h >= 12 ? 'PM' : 'AM';
    final hr  = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hr:$m $per';
  }

  static String _currencySymbol(String code) {
    const map = {
      'USD': r'$',  'CAD': r'CA$', 'AUD': r'A$',  'BRL': r'R$',
      'MXN': r'MX$','EUR': '€',   'GBP': '£',     'CHF': 'Fr',
      'RUB': '₽',   'TRY': '₺',   'SEK': 'kr',    'NOK': 'kr',
      'AED': 'AED ', 'SAR': 'SAR ','IRR': 'IRR ',  'AFN': 'AFN ',
      'IQD': 'IQD ','KWD': 'KWD ','QAR': 'QAR ',  'JPY': '¥',
      'CNY': '¥',   'KRW': '₩',   'INR': '₹',     'PKR': 'Rs ',
      'BDT': '৳',   'THB': '฿',   'VND': '₫',     'SGD': r'S$',
      'HKD': r'HK$',
    };
    return map[code] ?? r'$';
  }
}
