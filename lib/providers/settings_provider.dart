import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SettingsProvider extends ChangeNotifier {
  final Box _box = Hive.box('settings');

  bool get isDarkMode => _box.get('darkMode', defaultValue: false);
  bool get soundEnabled => _box.get('soundEnabled', defaultValue: true);
  String get currency => _box.get('currency', defaultValue: 'USD');
  String get currencySymbol => _getCurrencySymbol(currency);
  double get monthlyBudget => _box.get('monthlyBudget', defaultValue: 0.0);
  int get streak => _box.get('streak', defaultValue: 0);
  String? get lastStreakDate => _box.get('lastStreakDate');

  String _getCurrencySymbol(String code) {
    const map = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'IRR': '﷼',
      'JPY': '¥',
      'CAD': 'CA\$',
      'AUD': 'A\$',
    };
    return map[code] ?? '\$';
  }

  void toggleDarkMode() {
    _box.put('darkMode', !isDarkMode);
    notifyListeners();
  }

  void toggleSound() {
    _box.put('soundEnabled', !soundEnabled);
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
    {'code': 'USD', 'label': 'US Dollar (\$)'},
    {'code': 'EUR', 'label': 'Euro (€)'},
    {'code': 'GBP', 'label': 'British Pound (£)'},
    {'code': 'IRR', 'label': 'Iranian Rial (﷼)'},
    {'code': 'JPY', 'label': 'Japanese Yen (¥)'},
    {'code': 'CAD', 'label': 'Canadian Dollar (CA\$)'},
    {'code': 'AUD', 'label': 'Australian Dollar (A\$)'},
  ];
}
