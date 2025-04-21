// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'broken_order.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BrokenOrderAdapter extends TypeAdapter<BrokenOrder> {
  @override
  final int typeId = 12;

  @override
  BrokenOrder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BrokenOrder(
      id: fields[0] as String,
      orderNumber: fields[1] as String,
      date: fields[2] as String,
      routeId: fields[3] as String,
      routeName: fields[4] as String,
      items: (fields[5] as List).cast<BrokenOrderItem>(),
      syncStatus: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BrokenOrder obj) {
    writer
      ..writeByte(7)
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
      ..write(obj.syncStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrokenOrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BrokenOrderItemAdapter extends TypeAdapter<BrokenOrderItem> {
  @override
  final int typeId = 13;

  @override
  BrokenOrderItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BrokenOrderItem(
      productId: fields[0] as String,
      productName: fields[1] as String,
      quantity: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, BrokenOrderItem obj) {
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
      other is BrokenOrderItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
