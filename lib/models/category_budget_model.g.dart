// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_budget_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoryBudgetModelAdapter extends TypeAdapter<CategoryBudgetModel> {
  @override
  final int typeId = 7;

  @override
  CategoryBudgetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryBudgetModel(
      categoryId: fields[0] as String,
      limitAmount: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryBudgetModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.categoryId)
      ..writeByte(1)
      ..write(obj.limitAmount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryBudgetModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
