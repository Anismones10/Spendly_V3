import 'package:hive/hive.dart';

part 'category_model.g.dart';

@HiveType(typeId: 1)
class CategoryModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int colorValue;

  @HiveField(3)
  String icon; // emoji or icon code

  @HiveField(4)
  bool isCustom;

  CategoryModel({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.icon,
    this.isCustom = false,
  });
}
