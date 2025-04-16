import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/offline_storage_service.dart';
import '../../models/delivery_order.dart';
import '../../models/loading_order.dart';
import 'update_delivery_order.dart';

class ListDeliveryOrders extends StatefulWidget {
  @override
  _ListDeliveryOrdersState createState() => _ListDeliveryOrdersState();
}

class _ListDeliveryOrdersState extends State<ListDeliveryOrders> {
  final OfflineStorageService _storageService = OfflineStorageService();
  List<DeliveryOrder> _deliveryOrders = [];
  List<DeliveryOrder> _filteredOrders = [];
  bool _isLoading = true;
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _storageService.getDeliveryOrdersByDate(_selectedDate);
      setState(() {
        _deliveryOrders = orders;
        _filteredOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load orders: $e')),
      );
    }
  }

  void _filterOrders(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredOrders = _deliveryOrders;
      } else {
        _filteredOrders = _deliveryOrders
            .where((order) => order.sellerName
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
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
      _loadOrders();
    }
  }

  void _showOrderDetails(DeliveryOrder order) async {
    // Get the loading order for this delivery
    final loadingOrder = await _storageService.getLoadingOrderByDateAndRoute(
      order.deliveryDate,
      order.route,
    );

    if (loadingOrder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loading order not found')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateDeliveryOrder(
          deliveryOrder: order,
          loadingOrder: loadingOrder,
        ),
      ),
    );

    if (result == true) {
      // Refresh the list if order was updated
      _loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery Orders List'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Orders for $_selectedDate',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by seller name',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _filterOrders,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                    ? Center(child: Text('No orders found'))
                    : ListView.builder(
                        itemCount: _filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = _filteredOrders[index];
                          return Card(
                            margin: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              title: Text(order.sellerName),
                              subtitle: Text('Order #${order.orderNumber}'),
                              trailing: Icon(Icons.chevron_right),
                              onTap: () => _showOrderDetails(order),
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
