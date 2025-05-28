// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'denomination.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DenominationAdapter extends TypeAdapter<Denomination> {
  @override
  final int typeId = 11;

  @override
  Denomination read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Denomination(
      date: fields[0] as String,
      note500: fields[1] as int,
      note200: fields[2] as int,
      note100: fields[3] as int,
      note50: fields[4] as int,
      note20: fields[5] as int,
      note10: fields[6] as int,
      coin1: fields[7] as int,
      coin2: fields[8] as int,
      coin5: fields[9] as int,
      totalCashCollected: fields[10] as double,
      totalExpenses: fields[11] as double,
      denominationTotal: fields[12] as double,
      difference: fields[13] as double,
      localId: fields[14] as String?,
      syncStatus: fields[15] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Denomination obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.note500)
      ..writeByte(2)
      ..write(obj.note200)
      ..writeByte(3)
      ..write(obj.note100)
      ..writeByte(4)
      ..write(obj.note50)
      ..writeByte(5)
      ..write(obj.note20)
      ..writeByte(6)
      ..write(obj.note10)
      ..writeByte(7)
      ..write(obj.coin1)
      ..writeByte(8)
      ..write(obj.coin2)
      ..writeByte(9)
      ..write(obj.coin5)
      ..writeByte(10)
      ..write(obj.totalCashCollected)
      ..writeByte(11)
      ..write(obj.totalExpenses)
      ..writeByte(12)
      ..write(obj.denominationTotal)
      ..writeByte(13)
      ..write(obj.difference)
      ..writeByte(14)
      ..write(obj.localId)
      ..writeByte(15)
      ..write(obj.syncStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DenominationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
