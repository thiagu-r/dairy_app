import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/public_sale.dart';
import '../../models/loading_order.dart';
import '../../services/offline_storage_service.dart';
import 'denomination_screen.dart';

class AddPublicSale extends StatefulWidget {
  final String saleDate;

  AddPublicSale({required this.saleDate});

  @override
  _AddPublicSaleState createState() => _AddPublicSaleState();
}

class _AddPublicSaleState extends State<AddPublicSale> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _storageService = OfflineStorageService();
  
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _amountCollectedController = TextEditingController();
  
  LoadingOrder? _loadingOrder;
  List<PublicSaleItem> _items = [];
  Map<int, double> _availableExtras = {};
  String _paymentMethod = 'cash';
  bool _isLoading = true;
  String _totalPrice = '0.00';
  String _balanceAmount = '0.00';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLoadingOrder();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerAddressController.dispose();
    _amountCollectedController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _calculateAvailableQuantities(_loadingOrder!);
    }
  }

  Future<void> _loadLoadingOrder() async {
    setState(() => _isLoading = true);
    try {
      // Get loading order for current route and date
      final loadingOrder = await _storageService.getLoadingOrderByDateAndRoute(
        widget.saleDate,
        // TODO: Get current route ID from somewhere
        1, // Replace with actual route ID
      );

      if (loadingOrder == null) {
        throw Exception('No loading order found for this date');
      }

      // Calculate available quantities
      await _calculateAvailableQuantities(loadingOrder);

      setState(() {
        _loadingOrder = loadingOrder;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _calculateAvailableQuantities(LoadingOrder loadingOrder) async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      // Get all delivery orders for this loading order
      final deliveryOrders = await _storageService.getDeliveryOrdersByDateAndRoute(
        widget.saleDate,
        loadingOrder.route,
      );

      // Get all public sales for this date and route
      final publicSales = await _storageService.getPublicSalesByDateAndRoute(
        widget.saleDate,
        loadingOrder.route,
      );

      // Calculate used quantities
      Map<int, double> usedQuantities = {};
      
      // Add quantities from delivery orders
      for (var order in deliveryOrders) {
        for (var item in order.items) {
          usedQuantities[item.product] = (usedQuantities[item.product] ?? 0) +
              double.parse(item.deliveredQuantity);
        }
      }

      // Add quantities from public sales (excluding current items)
      for (var sale in publicSales) {
        for (var item in sale.items) {
          usedQuantities[item.product] = (usedQuantities[item.product] ?? 0) +
              double.parse(item.quantity);
        }
      }

      // Add broken quantities from loading order
      for (var item in loadingOrder.items) {
        if (item.brokenQuantity != null && item.brokenQuantity! > 0) {
          usedQuantities[item.product] = (usedQuantities[item.product] ?? 0) +
              item.brokenQuantity!;
        }
      }

      // Subtract current items from used quantities since they're not yet saved
      for (var item in _items) {
        usedQuantities[item.product] = (usedQuantities[item.product] ?? 0) -
            double.parse(item.quantity);
      }

      // Calculate available quantities
      _availableExtras = {};
      for (var loadingItem in loadingOrder.items) {
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

  void _showAddItemDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        LoadingOrderItem? selectedItem;
        String quantity = '';

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.add_shopping_cart_outlined, color: Theme.of(context).colorScheme.primary),
                  SizedBox(width: 8),
                  Text('Add Product'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<LoadingOrderItem>(
                      decoration: InputDecoration(
                        labelText: 'Select Product',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                      value: selectedItem,
                      items: _loadingOrder?.items
                          .where((item) => (_availableExtras[item.product] ?? 0) > 0)
                          .map((item) => DropdownMenuItem(
                                value: item,
                                child: Text(
                                  '${item.productName} (${_availableExtras[item.product]?.toStringAsFixed(3)} available)',
                                ),
                              ))
                          .toList(),
                      onChanged: (LoadingOrderItem? value) {
                        setDialogState(() {
                          selectedItem = value;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    if (selectedItem != null)
                      Text(
                        'Unit Price: Rs.${selectedItem!.unitPrice ?? "0"}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      onChanged: (String value) {
                        setDialogState(() {
                          quantity = value;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    if (selectedItem != null && quantity.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Total: Rs.${_calculateItemTotal(selectedItem!, quantity)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (selectedItem != null && quantity.isNotEmpty) {
                      _addItemToSale(selectedItem!, quantity);
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _calculateItemTotal(LoadingOrderItem item, String quantity) {
    try {
      final qty = double.parse(quantity);
      final price = double.parse(item.unitPrice ?? "0");
      return (qty * price).toStringAsFixed(2);
    } catch (e) {
      return "0.00";
    }
  }

  void _addItemToSale(LoadingOrderItem selectedItem, String quantity) {
    try {
      double qty = double.parse(quantity);
      double available = _availableExtras[selectedItem.product] ?? 0;
      String unitPrice = selectedItem.unitPrice ?? "0";
      
      if (qty > available) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not enough stock available')),
        );
        return;
      }

      setState(() {
        _items.add(PublicSaleItem(
          id: 0,
          product: selectedItem.product,
          productName: selectedItem.productName,
          quantity: quantity,
          unitPrice: unitPrice,
          totalPrice: _calculateItemTotal(selectedItem, quantity),
        ));
        _availableExtras[selectedItem.product] = available - qty;
        _updateTotalPrice();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid quantity entered')),
      );
    }
  }

  void _updateTotalPrice() {
    double total = 0;
    for (var item in _items) {
      total += double.parse(item.totalPrice);
    }
    setState(() {
      _totalPrice = total.toStringAsFixed(2);
      _updateBalanceAmount();
    });
  }

  void _updateBalanceAmount() {
    double total = double.parse(_totalPrice);
    double collected = double.parse(_amountCollectedController.text.isEmpty 
        ? '0' 
        : _amountCollectedController.text);
    setState(() {
      _balanceAmount = (total - collected).toStringAsFixed(2);
    });
  }

  Future<void> _saveSale({Map<int, int>? denominations}) async {
    if (_formKey.currentState?.validate() != true || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    try {
      final sale = PublicSale(
        id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
        route: _loadingOrder!.route,
        customerName: _customerNameController.text.isEmpty 
            ? null 
            : _customerNameController.text,
        customerPhone: _customerPhoneController.text.isEmpty 
            ? null 
            : _customerPhoneController.text,
        customerAddress: _customerAddressController.text.isEmpty 
            ? null 
            : _customerAddressController.text,
        saleDate: widget.saleDate,
        saleTime: DateFormat('HH:mm:ss').format(DateTime.now()),
        paymentMethod: _paymentMethod,
        totalPrice: _totalPrice,
        amountCollected: _amountCollectedController.text.isEmpty 
            ? '0.00' 
            : _amountCollectedController.text,
        balanceAmount: _balanceAmount,
        items: _items,
        // Add denominations here if you update the model
      );

      await _storageService.storePublicSale(sale);
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save sale: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_loadingOrder != null) {
          await _calculateAvailableQuantities(_loadingOrder!);
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('New Public Sale', style: Theme.of(context).textTheme.titleLarge),
          actions: [
            IconButton(
              icon: Icon(Icons.save),
              onPressed: () async {
                // On save, show denomination screen and wait for confirmation
                if (_formKey.currentState?.validate() != true || _items.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please add at least one item')),
                  );
                  return;
                }
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DenominationScreen(
                      amount: double.tryParse(_amountCollectedController.text) ?? 0,
                    ),
                  ),
                );
                if (result != null && result is Map<int, int>) {
                  await _saveSale(denominations: result);
                }
              },
              tooltip: 'Save Sale',
            ),
          ],
        ),
        floatingActionButton: _isLoading
            ? null
            : FloatingActionButton.extended(
                onPressed: _showAddItemDialog,
                icon: Icon(Icons.add),
                label: Text('Add Item'),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.all(20),
                  children: [
                    // Customer Info Section
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _customerNameController,
                              decoration: InputDecoration(
                                labelText: 'Customer Name (Optional)',
                                prefixIcon: Icon(Icons.person_outline),
                                filled: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _customerPhoneController,
                              decoration: InputDecoration(
                                labelText: 'Customer Phone (Optional)',
                                prefixIcon: Icon(Icons.phone),
                                filled: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _customerAddressController,
                              decoration: InputDecoration(
                                labelText: 'Customer Address (Optional)',
                                prefixIcon: Icon(Icons.location_on_outlined),
                                filled: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Items Section
                    Text('Items', style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 8),
                    ..._items.map((item) => Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 1,
                          child: ListTile(
                            leading: Icon(Icons.shopping_bag_outlined, color: Theme.of(context).colorScheme.primary),
                            title: Text(item.productName),
                            subtitle: Text('Qty: ${item.quantity}  |  Unit: Rs.${item.unitPrice}\nTotal: Rs.${item.totalPrice}'),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _availableExtras[item.product] =
                                      (_availableExtras[item.product] ?? 0) + double.parse(item.quantity);
                                  _items.remove(item);
                                  _updateTotalPrice();
                                });
                              },
                            ),
                          ),
                        )),
                    if (_items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text('No items added yet.', style: TextStyle(color: Colors.grey)),
                      ),
                    SizedBox(height: 24),

                    // Payment Details Section
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Payment Details', style: Theme.of(context).textTheme.titleMedium),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Price:', style: TextStyle(fontSize: 16)),
                                Text('Rs.$_totalPrice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            SizedBox(height: 12),
                            TextFormField(
                              controller: _amountCollectedController,
                              decoration: InputDecoration(
                                labelText: 'Amount Collected',
                                prefixIcon: Icon(Icons.payments_outlined),
                                prefixText: 'Rs.',
                                filled: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              onChanged: (value) => _updateBalanceAmount(),
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Balance Amount:', style: TextStyle(fontSize: 16)),
                                Text(
                                  'Rs.$_balanceAmount',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: double.parse(_balanceAmount) > 0 ? Colors.red : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _paymentMethod,
                              decoration: InputDecoration(
                                labelText: 'Payment Method',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                              ),
                              items: [
                                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                                DropdownMenuItem(value: 'online', child: Text('Online')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _paymentMethod = value ?? 'cash';
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }
}
