import 'package:hive/hive.dart';

@HiveType(typeId: 4)
class DeliveryOrder {
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
  final String totalPrice;

  @HiveField(9)
  final String openingBalance;

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
    required this.syncStatus,
  });

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    return DeliveryOrder(
      id: json['id'],
      orderNumber: json['order_number'],
      seller: json['seller'],
      sellerName: json['seller_name'],
      route: json['route'],
      routeName: json['route_name'],
      deliveryDate: json['delivery_date'],
      deliveryTime: json['delivery_time'],
      totalPrice: json['total_price'],
      openingBalance: json['opening_balance'],
      amountCollected: json['amount_collected'],
      balanceAmount: json['balance_amount'],
      paymentMethod: json['payment_method'],
      status: json['status'],
      notes: json['notes'],
      items: (json['items'] as List)
          .map((item) => DeliveryOrderItem.fromJson(item))
          .toList(),
      syncStatus: json['sync_status'] ?? 'pending',
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
      'sync_status': syncStatus,
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
      id: json['id'],
      product: json['product'],
      productName: json['product_name'],
      orderedQuantity: json['ordered_quantity'],
      extraQuantity: json['extra_quantity'],
      deliveredQuantity: json['delivered_quantity'],
      unitPrice: json['unit_price'],
      totalPrice: json['total_price'],
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

class DeliveryOrderAdapter extends TypeAdapter<DeliveryOrder> {
  @override
  final int typeId = 4;

  @override
  DeliveryOrder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeliveryOrder(
      id: fields[0] as int,
      orderNumber: fields[1] as String,
      seller: fields[2] as int,
      sellerName: fields[3] as String,
      route: fields[4] as int,
      routeName: fields[5] as String,
      deliveryDate: fields[6] as String,
      deliveryTime: fields[7] as String?,
      totalPrice: fields[8] as String,
      openingBalance: fields[9] as String,
      amountCollected: fields[10] as String,
      balanceAmount: fields[11] as String,
      paymentMethod: fields[12] as String,
      status: fields[13] as String,
      notes: fields[14] as String?,
      items: (fields[15] as List).cast<DeliveryOrderItem>(),
      syncStatus: fields[16] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DeliveryOrder obj) {
    writer.writeByte(17);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.orderNumber);
    writer.writeByte(2);
    writer.write(obj.seller);
    writer.writeByte(3);
    writer.write(obj.sellerName);
    writer.writeByte(4);
    writer.write(obj.route);
    writer.writeByte(5);
    writer.write(obj.routeName);
    writer.writeByte(6);
    writer.write(obj.deliveryDate);
    writer.writeByte(7);
    writer.write(obj.deliveryTime);
    writer.writeByte(8);
    writer.write(obj.totalPrice);
    writer.writeByte(9);
    writer.write(obj.openingBalance);
    writer.writeByte(10);
    writer.write(obj.amountCollected);
    writer.writeByte(11);
    writer.write(obj.balanceAmount);
    writer.writeByte(12);
    writer.write(obj.paymentMethod);
    writer.writeByte(13);
    writer.write(obj.status);
    writer.writeByte(14);
    writer.write(obj.notes);
    writer.writeByte(15);
    writer.write(obj.items);
    writer.writeByte(16);
    writer.write(obj.syncStatus);
  }
}

class DeliveryOrderItemAdapter extends TypeAdapter<DeliveryOrderItem> {
  @override
  final int typeId = 5;

  @override
  DeliveryOrderItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeliveryOrderItem(
      id: fields[0] as int,
      product: fields[1] as int,
      productName: fields[2] as String,
      orderedQuantity: fields[3] as String,
      extraQuantity: fields[4] as String,
      deliveredQuantity: fields[5] as String,
      unitPrice: fields[6] as String,
      totalPrice: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DeliveryOrderItem obj) {
    writer.writeByte(8);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.product);
    writer.writeByte(2);
    writer.write(obj.productName);
    writer.writeByte(3);
    writer.write(obj.orderedQuantity);
    writer.writeByte(4);
    writer.write(obj.extraQuantity);
    writer.writeByte(5);
    writer.write(obj.deliveredQuantity);
    writer.writeByte(6);
    writer.write(obj.unitPrice);
    writer.writeByte(7);
    writer.write(obj.totalPrice);
  }
}
