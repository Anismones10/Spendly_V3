import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/category_model.dart';

class CategoryProvider extends ChangeNotifier {
  final Box<CategoryModel> _box = Hive.box<CategoryModel>('categories');

  static final List<CategoryModel> _defaults = [
    CategoryModel(id: 'food', name: 'Food', colorValue: 0xFFFF6B6B, icon: 'food'),
    CategoryModel(id: 'transport', name: 'Transport', colorValue: 0xFF4ECDC4, icon: 'transport'),
    CategoryModel(id: 'bills', name: 'Bills', colorValue: 0xFF45B7D1, icon: 'bills'),
    CategoryModel(id: 'entertainment', name: 'Entertainment', colorValue: 0xFF96CEB4, icon: 'entertainment'),
    CategoryModel(id: 'health', name: 'Health', colorValue: 0xFFFF9FF3, icon: 'health'),
    CategoryModel(id: 'shopping', name: 'Shopping', colorValue: 0xFFFFBE76, icon: 'shopping'),
  ];

  CategoryProvider() {
    _seedDefaults();
  }

  void _seedDefaults() {
    for (final cat in _defaults) {
      if (!_box.containsKey(cat.id)) {
        _box.put(cat.id, cat);
      }
    }
  }

  List<CategoryModel> get categories => _box.values.toList();

  CategoryModel? getById(String id) => _box.get(id);

  void addCustomCategory(CategoryModel category) {
    _box.put(category.id, category);
    notifyListeners();
  }

  void deleteCustomCategory(String id) {
    final cat = _box.get(id);
    if (cat != null && cat.isCustom) {
      _box.delete(id);
      notifyListeners();
    }
  }

  void clearAll() {
    _box.clear();
    _seedDefaults(); // re-add defaults after clearing
    notifyListeners();
  }
}
