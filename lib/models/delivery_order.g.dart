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
      id: fields[0] as int,
      orderNumber: fields[1] as String,
      seller: fields[2] as int,
      sellerName: fields[3] as String,
      route: fields[4] as int,
      routeName: fields[5] as String,
      deliveryDate: fields[6] as String,
      deliveryTime: fields[7] as String?,
      totalPrice: fields[8] as String,
      openingBalance: fields[9] as String,
      amountCollected: fields[10] as String,
      balanceAmount: fields[11] as String,
      paymentMethod: fields[12] as String,
      status: fields[13] as String,
      notes: fields[14] as String?,
      items: (fields[15] as List).cast<DeliveryOrderItem>(),
      syncStatus: fields[16] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DeliveryOrder obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.orderNumber)
      ..writeByte(2)
      ..write(obj.seller)
      ..writeByte(3)
      ..write(obj.sellerName)
      ..writeByte(4)
      ..write(obj.route)
      ..writeByte(5)
      ..write(obj.routeName)
      ..writeByte(6)
      ..write(obj.deliveryDate)
      ..writeByte(7)
      ..write(obj.deliveryTime)
      ..writeByte(8)
      ..write(obj.totalPrice)
      ..writeByte(9)
      ..write(obj.openingBalance)
      ..writeByte(10)
      ..write(obj.amountCollected)
      ..writeByte(11)
      ..write(obj.balanceAmount)
      ..writeByte(12)
      ..write(obj.paymentMethod)
      ..writeByte(13)
      ..write(obj.status)
      ..writeByte(14)
      ..write(obj.notes)
      ..writeByte(15)
      ..write(obj.items)
      ..writeByte(16)
      ..write(obj.syncStatus);
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
