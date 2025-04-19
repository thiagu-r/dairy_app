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
  final String deliveredQuantity;
  
  @HiveField(7)
  final String totalQuantity;
  
  @HiveField(8)
  final String returnQuantity;
  
  @HiveField(9)
  final String? unitPrice;
  
  @HiveField(10)
  double? brokenQuantity;

  LoadingOrderItem({
    required this.id,
    required this.product,
    required this.productName,
    required this.purchaseOrderQuantity,
    required this.loadedQuantity,
    required this.remainingQuantity,
    required this.deliveredQuantity,
    required this.totalQuantity,
    required this.returnQuantity,
    this.unitPrice,
    this.brokenQuantity,
  });

  factory LoadingOrderItem.fromJson(Map<String, dynamic> json) {
    return LoadingOrderItem(
      id: json['id'],
      product: json['product'],
      productName: json['product_name'],
      purchaseOrderQuantity: json['purchase_order_quantity'],
      loadedQuantity: json['loaded_quantity'],
      remainingQuantity: json['remaining_quantity'],
      deliveredQuantity: json['delivered_quantity'],
      totalQuantity: json['total_quantity'],
      returnQuantity: json['return_quantity'],
      unitPrice: json['unit_price'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product': product,
    'product_name': productName,
    'purchase_order_quantity': purchaseOrderQuantity,
    'loaded_quantity': loadedQuantity,
    'remaining_quantity': remainingQuantity,
    'delivered_quantity': deliveredQuantity,
    'total_quantity': totalQuantity,
    'return_quantity': returnQuantity,
    'unit_price': unitPrice,
  };
}
