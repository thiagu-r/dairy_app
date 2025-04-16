import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/offline_storage_service.dart';
import '../../models/delivery_order.dart';

class ListDeliveryOrders extends StatefulWidget {
  @override
  _ListDeliveryOrdersState createState() => _ListDeliveryOrdersState();
}

class _ListDeliveryOrdersState extends State<ListDeliveryOrders> {
  final OfflineStorageService _storageService = OfflineStorageService();
  List<DeliveryOrder> _deliveryOrders = [];
  bool _isLoading = true;
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      // For now, we'll get all orders for the selected date
      final orders = await _storageService.getDeliveryOrdersByDate(_selectedDate);
      setState(() {
        _deliveryOrders = orders;
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
            child: Text(
              'Orders for $_selectedDate',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _deliveryOrders.isEmpty
                    ? Center(child: Text('No orders found for this date'))
                    : ListView.builder(
                        itemCount: _deliveryOrders.length,
                        itemBuilder: (context, index) {
                          final order = _deliveryOrders[index];
                          return Card(
                            margin: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ExpansionTile(
                              title: Text('Order #${order.orderNumber}'),
                              subtitle: Text(
                                'Route: ${order.routeName}\n'
                                'Status: ${order.status}',
                              ),
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Seller: ${order.sellerName}'),
                                      Text('Total Price: ${order.totalPrice}'),
                                      Text('Payment Method: ${order.paymentMethod}'),
                                      Text('Sync Status: ${order.syncStatus}'),
                                      if (order.notes?.isNotEmpty == true)
                                        Text('Notes: ${order.notes}'),
                                      SizedBox(height: 8),
                                      Text(
                                        'Items:',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      ...order.items.map((item) => ListTile(
                                            title: Text(item.productName),
                                            subtitle: Text(
                                              'Ordered: ${item.orderedQuantity}\n'
                                              'Delivered: ${item.deliveredQuantity}',
                                            ),
                                            trailing: Text('₹${item.totalPrice}'),
                                          )),
                                    ],
                                  ),
                                ),
                              ],
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