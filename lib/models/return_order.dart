import 'package:hive/hive.dart';

part 'return_order.g.dart';

@HiveType(typeId: 14)
class ReturnOrder extends HiveObject {
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
  final List<ReturnOrderItem> items;

  @HiveField(6)
  String syncStatus;

  @HiveField(7)
  final String localId;

  ReturnOrder({
    required this.id,
    required this.orderNumber,
    required this.date,
    required this.routeId,
    required this.routeName,
    required this.items,
    this.syncStatus = 'pending',
    String? localId,
  }) : this.localId = localId ?? 'mobile-ro-${DateTime.now().millisecondsSinceEpoch}';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'date': date,
      'route_id': routeId,
      'route_name': routeName,
      'items': items.map((item) => item.toJson()).toList(),
      'local_id': localId,
    };
  }
}

@HiveType(typeId: 15)
class ReturnOrderItem {
  @HiveField(0)
  final String productId;

  @HiveField(1)
  final String productName;

  @HiveField(2)
  final double quantity;

  ReturnOrderItem({
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
}