import 'package:hive/hive.dart';

part 'delivery_order.g.dart';  // This will be generated

@HiveType(typeId: 4)
class DeliveryOrder extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String orderNumber;

  @HiveField(2)
  final int seller;

  @HiveField(3)
  final String sellerName;

  @HiveField(4)
  final int route;

  @HiveField(5)
  final String routeName;

  @HiveField(6)
  final String deliveryDate;

  @HiveField(7)
  String? deliveryTime;

  @HiveField(8)
  String totalPrice;

  @HiveField(9)
  String openingBalance;

  @HiveField(10)
  String amountCollected;

  @HiveField(11)
  String balanceAmount;

  @HiveField(12)
  String paymentMethod;

  @HiveField(13)
  String status;

  @HiveField(14)
  String? notes;

  @HiveField(15)
  List<DeliveryOrderItem> items;

  @HiveField(16)
  String syncStatus;

  DeliveryOrder({
    required this.id,
    required this.orderNumber,
    required this.seller,
    required this.sellerName,
    required this.route,
    required this.routeName,
    required this.deliveryDate,
    this.deliveryTime,
    required this.totalPrice,
    required this.openingBalance,
    required this.amountCollected,
    required this.balanceAmount,
    required this.paymentMethod,
    required this.status,
    this.notes,
    required this.items,
    this.syncStatus = 'synced',
  });

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    return DeliveryOrder(
      id: json['id'] as int,
      orderNumber: json['order_number'] as String,
      seller: json['seller'] as int,
      sellerName: json['seller_name'] as String,
      route: json['route'] as int,
      routeName: json['route_name'] as String,
      deliveryDate: json['delivery_date'] as String,
      deliveryTime: json['delivery_time'] as String?,
      totalPrice: json['total_price'] as String,
      openingBalance: json['opening_balance'] as String,
      amountCollected: json['amount_collected'] as String,
      balanceAmount: json['balance_amount'] as String,
      paymentMethod: json['payment_method'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      items: (json['items'] as List<dynamic>)
          .map((item) => DeliveryOrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      syncStatus: 'synced',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'seller': seller,
      'seller_name': sellerName,
      'route': route,
      'route_name': routeName,
      'delivery_date': deliveryDate,
      'delivery_time': deliveryTime,
      'total_price': totalPrice,
      'opening_balance': openingBalance,
      'amount_collected': amountCollected,
      'balance_amount': balanceAmount,
      'payment_method': paymentMethod,
      'status': status,
      'notes': notes,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

@HiveType(typeId: 5)
class DeliveryOrderItem {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int product;

  @HiveField(2)
  final String productName;

  @HiveField(3)
  final String orderedQuantity;

  @HiveField(4)
  final String extraQuantity;

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
      id: json['id'] as int,
      product: json['product'] as int,
      productName: json['product_name'] as String,
      orderedQuantity: json['ordered_quantity'] as String,
      extraQuantity: json['extra_quantity'] as String,
      deliveredQuantity: json['delivered_quantity'] as String,
      unitPrice: json['unit_price'] as String,
      totalPrice: json['total_price'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
}

