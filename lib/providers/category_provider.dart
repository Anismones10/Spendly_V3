import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/category_model.dart';

class CategoryProvider extends ChangeNotifier {
  final Box<CategoryModel> _box = Hive.box<CategoryModel>('categories');
  final Box _settingsBox = Hive.box('settings');

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

  // ── Order management ──────────────────────────────────────────────────────

  List<String> get _savedOrder {
    final saved = _settingsBox.get('categoryOrder') as List?;
    return saved != null ? List<String>.from(saved) : [];
  }

  void _saveOrder(List<String> order) {
    _settingsBox.put('categoryOrder', order);
  }

  /// Returns categories in the user-defined order
  List<CategoryModel> get categories {
    final all = _box.values.toList();
    final order = _savedOrder;

    if (order.isEmpty) return all;

    // Sort by saved order, put unknown ones at end
    final ordered = <CategoryModel>[];
    for (final id in order) {
      final cat = all.firstWhere((c) => c.id == id,
          orElse: () => CategoryModel(
              id: '', name: '', colorValue: 0, icon: ''));
      if (cat.id.isNotEmpty) ordered.add(cat);
    }

    // Add any categories not in saved order (newly added)
    for (final cat in all) {
      if (!order.contains(cat.id)) {
        ordered.add(cat);
      }
    }

    return ordered;
  }

  CategoryModel? getById(String id) => _box.get(id);

  /// Reorder categories — called when user drags
  void reorderCategories(int oldIndex, int newIndex) {
    final current = categories;
    if (oldIndex < newIndex) newIndex -= 1;
    final item = current.removeAt(oldIndex);
    current.insert(newIndex, item);
    _saveOrder(current.map((c) => c.id).toList());
    notifyListeners();
  }

  void addCustomCategory(CategoryModel category) {
    _box.put(category.id, category);
    // Add to end of order
    final order = _savedOrder;
    if (!order.contains(category.id)) {
      order.add(category.id);
      _saveOrder(order);
    }
    notifyListeners();
  }

  void deleteCustomCategory(String id) {
    final cat = _box.get(id);
    if (cat != null && cat.isCustom) {
      _box.delete(id);
      final order = _savedOrder..remove(id);
      _saveOrder(order);
      notifyListeners();
    }
  }

  void clearAll() {
    _box.clear();
    _settingsBox.delete('categoryOrder');
    _seedDefaults();
    notifyListeners();
  }
}
