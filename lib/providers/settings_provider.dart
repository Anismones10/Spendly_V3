import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SettingsProvider extends ChangeNotifier {
  final Box _box = Hive.box('settings');

  bool get isDarkMode => _box.get('darkMode', defaultValue: false);
  bool get soundEnabled => _box.get('soundEnabled', defaultValue: true);
  bool get hapticEnabled => _box.get('hapticEnabled', defaultValue: true);
  String get currency => _box.get('currency', defaultValue: 'USD');
  String get currencySymbol => _getCurrencySymbol(currency);
  double get monthlyBudget => (_box.get('monthlyBudget', defaultValue: 0.0) as num).toDouble();
  int get streak => (_box.get('streak', defaultValue: 0) as num).toInt();
  String? get lastStreakDate => _box.get('lastStreakDate');
  bool get notifEnabled  => _box.get('notifEnabled',  defaultValue: false) as bool;
  bool get notifDaily    => _box.get('notifDaily',    defaultValue: true)  as bool;
  bool get notifWeekly   => _box.get('notifWeekly',   defaultValue: true)  as bool;
  bool get notifBudget   => _box.get('notifBudget',   defaultValue: true)  as bool;
  bool get notifLoan     => _box.get('notifLoan',     defaultValue: true)  as bool;
  bool get notifGoal     => _box.get('notifGoal',     defaultValue: true)  as bool;
  int  get notifHour     => _box.get('notifHour',     defaultValue: 21)    as int;
  int  get notifMinute   => _box.get('notifMinute',   defaultValue: 0)     as int;

  String _getCurrencySymbol(String code) {
    const map = {
      // Americas
      'USD': r'$',
      'CAD': r'CA$',
      'AUD': r'A$',
      'BRL': r'R$',
      'MXN': r'MX$',
      // Europe
      'EUR': '€',
      'GBP': '£',
      'CHF': 'Fr',
      'RUB': '₽',
      'TRY': '₺',
      'SEK': 'kr',
      'NOK': 'kr',
      // Middle East & Africa
      'AED': 'د.إ',
      'SAR': '﷼',
      'IRR': '﷼',
      'AFN': '؋',
      'IQD': 'ع.د',
      'KWD': 'د.ك',
      'QAR': 'ر.ق',
      // Asia
      'JPY': '¥',
      'CNY': '¥',
      'KRW': '₩',
      'INR': '₹',
      'PKR': '₨',
      'BDT': '৳',
      'THB': '฿',
      'VND': '₫',
      'SGD': r'S$',
      'HKD': r'HK$',
    };
    return map[code] ?? r'$';
  }

  void toggleDarkMode() {
    _box.put('darkMode', !isDarkMode);
    notifyListeners();
  }

  void toggleSound() {
    _box.put('soundEnabled', !soundEnabled);
    notifyListeners();
  }

  void toggleHaptic() {
    _box.put('hapticEnabled', !hapticEnabled);
    notifyListeners();
  }

  void setCurrency(String code) {
    _box.put('currency', code);
    notifyListeners();
  }

  void setMonthlyBudget(double budget) {
    _box.put('monthlyBudget', budget);
    notifyListeners();
  }

  void updateStreak(bool underBudget) {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final lastDate = lastStreakDate;

    if (lastDate == todayStr) return;

    if (underBudget) {
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayStr = '${yesterday.year}-${yesterday.month}-${yesterday.day}';
      if (lastDate == yesterdayStr) {
        _box.put('streak', streak + 1);
      } else {
        _box.put('streak', 1);
      }
    } else {
      _box.put('streak', 0);
    }
    _box.put('lastStreakDate', todayStr);
    notifyListeners();
  }

  void clearAllData() {
    _box.clear();
    notifyListeners();
  }

  static const List<Map<String, String>> currencies = [
    // ── Americas ──────────────────────────────────
    {'code': 'USD', 'label': 'US Dollar — \$'},
    {'code': 'CAD', 'label': 'Canadian Dollar — CA\$'},
    {'code': 'AUD', 'label': 'Australian Dollar — A\$'},
    {'code': 'BRL', 'label': 'Brazilian Real — R\$'},
    {'code': 'MXN', 'label': 'Mexican Peso — MX\$'},
    // ── Europe ────────────────────────────────────
    {'code': 'EUR', 'label': 'Euro — €'},
    {'code': 'GBP', 'label': 'British Pound — £'},
    {'code': 'CHF', 'label': 'Swiss Franc — Fr'},
    {'code': 'RUB', 'label': 'Russian Ruble — ₽'},
    {'code': 'TRY', 'label': 'Turkish Lira — ₺'},
    {'code': 'SEK', 'label': 'Swedish Krona — kr'},
    {'code': 'NOK', 'label': 'Norwegian Krone — kr'},
    // ── Middle East & Africa ──────────────────────
    {'code': 'AED', 'label': 'UAE Dirham — د.إ'},
    {'code': 'SAR', 'label': 'Saudi Riyal — ﷼'},
    {'code': 'IRR', 'label': 'Iranian Rial — ﷼'},
    {'code': 'AFN', 'label': 'Afghan Afghani — ؋'},
    {'code': 'IQD', 'label': 'Iraqi Dinar — ع.د'},
    {'code': 'KWD', 'label': 'Kuwaiti Dinar — د.ك'},
    {'code': 'QAR', 'label': 'Qatari Riyal — ر.ق'},
    // ── Asia ──────────────────────────────────────
    {'code': 'JPY', 'label': 'Japanese Yen — ¥'},
    {'code': 'CNY', 'label': 'Chinese Yuan — ¥'},
    {'code': 'KRW', 'label': 'South Korean Won — ₩'},
    {'code': 'INR', 'label': 'Indian Rupee — ₹'},
    {'code': 'PKR', 'label': 'Pakistani Rupee — ₨'},
    {'code': 'BDT', 'label': 'Bangladeshi Taka — ৳'},
    {'code': 'THB', 'label': 'Thai Baht — ฿'},
    {'code': 'VND', 'label': 'Vietnamese Dong — ₫'},
    {'code': 'SGD', 'label': 'Singapore Dollar — S\$'},
    {'code': 'HKD', 'label': 'Hong Kong Dollar — HK\$'},
  ];
}
