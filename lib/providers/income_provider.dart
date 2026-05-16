import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/income_model.dart';
import '../models/wallet_model.dart';

class IncomeProvider extends ChangeNotifier {
  final Box<IncomeModel> _box = Hive.box<IncomeModel>('income');
  final Box<WalletModel> _walletBox = Hive.box<WalletModel>('wallets');

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
