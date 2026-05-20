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

  @HiveField(8)
  String? walletId;

  @HiveField(9)
  int? timeHour; // NEW — hour (0–23)

  @HiveField(10)
  int? timeMinute; // NEW — minute (0–59)

  @HiveField(11)
  String? recurringParentId; // NEW — links generated instances to parent

  @HiveField(12)
  DateTime? recurringLastGenerated; // NEW — tracks last auto-generation date

  ExpenseModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.note,
    this.isRecurring = false,
    this.recurringType,
    this.walletId,
    this.timeHour,
    this.timeMinute,
    this.recurringParentId,
    this.recurringLastGenerated,
  });

  /// Returns the full DateTime combining date + time fields
  DateTime get dateTime {
    return DateTime(
      date.year,
      date.month,
      date.day,
      timeHour ?? 0,
      timeMinute ?? 0,
    );
  }

  /// Formatted time string e.g. "09:30 AM"
  String get formattedTime {
    if (timeHour == null || timeMinute == null) return '';
    final h = timeHour!;
    final m = timeMinute!;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final min = m.toString().padLeft(2, '0');
    return '$hour:$min $period';
  }
}
