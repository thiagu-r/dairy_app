import 'package:hive/hive.dart';

part 'delivery_order.g.dart';

@HiveType(typeId: 4)
class DeliveryOrder extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String orderNumber;

  @HiveField(2)
  final String deliveryDate;

  @HiveField(3)
  final int route;

  @HiveField(4)
  final String routeName;

  @HiveField(5)
  final String sellerName;

  @HiveField(6)
  final String status;

  @HiveField(7)
  List<DeliveryOrderItem> items;

  DeliveryOrder({
    required this.id,
    required this.orderNumber,
    required this.deliveryDate,
    required this.route,
    required this.routeName,
    required this.sellerName,
    required this.status,
    required this.items,
  });

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    return DeliveryOrder(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? '',
      deliveryDate: json['delivery_date']?.toString() ?? '',
      route: json['route'] is int ? json['route'] : int.parse(json['route'].toString()),
      routeName: json['route_name']?.toString() ?? '',
      sellerName: json['seller_name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      items: (json['items'] as List? ?? [])
          .map((item) => DeliveryOrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_number': orderNumber,
    'delivery_date': deliveryDate,
    'route': route,
    'route_name': routeName,
    'seller_name': sellerName,
    'status': status,
    'items': items.map((item) => item.toJson()).toList(),
  };
}

@HiveType(typeId: 5)
class DeliveryOrderItem extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int product;

  @HiveField(2)
  final String productName;

  @HiveField(3)
  final String orderedQuantity;

  @HiveField(4)
  String extraQuantity;

  @HiveField(5)
  String deliveredQuantity;

  @HiveField(6)
  final String unitPrice;

  @HiveField(7)
  String totalPrice;

  DeliveryOrderItem({
    required this.id,
    required this.product,
    required this.productName,
    required this.orderedQuantity,
    required this.extraQuantity,
    required this.deliveredQuantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory DeliveryOrderItem.fromJson(Map<String, dynamic> json) {
    return DeliveryOrderItem(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      product: json['product'] is int ? json['product'] : int.parse(json['product'].toString()),
      productName: json['product_name']?.toString() ?? '',
      orderedQuantity: json['ordered_quantity']?.toString() ?? "0",
      extraQuantity: json['extra_quantity']?.toString() ?? "0",
      deliveredQuantity: json['delivered_quantity']?.toString() ?? "0",
      unitPrice: json['unit_price']?.toString() ?? "0",
      totalPrice: json['total_price']?.toString() ?? "0",
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product': product,
    'product_name': productName,
    'ordered_quantity': orderedQuantity,
    'extra_quantity': extraQuantity,
    'delivered_quantity': deliveredQuantity,
    'unit_price': unitPrice,
    'total_price': totalPrice,
  };
}
