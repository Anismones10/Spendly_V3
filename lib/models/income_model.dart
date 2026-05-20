import 'package:hive/hive.dart';

part 'income_model.g.dart';

@HiveType(typeId: 4)
class IncomeModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String? note;

  @HiveField(5)
  String source; // 'salary', 'freelance', 'gift', 'sale', 'other'

  @HiveField(6)
  String? walletId;

  @HiveField(7)
  int? timeHour; // NEW — hour (0–23)

  @HiveField(8)
  int? timeMinute; // NEW — minute (0–59)

  IncomeModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    this.note,
    this.source = 'other',
    this.walletId,
    this.timeHour,
    this.timeMinute,
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
