import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/delivery_order.dart';
import '../../models/loading_order.dart';
import '../../services/offline_storage_service.dart';

class UpdateDeliveryOrder extends StatefulWidget {
  final DeliveryOrder deliveryOrder;
  final LoadingOrder loadingOrder;

  UpdateDeliveryOrder({
    required this.deliveryOrder,
    required this.loadingOrder,
  });

  @override
  _UpdateDeliveryOrderState createState() => _UpdateDeliveryOrderState();
}

class _UpdateDeliveryOrderState extends State<UpdateDeliveryOrder> {
  final OfflineStorageService _storageService = OfflineStorageService();
  late List<DeliveryOrderItem> _items;
  late Map<int, LoadingOrderItem> _loadingItems;
  late Map<int, double> _availableExtras;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.deliveryOrder.items);
    _loadingItems = {
      for (var item in widget.loadingOrder.items) item.product: item
    };
    _calculateAvailableExtras();
  }

  Future<void> _calculateAvailableExtras() async {
    setState(() => _isLoading = true);
    
    try {
      // Get all delivery orders for this loading order
      final allDeliveryOrders = await _storageService.getDeliveryOrdersByDateAndRoute(
        widget.deliveryOrder.deliveryDate,
        widget.deliveryOrder.route,
      );

      // Calculate used quantities for each product
      Map<int, double> usedQuantities = {};
      for (var order in allDeliveryOrders) {
        for (var item in order.items) {
          usedQuantities[item.product] = (usedQuantities[item.product] ?? 0) +
              double.parse(item.deliveredQuantity);
        }
      }

      // Calculate available extras
      _availableExtras = {};
      for (var loadingItem in widget.loadingOrder.items) {
        double totalLoaded = double.parse(loadingItem.totalQuantity);
        double used = usedQuantities[loadingItem.product] ?? 0;
        _availableExtras[loadingItem.product] = totalLoaded - used;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to calculate available quantities: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateDeliveredQuantity(DeliveryOrderItem item, String newQuantity) async {
    if (newQuantity.isEmpty) return;
    
    try {
      double currentQuantity = double.parse(item.deliveredQuantity);
      double newQty = double.parse(newQuantity);
      double available = _availableExtras[item.product] ?? 0;

      if (newQty < currentQuantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot decrease delivered quantity')),
        );
        return;
      }

      if (newQty - currentQuantity > available) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not enough stock available')),
        );
        return;
      }

      setState(() {
        item.deliveredQuantity = newQuantity;
        item.calculateTotalPrice();
        _availableExtras[item.product] = available - (newQty - currentQuantity);
        widget.deliveryOrder.items = _items; // Ensure delivery order has updated items
        widget.deliveryOrder.updateTotalPrice(); // Update order total price
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid quantity format: $e')),
      );
    }
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) {
        LoadingOrderItem? selectedItem;
        String quantity = '';

        return AlertDialog(
          title: Text('Add New Item'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<LoadingOrderItem>(
                    hint: Text('Select Product'),
                    value: selectedItem,
                    items: widget.loadingOrder.items
                        .where((item) => (_availableExtras[item.product] ?? 0) > 0)
                        .map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text('${item.productName} (${_availableExtras[item.product]?.toStringAsFixed(3)} available)'),
                      );
                    }).toList(),
                    onChanged: (item) {
                      setState(() => selectedItem = item);
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => quantity = value,
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (selectedItem != null && quantity.isNotEmpty) {
                  try {
                    double qty = double.parse(quantity);
                    double available = _availableExtras[selectedItem!.product] ?? 0;
                    
                    if (qty > available) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Not enough stock available')),
                      );
                      return;
                    }

                    // Find existing item if any
                    DeliveryOrderItem? existingItem = _items.firstWhere(
                      (item) => item.product == selectedItem!.product,
                      orElse: () => DeliveryOrderItem(
                        id: 0,
                        product: selectedItem!.product,
                        productName: selectedItem!.productName,
                        orderedQuantity: '0.000',
                        extraQuantity: '0.000',
                        deliveredQuantity: '0.000',
                        unitPrice: selectedItem!.unitPrice ?? '0',
                        totalPrice: '0',
                      ),
                    );

                    setState(() {
                      if (!_items.contains(existingItem)) {
                        // If it's a new item, add it to the list
                        _items.add(existingItem);
                      }
                      
                      // Update the quantities
                      double currentQty = double.parse(existingItem.deliveredQuantity);
                      double newQty = currentQty + qty;
                      existingItem.deliveredQuantity = newQty.toStringAsFixed(3);
                      existingItem.extraQuantity = (double.parse(existingItem.extraQuantity) + qty).toStringAsFixed(3);
                      existingItem.calculateTotalPrice();
                      
                      _availableExtras[selectedItem!.product] = available - qty;
                      widget.deliveryOrder.items = _items;
                      widget.deliveryOrder.updateTotalPrice();
                    });
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invalid quantity format')),
                    );
                  }
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveDeliveryOrder() async {
    try {
      // Only set delivery time if it hasn't been set before
      if (widget.deliveryOrder.deliveryTime == null || widget.deliveryOrder.deliveryTime!.isEmpty) {
        final now = DateTime.now();
        widget.deliveryOrder.deliveryTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      }
      
      widget.deliveryOrder.items = _items;
      widget.deliveryOrder.updateTotalPrice(); // This will also update balance amount
      await _storageService.updateDeliveryOrder(widget.deliveryOrder);
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save delivery order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show confirmation dialog before leaving
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Unsaved Changes'),
            content: Text('Do you want to save changes before leaving?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true); // Close dialog
                  Navigator.pop(context); // Close form
                },
                child: Text('Discard'),
              ),
              TextButton(
                onPressed: () async {
                  await _saveDeliveryOrder();
                  Navigator.pop(context, true);
                },
                child: Text('Save'),
              ),
            ],
          ),
        );
        return result ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Update Delivery - ${widget.deliveryOrder.sellerName}'),
          actions: [
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveDeliveryOrder,
            ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.all(16),
                      children: [
                        // Order Items List
                        Text(
                          'Order Items',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: item.deliveredQuantity,
                                            decoration: InputDecoration(
                                              labelText: 'Delivered Quantity',
                                              helperText: 'Ordered: ${item.orderedQuantity}',
                                            ),
                                            keyboardType: TextInputType.number,
                                            onChanged: (value) => _updateDeliveredQuantity(item, value),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Text('Available: ${_availableExtras[item.product]?.toStringAsFixed(3)}'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 24),
                        
                        // Payment Details Section
                        Text(
                          'Payment Details',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 16),
                        
                        // Total Price (Read-only)
                        TextFormField(
                          initialValue: widget.deliveryOrder.totalPrice,
                          decoration: InputDecoration(
                            labelText: 'Total Price',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                          enabled: false,
                        ),
                        SizedBox(height: 16),
                        
                        // Opening Balance (Read-only)
                        TextFormField(
                          initialValue: widget.deliveryOrder.openingBalance,
                          decoration: InputDecoration(
                            labelText: 'Opening Balance',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                          enabled: false,
                        ),
                        SizedBox(height: 16),
                        
                        // Amount Collected
                        TextFormField(
                          initialValue: widget.deliveryOrder.amountCollected,
                          decoration: InputDecoration(
                            labelText: 'Amount Collected',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              widget.deliveryOrder.amountCollected = value;
                              widget.deliveryOrder.updateBalanceAmount();
                            });
                          },
                        ),
                        SizedBox(height: 16),
                        
                        // Balance Amount (Read-only)
                        TextFormField(
                          initialValue: widget.deliveryOrder.balanceAmount,
                          decoration: InputDecoration(
                            labelText: 'Balance Amount',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                          enabled: false,
                        ),
                        SizedBox(height: 16),
                        
                        // Payment Method
                        DropdownButtonFormField<String>(
                          value: widget.deliveryOrder.paymentMethod,
                          decoration: InputDecoration(
                            labelText: 'Payment Method',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(value: 'cash', child: Text('Cash')),
                            DropdownMenuItem(value: 'credit', child: Text('Credit')),
                            DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              widget.deliveryOrder.paymentMethod = value ?? 'cash';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: _showAddItemDialog,
                      child: Text('Add New Item'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
