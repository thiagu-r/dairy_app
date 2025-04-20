import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../providers/network_provider.dart';
import '../models/public_sale.dart';
import '../models/delivery_order.dart';
import '../models/broken_order.dart';
import '../models/return_order.dart';
import '../models/expense.dart';
import '../models/denomination.dart';
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

    setState(() => _isSyncing = true);

    try {
      // Get all unsynced data from Hive
      final publicSalesBox = await Hive.openBox<PublicSale>('publicSales');
      final deliveryOrdersBox = await Hive.openBox<DeliveryOrder>('deliveryOrders');
      final brokenOrdersBox = await Hive.openBox<BrokenOrder>('brokenOrders');
      final returnOrdersBox = await Hive.openBox<ReturnOrder>('returnOrders');
      final expensesBox = await Hive.openBox<Expense>('expenses');
      final denominationsBox = await Hive.openBox<Denomination>('denominations');

      // Get unsynced records from each box
      final unsyncedSales = publicSalesBox.values
          .where((sale) => sale.syncStatus == 'pending')
          .toList();
      
      final unsyncedDeliveries = deliveryOrdersBox.values
          .where((order) => order.syncStatus == 'pending')
          .toList();

      final unsyncedBrokenOrders = brokenOrdersBox.values
          .where((order) => order.syncStatus == 'pending')
          .toList();

      final unsyncedReturnOrders = returnOrdersBox.values
          .where((order) => order.syncStatus == 'pending')
          .toList();

      final unsyncedExpenses = expensesBox.values
          .where((expense) => expense.syncStatus == 'pending')
          .toList();

      final unsyncedDenominations = denominationsBox.values
          .where((denomination) => denomination.syncStatus == 'pending')
          .toList();

      // Skip sync if no pending changes
      if (unsyncedSales.isEmpty && 
          unsyncedDeliveries.isEmpty && 
          unsyncedBrokenOrders.isEmpty &&
          unsyncedReturnOrders.isEmpty &&
          unsyncedExpenses.isEmpty &&
          unsyncedDenominations.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No pending changes to sync'),
              backgroundColor: Colors.blue,
            ),
          );
        }
        return;
      }

      // Prepare payload with all unsynced data
      final payload = {
        'data': {
          'public_sales': unsyncedSales.map((sale) => sale.toJson()).toList(),
          'delivery_orders': unsyncedDeliveries.map((order) => order.toJson()).toList(),
          'broken_orders': unsyncedBrokenOrders.map((order) => order.toJson()).toList(),
          'return_orders': unsyncedReturnOrders.map((order) => order.toJson()).toList(),
          'expenses': unsyncedExpenses.map((expense) => expense.toJson()).toList(),
          'denominations': unsyncedDenominations.map((denomination) => denomination.toJson()).toList(),
        }
      };

      // Call sync API
      final response = await _apiService.syncData(payload);

      // Update local status based on response
      if (response['success'] == true) {
        // Update sync status for all synced items
        await Future.wait([
          ...unsyncedSales.map((sale) async {
            sale.syncStatus = 'synced';
            await sale.save();
          }),
          ...unsyncedDeliveries.map((order) async {
            order.syncStatus = 'synced';
            await order.save();
          }),
          ...unsyncedBrokenOrders.map((order) async {
            order.syncStatus = 'synced';
            await order.save();
          }),
          ...unsyncedReturnOrders.map((order) async {
            order.syncStatus = 'synced';
            await order.save();
          }),
          ...unsyncedExpenses.map((expense) async {
            expense.syncStatus = 'synced';
            await expense.save();
          }),
          ...unsyncedDenominations.map((denomination) async {
            denomination.syncStatus = 'synced';
            await denomination.save();
          }),
        ]);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sync completed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Sync failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bharat Dairy Delivery'),
        actions: [
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: _isSyncing ? null : _syncData,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              final networkProvider = Provider.of<NetworkProvider>(context, listen: false);
              
              // Show confirmation dialog
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
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('Logout'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                // Perform local logout regardless of network status
                await Provider.of<AuthProvider>(context, listen: false).logout();
                
                // Navigate to login screen
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
      body: _buildHomeContent(context),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    final networkProvider = Provider.of<NetworkProvider>(context);
    
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
            
          Text(
            'Dashboard',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 16),
          
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildMenuCard(
                  context: context,
                  title: 'Sync Data',
                  icon: Icons.sync,
                  color: Colors.teal,
                  onTap: _syncData,
                  isLoading: _isSyncing,
                ),
                _buildMenuCard(
                  context: context,
                  title: 'Load Orders',
                  icon: Icons.downloading,
                  color: Colors.blue,
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
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                CircularProgressIndicator(color: color)
              else
                Icon(icon, size: 48, color: color),
              SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
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
