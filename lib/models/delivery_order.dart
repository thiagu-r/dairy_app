import 'package:hive/hive.dart';

part 'delivery_order.g.dart';

@HiveType(typeId: 4)
class DeliveryOrder extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  String orderNumber;

  @HiveField(2)
  String deliveryDate;

  @HiveField(3)
  int route;

  @HiveField(4)
  final String routeName;

  @HiveField(5)
  final String sellerName;

  @HiveField(6)
  final String status;

  @HiveField(7)
  List<DeliveryOrderItem> items;

  @HiveField(8)
  final int seller;

  @HiveField(9)
  String? deliveryTime;

  @HiveField(10)
  String totalPrice;

  @HiveField(11)
  final String openingBalance;

  @HiveField(12)
  String amountCollected;

  @HiveField(13)
  String balanceAmount;

  @HiveField(14)
  String paymentMethod;

  @HiveField(15)
  String? notes;

  @HiveField(16)
  String syncStatus;

  DeliveryOrder({
    required this.id,
    required this.orderNumber,
    required this.deliveryDate,
    required this.route,
    required this.routeName,
    required this.sellerName,
    required this.status,
    required this.items,
    required this.seller,
    this.deliveryTime,
    this.totalPrice = "0.00",
    required this.openingBalance,
    this.amountCollected = "0.00",
    required this.balanceAmount,
    this.paymentMethod = "cash",
    this.notes,
    this.syncStatus = "pending",
  });

  void updateTotalPrice() {
    double total = 0.0;
    for (var item in items) {
      item.calculateTotalPrice();
      total += double.parse(item.totalPrice);
    }
    totalPrice = total.toStringAsFixed(2);
    updateBalanceAmount();
  }

  void updateBalanceAmount() {
    double balance = double.parse(totalPrice) - double.parse(amountCollected);
    balanceAmount = balance.toStringAsFixed(2);
  }

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    return DeliveryOrder(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      orderNumber: json['order_number']?.toString() ?? '',
      deliveryDate: json['delivery_date']?.toString() ?? '',
      route: json['route'] is int ? json['route'] : int.parse(json['route'].toString()),
      routeName: json['route_name']?.toString() ?? '',
      sellerName: json['seller_name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      seller: json['seller'] is int ? json['seller'] : int.parse(json['seller'].toString()),
      deliveryTime: json['delivery_time']?.toString(),
      totalPrice: json['total_price']?.toString() ?? "0.00",
      openingBalance: json['opening_balance']?.toString() ?? "0.00",
      amountCollected: json['amount_collected']?.toString() ?? "0.00",
      balanceAmount: json['balance_amount']?.toString() ?? "0.00",
      paymentMethod: json['payment_method']?.toString() ?? "cash",
      notes: json['notes']?.toString(),
      syncStatus: json['sync_status']?.toString() ?? "pending",
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
    'seller': seller,
    'delivery_time': deliveryTime,
    'total_price': totalPrice,
    'opening_balance': openingBalance,
    'amount_collected': amountCollected,
    'balance_amount': balanceAmount,
    'payment_method': paymentMethod,
    'notes': notes,
    'sync_status': syncStatus,
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

  void calculateTotalPrice() {
    double delivered = double.parse(deliveredQuantity);
    double price = double.parse(unitPrice);
    totalPrice = (delivered * price).toStringAsFixed(2);
  }

  factory DeliveryOrderItem.fromJson(Map<String, dynamic> json) {
    return DeliveryOrderItem(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      product: json['product'] is int ? json['product'] : int.parse(json['product'].toString()),
      productName: json['product_name']?.toString() ?? '',
      orderedQuantity: json['ordered_quantity']?.toString() ?? "0.000",
      extraQuantity: json['extra_quantity']?.toString() ?? "0.000",
      deliveredQuantity: json['delivered_quantity']?.toString() ?? "0.000",
      unitPrice: json['unit_price']?.toString() ?? "0.00",
      totalPrice: json['total_price']?.toString() ?? "0.00",
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
