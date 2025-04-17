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
  String syncStatus = 'pending';

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
  });
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
}
