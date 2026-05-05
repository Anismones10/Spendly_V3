import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/loan_model.dart';

class LoanProvider extends ChangeNotifier {
  final Box<LoanModel> _box = Hive.box<LoanModel>('loans');

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

  void addLoan(LoanModel loan) {
    _box.put(loan.id, loan);
    notifyListeners();
  }

  void updateLoan(LoanModel loan) {
    _box.put(loan.id, loan);
    notifyListeners();
  }

  void markPayment(String id, double amount) {
    final loan = _box.get(id);
    if (loan != null) {
      loan.paidAmount = (loan.paidAmount + amount).clamp(0, loan.amount);
      loan.status = loan.paidAmount >= loan.amount
          ? 'paid'
          : loan.paidAmount > 0
              ? 'partial'
              : 'pending';
      loan.save();
      notifyListeners();
    }
  }

  void deleteLoan(String id) {
    _box.delete(id);
    notifyListeners();
  }

  void clearAll() {
    _box.clear();
    notifyListeners();
  }
}
