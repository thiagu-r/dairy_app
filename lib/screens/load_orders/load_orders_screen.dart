// lib/screens/load_orders/load_orders_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../models/route_model.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import '../../models/loading_order.dart';
import '../../services/offline_storage_service.dart';
import 'package:hive/hive.dart';

class LoadOrdersScreen extends StatefulWidget {
  @override
  _LoadOrdersScreenState createState() => _LoadOrdersScreenState();
}

class _LoadOrdersScreenState extends State<LoadOrdersScreen> {
  final ApiService _apiService = ApiService();
  final OfflineStorageService _storageService = OfflineStorageService();
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _loadingTimeController = TextEditingController();
  final _cratesController = TextEditingController();
  
  List<RouteModel> _routes = [];
  RouteModel? _selectedRoute;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isPurchaseOrderLoading = false;
  String _errorMessage = '';
  Map<String, dynamic>? _purchaseOrderData;
  int? _purchaseOrderId;
  
  @override
  void initState() {
    super.initState();
    _fetchRoutes();
    _loadingTimeController.text = DateFormat('HH:mm').format(DateTime.now());
  }
  
  @override
  void dispose() {
    _notesController.dispose();
    _loadingTimeController.dispose();
    _cratesController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchRoutes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final routes = await _apiService.getRoutes();
      setState(() {
        _routes = routes;
        _isLoading = false;
        if (routes.isNotEmpty) {
          _selectedRoute = routes[0];
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load routes: $e';
      });
    }
  }
  
