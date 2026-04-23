import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/savings_model.dart';

class SavingsProvider extends ChangeNotifier {
  final Box<SavingsModel> _box = Hive.box<SavingsModel>('savings');

  List<SavingsModel> get savings => _box.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  double get totalSaved => _box.values.fold(0, (sum, s) => sum + s.amount);

  void addSaving(SavingsModel saving) {
    _box.put(saving.id, saving);
    notifyListeners();
  }

  void clearAll() {
    _box.clear();
    notifyListeners();
  }
}
