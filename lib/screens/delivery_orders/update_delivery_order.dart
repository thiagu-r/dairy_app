import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/delivery_order.dart';
import '../../models/loading_order.dart';
import '../../services/offline_storage_service.dart';
import 'return_order_card.dart';

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

class _UpdateDeliveryOrderState extends State<UpdateDeliveryOrder> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _storageService = OfflineStorageService();
  bool _isLoading = true;
  late DeliveryOrder _workingDeliveryOrder;
  late List<DeliveryOrderItem> _items;
  late Map<int, LoadingOrderItem> _loadingItems;
  Map<int, double> _availableExtras = {};
  Map<int, TextEditingController> _quantityControllers = {};
  final _amountCollectedController = TextEditingController();
  final _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeOrder();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _amountCollectedController.dispose();
    _notesController.dispose();
    _quantityControllers.values.forEach((controller) => controller.dispose());
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _calculateAvailableExtras();
    }
  }

  Future<void> _initializeOrder() async {
    _workingDeliveryOrder = DeliveryOrder(
      id: widget.deliveryOrder.id,
      orderNumber: widget.deliveryOrder.orderNumber,
      deliveryDate: widget.deliveryOrder.deliveryDate,
      route: widget.deliveryOrder.route,
      routeName: widget.deliveryOrder.routeName,
      sellerName: widget.deliveryOrder.sellerName,
      status: widget.deliveryOrder.status,
      items: List.from(widget.deliveryOrder.items),
      seller: widget.deliveryOrder.seller,
      deliveryTime: widget.deliveryOrder.deliveryTime,
      totalPrice: widget.deliveryOrder.totalPrice,
      openingBalance: widget.deliveryOrder.openingBalance,
      amountCollected: widget.deliveryOrder.amountCollected,
      balanceAmount: widget.deliveryOrder.balanceAmount,
      paymentMethod: widget.deliveryOrder.paymentMethod,
      notes: widget.deliveryOrder.notes,
      syncStatus: widget.deliveryOrder.syncStatus,
    );
    
    _items = _workingDeliveryOrder.items;
    _loadingItems = {
      for (var item in widget.loadingOrder.items) item.product: item
    };

    // Initialize controllers for existing items
    for (var item in _items) {
      _quantityControllers[item.product] = TextEditingController(
        text: item.deliveredQuantity
      );
    }

    _amountCollectedController.text = _workingDeliveryOrder.amountCollected;
    _notesController.text = _workingDeliveryOrder.notes ?? '';

    await _calculateAvailableExtras();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Recalculate quantities when returning to this screen
        await _calculateAvailableExtras();
        return true;
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
                  // Add search bar
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Material(
                      elevation: 1,
                      borderRadius: BorderRadius.circular(14),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search Products',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          filled: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.all(16),
                      children: [
                        Row(
                          children: [
                            Text(
                              'Order Items',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 12),
                            Expanded(child: Divider(thickness: 1)),
                          ],
                        ),
                        SizedBox(height: 16),
                        ..._buildFilteredItemsList(),
                        SizedBox(height: 24),
                        
                        // Payment Details Section
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: _buildPaymentDetails(),
                        ),
                        
                        // Payment Method
                        DropdownButtonFormField<String>(
                          value: _workingDeliveryOrder.paymentMethod,  // Changed from widget.deliveryOrder to _workingDeliveryOrder
                          decoration: const InputDecoration(
                            labelText: 'Payment Method',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'cash', child: Text('Cash')),
                            DropdownMenuItem(value: 'credit', child: Text('Credit')),
                            DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _workingDeliveryOrder.paymentMethod = value ?? 'cash';  // Update _workingDeliveryOrder instead
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildItemCard(DeliveryOrderItem item) {
    return Card(
      margin: EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: Theme.of(context).colorScheme.primary, size: 28),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.productName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Total: Rs.${item.totalPrice}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityControllers[item.product],
                    decoration: InputDecoration(
                      labelText: 'Delivered Quantity',
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      helperText: 'Ordered: ${item.orderedQuantity}',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.check_circle_outline, color: Colors.green),
                    onPressed: () => _updateItemQuantity(item),
                    tooltip: 'Update Quantity',
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Available: ${_availableExtras[item.product]?.toStringAsFixed(3)}'),
                Text(
                  'Total: Rs.${item.totalPrice}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFilteredItemsList() {
    return _items
        .where((item) {
          final matchesSearch = item.productName.toLowerCase().contains(_searchQuery);
          final hasQuantity = double.parse(item.orderedQuantity) > 0 || 
                            double.parse(item.deliveredQuantity) > 0;
          return matchesSearch && (hasQuantity || _searchQuery.isNotEmpty);
        })
        .map((item) => _buildItemCard(item))
        .toList();
  }

  Future<void> _calculateAvailableExtras() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    
    try {
      final allDeliveryOrders = await _storageService.getDeliveryOrdersByDateAndRoute(
        widget.deliveryOrder.deliveryDate,
        widget.deliveryOrder.route,
      );

      final publicSales = await _storageService.getPublicSalesByDateAndRoute(
        widget.deliveryOrder.deliveryDate,
        widget.deliveryOrder.route,
      );

      Map<int, double> usedQuantities = {};
      
      // Add quantities from all other delivery orders
      for (var order in allDeliveryOrders) {
        if (order.id != widget.deliveryOrder.id) {
          for (var item in order.items) {
            usedQuantities[item.product] = (usedQuantities[item.product] ?? 0) +
                double.parse(item.deliveredQuantity);
          }
        }
      }

      // Add quantities from public sales
      for (var sale in publicSales) {
        for (var item in sale.items) {
          usedQuantities[item.product] = (usedQuantities[item.product] ?? 0) +
              double.parse(item.quantity);
        }
      }

      // Add current working quantities
      for (var item in _items) {
        usedQuantities[item.product] = (usedQuantities[item.product] ?? 0) +
            double.parse(item.deliveredQuantity);
      }

      // Add broken quantities from loading order
      for (var item in widget.loadingOrder.items) {
        if (item.brokenQuantity != null && item.brokenQuantity! > 0) {
          usedQuantities[item.product] = (usedQuantities[item.product] ?? 0) +
              item.brokenQuantity!;
        }
      }

      // Calculate available extras
      _availableExtras = {};
      for (var loadingItem in widget.loadingOrder.items) {
        double totalLoaded = double.parse(loadingItem.totalQuantity);
        double used = usedQuantities[loadingItem.product] ?? 0;
        _availableExtras[loadingItem.product] = totalLoaded - used;
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to calculate available quantities: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateOrderTotals() {
    // Calculate total price
    double orderTotal = 0;
    for (var item in _items) {
      orderTotal += double.parse(item.totalPrice);
    }
    
    setState(() {
      _workingDeliveryOrder.totalPrice = orderTotal.toStringAsFixed(2);
      _updateBalanceAmount();
    });
  }

  void _updateBalanceAmount() {
    double total = double.parse(_workingDeliveryOrder.totalPrice) + 
                   double.parse(_workingDeliveryOrder.openingBalance);
    double collected = double.parse(_amountCollectedController.text.isEmpty 
        ? '0' 
        : _amountCollectedController.text);
    
    setState(() {
      _workingDeliveryOrder.amountCollected = _amountCollectedController.text;
      _workingDeliveryOrder.balanceAmount = (total - collected).toStringAsFixed(2);
    });
  }

  void _handleQuantityChange(DeliveryOrderItem item, String newQuantity) {
    if (newQuantity.isEmpty) return;
    
    try {
      double currentQuantity = double.parse(item.deliveredQuantity);
      double newQty = double.parse(newQuantity);
      double available = _availableExtras[item.product] ?? 0;

      // Add current quantity to available for recalculation
      available += currentQuantity;

      if (newQty > available) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not enough stock available')),
        );
        _quantityControllers[item.product]?.text = item.deliveredQuantity;
        return;
      }

      setState(() {
        item.deliveredQuantity = newQuantity;
        double unitPrice = double.parse(item.unitPrice);
        item.totalPrice = (newQty * unitPrice).toStringAsFixed(2);
        
        _availableExtras[item.product] = available - newQty;
        
        _updateOrderTotals();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid quantity format')),
      );
      _quantityControllers[item.product]?.text = item.deliveredQuantity;
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
        // Update the item's delivered quantity and total price
        item.deliveredQuantity = newQuantity;
        double unitPrice = double.parse(item.unitPrice);
        item.totalPrice = (newQty * unitPrice).toStringAsFixed(2);
        
        // Update available extras
        _availableExtras[item.product] = available - (newQty - currentQuantity);
        
        // Update order totals
        _updateOrderTotals();
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
              // Calculate preview total price
              double previewTotal = 0;
              if (selectedItem != null && quantity.isNotEmpty) {
                try {
                  double qty = double.parse(quantity);
                  double unitPrice = double.parse(selectedItem!.unitPrice ?? "0");
                  previewTotal = qty * unitPrice;
                } catch (e) {
                  // Handle parsing errors silently
                }
              }

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
                    onChanged: (value) {
                      setState(() => quantity = value);
                    },
                  ),
                  if (previewTotal > 0)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Total: Rs.${previewTotal.toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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

                    var existingItem = _items.firstWhere(
                      (item) => item.product == selectedItem!.product,
                      orElse: () => DeliveryOrderItem(
                        id: 0,
                        product: selectedItem!.product,
                        productName: selectedItem!.productName,
                        orderedQuantity: '0.000',
                        deliveredQuantity: '0.000',
                        unitPrice: selectedItem!.unitPrice ?? '0',
                        totalPrice: '0',
                      ),
                    );

                    setState(() {
                      if (!_items.contains(existingItem)) {
                        _items.add(existingItem);
                        // Create controller for new item
                        _quantityControllers[existingItem.product] = TextEditingController(
                          text: existingItem.deliveredQuantity
                        )..addListener(() {
                          _handleQuantityChange(existingItem, _quantityControllers[existingItem.product]!.text);
                        });
                      }
                      
                      double currentQty = double.parse(existingItem.deliveredQuantity);
                      double newQty = currentQty + qty;
                      
                      // Update controller text which will trigger the listener
                      _quantityControllers[existingItem.product]?.text = newQty.toStringAsFixed(3);
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
      if (_workingDeliveryOrder.deliveryTime == null || _workingDeliveryOrder.deliveryTime!.isEmpty) {
        final now = DateTime.now();
        _workingDeliveryOrder.deliveryTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      }
      
      // Copy the working delivery order back to the original
      widget.deliveryOrder.items = List.from(_workingDeliveryOrder.items);
      widget.deliveryOrder.totalPrice = _workingDeliveryOrder.totalPrice;
      widget.deliveryOrder.amountCollected = _amountCollectedController.text;
      widget.deliveryOrder.balanceAmount = _workingDeliveryOrder.balanceAmount;
      widget.deliveryOrder.paymentMethod = _workingDeliveryOrder.paymentMethod;
      widget.deliveryOrder.deliveryTime = _workingDeliveryOrder.deliveryTime;
      
      await _storageService.updateDeliveryOrder(widget.deliveryOrder);
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save delivery order: $e')),
      );
    }
  }

  void _updateItemQuantity(DeliveryOrderItem item) {
    final newQuantity = _quantityControllers[item.product]?.text ?? '';
    if (newQuantity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a quantity')),
      );
      return;
    }

    try {
      double currentQuantity = double.parse(item.deliveredQuantity);
      double newQty = double.parse(newQuantity);
      double available = _availableExtras[item.product] ?? 0;

      // Add the current quantity to available if we're updating
      if (currentQuantity > 0) {
        available += currentQuantity;
      }

      if (newQty > available) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not enough stock available')),
        );
        _quantityControllers[item.product]?.text = item.deliveredQuantity;
        return;
      }

      setState(() {
        item.deliveredQuantity = newQuantity;
        double unitPrice = double.parse(item.unitPrice);
        item.totalPrice = (newQty * unitPrice).toStringAsFixed(2);
        
        _availableExtras[item.product] = available - newQty;
        
        _updateOrderTotals();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid quantity format')),
      );
      _quantityControllers[item.product]?.text = item.deliveredQuantity;
    }
  }

  Widget _buildPaymentDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Details',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        
        // Total Price
        Text(
          'Total Price: Rs.${_workingDeliveryOrder.totalPrice}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        
        // Opening Balance
        Text(
          'Opening Balance: Rs.${_workingDeliveryOrder.openingBalance}',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 16),
        
        // Amount Collected
        TextFormField(
          controller: _amountCollectedController,
          decoration: InputDecoration(
            labelText: 'Amount Collected',
            border: OutlineInputBorder(),
            prefixText: 'Rs.',
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) => _updateBalanceAmount(),
        ),
        SizedBox(height: 16),
        
        // Balance Amount
        Text(
          'Balance Amount: Rs.${_workingDeliveryOrder.balanceAmount}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: double.parse(_workingDeliveryOrder.balanceAmount) > 0 
                ? Colors.red 
                : Colors.green,
          ),
        ),
      ],
    );
  }
}
