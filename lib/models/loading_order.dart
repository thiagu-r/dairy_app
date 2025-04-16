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

  @HiveField(7)
  final int? cratesLoaded;  // Made nullable

  @HiveField(8)
  final String? loadingTime;  // Made nullable

  LoadingOrder({
    required this.id,
    required this.orderNumber,
    required this.route,
    required this.routeName,
    required this.loadingDate,
    required this.status,
    required this.items,
    this.cratesLoaded,  // Made optional
    this.loadingTime,   // Made optional
  });

  factory LoadingOrder.fromJson(Map<String, dynamic> json) {
    return LoadingOrder(
      id: json['id'] as int,
      orderNumber: json['order_number'] as String,
      route: json['route'] as int,
      routeName: json['route_name'] as String,
      loadingDate: json['loading_date'] as String,
      status: json['status'] as String,
      cratesLoaded: json['crates_loaded'] as int?,  // Handle nullable
      loadingTime: json['loading_time'] as String?,  // Handle nullable
      items: (json['items'] as List)
          .map((item) => LoadingOrderItem.fromJson(item))  // Use fromJson constructor
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
      'crates_loaded': cratesLoaded,
      'loading_time': loadingTime,
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

  @HiveField(7)
  final String deliveredQuantity;

  @HiveField(8)
  final String returnQuantity;

  LoadingOrderItem({
    required this.id,
    required this.product,
    required this.productName,
    required this.purchaseOrderQuantity,
    required this.loadedQuantity,
    required this.remainingQuantity,
    required this.totalQuantity,
    required this.deliveredQuantity,
    required this.returnQuantity,
  });

  factory LoadingOrderItem.fromJson(Map<String, dynamic> json) {
    return LoadingOrderItem(
      id: json['id'] as int,
      product: json['product'] as int,
      productName: json['product_name'] as String,
      purchaseOrderQuantity: (json['purchase_order_quantity'] ?? '0.000').toString(),
      loadedQuantity: (json['loaded_quantity'] ?? '0.000').toString(),
      remainingQuantity: (json['remaining_quantity'] ?? '0.000').toString(),
      totalQuantity: (json['total_quantity'] ?? '0.000').toString(),
      deliveredQuantity: (json['delivered_quantity'] ?? '0.000').toString(),
      returnQuantity: (json['return_quantity'] ?? '0.000').toString(),
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
      'delivered_quantity': deliveredQuantity,
      'return_quantity': returnQuantity,
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
      cratesLoaded: fields[7] as int?,  // Handle nullable
      loadingTime: fields[8] as String?,  // Handle nullable
    );
  }

  @override
  void write(BinaryWriter writer, LoadingOrder obj) {
    writer.writeByte(9);
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
    writer.writeByte(7);
    writer.write(obj.cratesLoaded);
    writer.writeByte(8);
    writer.write(obj.loadingTime);
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
      deliveredQuantity: fields[7] as String,
      returnQuantity: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LoadingOrderItem obj) {
    writer.writeByte(9);
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
    writer.writeByte(7);
    writer.write(obj.deliveredQuantity);
    writer.writeByte(8);
    writer.write(obj.returnQuantity);
  }
}
