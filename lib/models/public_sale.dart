import 'package:hive/hive.dart';

part 'public_sale.g.dart';

@HiveType(typeId: 6)
class PublicSale extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int route;

  @HiveField(2)
  final String? customerName;

  @HiveField(3)
  final String? customerPhone;

  @HiveField(4)
  final String? customerAddress;

  @HiveField(5)
  final String saleDate;

  @HiveField(6)
  final String? saleTime;

  @HiveField(7)
  final String paymentMethod;

  @HiveField(8)
  final String totalPrice;

  @HiveField(9)
  final String amountCollected;

  @HiveField(10)
  final String balanceAmount;

  @HiveField(11)
  final List<PublicSaleItem> items;

  @HiveField(12)
  String syncStatus;

  @HiveField(13)
  final String localId;

  @HiveField(14)
  final String status;

  @HiveField(15)
  final String? notes;

  PublicSale({
    required this.id,
    required this.route,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    required this.saleDate,
    this.saleTime,
    required this.paymentMethod,
    required this.totalPrice,
    required this.amountCollected,
    required this.balanceAmount,
    required this.items,
    this.syncStatus = 'pending',
    String? localId,
    this.status = 'completed',
    this.notes,
  }) : this.localId = localId ?? 'mobile-ps-${DateTime.now().millisecondsSinceEpoch}';

  Map<String, dynamic> toJson() => {
    'id': null,
    'route': route,
    'sale_date': saleDate,
    'sale_time': saleTime,
    'payment_method': paymentMethod,
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'customer_address': customerAddress,
    'total_price': totalPrice,
    'amount_collected': amountCollected,
    'balance_amount': balanceAmount,
    'status': status,
    'notes': notes,
    'local_id': localId,
    'items': items.map((item) => item.toJson()).toList(),
  };
}

@HiveType(typeId: 7)
class PublicSaleItem extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int product;

  @HiveField(2)
  final String productName;

  @HiveField(3)
  final String quantity;

  @HiveField(4)
  final String unitPrice;

  @HiveField(5)
  final String totalPrice;

  PublicSaleItem({
    required this.id,
    required this.product,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  Map<String, dynamic> toJson() => {
    'id': null,
    'product': product,
    'product_name': productName,
    'quantity': quantity,
    'unit_price': unitPrice,
    'total_price': totalPrice,
  };
}
