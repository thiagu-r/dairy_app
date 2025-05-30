import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/network_provider.dart';
import '../models/public_sale.dart';
import '../models/delivery_order.dart';
import '../models/broken_order.dart';
import '../models/return_order.dart';
import '../models/expense.dart';
import '../models/denomination.dart';
import '../models/loading_order.dart';
import '../services/api_service.dart';
import 'load_orders/load_orders_dashboard.dart';
import 'delivery_orders/delivery_orders_dashboard.dart';
import 'public_sales/public_sales_dashboard.dart';
import 'broken_orders/broken_orders_screen.dart';
import 'return_orders/return_orders_screen.dart';
import 'expenses/expenses_dashboard.dart';
import 'login_screen.dart';
import 'denomination/denomination_screen.dart';
import 'package:intl/intl.dart';
import '../services/offline_storage_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final OfflineStorageService _storageService = OfflineStorageService();
  bool _isSyncing = false;

  // Metrics for Loading Order
  String loadingOrderRoute = '';
  double loadingOrderTotalQty = 0.0;
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
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Loading Order
    final loadingOrders = await _storageService.getLoadingOrdersByDate(todayStr);
    LoadingOrder? loadingOrder;
    if (loadingOrders.isNotEmpty) {
      loadingOrder = loadingOrders.first;
      loadingOrderRoute = loadingOrder.route.toString();
      loadingOrderTotalQty = loadingOrder.items.fold(0.0, (sum, item) => sum + (double.tryParse(item.totalQuantity) ?? 0.0));
      loadingOrderProductCount = loadingOrder.items.length;
    } else {
      loadingOrderRoute = '-';
      loadingOrderTotalQty = 0.0;
      loadingOrderProductCount = 0;
    }

    // Delivery Order
    final deliveryOrders = await _storageService.getDeliveryOrdersByDate(todayStr);
    if (deliveryOrders.isNotEmpty) {
      deliveryOrderRoute = deliveryOrders.first.route.toString();
      deliveryOrderSellerCount = deliveryOrders.length;
    } else {
      deliveryOrderRoute = '-';
      deliveryOrderSellerCount = 0;
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

  Future<void> _syncData() async {
    if (_isSyncing) return;

    final networkProvider = Provider.of<NetworkProvider>(context, listen: false);
    if (!networkProvider.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot sync while offline'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final shouldSync = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sync Data'),
        content: Text('Are you sure you want to sync all pending data to the server?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sync'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
          ),
        ],
      ),
    ) ?? false;

    if (!shouldSync) return;

    setState(() => _isSyncing = true);

    try {
      // Always clear return orders before recalculating
      final returnOrdersBox = await Hive.openBox<ReturnOrder>('returnOrders');
      await returnOrdersBox.clear();
      // Calculate and store return orders before syncing
      await _calculateAndStoreReturnOrders();

      // Add debug logging for return orders
      print('\n=== DEBUG: Return Orders ===');
      print('Total return orders in box: ${returnOrdersBox.length}');
      print('All return orders: ${returnOrdersBox.values.toList()}');
      print('Pending return orders: ${returnOrdersBox.values.where((order) => order.syncStatus == 'pending').toList()}');

      // Add debug logging for current loading order
      final ordersBox = await Hive.openBox('ordersBox');
      print('\n=== DEBUG: Loading Order ===');
      print('Current loading order ID: ${ordersBox.get('currentLoadingOrderId')}');
      print('All keys in ordersBox: ${ordersBox.keys.toList()}');
      final currentLoadingOrderId = ordersBox.get('currentLoadingOrderId');
      print('Retrieved currentLoadingOrderId: $currentLoadingOrderId');

      // Get box lengths for debugging
      final publicSalesBox = await Hive.openBox<PublicSale>('publicSales');
      final deliveryOrdersBox = await Hive.openBox<DeliveryOrder>('deliveryOrders');
      final brokenOrdersBox = await Hive.openBox<BrokenOrder>('brokenOrders');
      final expensesBox = await Hive.openBox<Expense>('expenses');
      final denominationsBox = await Hive.openBox<Denomination>('denominations');

      print('\n=== DEBUG: Box Lengths ===');
      print('Public Sales Box Length: ${publicSalesBox.length}');
      print('Delivery Orders Box Length: ${deliveryOrdersBox.length}');
      print('Broken Orders Box Length: ${brokenOrdersBox.length}');
      print('Return Orders Box Length: ${returnOrdersBox.length}');
      print('Expenses Box Length: ${expensesBox.length}');
      print('Denominations Box Length: ${denominationsBox.length}');

      // Get unsynced counts
      final unsyncedSales = publicSalesBox.values.where((sale) => sale.syncStatus == 'pending').toList();
      final allDeliveries = deliveryOrdersBox.values.toList();
      final unsyncedBrokenOrders = brokenOrdersBox.values.where((order) => order.syncStatus == 'pending').toList();
      final returnOrders = returnOrdersBox.values.where((order) => order.syncStatus == 'pending').toList();
      final unsyncedExpenses = expensesBox.values.where((expense) => expense.syncStatus == 'pending').toList();
      final unsyncedDenominations = denominationsBox.values.where((denomination) => denomination.syncStatus == 'pending').toList();

      print('\n=== DEBUG: Unsynced Counts ===');
      print('Unsynced Sales: [32m${unsyncedSales.length}[0m');
      print('All Deliveries: [32m${allDeliveries.length}[0m');
      print('Unsynced Broken Orders: ${unsyncedBrokenOrders.length}');
      print('Unsynced Return Orders: ${returnOrders.length}');
      print('Unsynced Expenses: ${unsyncedExpenses.length}');
      print('Unsynced Denominations: ${unsyncedDenominations.length}');

      print('\n=== DEBUG: Return Orders Details ===');
      for (var order in returnOrders) {
        print('Return Order: [33m${order.toString()}[0m');
      }

      // Prepare payload with all unsynced data
      final payload = {
        'data': {
          'public_sales': unsyncedSales.map((sale) => sale.toJson()).toList(),
          'delivery_orders': allDeliveries.map((order) => order.toJson()).toList(),
          'broken_orders': unsyncedBrokenOrders.map((order) => order.toJson()).toList(),
          'return_orders': returnOrders.isEmpty
              ? []
              : [
                  ReturnOrder(
                    syncStatus: 'pending',
                    items: returnOrders.expand((order) => order.items).toList(),
                  ).toJson()
                ],
          'expenses': unsyncedExpenses.map((expense) => expense.toJson()).toList(),
          'denominations': unsyncedDenominations.map((denomination) => denomination.toJson()).toList(),
          'loading_order': {
            'order_number': currentLoadingOrderId ?? ordersBox.get('currentOrderNumber')
          },
        }
      };

      // Debug print the payload
      print('\n=== FULL SYNC PAYLOAD DEBUG ===');
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      String prettyJson = encoder.convert(payload);
      
      // Print payload in chunks for better readability
      print('\nFull Sync Payload:');
      const int chunkSize = 1000;
      for (var i = 0; i < prettyJson.length; i += chunkSize) {
        var end = (i + chunkSize < prettyJson.length) ? i + chunkSize : prettyJson.length;
        print(prettyJson.substring(i, end));
      }

      // Save payload to file for debugging
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/last_sync_payload.json');
        await file.writeAsString(prettyJson);
        print('\nPayload saved to: ${file.path}');
      } catch (e) {
        print('Failed to save payload to file: $e');
      }

      // Make API call
      final response = await _apiService.syncData(payload);

      if (response['success'] == true) {
        // Update sync status for all synced items
        await Future.wait([
          ...unsyncedSales.map((sale) {
            sale.syncStatus = 'synced';
            return publicSalesBox.put(sale.key, sale);
          }),
          ...allDeliveries.map((order) {
            order.syncStatus = 'synced';
            return deliveryOrdersBox.put(order.key, order);
          }),
          ...unsyncedBrokenOrders.map((order) {
            order.syncStatus = 'synced';
            return brokenOrdersBox.put(order.key, order);
          }),
          ...returnOrders.map((order) {
            order.syncStatus = 'synced';
            return returnOrdersBox.put(order.key, order);
          }),
          ...unsyncedExpenses.map((expense) {
            expense.syncStatus = 'synced';
            return expensesBox.put(expense.key, expense);
          }),
          ...unsyncedDenominations.map((denomination) {
            denomination.syncStatus = 'synced';
            return denominationsBox.put(denomination.key, denomination);
          }),
        ]);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data synced successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(response['message'] ?? 'Sync failed');
      }

    } catch (e) {
      print('\n=== DEBUG: Error in _syncData ===');
      print('Error details: $e');
      print('Stack trace: ${StackTrace.current}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _calculateAndStoreReturnOrders() async {
    final loadingOrdersBox = await Hive.openBox<LoadingOrder>('loadingOrders');
    final deliveryOrdersBox = await Hive.openBox<DeliveryOrder>('deliveryOrders');
    final returnOrdersBox = await Hive.openBox<ReturnOrder>('returnOrders');
    final publicSalesBox = await Hive.openBox<PublicSale>('publicSales');

    // Clear existing return orders
    await returnOrdersBox.clear();

    // Aggregate available quantities for all products across all loading orders
    Map<int, double> totalAvailableQuantities = {};

    for (var loadingOrder in loadingOrdersBox.values) {
      // Get all delivery orders for this loading order
      final deliveryOrders = deliveryOrdersBox.values.where((order) =>
        order.route == loadingOrder.route &&
        order.deliveryDate == loadingOrder.loadingDate
      ).toList();

      // Get all public sales for this route and date
      final publicSales = publicSalesBox.values.where((sale) =>
        sale.route == loadingOrder.route &&
        sale.saleDate == loadingOrder.loadingDate
      ).toList();

      // Calculate used quantities for this loading order
      Map<int, double> usedQuantities = {};
      // Add delivered quantities from delivery orders
      for (var order in deliveryOrders) {
        for (var item in order.items) {
          usedQuantities[item.product] = (usedQuantities[item.product] ?? 0) +
              double.parse(item.deliveredQuantity);
        }
      }
      // Add sold quantities from public sales
      for (var sale in publicSales) {
        for (var item in sale.items) {
          usedQuantities[item.product] = (usedQuantities[item.product] ?? 0) +
              double.parse(item.quantity);
        }
      }

      // For each product in the loading order, calculate available for this loading order
      for (var item in loadingOrder.items) {
        double totalLoaded = double.parse(item.totalQuantity);
        double used = usedQuantities[item.product] ?? 0;
        // Add broken quantity from loading order item (not from broken orders box)
        if (item.brokenQuantity != null && item.brokenQuantity! > 0) {
          used += item.brokenQuantity!;
        }
        double availableQty = totalLoaded - used;
        if (availableQty > 0) {
          totalAvailableQuantities[item.product] = (totalAvailableQuantities[item.product] ?? 0) + availableQty;
        }
      }
    }

    // Create one ReturnOrderItem per product (across all loading orders)
    List<ReturnOrderItem> returnItems = totalAvailableQuantities.entries
        .map((e) => ReturnOrderItem(product: e.key, quantity: e.value))
        .toList();

    // If there are return items, create and store a single return order
    if (returnItems.isNotEmpty) {
      final returnOrder = ReturnOrder(
        syncStatus: 'pending',
        items: returnItems,
      );
      await returnOrdersBox.add(returnOrder);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final networkProvider = Provider.of<NetworkProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Bharat Dairy Delivery'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: Icon(
                      Icons.person,
                      size: 35,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    authProvider.currentUser?.name ?? 'User',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    authProvider.currentUser?.email ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.sync),
              title: Text('Sync Data'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                _syncData();
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // Add navigation to settings screen when available
                _showComingSoonDialog(context);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context); // Close drawer
                
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Logout'),
                    content: Text(
                      networkProvider.isOnline 
                        ? 'Are you sure you want to logout?' 
                        : 'You are currently offline. Any unsynced data will remain on the device until you reconnect. Are you sure you want to logout?'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Logout'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true) {
                  await Provider.of<AuthProvider>(context, listen: false).logout();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoadOrdersDashboard()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: DashboardMetricCard(
                      icon: Icons.route,
                      title: 'Loading Order',
                      metrics: [
                        'Route: $loadingOrderRoute',
                        'Total Qty: ${loadingOrderTotalQty.toStringAsFixed(2)}',
                        'Products: $loadingOrderProductCount',
                      ],
                      color: Colors.blue,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DeliveryOrdersDashboard()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: DashboardMetricCard(
                      icon: Icons.local_shipping,
                      title: 'Delivery Order',
                      metrics: [
                        'Route: $deliveryOrderRoute',
                        'Sellers: $deliveryOrderSellerCount',
                      ],
                      color: Colors.green,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PublicSalesDashboard()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: DashboardMetricCard(
                      icon: Icons.store,
                      title: 'Public Sales',
                      metrics: [
                        'Sales: $publicSalesCount',
                        'Total: ₹${publicSalesTotal.toStringAsFixed(2)}',
                      ],
                      color: Colors.orange,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BrokenOrdersScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: DashboardMetricCard(
                      icon: Icons.error,
                      title: 'Broken Orders',
                      metrics: [
                        'Broken Products: $brokenProductsCount',
                      ],
                      color: Colors.red,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ReturnOrdersScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: DashboardMetricCard(
                      icon: Icons.assignment_return,
                      title: 'Returned Orders',
                      metrics: [
                        'Available Qty: $returnedAvailableQty',
                      ],
                      color: Colors.purple,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ExpensesDashboard()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: DashboardMetricCard(
                      icon: Icons.money_off,
                      title: 'Expenses',
                      metrics: [
                        'Expenses: $expensesCount',
                        'Total: ₹${expensesTotal.toStringAsFixed(2)}',
                      ],
                      color: Colors.teal,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DenominationScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: DashboardMetricCard(
                      icon: Icons.account_balance_wallet,
                      title: 'Denomination',
                      metrics: [
                        'Collected: ₹${denominationCollected.toStringAsFixed(2)}',
                        'Balance: ₹${denominationBalance.toStringAsFixed(2)}',
                      ],
                      color: Colors.brown,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Coming Soon'),
        content: Text('This feature is under development and will be available soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
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
