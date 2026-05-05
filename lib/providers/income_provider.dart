import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/income_model.dart';

class IncomeProvider extends ChangeNotifier {
  final Box<IncomeModel> _box = Hive.box<IncomeModel>('income');

  List<IncomeModel> get allIncome =>
      _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));

  List<IncomeModel> getIncomeForMonth(int year, int month) {
    return _box.values
        .where((e) => e.date.year == year && e.date.month == month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double getTotalForMonth(int year, int month) {
    return getIncomeForMonth(year, month)
        .fold(0, (sum, e) => sum + e.amount);
  }

  double getTotalForDay(DateTime day) {
    return _box.values
        .where((e) =>
            e.date.year == day.year &&
            e.date.month == day.month &&
            e.date.day == day.day)
        .fold(0, (sum, e) => sum + e.amount);
  }

  Map<String, double> getSourceTotals(int year, int month) {
    final income = getIncomeForMonth(year, month);
    final Map<String, double> totals = {};
    for (final e in income) {
      totals[e.source] = (totals[e.source] ?? 0) + e.amount;
    }
    return totals;
  }

  void addIncome(IncomeModel income) {
    _box.put(income.id, income);
    notifyListeners();
  }

  void updateIncome(IncomeModel income) {
    _box.put(income.id, income);
    notifyListeners();
  }

  void deleteIncome(String id) {
    _box.delete(id);
    notifyListeners();
  }

  void clearAll() {
    _box.clear();
    notifyListeners();
  }
}
