import 'package:hive/hive.dart';

part 'return_order.g.dart';

@HiveType(typeId: 14)
class ReturnOrder extends HiveObject {
  @HiveField(0)
  String syncStatus;

  @HiveField(1)
  final List<ReturnOrderItem> items;

  ReturnOrder({
    this.syncStatus = 'pending',
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'sync_status': syncStatus,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

@HiveType(typeId: 15)
class ReturnOrderItem {
  @HiveField(0)
  final int product;

  @HiveField(1)
  final double quantity;

  ReturnOrderItem({
    required this.product,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'product': product,
      'quantity': quantity,
    };
  }
}