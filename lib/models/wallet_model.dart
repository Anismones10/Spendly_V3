import 'package:hive/hive.dart';

part 'wallet_model.g.dart';

@HiveType(typeId: 6)
class WalletModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String type; // 'cash', 'card', 'bank', 'savings'

  @HiveField(3)
  double balance;

  @HiveField(4)
  int colorValue;

  @HiveField(5)
  String icon;

  /// If true → wallet can go negative (credit card style).
  /// If false → expense is hard-blocked when balance is insufficient.
  /// Defaults to true for 'card', false for everything else.
  @HiveField(6)
  bool allowOverdraft;

  WalletModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.colorValue,
    this.icon = 'wallet',
    bool? allowOverdraft,
  }) : allowOverdraft = allowOverdraft ?? (type == 'card');
}
