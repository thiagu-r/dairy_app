import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/offline_storage_service.dart';
import '../../models/loading_order.dart';
import '../../models/delivery_order.dart';
import '../../models/public_sale.dart';
import '../../models/expense.dart';
import '../../models/denomination.dart';
import '../../models/broken_order.dart';

class PublicSalesDashboard extends StatefulWidget {
  @override
  _PublicSalesDashboardState createState() => _PublicSalesDashboardState();
}

class _PublicSalesDashboardState extends State<PublicSalesDashboard> {
  final OfflineStorageService _storageService = OfflineStorageService();

  // Metrics
  String loadingOrderRoute = '';
  int loadingOrderTotalQty = 0;
  int loadingOrderProductCount = 0;

  String deliveryOrderRoute = '';
  int deliveryOrderSellerCount = 0;

  int publicSalesCount = 0;
  double publicSalesTotal = 0.0;

  int brokenProductsCount = 0;
  int returnedAvailableQty = 0;

  int expensesCount = 0;
  double expensesTotal = 0.0;

  double denominationCollected = 0.0;
  double denominationBalance = 0.0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    // Loading Order
    final loadingOrders = await _storageService.getLoadingOrdersByDate(todayStr);
    LoadingOrder? loadingOrder;
    if (loadingOrders.isNotEmpty) {
      loadingOrder = loadingOrders.first;
      loadingOrderRoute = loadingOrder.route.toString();
      loadingOrderTotalQty = loadingOrder.items.fold(0, (sum, item) => sum + (int.tryParse(item.totalQuantity) ?? 0));
      loadingOrderProductCount = loadingOrder.items.length;
    }

    // Delivery Order
    final deliveryOrders = await _storageService.getDeliveryOrdersByDate(todayStr);
    if (deliveryOrders.isNotEmpty) {
      deliveryOrderRoute = deliveryOrders.first.route.toString();
      deliveryOrderSellerCount = deliveryOrders.length;
    }

    // Public Sales
    final publicSales = await _storageService.getPublicSalesByDate(todayStr);
    publicSalesCount = publicSales.length;
    publicSalesTotal = publicSales.fold(0.0, (sum, sale) => sum + (double.tryParse(sale.totalPrice) ?? 0.0));

    // Broken Orders (filter by date)
    final brokenOrders = (await _storageService.getBrokenOrders())
        .where((order) => order.date == todayStr)
        .toList();
    brokenProductsCount = brokenOrders.fold(0, (sum, order) =>
      sum + order.items.fold(0, (itemSum, item) => itemSum + item.quantity.toInt())
    );

    // Returned Orders (Available Products)
    returnedAvailableQty = 0;
    if (loadingOrder != null) {
      // Get delivery orders and public sales for today/route
      final deliveryOrdersByRoute = await _storageService.getDeliveryOrdersByDateAndRoute(todayStr, loadingOrder.route);
      final publicSalesByRoute = await _storageService.getPublicSalesByDateAndRoute(todayStr, loadingOrder.route);

      // Calculate used quantities
      Map<int, double> usedQuantities = {};
      for (var order in deliveryOrdersByRoute) {
        for (var item in order.items) {
          usedQuantities[item.product] = (usedQuantities[item.product] ?? 0) + double.parse(item.deliveredQuantity);
        }
      }
      for (var sale in publicSalesByRoute) {
        for (var item in sale.items) {
          usedQuantities[item.product] = (usedQuantities[item.product] ?? 0) + double.parse(item.quantity);
        }
      }
      for (var item in loadingOrder.items) {
        if (item.brokenQuantity != null && item.brokenQuantity! > 0) {
          usedQuantities[item.product] = (usedQuantities[item.product] ?? 0) + item.brokenQuantity!;
        }
      }
      // Calculate available quantities
      for (var loadingItem in loadingOrder.items) {
        double totalLoaded = double.parse(loadingItem.totalQuantity);
        double used = usedQuantities[loadingItem.product] ?? 0;
        double available = totalLoaded - used;
        returnedAvailableQty += available.toInt();
      }
    }

    // Expenses
    final expenses = await _storageService.getExpensesByDate(todayStr);
    expensesCount = expenses.length;
    expensesTotal = expenses.fold(0.0, (sum, exp) => sum + exp.amount);

    // Denomination
    final denomination = await _storageService.getDenominationByDate(todayStr);
    if (denomination != null) {
      denominationCollected = denomination.totalCashCollected;
      denominationBalance = denomination.difference;
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                DashboardMetricCard(
                  icon: Icons.route,
                  title: 'Loading Order',
                  metrics: [
                    'Route: $loadingOrderRoute',
                    'Total Qty: $loadingOrderTotalQty',
                    'Products: $loadingOrderProductCount',
                  ],
                  color: Colors.blue,
                ),
              ],
            ),
    );
  }
}

class DashboardMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> metrics;
  final Color color;

  const DashboardMetricCard({
    required this.icon,
    required this.title,
    required this.metrics,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 32),
              radius: 28,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ...metrics.map((m) => Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(m, style: TextStyle(fontSize: 15)),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