  Future<void> _checkPurchaseOrder() async {
    if (_selectedRoute == null) {
      setState(() {
        _errorMessage = 'Please select a route';
      });
      return;
    }
    
    setState(() {
      _isPurchaseOrderLoading = true;
      _errorMessage = '';
      _purchaseOrderData = null;
      _purchaseOrderId = null;
    });
    
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    
    try {
      // First check if loading order exists
      final loadingOrderCheck = await _apiService.checkLoadingOrder(
        _selectedRoute!.id,
        formattedDate,
      );

      // Check if loading order exists and has actual order data
      if (loadingOrderCheck != null && 
          loadingOrderCheck is! Map<String, dynamic> || 
          (loadingOrderCheck is Map<String, dynamic> && loadingOrderCheck['exists'] != false)) {
        // Loading order exists, ask user to store it
        final shouldStore = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Loading Order Exists'),
            content: Text('A loading order already exists for this route and date. Would you like to sync it to your device?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Sync'),
              ),
            ],
          ),
        ) ?? false;

        if (shouldStore) {
          final loadingOrder = LoadingOrder.fromJson(loadingOrderCheck);
          await _storageService.storeLoadingOrder(loadingOrder);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loading order synced successfully'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context);
          return;
        }
      }

      // If no loading order exists or user cancelled, check purchase order
      final data = await _apiService.checkPurchaseOrder(
        _selectedRoute!.id, 
        formattedDate
      );
      
      setState(() {
        _isPurchaseOrderLoading = false;
        _purchaseOrderData = data;
        _purchaseOrderId = data['exists'] ? data['purchase_order_id'] : null;
      });
      
      if (!data['exists']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No purchase order found for this route and date'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isPurchaseOrderLoading = false;
        _errorMessage = 'Failed to check orders: $e';
      });
    }
  }
  
  Future<void> _checkAndCreateLoadingOrder() async {
    if (_formKey.currentState?.validate() != true || _purchaseOrderId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // First check if loading order exists
      final loadingOrderCheck = await _apiService.checkLoadingOrder(
        _selectedRoute!.id,
        DateFormat('yyyy-MM-dd').format(_selectedDate),
      );

      if (loadingOrderCheck != null && loadingOrderCheck['exists'] != false) {
        // Loading order exists, store it locally
        final loadingOrder = LoadingOrder.fromJson(loadingOrderCheck);
        await _storageService.storeLoadingOrder(loadingOrder);

        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loading order already exists and has been synced'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
        return;
      }

      // Validate crates input
      final cratesValue = _cratesController.text.trim();
      final crates = cratesValue.isEmpty ? 0 : int.tryParse(cratesValue) ?? 0;

      // If no existing loading order, create new one
      final payload = {
        "route": _selectedRoute!.id,
        "loading_date": DateFormat('yyyy-MM-dd').format(_selectedDate),
        "loading_time": _loadingTimeController.text,
        "purchase_order_id": _purchaseOrderId,
        "notes": _notesController.text.trim(),
        "crates": crates,
      };

      final response = await _apiService.createLoadingOrder(payload);
      
      if (response['success'] == true && response['loading_order'] != null) {
        final loadingOrder = LoadingOrder.fromJson(response['loading_order']);
        await _storageService.storeLoadingOrder(loadingOrder);

        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Loading order created successfully'),
            backgroundColor: Colors.green,
          ),
        );

        _clearForm();
        Navigator.pop(context);

        // After successful loading order creation/retrieval
        final ordersBox = await Hive.openBox('ordersBox');
        await ordersBox.put('currentLoadingOrderId', loadingOrder.id);
        await ordersBox.put('currentOrderNumber', loadingOrder.orderNumber);
      } else {
        throw Exception(response['message'] ?? 'Failed to create loading order');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to create loading order: $e';
      });
    }
  }

  void _clearForm() {
    _notesController.clear();
    _cratesController.clear();
    _purchaseOrderData = null;
    _purchaseOrderId = null;
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(Duration(days: 7)),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _purchaseOrderData = null;
        _purchaseOrderId = null;
      });
    }
  }
  
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null) {
      setState(() {
        _loadingTimeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Load Orders'),
      ),
      body: _isLoading 
        ? LoadingIndicator() 
        : _errorMessage.isNotEmpty 
          ? ErrorMessage(message: _errorMessage, onRetry: _fetchRoutes)
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Loading Order',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16),
                    
                    // Route Dropdown
                    DropdownButtonFormField<RouteModel>(
                      decoration: InputDecoration(
                        labelText: 'Select Route',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedRoute,
                      items: _routes.map((route) {
                        return DropdownMenuItem<RouteModel>(
                          value: route,
                          child: Text('${route.name} (${route.code})'),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null) return 'Please select a route';
                        return null;
                      },
                      onChanged: (RouteModel? newValue) {
                        setState(() {
                          _selectedRoute = newValue;
                          _purchaseOrderData = null;
                          _purchaseOrderId = null;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Date Picker
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Loading Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('yyyy-MM-dd').format(_selectedDate),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Check Purchase Order Button
                    ElevatedButton.icon(
                      onPressed: _isPurchaseOrderLoading ? null : _checkPurchaseOrder,
                      icon: Icon(Icons.search),
                      label: Text('Check Purchase Order'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Purchase Order Items Table
                    if (_isPurchaseOrderLoading)
                      Center(child: CircularProgressIndicator()),
                      
                    if (_purchaseOrderData != null && _purchaseOrderData!['exists'] == true)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Purchase Order #${_purchaseOrderData!['purchase_order_id']}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 8),
                          
                          // Items Table
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: [
                                  DataColumn(label: Text('Product')),
                                  DataColumn(label: Text('Total Qty')),
                                  DataColumn(label: Text('Remaining')),
                                ],
                                rows: List<DataRow>.generate(
                                  (_purchaseOrderData!['items'] as List).length,
                                  (index) {
                                    final item = _purchaseOrderData!['items'][index];
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(item['product_name'])),
                                        DataCell(Text(item['total_quantity'])),
                                        DataCell(Text(item['remaining_quantity'])),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 24),
                          
                          // Additional Form Fields for Loading Order
                          Text(
                            'Loading Details',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 16),
                          
                          // Loading Time
                          InkWell(
                            onTap: () => _selectTime(context),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Loading Time',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.access_time),
                              ),
                              child: Text(_loadingTimeController.text),
                            ),
                          ),
                          SizedBox(height: 16),
                          
                          // Crates
                          TextFormField(
                            controller: _cratesController,
                            decoration: InputDecoration(
                              labelText: 'Number of Crates',
                              border: OutlineInputBorder(),
                              hintText: '0',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return null; // Allow empty value, will default to 0
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          
                          // Notes
                          TextFormField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              labelText: 'Notes',
                              border: OutlineInputBorder(),
                              hintText: 'Add any additional information',
                            ),
                            maxLines: 3,
                          ),
                          SizedBox(height: 24),
                          
                          // Submit Button
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _checkAndCreateLoadingOrder,
                            icon: Icon(Icons.check_circle),
                            label: Text('Create Loading Order'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              minimumSize: Size(double.infinity, 50),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
