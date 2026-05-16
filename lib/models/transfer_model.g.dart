// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransferModelAdapter extends TypeAdapter<TransferModel> {
  @override
  final int typeId = 8;

  @override
  TransferModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransferModel(
      id: fields[0] as String,
      fromWalletId: fields[1] as String,
      toWalletId: fields[2] as String,
      amount: fields[3] as double,
      date: fields[4] as DateTime,
      note: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TransferModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fromWalletId)
      ..writeByte(2)
      ..write(obj.toWalletId)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
