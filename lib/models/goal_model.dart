import 'package:hive/hive.dart';

part 'goal_model.g.dart';

@HiveType(typeId: 2)
class GoalModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double targetAmount;

  @HiveField(3)
  double savedAmount;

  @HiveField(4)
  DateTime? deadline;

  @HiveField(5)
  bool isCompleted;

  GoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.savedAmount = 0,
    this.deadline,
    this.isCompleted = false,
  });

  double get progress => savedAmount / targetAmount;
  double get remaining => targetAmount - savedAmount;
}
