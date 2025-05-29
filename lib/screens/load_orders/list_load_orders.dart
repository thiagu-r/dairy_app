import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/offline_storage_service.dart';
import '../../models/loading_order.dart';
import 'edit_load_order.dart';

class ListLoadOrders extends StatefulWidget {
  @override
  _ListLoadOrdersState createState() => _ListLoadOrdersState();
}

class _ListLoadOrdersState extends State<ListLoadOrders> {
  final OfflineStorageService _storageService = OfflineStorageService();
  List<LoadingOrder> _loadingOrders = [];
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
      final orders = await _storageService.getLoadingOrdersByDate(_selectedDate);
      setState(() {
        _loadingOrders = orders;
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
        title: Text('Load Orders List'),
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
                : _loadingOrders.isEmpty
                    ? Center(child: Text('No orders found for this date'))
                    : ListView.builder(
                        itemCount: _loadingOrders.length,
                        itemBuilder: (context, index) {
                          final order = _loadingOrders[index];
                          return Card(
                            margin: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ExpansionTile(
                              title: Text('Order #${order.orderNumber}'),
                              subtitle: Text(
                                'Route: ${order.routeName}\nStatus: ${order.status}',
                              ),
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Items:', style: Theme.of(context).textTheme.titleMedium),
                                      SizedBox(height: 8),
                                      ...order.items.map((item) => Padding(
                                        padding: EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Text(item.productName),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Text('Qty: ${item.loadedQuantity}'),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Text('Rem: ${item.remainingQuantity}'),
                                            ),
                                          ],
                                        ),
                                      )).toList(),
                                      SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EditLoadOrder(
                                                orderNumber: order.orderNumber,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text('Edit Order'),
                                      ),
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
