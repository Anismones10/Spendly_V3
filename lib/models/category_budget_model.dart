import 'package:hive/hive.dart';

part 'category_budget_model.g.dart';

@HiveType(typeId: 7)
class CategoryBudgetModel extends HiveObject {
  @HiveField(0)
  String categoryId;

  @HiveField(1)
  double limitAmount;

  CategoryBudgetModel({
    required this.categoryId,
    required this.limitAmount,
  });
}
