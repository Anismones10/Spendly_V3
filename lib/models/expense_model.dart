import 'package:hive/hive.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 0)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String categoryId;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  String? note;

  @HiveField(6)
  bool isRecurring;

  @HiveField(7)
  String? recurringType; // 'daily', 'weekly', 'monthly'

  ExpenseModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.note,
    this.isRecurring = false,
    this.recurringType,
  });
}
