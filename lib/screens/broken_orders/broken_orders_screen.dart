import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/loading_order.dart';
import '../../models/broken_order.dart';
import '../../services/offline_storage_service.dart';
import '../../services/api_service.dart';
import '../../providers/network_provider.dart';
import 'package:provider/provider.dart';

class BrokenOrdersScreen extends StatefulWidget {
  @override
  _BrokenOrdersScreenState createState() => _BrokenOrdersScreenState();
}

class _BrokenOrdersScreenState extends State<BrokenOrdersScreen> {
  final _storageService = OfflineStorageService();
  final _apiService = ApiService();
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  List<LoadingOrder> _loadingOrders = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadLoadingOrders();
  }

  Future<void> _loadLoadingOrders() async {
    setState(() => _isLoading = true);
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      _loadingOrders = await _storageService.getLoadingOrdersByDate(formattedDate);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load orders: $e';
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadLoadingOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Broken Orders'),
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
              'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
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
                                    onPressed: () => _showBrokenItemsDialog(order),
                                    child: Text('Add Broken Items'),
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

  void _showBrokenItemsDialog(LoadingOrder order) {
    showDialog(
      context: context,
      builder: (context) => BrokenItemsDialog(loadingOrder: order),
    ).then((updated) {
      if (updated == true) {
        _loadLoadingOrders();
      }
    });
  }
}

class BrokenItemsDialog extends StatefulWidget {
  final LoadingOrder loadingOrder;

  BrokenItemsDialog({required this.loadingOrder});

  @override
  _BrokenItemsDialogState createState() => _BrokenItemsDialogState();
}

class _BrokenItemsDialogState extends State<BrokenItemsDialog> {
  final Map<int, TextEditingController> _brokenControllers = {};
  final _storageService = OfflineStorageService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (var item in widget.loadingOrder.items) {
      _brokenControllers[item.product] = TextEditingController(
        text: item.brokenQuantity?.toString() ?? '0',
      );
    }
  }

  @override
  void dispose() {
    _brokenControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _saveBrokenItems() async {
    setState(() => _isSaving = true);
    try {
      // Update broken quantities in loading order
      List<BrokenOrderItem> brokenItems = [];
      
      for (var item in widget.loadingOrder.items) {
        final brokenQty = _brokenControllers[item.product]?.text ?? '0';
        final quantity = double.tryParse(brokenQty) ?? 0;
        
        if (quantity > 0) {
          item.brokenQuantity = quantity;
          brokenItems.add(BrokenOrderItem(
            productId: item.product.toString(),
            productName: item.productName,
            quantity: quantity,
          ));
        }
      }

      // Only create broken order if there are broken items
      if (brokenItems.isNotEmpty) {
        final brokenOrder = BrokenOrder(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          orderNumber: 'BO-${widget.loadingOrder.orderNumber}',
          date: widget.loadingOrder.loadingDate,
          routeId: widget.loadingOrder.route.toString(),
          routeName: widget.loadingOrder.routeName,
          items: brokenItems,
          syncStatus: 'pending',
        );

        // Save broken order
        await _storageService.saveBrokenOrder(brokenOrder);
      }

      // Save updated loading order
      await _storageService.updateLoadingOrder(widget.loadingOrder);

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save broken items: $e')),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Broken Items - Order #${widget.loadingOrder.orderNumber}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.loadingOrder.items.map((item) {
            return Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(item.productName),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _brokenControllers[item.product],
                      decoration: InputDecoration(
                        labelText: 'Broken',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveBrokenItems,
          child: _isSaving
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Save'),
        ),
      ],
    );
  }
}
