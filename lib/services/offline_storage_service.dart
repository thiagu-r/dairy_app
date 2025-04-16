import 'package:hive/hive.dart';
import '../models/loading_order.dart';
import '../models/delivery_order.dart';

class OfflineStorageService {
  static const String loadingOrdersBox = 'loadingOrders';
  static const String deliveryOrdersBox = 'deliveryOrders';

  // Store loading order
  Future<void> storeLoadingOrder(LoadingOrder order) async {
    final box = Hive.box<LoadingOrder>(loadingOrdersBox);  // Use existing box instead of opening new one
    await box.put(order.orderNumber, order);
  }

  // Get loading order by date
  Future<List<LoadingOrder>> getLoadingOrdersByDate(String date) async {
    final box = Hive.box<LoadingOrder>(loadingOrdersBox);  // Use existing box instead of opening new one
    return box.values.where((order) => order.loadingDate == date).toList();
  }

  // Store delivery orders
  Future<void> storeDeliveryOrders(List<DeliveryOrder> orders) async {
    final box = Hive.box<DeliveryOrder>(deliveryOrdersBox);  // Use existing box instead of opening new one
    for (var order in orders) {
      await box.put(order.orderNumber, order);
    }
  }

  // Get delivery orders by date and route
  Future<List<DeliveryOrder>> getDeliveryOrdersByDateAndRoute(String date, int routeId) async {
    final box = Hive.box<DeliveryOrder>(deliveryOrdersBox);
    return box.values
        .where((order) => order.deliveryDate == date && order.route == routeId)
        .toList();
  }

  // Get single delivery order by order number
  Future<DeliveryOrder?> getDeliveryOrder(String orderNumber) async {
    final box = Hive.box<DeliveryOrder>(deliveryOrdersBox);
    return box.get(orderNumber);
  }

  // Update single delivery order
  Future<void> updateDeliveryOrder(DeliveryOrder order) async {
    final box = Hive.box<DeliveryOrder>(deliveryOrdersBox);
    order.syncStatus = 'pending';  // Mark as needing sync
    await box.put(order.orderNumber, order);
  }

  // Get all pending sync delivery orders
  Future<List<DeliveryOrder>> getPendingSyncDeliveryOrders() async {
    final box = Hive.box<DeliveryOrder>(deliveryOrdersBox);
    return box.values.where((order) => order.syncStatus == 'pending').toList();
  }

  // Get delivery orders by date
  Future<List<DeliveryOrder>> getDeliveryOrdersByDate(String date) async {
    final box = Hive.box<DeliveryOrder>(deliveryOrdersBox);
    return box.values.where((order) => order.deliveryDate == date).toList();
  }
}
