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

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  bool _isSyncing = false;

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
      body: _buildHomeContent(context),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    final networkProvider = Provider.of<NetworkProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.currentUser?.name ?? 'User';
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Network status indicator
          if (!networkProvider.isOnline)
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.orange.shade800),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You are currently offline. Some features may be limited.',
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),
          // Welcome message and dashboard header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $userName',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Dashboard',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 1,
              padding: EdgeInsets.only(bottom: 16),
              children: [
                _buildMenuCard(
                  context: context,
                  title: 'Sync Data',
                  icon: Icons.sync,
                  color: Theme.of(context).colorScheme.primary,
                  onTap: _syncData,
                  isLoading: _isSyncing,
                ),
                _buildMenuCard(
                  context: context,
                  title: 'Load Orders',
                  icon: Icons.downloading,
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoadOrdersDashboard()),
                  ),
                ),
                _buildMenuCard(
                  context: context,
                  title: 'Delivery Orders',
                  icon: Icons.local_shipping,
                  color: Colors.green,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DeliveryOrdersDashboard()),
                  ),
                ),
                _buildMenuCard(
                  context: context,
                  title: 'Public Sales',
                  icon: Icons.store,
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PublicSalesDashboard()),
                  ),
                ),
                _buildMenuCard(
                  context: context,
                  title: 'Broken Orders',
                  icon: Icons.broken_image,
                  color: Colors.red,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BrokenOrdersScreen()),
                  ),
                ),
                _buildMenuCard(
                  context: context,
                  title: 'Returned Orders',
                  icon: Icons.assignment_return,
                  color: Colors.orange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ReturnOrdersScreen()),
                  ),
                ),
                _buildMenuCard(
                  context: context,
                  title: 'Denominations',
                  icon: Icons.attach_money,
                  color: Colors.teal,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DenominationScreen()),
                  ),
                ),
                _buildMenuCard(
                  context: context,
                  title: 'Expenses',
                  icon: Icons.account_balance_wallet,
                  color: Colors.indigo,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ExpensesDashboard()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(vertical: 28, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                CircularProgressIndicator(color: color)
              else
                Icon(icon, size: 44, color: color),
              SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
