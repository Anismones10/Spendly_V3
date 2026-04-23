import 'package:hive/hive.dart';

part 'savings_model.g.dart';

@HiveType(typeId: 3)
class SavingsModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String note;

  SavingsModel({
    required this.id,
    required this.amount,
    required this.date,
    this.note = '',
  });
}
