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

  Widget _buildOrderCard(DeliveryOrder order) {
    final bool isUpdated = order.actualDeliveryDate != null;
    
    // Calculate total delivered quantity
    double totalDeliveredQuantity = 0;
    for (var item in order.items) {
      totalDeliveredQuantity += double.parse(item.deliveredQuantity);
    }
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      color: isUpdated ? Colors.green.withOpacity(0.08) : Theme.of(context).colorScheme.surfaceVariant,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showOrderDetails(order),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.store, color: Theme.of(context).colorScheme.primary, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.sellerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isUpdated ? Colors.green : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text('Order #${order.orderNumber}', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text('Quantity: ${totalDeliveredQuantity.toStringAsFixed(3)}'),
                    Text('Amount: Rs.${order.totalPrice}', style: TextStyle(fontWeight: FontWeight.bold)),
                    if (isUpdated)
                      Text(
                        'Updated on: ${order.actualDeliveryDate}',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isUpdated)
                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                  Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Divider(height: 24, thickness: 1),
                SizedBox(height: 8),
                Material(
                  elevation: 1,
                  borderRadius: BorderRadius.circular(14),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by seller name',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                    onChanged: _filterOrders,
                  ),
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
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        itemBuilder: (context, index) {
                          final order = _filteredOrders[index];
                          return _buildOrderCard(order);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
