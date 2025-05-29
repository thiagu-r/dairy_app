import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/loading_order.dart';
import '../../services/offline_storage_service.dart';

class ReturnOrdersScreen extends StatefulWidget {
  @override
  _ReturnOrdersScreenState createState() => _ReturnOrdersScreenState();
}

class _ReturnOrdersScreenState extends State<ReturnOrdersScreen> {
  final _storageService = OfflineStorageService();
  bool _isLoading = false;
  String _error = '';
  List<LoadingOrder> _loadingOrders = [];
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_selectedDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
        title: Text('Return Orders'),
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
              'Date: $_selectedDate',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(child: Text(_error))
                    : _loadingOrders.isEmpty
                        ? Center(child: Text('No loading orders found for this date'))
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
                                    onPressed: () => _showReturnItemsDialog(order),
                                    child: Text('View Return Items'),
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

  Future<void> _showReturnItemsDialog(LoadingOrder loadingOrder) async {
    // Get all delivery orders for this loading order
    final deliveryOrders = await _storageService.getDeliveryOrdersByDateAndRoute(
      loadingOrder.loadingDate,
      loadingOrder.route,
    );

    // Calculate used quantities
    Map<int, double> usedQuantities = {};
    for (var order in deliveryOrders) {
      for (var item in order.items) {
        usedQuantities[item.product] = (usedQuantities[item.product] ?? 0) +
            double.parse(item.deliveredQuantity);
      }
    }

    // Calculate return quantities
    Map<int, double> returnQuantities = {};
    for (var item in loadingOrder.items) {
      double totalLoaded = double.parse(item.totalQuantity);
      double used = usedQuantities[item.product] ?? 0;
      if (item.brokenQuantity != null) {
        used += item.brokenQuantity!;
      }
      double returnQty = totalLoaded - used;
      if (returnQty > 0) {
        returnQuantities[item.product] = returnQty;
      }
    }

    // Show dialog with return items
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Return Items - Order #${loadingOrder.orderNumber}'),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    horizontalMargin: 12,
                    columnSpacing: 24,
                    columns: [
                      DataColumn(label: Text('Product')),
                      DataColumn(label: Text('Return Qty')),
                      DataColumn(label: Text('Unit Price')),
                      DataColumn(label: Text('Total')),
                    ],
                    rows: loadingOrder.items
                        .where((item) => (returnQuantities[item.product] ?? 0) > 0)
                        .map((item) {
                      final returnQty = returnQuantities[item.product] ?? 0;
                      final unitPrice = double.tryParse(item.unitPrice ?? '0') ?? 0;
                      final totalPrice = returnQty * unitPrice;

                      return DataRow(
                        cells: [
                          DataCell(Text(item.productName)),
                          DataCell(Text(returnQty.toStringAsFixed(3))),
                          DataCell(Text('₹${unitPrice.toStringAsFixed(2)}')),
                          DataCell(Text('₹${totalPrice.toStringAsFixed(2)}')),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Total Return Value: ₹${_calculateTotalReturnValue(loadingOrder, returnQuantities).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  double _calculateTotalReturnValue(LoadingOrder order, Map<int, double> returnQuantities) {
    double total = 0;
    for (var item in order.items) {
      final returnQty = returnQuantities[item.product] ?? 0;
      final unitPrice = double.tryParse(item.unitPrice ?? '0') ?? 0;
      total += returnQty * unitPrice;
    }
    return total;
  }
}
