// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loading_order.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LoadingOrderAdapter extends TypeAdapter<LoadingOrder> {
  @override
  final int typeId = 1;

  @override
  LoadingOrder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LoadingOrder(
      id: fields[0] as String,
      orderNumber: fields[1] as String,
      loadingDate: fields[2] as String,
      route: fields[3] as int,
      routeName: fields[4] as String,
      status: fields[5] as String,
      items: (fields[6] as List).cast<LoadingOrderItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, LoadingOrder obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.orderNumber)
      ..writeByte(2)
      ..write(obj.loadingDate)
      ..writeByte(3)
      ..write(obj.route)
      ..writeByte(4)
      ..write(obj.routeName)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.items);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadingOrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LoadingOrderItemAdapter extends TypeAdapter<LoadingOrderItem> {
  @override
  final int typeId = 2;

  @override
  LoadingOrderItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LoadingOrderItem(
      id: fields[0] as int,
      product: fields[1] as int,
      productName: fields[2] as String,
      purchaseOrderQuantity: fields[3] as String,
      loadedQuantity: fields[4] as String,
      remainingQuantity: fields[5] as String,
      deliveredQuantity: fields[6] as String,
      totalQuantity: fields[7] as String,
      returnQuantity: fields[8] as String,
      unitPrice: fields[9] as String?,
      brokenQuantity: fields[10] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, LoadingOrderItem obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.product)
      ..writeByte(2)
      ..write(obj.productName)
      ..writeByte(3)
      ..write(obj.purchaseOrderQuantity)
      ..writeByte(4)
      ..write(obj.loadedQuantity)
      ..writeByte(5)
      ..write(obj.remainingQuantity)
      ..writeByte(6)
      ..write(obj.deliveredQuantity)
      ..writeByte(7)
      ..write(obj.totalQuantity)
      ..writeByte(8)
      ..write(obj.returnQuantity)
      ..writeByte(9)
      ..write(obj.unitPrice)
      ..writeByte(10)
      ..write(obj.brokenQuantity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadingOrderItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
