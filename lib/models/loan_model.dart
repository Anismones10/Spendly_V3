import 'package:hive/hive.dart';

part 'loan_model.g.dart';

@HiveType(typeId: 5)
class LoanModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String personName;

  @HiveField(2)
  double amount;

  @HiveField(3)
  double paidAmount;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  DateTime? dueDate;

  @HiveField(6)
  String type; // 'lending' or 'borrowing'

  @HiveField(7)
  String? note;

  @HiveField(8)
  String status; // 'pending', 'partial', 'paid'

  @HiveField(9)
  String? walletId; // NEW — which wallet is affected

  LoanModel({
    required this.id,
    required this.personName,
    required this.amount,
    this.paidAmount = 0,
    required this.date,
    this.dueDate,
    required this.type,
    this.note,
    this.status = 'pending',
    this.walletId,
  });

  double get remaining => amount - paidAmount;
  double get progress =>
      amount > 0 ? (paidAmount / amount).clamp(0.0, 1.0) : 0.0;
  bool get isOverdue =>
      dueDate != null &&
      dueDate!.isBefore(DateTime.now()) &&
      status != 'paid';
}
