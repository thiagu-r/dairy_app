import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class LoadingOrder {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String orderNumber;

  @HiveField(2)
  final int route;

  @HiveField(3)
  final String routeName;

  @HiveField(4)
  final String loadingDate;

  @HiveField(5)
  final String status;

  @HiveField(6)
  final List<LoadingOrderItem> items;

  LoadingOrder({
    required this.id,
    required this.orderNumber,
    required this.route,
    required this.routeName,
    required this.loadingDate,
    required this.status,
    required this.items,
  });

  factory LoadingOrder.fromJson(Map<String, dynamic> json) {
    return LoadingOrder(
      id: json['id'],
      orderNumber: json['order_number'],
      route: json['route'],
      routeName: json['route_name'],
      loadingDate: json['loading_date'],
      status: json['status'],
      items: (json['items'] as List)
          .map((item) => LoadingOrderItem.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'route': route,
      'route_name': routeName,
      'loading_date': loadingDate,
      'status': status,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

@HiveType(typeId: 3)
class LoadingOrderItem {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int product;

  @HiveField(2)
  final String productName;

  @HiveField(3)
  final String purchaseOrderQuantity;

  @HiveField(4)
  final String loadedQuantity;

  @HiveField(5)
  final String remainingQuantity;

  @HiveField(6)
  final String totalQuantity;

  LoadingOrderItem({
    required this.id,
    required this.product,
    required this.productName,
    required this.purchaseOrderQuantity,
    required this.loadedQuantity,
    required this.remainingQuantity,
    required this.totalQuantity,
  });

  factory LoadingOrderItem.fromJson(Map<String, dynamic> json) {
    return LoadingOrderItem(
      id: json['id'],
      product: json['product'],
      productName: json['product_name'],
      purchaseOrderQuantity: json['purchase_order_quantity'],
      loadedQuantity: json['loaded_quantity'],
      remainingQuantity: json['remaining_quantity'],
      totalQuantity: json['total_quantity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product,
      'product_name': productName,
      'purchase_order_quantity': purchaseOrderQuantity,
      'loaded_quantity': loadedQuantity,
      'remaining_quantity': remainingQuantity,
      'total_quantity': totalQuantity,
    };
  }
}

class LoadingOrderAdapter extends TypeAdapter<LoadingOrder> {
  @override
  final int typeId = 2;

  @override
  LoadingOrder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LoadingOrder(
      id: fields[0] as int,
      orderNumber: fields[1] as String,
      route: fields[2] as int,
      routeName: fields[3] as String,
      loadingDate: fields[4] as String,
      status: fields[5] as String,
      items: (fields[6] as List).cast<LoadingOrderItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, LoadingOrder obj) {
    writer.writeByte(7);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.orderNumber);
    writer.writeByte(2);
    writer.write(obj.route);
    writer.writeByte(3);
    writer.write(obj.routeName);
    writer.writeByte(4);
    writer.write(obj.loadingDate);
    writer.writeByte(5);
    writer.write(obj.status);
    writer.writeByte(6);
    writer.write(obj.items);
  }
}

class LoadingOrderItemAdapter extends TypeAdapter<LoadingOrderItem> {
  @override
  final int typeId = 3;

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
      totalQuantity: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LoadingOrderItem obj) {
    writer.writeByte(7);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.product);
    writer.writeByte(2);
    writer.write(obj.productName);
    writer.writeByte(3);
    writer.write(obj.purchaseOrderQuantity);
    writer.writeByte(4);
    writer.write(obj.loadedQuantity);
    writer.writeByte(5);
    writer.write(obj.remainingQuantity);
    writer.writeByte(6);
    writer.write(obj.totalQuantity);
  }
}
