import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/income_model.dart';
import '../models/wallet_model.dart';

class IncomeProvider extends ChangeNotifier {
  final Box<IncomeModel> _box = Hive.box<IncomeModel>('income');
  final Box<WalletModel> _walletBox = Hive.box<WalletModel>('wallets');

  // ── Filter state ───────────────────────────────────────────────────────────
  // Named to match ExpenseProvider so the shared filter bar can drive either
  // one without a translation layer.
  String _searchQuery = '';
  String? _filterSource;
  String _sortBy = 'dateDesc';
  DateTimeRange? _dateRange;

  String get searchQuery => _searchQuery;
  String? get filterSource => _filterSource;
  String get sortBy => _sortBy;
  DateTimeRange? get dateRange => _dateRange;

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterSource(String? source) {
    _filterSource = source;
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
    _filterSource = null;
    _sortBy = 'dateDesc';
    _dateRange = null;
    notifyListeners();
  }

  /// Everything matching the current search, source and date filters, in the
  /// chosen sort order.
  List<IncomeModel> get filteredIncome {
    var list = _box.values.toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((e) => e.name.toLowerCase().contains(q)).toList();
    }

    if (_filterSource != null) {
      list = list.where((e) => e.source == _filterSource).toList();
    }

    if (_dateRange != null) {
      // End is inclusive of the whole day, matching how the ranges are built.
      list = list
          .where((e) =>
              e.date.isAfter(
                  _dateRange!.start.subtract(const Duration(days: 1))) &&
              e.date.isBefore(_dateRange!.end.add(const Duration(days: 1))))
          .toList();
    }

    switch (_sortBy) {
      case 'dateAsc':
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'amountDesc':
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'amountAsc':
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case 'dateDesc':
      default:
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
    }
    return list;
  }

  /// Every distinct source in use, for the filter sheet to offer.
  List<String> get allSources {
    final set = _box.values.map((e) => e.source).toSet().toList();
    set.sort();
    return set;
  }

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

  /// Day of month → total earned that day, for the days that had any.
  ///
  /// Mirrors ExpenseProvider.getDailyTotals so the two Overview tabs can find
  /// their best and quietest days the same way. Days with nothing earned are
  /// absent rather than zero — the callers count them as the difference from
  /// the month's length.
  Map<int, double> getDailyTotals(int year, int month) {
    final income = getIncomeForMonth(year, month);
    final Map<int, double> totals = {};
    for (final e in income) {
      totals[e.date.day] = (totals[e.date.day] ?? 0) + e.amount;
    }
    return totals;
  }

  Map<String, double> getSourceTotals(int year, int month) {    final income = getIncomeForMonth(year, month);
    final Map<String, double> totals = {};
    for (final e in income) {
      totals[e.source] = (totals[e.source] ?? 0) + e.amount;
    }
    return totals;
  }

  // ── Add income → increase wallet balance ───────────────────────────────────
  void addIncome(IncomeModel income) {
    _box.put(income.id, income);

    // If a wallet is selected, increase its balance
    if (income.walletId != null) {
      final wallet = _walletBox.get(income.walletId);
      if (wallet != null) {
        wallet.balance += income.amount;
        wallet.save();
      }
    }

    notifyListeners();
  }

  // ── Update income → adjust wallet balance difference ───────────────────────
  void updateIncome(IncomeModel income) {
    final old = _box.get(income.id);

    // Reverse old wallet effect
    if (old != null && old.walletId != null) {
      final oldWallet = _walletBox.get(old.walletId);
      if (oldWallet != null) {
        oldWallet.balance -= old.amount;
        oldWallet.save();
      }
    }

    // Apply new wallet effect
    if (income.walletId != null) {
      final newWallet = _walletBox.get(income.walletId);
      if (newWallet != null) {
        newWallet.balance += income.amount;
        newWallet.save();
      }
    }

    _box.put(income.id, income);
    notifyListeners();
  }

  // ── Delete income → decrease wallet balance ────────────────────────────────
  void deleteIncome(String id) {
    final income = _box.get(id);

    if (income != null && income.walletId != null) {
      final wallet = _walletBox.get(income.walletId);
      if (wallet != null) {
        wallet.balance -= income.amount;
        // Don't go below 0
        if (wallet.balance < 0) wallet.balance = 0;
        wallet.save();
      }
    }

    _box.delete(id);
    notifyListeners();
  }

  void clearAll() {
    _box.clear();
    notifyListeners();
  }
}
