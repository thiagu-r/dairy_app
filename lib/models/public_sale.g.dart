// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_sale.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PublicSaleAdapter extends TypeAdapter<PublicSale> {
  @override
  final int typeId = 6;

  @override
  PublicSale read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PublicSale(
      id: fields[0] as int,
      route: fields[1] as int,
      customerName: fields[2] as String?,
      customerPhone: fields[3] as String?,
      customerAddress: fields[4] as String?,
      saleDate: fields[5] as String,
      saleTime: fields[6] as String?,
      paymentMethod: fields[7] as String,
      totalPrice: fields[8] as String,
      amountCollected: fields[9] as String,
      balanceAmount: fields[10] as String,
      items: (fields[11] as List).cast<PublicSaleItem>(),
      syncStatus: fields[12] as String,
      localId: fields[13] as String?,
      status: fields[14] as String,
      notes: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PublicSale obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.route)
      ..writeByte(2)
      ..write(obj.customerName)
      ..writeByte(3)
      ..write(obj.customerPhone)
      ..writeByte(4)
      ..write(obj.customerAddress)
      ..writeByte(5)
      ..write(obj.saleDate)
      ..writeByte(6)
      ..write(obj.saleTime)
      ..writeByte(7)
      ..write(obj.paymentMethod)
      ..writeByte(8)
      ..write(obj.totalPrice)
      ..writeByte(9)
      ..write(obj.amountCollected)
      ..writeByte(10)
      ..write(obj.balanceAmount)
      ..writeByte(11)
      ..write(obj.items)
      ..writeByte(12)
      ..write(obj.syncStatus)
      ..writeByte(13)
      ..write(obj.localId)
      ..writeByte(14)
      ..write(obj.status)
      ..writeByte(15)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicSaleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PublicSaleItemAdapter extends TypeAdapter<PublicSaleItem> {
  @override
  final int typeId = 7;

  @override
  PublicSaleItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PublicSaleItem(
      id: fields[0] as int,
      product: fields[1] as int,
      productName: fields[2] as String,
      quantity: fields[3] as String,
      unitPrice: fields[4] as String,
      totalPrice: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PublicSaleItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.product)
      ..writeByte(2)
      ..write(obj.productName)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.unitPrice)
      ..writeByte(5)
      ..write(obj.totalPrice);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicSaleItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
