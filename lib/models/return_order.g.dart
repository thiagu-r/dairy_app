// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'return_order.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReturnOrderAdapter extends TypeAdapter<ReturnOrder> {
  @override
  final int typeId = 14;

  @override
  ReturnOrder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReturnOrder(
      syncStatus: fields[0] as String,
      items: (fields[1] as List).cast<ReturnOrderItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, ReturnOrder obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.syncStatus)
      ..writeByte(1)
      ..write(obj.items);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReturnOrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReturnOrderItemAdapter extends TypeAdapter<ReturnOrderItem> {
  @override
  final int typeId = 15;

  @override
  ReturnOrderItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReturnOrderItem(
      product: fields[0] as int,
      quantity: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ReturnOrderItem obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.product)
      ..writeByte(1)
      ..write(obj.quantity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReturnOrderItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
