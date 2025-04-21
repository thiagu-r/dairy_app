import 'package:hive/hive.dart';

part 'broken_order.g.dart';

@HiveType(typeId: 12)
class BrokenOrder extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String orderNumber;

  @HiveField(2)
  final String date;

  @HiveField(3)
  final String routeId;

  @HiveField(4)
  final String routeName;

  @HiveField(5)
  final List<BrokenOrderItem> items;

  @HiveField(6)
  String syncStatus;

  BrokenOrder({
    required this.id,
    required this.orderNumber,
    required this.date,
    required this.routeId,
    required this.routeName,
    required this.items,
    this.syncStatus = 'pending',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'date': date,
      'route_id': routeId,
      'route_name': routeName,
      'items': items.map((item) => item.toJson()).toList(),
      'sync_status': syncStatus,
    };
  }
}

@HiveType(typeId: 13)
class BrokenOrderItem extends HiveObject {
  @HiveField(0)
  final String productId;

  @HiveField(1)
  final String productName;

  @HiveField(2)
  final double quantity;

  BrokenOrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
    };
  }

  factory BrokenOrderItem.fromJson(Map<String, dynamic> json) {
    return BrokenOrderItem(
      productId: json['product_id'].toString(),
      productName: json['product_name'],
      quantity: double.parse(json['quantity'].toString()),
    );
  }
}
