import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/public_sale.dart';
import '../../models/loading_order.dart';
import '../../services/offline_storage_service.dart';

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
    showDialog(
      context: context,
      builder: (context) {
        LoadingOrderItem? selectedItem;
        String quantity = '';

        return AlertDialog(
          title: Text('Add Product'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<LoadingOrderItem>(
                    hint: Text('Select Product'),
                    value: selectedItem,
                    items: _loadingOrder?.items
                        .where((item) => (_availableExtras[item.product] ?? 0) > 0)
                        .map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(
                          '${item.productName} (${_availableExtras[item.product]?.toStringAsFixed(3)} available) - Rs.${item.unitPrice ?? "0"}',
                        ),
                      );
                    }).toList(),
                    onChanged: (item) {
                      setState(() => selectedItem = item);
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) => quantity = value,
                  ),
                  if (selectedItem != null && quantity.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        'Total: Rs.${(double.parse(quantity) * double.parse(selectedItem!.unitPrice ?? "0")).toStringAsFixed(2)}',
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
                  double qty = double.parse(quantity);
                  double available = _availableExtras[selectedItem!.product] ?? 0;
                  String unitPrice = selectedItem!.unitPrice ?? "0";
                  
                  if (qty > available) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Not enough stock available')),
                    );
                    return;
                  }

                  setState(() {
                    _items.add(PublicSaleItem(
                      id: 0,
                      product: selectedItem!.product,
                      productName: selectedItem!.productName,
                      quantity: quantity,
                      unitPrice: unitPrice,
                      totalPrice: (qty * double.parse(unitPrice)).toStringAsFixed(2),
                    ));
                    _availableExtras[selectedItem!.product] = available - qty;
                    _updateTotalPrice();
                  });
                  Navigator.pop(context);
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
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

  Future<void> _saveSale() async {
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
          title: Text('New Public Sale'),
          actions: [
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveSale,
            ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    TextFormField(
                      controller: _customerNameController,
                      decoration: InputDecoration(
                        labelText: 'Customer Name (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _customerPhoneController,
                      decoration: InputDecoration(
                        labelText: 'Customer Phone (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _customerAddressController,
                      decoration: InputDecoration(
                        labelText: 'Customer Address (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Items',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Card(
                          child: ListTile(
                            title: Text(item.productName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Quantity: ${item.quantity}'),
                                Text('Unit Price: Rs.${item.unitPrice}'),
                                Text('Total: Rs.${item.totalPrice}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  _availableExtras[item.product] = 
                                      (_availableExtras[item.product] ?? 0) + 
                                      double.parse(item.quantity);
                                  _items.removeAt(index);
                                  _updateTotalPrice();
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _showAddItemDialog,
                      child: Text('Add Item'),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Payment Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Total Price: Rs.$_totalPrice',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _amountCollectedController,
                      decoration: InputDecoration(
                        labelText: 'Amount Collected',
                        prefixText: 'Rs.',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) => _updateBalanceAmount(),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Balance Amount: Rs.$_balanceAmount',
                      style: TextStyle(
                        fontSize: 16,
                        color: double.parse(_balanceAmount) > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: InputDecoration(
                        labelText: 'Payment Method',
                        border: OutlineInputBorder(),
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
    );
  }
}
