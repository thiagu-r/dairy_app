import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/offline_storage_service.dart';
import '../../providers/network_provider.dart';
import '../../models/delivery_order.dart';
import '../../models/route_model.dart';

class DeliveryOrdersScreen extends StatefulWidget {
  @override
  _DeliveryOrdersScreenState createState() => _DeliveryOrdersScreenState();
}

class _DeliveryOrdersScreenState extends State<DeliveryOrdersScreen> {
  final ApiService _apiService = ApiService();
  final OfflineStorageService _storageService = OfflineStorageService();
  
  List<DeliveryOrder> _deliveryOrders = [];
  bool _isLoading = false;
  String _error = '';
  late RouteModel _selectedRoute;
  late String _selectedDate;
  
  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().toString().split(' ')[0];
    _loadDeliveryOrders();
  }

  Future<void> _loadDeliveryOrders() async {
    setState(() => _isLoading = true);
    try {
      List<DeliveryOrder> orders;
      final networkProvider = Provider.of<NetworkProvider>(context, listen: false);
      
      if (networkProvider.isOnline) {  // Changed from isConnected to isOnline
        // If online, fetch from API and store locally
        orders = await _apiService.getDeliveryOrders(_selectedDate, _selectedRoute.id);
        
        // Store the fetched orders locally
        await _storageService.storeDeliveryOrders(orders);
      } else {
        // If offline, get from local storage
        orders = await _storageService.getDeliveryOrdersByDateAndRoute(
          _selectedDate,
          _selectedRoute.id,
        );
      }
      
      setState(() {
        _deliveryOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load delivery orders: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery Orders'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : _deliveryOrders.isEmpty
                  ? Center(child: Text('No delivery orders found'))
                  : ListView.builder(
                      itemCount: _deliveryOrders.length,
                      itemBuilder: (context, index) {
                        final order = _deliveryOrders[index];
                        return ListTile(
                          title: Text('Order #${order.orderNumber}'),
                          subtitle: Text('Route: ${order.routeName}'),
                          trailing: Text(order.status),
                        );
                      },
                    ),
    );
  }
}
