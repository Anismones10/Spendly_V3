import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/expense_model.dart';

class ExpenseProvider extends ChangeNotifier {
  final Box<ExpenseModel> _box = Hive.box<ExpenseModel>('expenses');

  String _searchQuery = '';
  String? _filterCategory;
  String _sortBy = 'dateDesc';
  DateTimeRange? _dateRange;

  String get searchQuery => _searchQuery;
  String? get filterCategory => _filterCategory;
  String get sortBy => _sortBy;
  DateTimeRange? get dateRange => _dateRange;

  List<ExpenseModel> get allExpenses => _box.values.toList();

  List<ExpenseModel> get filteredExpenses {
    List<ExpenseModel> list = _box.values.toList();

    if (_searchQuery.isNotEmpty) {
      list = list.where((e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    if (_filterCategory != null) {
      list = list.where((e) => e.categoryId == _filterCategory).toList();
    }
    if (_dateRange != null) {
      list = list.where((e) =>
        e.date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
        e.date.isBefore(_dateRange!.end.add(const Duration(days: 1)))
      ).toList();
    }

    switch (_sortBy) {
      case 'amountAsc':
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case 'amountDesc':
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'dateAsc':
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'dateDesc':
      default:
        list.sort((a, b) => b.date.compareTo(a.date));
    }
    return list;
  }

  // ── Wallet filtering ────────────────────────────────────────────────────────

  /// All expenses paid from a specific wallet
  List<ExpenseModel> getExpensesForWallet(String walletId) {
    return _box.values
        .where((e) => e.walletId == walletId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Total spent from a specific wallet
  double getTotalForWallet(String walletId) {
    return getExpensesForWallet(walletId)
        .fold(0, (sum, e) => sum + e.amount);
  }

  /// Total spent from a wallet in a specific month
  double getWalletTotalForMonth(String walletId, int year, int month) {
    return _box.values
        .where((e) =>
            e.walletId == walletId &&
            e.date.year == year &&
            e.date.month == month)
        .fold(0, (sum, e) => sum + e.amount);
  }

  // ── Existing methods ────────────────────────────────────────────────────────

  List<ExpenseModel> getExpensesForMonth(int year, int month) {
    return _box.values.where((e) => e.date.year == year && e.date.month == month).toList();
  }

  List<ExpenseModel> getExpensesForDay(DateTime day) {
    return _box.values.where((e) =>
      e.date.year == day.year && e.date.month == day.month && e.date.day == day.day
    ).toList();
  }

  double getTotalForMonth(int year, int month) {
    return getExpensesForMonth(year, month).fold(0, (sum, e) => sum + e.amount);
  }

  double getTotalForDay(DateTime day) {
    return getExpensesForDay(day).fold(0, (sum, e) => sum + e.amount);
  }

  double getTotalForWeek() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _box.values
        .where((e) => e.date.isAfter(weekAgo))
        .fold(0, (sum, e) => sum + e.amount);
  }

  Map<String, double> getCategoryTotals(int year, int month) {
    final expenses = getExpensesForMonth(year, month);
    final Map<String, double> totals = {};
    for (final e in expenses) {
      totals[e.categoryId] = (totals[e.categoryId] ?? 0) + e.amount;
    }
    return totals;
  }

  Map<int, double> getDailyTotals(int year, int month) {
    final expenses = getExpensesForMonth(year, month);
    final Map<int, double> totals = {};
    for (final e in expenses) {
      totals[e.date.day] = (totals[e.date.day] ?? 0) + e.amount;
    }
    return totals;
  }

  void addExpense(ExpenseModel expense) {
    _box.put(expense.id, expense);
    notifyListeners();
  }

  void updateExpense(ExpenseModel expense) {
    _box.put(expense.id, expense);
    notifyListeners();
  }

  void deleteExpense(String id) {
    _box.delete(id);
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterCategory(String? categoryId) {
    _filterCategory = categoryId;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  void setDateRange(DateTimeRange? range) {
    _dateRange = range;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterCategory = null;
    _sortBy = 'dateDesc';
    _dateRange = null;
    notifyListeners();
  }

  void clearAll() {
    _box.clear();
    notifyListeners();
  }

  List<String> getInsights({Map<String, String> categoryNames = const {}}) {
    final now = DateTime.now();
    final insights = <String>[];

    final thisMonth = getTotalForMonth(now.year, now.month);
    final lastMonth = getTotalForMonth(
      now.month == 1 ? now.year - 1 : now.year,
      now.month == 1 ? 12 : now.month - 1,
    );

    if (lastMonth > 0) {
      final diff = ((thisMonth - lastMonth) / lastMonth * 100).round();
      if (diff > 0) {
        insights.add('You spent $diff% more this month compared to last month.');
      } else if (diff < 0) {
        insights.add('Great job! You saved ${diff.abs()}% more than last month! 🎉');
      }
    }

    final catTotals = getCategoryTotals(now.year, now.month);
    if (catTotals.isNotEmpty) {
      final topCat = catTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      final catName = categoryNames[topCat.key] ?? topCat.key;
      insights.add('Your biggest expense this month was "$catName".');
    }

    final todayTotal = getTotalForDay(now);
    if (todayTotal > 0) {
      insights.add('You have spent ${todayTotal.toStringAsFixed(2)} today.');
    }

    return insights;
  }
}
