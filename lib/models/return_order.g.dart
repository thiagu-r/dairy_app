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
      id: fields[0] as String,
      orderNumber: fields[1] as String,
      date: fields[2] as String,
      routeId: fields[3] as String,
      routeName: fields[4] as String,
      items: (fields[5] as List).cast<ReturnOrderItem>(),
      syncStatus: fields[6] as String,
      localId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ReturnOrder obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.orderNumber)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.routeId)
      ..writeByte(4)
      ..write(obj.routeName)
      ..writeByte(5)
      ..write(obj.items)
      ..writeByte(6)
      ..write(obj.syncStatus)
      ..writeByte(7)
      ..write(obj.localId);
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
      productId: fields[0] as String,
      productName: fields[1] as String,
      quantity: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ReturnOrderItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
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
