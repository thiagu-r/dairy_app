import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/offline_storage_service.dart';
import '../../models/loading_order.dart';
import '../../models/delivery_order.dart';

class FetchDeliveryOrders extends StatefulWidget {
  @override
  _FetchDeliveryOrdersState createState() => _FetchDeliveryOrdersState();
}

class _FetchDeliveryOrdersState extends State<FetchDeliveryOrders> {
  final OfflineStorageService _storageService = OfflineStorageService();
  final ApiService _apiService = ApiService();
  
  List<LoadingOrder> _loadingOrders = [];
  bool _isLoading = false;
  String _error = '';
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadLoadingOrders();
  }

  Future<void> _loadLoadingOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _storageService.getLoadingOrdersByDate(_selectedDate);
      setState(() {
        _loadingOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load loading orders: $e';
      });
    }
  }

  Future<void> _fetchDeliveryOrders(LoadingOrder loadingOrder) async {
    setState(() => _isLoading = true);
    try {
      // Check if orders already exist
      final hasExisting = await _storageService.hasDeliveryOrdersForRouteAndDate(
        loadingOrder.route,
        loadingOrder.loadingDate,
      );

      if (hasExisting) {
        final shouldRefetch = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Orders Already Exist'),
            content: Text(
              'Delivery orders for this route and date already exist. Do you want to fetch and replace them?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Replace'),
              ),
            ],
          ),
        ) ?? false;

        if (!shouldRefetch) {
          setState(() => _isLoading = false);
          return;
        }
      }

      final deliveryOrders = await _apiService.getDeliveryOrders(
        loadingOrder.loadingDate,
        loadingOrder.route,
      );
      
      // Store orders in offline storage (this will replace existing orders)
      await _storageService.storeDeliveryOrders(deliveryOrders);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasExisting 
              ? 'Successfully updated delivery orders'
              : 'Successfully fetched and stored delivery orders'
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch delivery orders: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_selectedDate),
      firstDate: DateTime.now().subtract(Duration(days: 30)),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateFormat('yyyy-MM-dd').format(picked);
      });
      _loadLoadingOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fetch Delivery Orders'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Loading Orders for $_selectedDate',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Expanded(
                      child: _loadingOrders.isEmpty
                          ? Center(
                              child: Text('No loading orders found for this date'),
                            )
                          : ListView.builder(
                              itemCount: _loadingOrders.length,
                              itemBuilder: (context, index) {
                                final order = _loadingOrders[index];
                                return Card(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: ListTile(
                                    title: Text('Order #${order.orderNumber}'),
                                    subtitle: Text(
                                      'Route: ${order.routeName}\n'
                                      'Status: ${order.status}',
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: () => _fetchDeliveryOrders(order),
                                      child: Text('Fetch Delivery Orders'),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
