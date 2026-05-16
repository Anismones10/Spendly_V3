import 'package:hive/hive.dart';

part 'transfer_model.g.dart';

@HiveType(typeId: 8)
class TransferModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String fromWalletId;

  @HiveField(2)
  String toWalletId;

  @HiveField(3)
  double amount;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  String? note;

  TransferModel({
    required this.id,
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    required this.date,
    this.note,
  });
}
