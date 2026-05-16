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
  String? walletId; // NEW — which wallet receives this income

  IncomeModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    this.note,
    this.source = 'other',
    this.walletId,
  });
}
