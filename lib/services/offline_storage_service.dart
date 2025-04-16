import 'package:hive_flutter/hive_flutter.dart';
import '../models/loading_order.dart';
import '../models/delivery_order.dart';

class OfflineStorageService {
  static const String LOADING_ORDERS_BOX = 'loading_orders';
  static const String DELIVERY_ORDERS_BOX = 'delivery_orders';

  Future<void> storeLoadingOrder(LoadingOrder order) async {
    final box = await Hive.openBox<LoadingOrder>(LOADING_ORDERS_BOX);
    await box.put(order.id, order);
  }

  Future<List<LoadingOrder>> getLoadingOrdersByDate(String date) async {
    final box = await Hive.openBox<LoadingOrder>(LOADING_ORDERS_BOX);
    return box.values
        .where((order) => order.loadingDate == date)
        .toList();
  }

  Future<LoadingOrder?> getLoadingOrderByDateAndRoute(String date, int route) async {
    final box = await Hive.openBox<LoadingOrder>(LOADING_ORDERS_BOX);
    try {
      return box.values.firstWhere(
        (order) => order.loadingDate == date && order.route == route,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> storeDeliveryOrders(List<DeliveryOrder> orders) async {
    final box = await Hive.openBox<DeliveryOrder>(DELIVERY_ORDERS_BOX);
    for (var order in orders) {
      await box.put(order.id, order);
    }
  }

  Future<List<DeliveryOrder>> getDeliveryOrdersByDate(String date) async {
    final box = await Hive.openBox<DeliveryOrder>(DELIVERY_ORDERS_BOX);
    return box.values
        .where((order) => order.deliveryDate == date)
        .toList();
  }

  Future<List<DeliveryOrder>> getDeliveryOrdersByDateAndRoute(
    String date,
    int route,
  ) async {
    final box = await Hive.openBox<DeliveryOrder>(DELIVERY_ORDERS_BOX);
    return box.values
        .where((order) => 
            order.deliveryDate == date && 
            order.route == route)
        .toList();
  }

  Future<void> updateDeliveryOrder(DeliveryOrder order) async {
    final box = await Hive.openBox<DeliveryOrder>(DELIVERY_ORDERS_BOX);
    await box.put(order.id, order);
  }
}
