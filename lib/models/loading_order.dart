import 'package:hive/hive.dart';

part 'loading_order.g.dart';

@HiveType(typeId: 1)
class LoadingOrder extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String orderNumber;

  @HiveField(2)
  final String loadingDate;

  @HiveField(3)
  final int route;

  @HiveField(4)
  final String routeName;

  @HiveField(5)
  final String status;

  @HiveField(6)
  final List<LoadingOrderItem> items;

  LoadingOrder({
    required this.id,
    required this.orderNumber,
    required this.loadingDate,
    required this.route,
    required this.routeName,
    required this.status,
    required this.items,
  });

  factory LoadingOrder.fromJson(Map<String, dynamic> json) {
    return LoadingOrder(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? '',
      loadingDate: json['loading_date']?.toString() ?? '',
      route: json['route'] is int ? json['route'] : int.parse(json['route'].toString()),
      routeName: json['route_name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      items: (json['items'] as List? ?? [])
          .map((item) => LoadingOrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_number': orderNumber,
    'loading_date': loadingDate,
    'route': route,
    'route_name': routeName,
    'status': status,
    'items': items.map((item) => item.toJson()).toList(),
  };
}

@HiveType(typeId: 2)
class LoadingOrderItem extends HiveObject {
  @HiveField(0)
  final int product;

  @HiveField(1)
  final String productName;

  @HiveField(2)
  final String totalQuantity;

  @HiveField(3)
  String loadedQuantity;

  @HiveField(4)
  String remainingQuantity;

  LoadingOrderItem({
    required this.product,
    required this.productName,
    required this.totalQuantity,
    this.loadedQuantity = "0",
    this.remainingQuantity = "0",
  });

  factory LoadingOrderItem.fromJson(Map<String, dynamic> json) {
    return LoadingOrderItem(
      product: json['product'] is int ? json['product'] : int.parse(json['product'].toString()),
      productName: json['product_name']?.toString() ?? '',
      totalQuantity: json['total_quantity']?.toString() ?? "0",
      loadedQuantity: json['loaded_quantity']?.toString() ?? "0",
      remainingQuantity: json['remaining_quantity']?.toString() ?? "0",
    );
  }

  Map<String, dynamic> toJson() => {
    'product': product,
    'product_name': productName,
    'total_quantity': totalQuantity,
    'loaded_quantity': loadedQuantity,
    'remaining_quantity': remainingQuantity,
  };
}
