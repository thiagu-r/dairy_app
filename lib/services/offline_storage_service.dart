import 'package:hive/hive.dart';
import '../models/loading_order.dart';
import '../models/delivery_order.dart';

class OfflineStorageService {
  static const String loadingOrdersBox = 'loadingOrders';
  static const String deliveryOrdersBox = 'deliveryOrders';

  // Store loading order
  Future<void> storeLoadingOrder(LoadingOrder order) async {
    final box = await Hive.openBox<LoadingOrder>(loadingOrdersBox);
    await box.put(order.orderNumber, order);
  }

  // Get loading order by date
  Future<List<LoadingOrder>> getLoadingOrdersByDate(String date) async {
    final box = await Hive.openBox<LoadingOrder>(loadingOrdersBox);
    return box.values.where((order) => order.loadingDate == date).toList();
  }

  // Store delivery orders
  Future<void> storeDeliveryOrders(List<DeliveryOrder> orders) async {
    final box = await Hive.openBox<DeliveryOrder>(deliveryOrdersBox);
    for (var order in orders) {
      await box.put(order.orderNumber, order);
    }
  }

  // Get delivery orders by date
  Future<List<DeliveryOrder>> getDeliveryOrdersByDate(String date) async {
    final box = await Hive.openBox<DeliveryOrder>(deliveryOrdersBox);
    return box.values.where((order) => order.deliveryDate == date).toList();
  }

  // Update delivery order
  Future<void> updateDeliveryOrder(DeliveryOrder order) async {
    final box = await Hive.openBox<DeliveryOrder>(deliveryOrdersBox);
    order.syncStatus = 'pending';
    await box.put(order.orderNumber, order);
  }

  // Get pending sync delivery orders
  Future<List<DeliveryOrder>> getPendingSyncDeliveryOrders() async {
    final box = await Hive.openBox<DeliveryOrder>(deliveryOrdersBox);
    return box.values.where((order) => order.syncStatus == 'pending').toList();
  }
}