import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/goal_model.dart';

class GoalProvider extends ChangeNotifier {
  final Box<GoalModel> _box = Hive.box<GoalModel>('goals');

  List<GoalModel> get goals => _box.values.toList();
  List<GoalModel> get activeGoals => goals.where((g) => !g.isCompleted).toList();
  List<GoalModel> get completedGoals => goals.where((g) => g.isCompleted).toList();

  void addGoal(GoalModel goal) {
    _box.put(goal.id, goal);
    notifyListeners();
  }

  void updateGoalSavings(String id, double amount) {
    final goal = _box.get(id);
    if (goal != null) {
      goal.savedAmount += amount;
      if (goal.savedAmount >= goal.targetAmount) {
        goal.isCompleted = true;
      }
      goal.save();
      notifyListeners();
    }
  }

  void deleteGoal(String id) {
    _box.delete(id);
    notifyListeners();
  }

  void clearAll() {
    _box.clear();
    notifyListeners();
  }
}
