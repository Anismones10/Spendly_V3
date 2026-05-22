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

  ExpenseProvider() {
    // Run recurring check on startup
    _processRecurringExpenses();
  }

  // ── Recurring expense engine ─────────────────────────────────────────────

  /// Called on app start and whenever needed.
  /// Generates missed recurring instances for all parent recurring expenses.
  void _processRecurringExpenses() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Find all parent recurring expenses (those with isRecurring=true and no parent)
    final parents = _box.values
        .where((e) => e.isRecurring && e.recurringParentId == null)
        .toList();

    bool changed = false;

    for (final parent in parents) {
      if (parent.recurringType == null) continue;

      // Determine the last generated date (or parent's own date if never generated)
      DateTime lastGen = parent.recurringLastGenerated ??
          DateTime(parent.date.year, parent.date.month, parent.date.day);

      // Generate all missed instances up to today
      DateTime next = _nextOccurrence(lastGen, parent.recurringType!);

      while (!next.isAfter(today)) {
        // Check if an instance for this exact date already exists
        final alreadyExists = _box.values.any((e) =>
            e.recurringParentId == parent.id &&
            e.date.year == next.year &&
            e.date.month == next.month &&
            e.date.day == next.day);

        if (!alreadyExists) {
          final instance = ExpenseModel(
            id: '${parent.id}_${next.millisecondsSinceEpoch}',
            name: parent.name,
            amount: parent.amount,
            categoryId: parent.categoryId,
            date: next,
            note: parent.note,
            isRecurring: false, // instances are not themselves recurring
            recurringType: null,
            walletId: parent.walletId,
            timeHour: parent.timeHour,
            timeMinute: parent.timeMinute,
            recurringParentId: parent.id,
          );
          _box.put(instance.id, instance);
          changed = true;
        }

        // Update last generated on the parent
        parent.recurringLastGenerated = next;
        parent.save();

        lastGen = next;
        next = _nextOccurrence(lastGen, parent.recurringType!);
      }
    }

    if (changed) notifyListeners();
  }

  /// Computes the next occurrence date after [from] based on [type].
  DateTime _nextOccurrence(DateTime from, String type) {
    switch (type) {
      case 'daily':
        return DateTime(from.year, from.month, from.day + 1);
      case 'weekly':
        return DateTime(from.year, from.month, from.day + 7);
      case 'monthly':
        return DateTime(from.year, from.month + 1, from.day);
      default:
        return DateTime(from.year, from.month + 1, from.day);
    }
  }

  /// Call this to re-run the recurring engine (e.g. after app resume).
  void checkRecurring() => _processRecurringExpenses();

  // ── Getters ──────────────────────────────────────────────────────────────

  List<ExpenseModel> get allExpenses => _box.values.toList();

  /// All parent recurring templates (for management UI)
  List<ExpenseModel> get recurringTemplates => _box.values
      .where((e) => e.isRecurring && e.recurringParentId == null)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  List<ExpenseModel> get filteredExpenses {
    List<ExpenseModel> list = _box.values.toList();

    if (_searchQuery.isNotEmpty) {
      list = list
          .where((e) =>
              e.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_filterCategory != null) {
      list =
          list.where((e) => e.categoryId == _filterCategory).toList();
    }
    if (_dateRange != null) {
      list = list
          .where((e) =>
              e.date.isAfter(_dateRange!.start
                  .subtract(const Duration(days: 1))) &&
              e.date.isBefore(
                  _dateRange!.end.add(const Duration(days: 1))))
          .toList();
    }

    switch (_sortBy) {
      case 'amountAsc':
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case 'amountDesc':
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'dateAsc':
        // Sort by full dateTime (date + time)
        list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        break;
      case 'dateDesc':
      default:
        list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    }
    return list;
  }

  // ── Wallet filtering ─────────────────────────────────────────────────────

  List<ExpenseModel> getExpensesForWallet(String walletId) {
    return _box.values
        .where((e) => e.walletId == walletId)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  double getTotalForWallet(String walletId) {
    return getExpensesForWallet(walletId)
        .fold(0, (sum, e) => sum + e.amount);
  }

  double getWalletTotalForMonth(
      String walletId, int year, int month) {
    return _box.values
        .where((e) =>
            e.walletId == walletId &&
            e.date.year == year &&
            e.date.month == month)
        .fold(0, (sum, e) => sum + e.amount);
  }

  // ── Standard methods ─────────────────────────────────────────────────────

  List<ExpenseModel> getExpensesForMonth(int year, int month) {
    return _box.values
        .where((e) => e.date.year == year && e.date.month == month)
        .toList();
  }

  List<ExpenseModel> getExpensesForDay(DateTime day) {
    return _box.values
        .where((e) =>
            e.date.year == day.year &&
            e.date.month == day.month &&
            e.date.day == day.day)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  double getTotalForMonth(int year, int month) {
    return getExpensesForMonth(year, month)
        .fold(0, (sum, e) => sum + e.amount);
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
    // After adding a new recurring parent, generate its first future instances
    if (expense.isRecurring) _processRecurringExpenses();
    notifyListeners();
  }

  void updateExpense(ExpenseModel expense) {
    _box.put(expense.id, expense);
    notifyListeners();
  }

  /// Deletes an expense. If it's a recurring parent, deletes all its instances too.
  void deleteExpense(String id) {
    final expense = _box.get(id);
    if (expense != null && expense.isRecurring) {
      // Delete all generated instances
      final instanceKeys = _box.values
          .where((e) => e.recurringParentId == id)
          .map((e) => e.id)
          .toList();
      for (final key in instanceKeys) {
        _box.delete(key);
      }
    }
    _box.delete(id);
    notifyListeners();
  }

  /// Deletes only the generated instances of a recurring parent (keeps parent).
  void deleteRecurringInstances(String parentId) {
    final instanceKeys = _box.values
        .where((e) => e.recurringParentId == parentId)
        .map((e) => e.id)
        .toList();
    for (final key in instanceKeys) {
      _box.delete(key);
    }
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

  List<String> getInsights(
      {Map<String, String> categoryNames = const {}}) {
    final now = DateTime.now();
    final insights = <String>[];

    final thisMonth = getTotalForMonth(now.year, now.month);
    final lastMonth = getTotalForMonth(
      now.month == 1 ? now.year - 1 : now.year,
      now.month == 1 ? 12 : now.month - 1,
    );

    if (lastMonth > 0) {
      final diff =
          ((thisMonth - lastMonth) / lastMonth * 100).round();
      if (diff > 0) {
        insights.add(
            'You spent $diff% more this month compared to last month.');
      } else if (diff < 0) {
        insights.add(
            'Great job! You saved ${diff.abs()}% more than last month!');
      }
    }

    final catTotals = getCategoryTotals(now.year, now.month);
    if (catTotals.isNotEmpty) {
      final topCat = catTotals.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      final catName = categoryNames[topCat.key] ?? topCat.key;
      insights
          .add('Your biggest expense this month was "$catName".');
    }

    final todayTotal = getTotalForDay(now);
    if (todayTotal > 0) {
      insights.add(
          'You have spent ${todayTotal.toStringAsFixed(2)} today.');
    }

    return insights;
  }
}
