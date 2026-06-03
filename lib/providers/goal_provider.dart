import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/goal_model.dart';
import '../utils/notification_helper.dart';

class GoalProvider extends ChangeNotifier {
  final Box<GoalModel> _box = Hive.box<GoalModel>('goals');

  List<GoalModel> get goals => _box.values.toList();
  List<GoalModel> get activeGoals => goals.where((g) => !g.isCompleted).toList();
  List<GoalModel> get completedGoals => goals.where((g) => g.isCompleted).toList();

  void addGoal(GoalModel goal) {
    _box.put(goal.id, goal);
    notifyListeners();
  }

  void updateGoalSavings(String id, double amount) async {
    final goal = _box.get(id);
    if (goal == null) return;

    final oldPercent = (goal.savedAmount / goal.targetAmount * 100).round();

    goal.savedAmount += amount;
    if (goal.savedAmount >= goal.targetAmount) {
      goal.isCompleted = true;
    }
    goal.save();
    notifyListeners();

    final newPercent = (goal.savedAmount / goal.targetAmount * 100).round();
    final settings   = Hive.box('settings');
    final notifEnabled = settings.get('notifEnabled', defaultValue: false) as bool;
    final notifGoal    = settings.get('notifGoal',    defaultValue: true)  as bool;

    if (!notifEnabled || !notifGoal) return;

    // Fire milestone at 50%, 75%, 100% — only once each
    final milestones = [50, 75, 100];
    final goalIndex  = _box.values.toList().indexWhere((g) => g.id == id);

    for (final milestone in milestones) {
      if (oldPercent < milestone && newPercent >= milestone) {
        await NotificationHelper.showGoalMilestone(
          index: goalIndex >= 0 ? goalIndex : 0,
          goalName: goal.name,
          percent: milestone,
        );
        break; // Only fire the highest milestone reached
      }
    }
  }

  void updateGoalDetails({
    required String id,
    required String name,
    required double targetAmount,
    DateTime? deadline,
    String? iconKey,
  }) {
    final goal = _box.get(id);
    if (goal != null) {
      goal.name = name;
      goal.targetAmount = targetAmount;
      goal.deadline = deadline;
      goal.iconKey = iconKey;
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
