// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan_model.dart';

class LoanModelAdapter extends TypeAdapter<LoanModel> {
  @override
  final int typeId = 5;

  @override
  LoanModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LoanModel(
      id: fields[0] as String,
      personName: fields[1] as String,
      amount: fields[2] as double,
      paidAmount: fields[3] as double,
      date: fields[4] as DateTime,
      dueDate: fields[5] as DateTime?,
      type: fields[6] as String,
      note: fields[7] as String?,
      status: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LoanModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.personName)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.paidAmount)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.dueDate)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.note)
      ..writeByte(8)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
