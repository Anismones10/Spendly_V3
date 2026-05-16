import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/category_budget_model.dart';

class CategoryBudgetProvider extends ChangeNotifier {
  final Box<CategoryBudgetModel> _box =
      Hive.box<CategoryBudgetModel>('category_budgets');

  List<CategoryBudgetModel> get all => _box.values.toList();

  /// Get budget for a specific category (null if not set)
  CategoryBudgetModel? getForCategory(String categoryId) =>
      _box.get(categoryId);

  /// Get limit amount for a category (0 if not set)
  double getLimitFor(String categoryId) =>
      _box.get(categoryId)?.limitAmount ?? 0;

  /// Check if a category has a budget set
  bool hasBudget(String categoryId) => _box.containsKey(categoryId);

  /// Usage percentage for a category (0.0 to 1.0+)
  double getUsagePercent(String categoryId, double spent) {
    final limit = getLimitFor(categoryId);
    if (limit <= 0) return 0;
    return spent / limit;
  }

  /// Status: 'ok', 'warning' (>=80%), 'danger' (>=100%)
  String getStatus(String categoryId, double spent) {
    final pct = getUsagePercent(categoryId, spent);
    if (pct >= 1.0) return 'danger';
    if (pct >= 0.8) return 'warning';
    return 'ok';
  }

  /// Color based on status
  Color getStatusColor(String categoryId, double spent) {
    final status = getStatus(categoryId, spent);
    switch (status) {
      case 'danger':
        return const Color(0xFFE57373);
      case 'warning':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF2ECC71);
    }
  }

  void setBudget(String categoryId, double limit) {
    final model = CategoryBudgetModel(
      categoryId: categoryId,
      limitAmount: limit,
    );
    _box.put(categoryId, model);
    notifyListeners();
  }

  void removeBudget(String categoryId) {
    _box.delete(categoryId);
    notifyListeners();
  }

  void clearAll() {
    _box.clear();
    notifyListeners();
  }
}
