import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/loan_model.dart';
import '../models/wallet_model.dart';

class LoanProvider extends ChangeNotifier {
  final Box<LoanModel> _box = Hive.box<LoanModel>('loans');
  final Box<WalletModel> _walletBox = Hive.box<WalletModel>('wallets');

  List<LoanModel> get allLoans => _box.values.toList();

  List<LoanModel> get lending =>
      _box.values.where((l) => l.type == 'lending').toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<LoanModel> get borrowing =>
      _box.values.where((l) => l.type == 'borrowing').toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<LoanModel> get overdueLoans =>
      _box.values.where((l) => l.isOverdue).toList();

  double get totalLending =>
      lending.where((l) => l.status != 'paid')
          .fold(0, (sum, l) => sum + l.remaining);

  double get totalBorrowing =>
      borrowing.where((l) => l.status != 'paid')
          .fold(0, (sum, l) => sum + l.remaining);

  double get netBalance => totalLending - totalBorrowing;

  // ── Add loan → affect wallet ──────────────────────────────────────────────
  void addLoan(LoanModel loan) {
    _box.put(loan.id, loan);

    if (loan.walletId != null) {
      final wallet = _walletBox.get(loan.walletId);
      if (wallet != null) {
        if (loan.type == 'borrowing') {
          // Borrowed money → comes INTO wallet → balance increases
          wallet.balance += loan.amount;
        } else {
          // Lent money → goes OUT of wallet → balance decreases
          wallet.balance -= loan.amount;
        }
        wallet.save();
      }
    }

    notifyListeners();
  }

  // ── Update loan → reverse old, apply new ─────────────────────────────────
  void updateLoan(LoanModel loan) {
    final old = _box.get(loan.id);

    // Reverse old wallet effect
    if (old != null && old.walletId != null) {
      final oldWallet = _walletBox.get(old.walletId);
      if (oldWallet != null) {
        if (old.type == 'borrowing') {
          oldWallet.balance -= old.amount;
        } else {
          oldWallet.balance += old.amount;
        }
        oldWallet.save();
      }
    }

    // Apply new wallet effect
    if (loan.walletId != null) {
      final newWallet = _walletBox.get(loan.walletId);
      if (newWallet != null) {
        if (loan.type == 'borrowing') {
          newWallet.balance += loan.amount;
        } else {
          newWallet.balance -= loan.amount;
        }
        newWallet.save();
      }
    }

    _box.put(loan.id, loan);
    notifyListeners();
  }

  // ── Record payment → affect wallet ───────────────────────────────────────
  void markPayment(String id, double amount) {
    final loan = _box.get(id);
    if (loan == null) return;

    final clampedAmount =
        amount.clamp(0, loan.remaining).toDouble();

    loan.paidAmount =
        (loan.paidAmount + clampedAmount).clamp(0, loan.amount);
    loan.status = loan.paidAmount >= loan.amount
        ? 'paid'
        : loan.paidAmount > 0
            ? 'partial'
            : 'pending';
    loan.save();

    // Payment affects wallet:
    // - Lending paid back → money comes BACK to wallet → balance increases
    // - Borrowing repaid → money leaves wallet → balance decreases
    if (loan.walletId != null) {
      final wallet = _walletBox.get(loan.walletId);
      if (wallet != null) {
        if (loan.type == 'lending') {
          wallet.balance += clampedAmount;
        } else {
          wallet.balance -= clampedAmount;
          if (wallet.balance < 0) wallet.balance = 0;
        }
        wallet.save();
      }
    }

    notifyListeners();
  }

  // ── Delete loan → reverse wallet effect ──────────────────────────────────
  void deleteLoan(String id) {
    final loan = _box.get(id);

    if (loan != null && loan.walletId != null) {
      final wallet = _walletBox.get(loan.walletId);
      if (wallet != null) {
        // Reverse the original wallet effect
        if (loan.type == 'borrowing') {
          // Was added → now remove remaining (unpaid portion)
          wallet.balance -= loan.remaining;
          if (wallet.balance < 0) wallet.balance = 0;
        } else {
          // Was deducted → now add remaining back
          wallet.balance += loan.remaining;
        }
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
