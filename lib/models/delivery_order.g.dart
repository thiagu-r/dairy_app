// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_order.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeliveryOrderAdapter extends TypeAdapter<DeliveryOrder> {
  @override
  final int typeId = 4;

  @override
  DeliveryOrder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeliveryOrder(
      id: fields[0] as String,
      orderNumber: fields[1] as String,
      deliveryDate: fields[2] as String,
      route: fields[3] as int,
      routeName: fields[4] as String,
      sellerName: fields[5] as String,
      status: fields[6] as String,
      items: (fields[7] as List).cast<DeliveryOrderItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, DeliveryOrder obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.orderNumber)
      ..writeByte(2)
      ..write(obj.deliveryDate)
      ..writeByte(3)
      ..write(obj.route)
      ..writeByte(4)
      ..write(obj.routeName)
      ..writeByte(5)
      ..write(obj.sellerName)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.items);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryOrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DeliveryOrderItemAdapter extends TypeAdapter<DeliveryOrderItem> {
  @override
  final int typeId = 5;

  @override
  DeliveryOrderItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeliveryOrderItem(
      id: fields[0] as int,
      product: fields[1] as int,
      productName: fields[2] as String,
      orderedQuantity: fields[3] as String,
      extraQuantity: fields[4] as String,
      deliveredQuantity: fields[5] as String,
      unitPrice: fields[6] as String,
      totalPrice: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DeliveryOrderItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.product)
      ..writeByte(2)
      ..write(obj.productName)
      ..writeByte(3)
      ..write(obj.orderedQuantity)
      ..writeByte(4)
      ..write(obj.extraQuantity)
      ..writeByte(5)
      ..write(obj.deliveredQuantity)
      ..writeByte(6)
      ..write(obj.unitPrice)
      ..writeByte(7)
      ..write(obj.totalPrice);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryOrderItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
