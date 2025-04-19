import 'package:hive/hive.dart';
import '../models/loading_order.dart';
import '../models/delivery_order.dart';
import '../models/public_sale.dart';
import '../models/expense.dart';
import '../models/route.dart' as route_model;

class OfflineStorageService {
  static const String loadingOrdersBox = 'loadingOrders';
  static const String deliveryOrdersBox = 'deliveryOrders';
  static const String publicSalesBox = 'publicSales';
  static const String expensesBox = 'expenses';
  static const String routesBox = 'routes';

  // Routes methods
  Future<void> addRoute(route_model.Route route) async {
    final box = await Hive.openBox<route_model.Route>(routesBox);
    await box.add(route);
  }

  Future<List<route_model.Route>> getRoutes() async {
    final box = await Hive.openBox<route_model.Route>(routesBox);
    return box.values.toList();
  }

  Future<route_model.Route?> getRouteById(int id) async {
    final box = await Hive.openBox<route_model.Route>(routesBox);
    return box.values.firstWhere((route) => route.id == id);
  }

  // Loading Orders methods
  Future<void> storeLoadingOrder(LoadingOrder order) async {
    final box = await Hive.openBox<LoadingOrder>(loadingOrdersBox);
    await box.add(order);
  }

  Future<List<LoadingOrder>> getLoadingOrdersByDate(String date) async {
    final box = await Hive.openBox<LoadingOrder>(loadingOrdersBox);
    return box.values.where((order) => order.loadingDate == date).toList();
  }

  Future<LoadingOrder?> getLoadingOrderByDateAndRoute(
    String date,
    int route,
  ) async {
    final box = await Hive.openBox<LoadingOrder>(loadingOrdersBox);
    try {
      return box.values.firstWhere(
        (order) => order.loadingDate == date && order.route == route,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> updateLoadingOrder(LoadingOrder order) async {
    final box = await Hive.openBox<LoadingOrder>(loadingOrdersBox);
    await box.put(order.key, order);
  }

  // Delivery Orders methods
  Future<void> storeDeliveryOrders(List<DeliveryOrder> orders) async {
    final box = await Hive.openBox<DeliveryOrder>(deliveryOrdersBox);
    
    // Clear existing orders for this route and date
    final firstOrder = orders.first;
    final existingOrders = box.values.where((order) => 
      order.route == firstOrder.route && 
      order.deliveryDate == firstOrder.deliveryDate
    );
    
    // Delete existing orders
    for (var order in existingOrders) {
      await box.delete(order.key);
    }
    
    // Store new orders
    for (var order in orders) {
      await box.add(order);
    }
  }

  Future<List<DeliveryOrder>> getDeliveryOrdersByDate(String date) async {
    final box = await Hive.openBox<DeliveryOrder>(deliveryOrdersBox);
    return box.values.where((order) => order.deliveryDate == date).toList();
  }

  Future<List<DeliveryOrder>> getDeliveryOrdersByDateAndRoute(
    String date,
    int route,
  ) async {
    final box = await Hive.openBox<DeliveryOrder>(deliveryOrdersBox);
    return box.values
        .where((order) => order.deliveryDate == date && order.route == route)
        .toList();
  }

  Future<void> updateDeliveryOrder(DeliveryOrder order) async {
    final box = await Hive.openBox<DeliveryOrder>(deliveryOrdersBox);
    await box.put(order.key, order);
  }

  Future<bool> hasDeliveryOrdersForRouteAndDate(int route, String date) async {
    final box = await Hive.openBox<DeliveryOrder>(deliveryOrdersBox);
    return box.values.any((order) => 
      order.route == route && 
      order.deliveryDate == date
    );
  }

  // Public Sales methods
  Future<List<PublicSale>> getPublicSalesByDate(String date) async {
    final box = await Hive.openBox<PublicSale>(publicSalesBox);
    return box.values.where((sale) => sale.saleDate == date).toList();
  }

  Future<List<PublicSale>> getPublicSalesByDateAndRoute(
    String date,
    int route,
  ) async {
    final box = await Hive.openBox<PublicSale>(publicSalesBox);
    return box.values
        .where((sale) => sale.saleDate == date && sale.route == route)
        .toList();
  }

  Future<void> storePublicSale(PublicSale sale) async {
    final box = await Hive.openBox<PublicSale>(publicSalesBox);
    await box.add(sale);
  }

  // Expenses methods
  Future<void> addExpense(Expense expense) async {
    final box = await Hive.openBox<Expense>(expensesBox);
    await box.add(expense);
  }

  Future<List<Expense>> getExpensesByDate(String date) async {
    final box = await Hive.openBox<Expense>(expensesBox);
    return box.values.where((expense) => expense.date == date).toList();
  }

  Future<List<Expense>> getExpensesByDateAndRoute(String date, int route) async {
    final box = await Hive.openBox<Expense>(expensesBox);
    return box.values
        .where((expense) => expense.date == date && expense.route == route)
        .toList();
  }
}
