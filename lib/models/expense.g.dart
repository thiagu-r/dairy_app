// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 16;

  @override
  Expense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Expense(
      id: fields[0] as String,
      date: fields[1] as String,
      description: fields[2] as String?,
      amount: fields[3] as double,
      route: fields[6] as int,
      expenseType: fields[7] as ExpenseType,
      syncStatus: fields[4] as String,
      localId: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.syncStatus)
      ..writeByte(5)
      ..write(obj.localId)
      ..writeByte(6)
      ..write(obj.route)
      ..writeByte(7)
      ..write(obj.expenseType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExpenseTypeAdapter extends TypeAdapter<ExpenseType> {
  @override
  final int typeId = 17;

  @override
  ExpenseType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExpenseType.food;
      case 1:
        return ExpenseType.vehicle;
      case 2:
        return ExpenseType.fuel;
      case 3:
        return ExpenseType.other;
      case 4:
        return ExpenseType.allowance;
      default:
        return ExpenseType.food;
    }
  }

  @override
  void write(BinaryWriter writer, ExpenseType obj) {
    switch (obj) {
      case ExpenseType.food:
        writer.writeByte(0);
        break;
      case ExpenseType.vehicle:
        writer.writeByte(1);
        break;
      case ExpenseType.fuel:
        writer.writeByte(2);
        break;
      case ExpenseType.other:
        writer.writeByte(3);
        break;
      case ExpenseType.allowance:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
