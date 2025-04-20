// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../config/api_config.dart';
import '../models/route_model.dart';
import '../models/delivery_order.dart';
import '../services/offline_storage_service.dart';

class ApiService {
  final String baseUrl = ApiConfig.baseUrl;
  
  // Get auth token from storage
  Future<String?> _getToken() async {
    final authBox = await Hive.openBox('authBox');
    return authBox.get('accessToken');
  }
  
  // Create headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
  
  // Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl${ApiConfig.login}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['detail'] ?? 'Login failed');
    }
  }
  
  // Get routes for loading orders
  Future<List<RouteModel>> getRoutes() async {
    try {
      final headers = await _getHeaders();
      print('Fetching routes with headers: $headers');
      
      final response = await http.get(
        Uri.parse('${baseUrl}${ApiConfig.routes}'),
        headers: headers,
      );
      
      print('Routes API Response - Status Code: ${response.statusCode}');
      print('Routes API Response - Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((route) => RouteModel.fromJson(route)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error fetching routes: $e');
      throw Exception('Failed to load routes: $e');
    }
  }
  
  // Check if purchase order exists for route and date
  Future<Map<String, dynamic>> checkPurchaseOrder(int routeId, String deliveryDate) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl${ApiConfig.checkPurchaseOrder}?route=$routeId&delivery_date=$deliveryDate'),
        headers: headers,
      );
      
      print('Check PO Response - Status Code: ${response.statusCode}');
      print('Check PO Response - Body: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error checking purchase order: $e');
      throw Exception('Failed to check purchase order: $e');
    }
  }
  
  // Create loading order
  Future<Map<String, dynamic>> createLoadingOrder(Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      print('Creating loading order with payload: $data');
      
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.createLoadingOrder}'),
        headers: headers,
        body: json.encode(data),
      );
      
      print('Create Loading Order Response - Status Code: ${response.statusCode}');
      print('Create Loading Order Response - Body: ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = response.body.isNotEmpty 
            ? json.decode(response.body) 
            : {'message': 'Failed to create loading order'};
        throw Exception(errorData['message'] ?? 'Failed to create loading order');
      }
    } catch (e) {
      print('Error creating loading order: $e');
      throw Exception('Failed to create loading order: $e');
    }
  }

  Future<List<DeliveryOrder>> getDeliveryOrders(String deliveryDate, int routeId) async {
    try {
      final headers = await _getHeaders();
      
      final uri = Uri.parse('$baseUrl/orders/delivery').replace(
        queryParameters: {
          'delivery_date': deliveryDate,
          'route': routeId.toString(),
        },
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final orders = data.map((json) {
          final order = DeliveryOrder.fromJson(json);
          // These fields should now be modifiable
          order.route = routeId;
          order.deliveryDate = deliveryDate;
          return order;
        }).toList();
        
        return orders;
      } else {
        final errorMessage = response.body.isNotEmpty 
            ? json.decode(response.body)['message'] ?? 'Failed to fetch delivery orders'
            : 'Failed to fetch delivery orders';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error fetching delivery orders: $e');
      throw Exception('Failed to fetch delivery orders: $e');
    }
  }

  Future<Map<String, dynamic>> checkLoadingOrder(int routeId, String deliveryDate) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/loading-orders/check-loading-order/?route=$routeId&delivery_date=$deliveryDate'),
        headers: headers,
      );
      
      print('Check Loading Order Response - Status Code: ${response.statusCode}');
      print('Check Loading Order Response - Body: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error checking loading order: $e');
      throw Exception('Failed to check loading order: $e');
    }
  }

  Future<Map<String, dynamic>> syncData(Map<String, dynamic> payload) async {
    try {
      final headers = await _getHeaders();
      
      // Update delivery orders status to completed
      if (payload['data']['delivery_orders'] != null) {
        payload['data']['delivery_orders'] = payload['data']['delivery_orders'].map((order) {
          order['status'] = 'completed';
          return order;
        }).toList();
      }
      
      // Print detailed sync payload with counts
      print('\n=== SYNC PAYLOAD DETAILS ===');
      print('Public Sales: ${payload['data']['public_sales']?.length ?? 0} items');
      print('Delivery Orders: ${payload['data']['delivery_orders']?.length ?? 0} items');
      print('Broken Orders: ${payload['data']['broken_orders']?.length ?? 0} items');
      print('Return Orders: ${payload['data']['return_orders']?.length ?? 0} items');
      print('Expenses: ${payload['data']['expenses']?.length ?? 0} items');
      print('Denominations: ${payload['data']['denominations']?.length ?? 0} items');
      
      // Add 1 second delay
      await Future.delayed(Duration(seconds: 1));
      
      // Print full payload in chunks for better readability
      print('\n=== FULL PAYLOAD (START) ===');
      final encodedPayload = json.encode(payload);
      const int chunkSize = 1000;
      
      for (var i = 0; i < encodedPayload.length; i += chunkSize) {
        print(encodedPayload.substring(
          i, 
          i + chunkSize < encodedPayload.length ? i + chunkSize : encodedPayload.length
        ));
      }
      print('=== FULL PAYLOAD (END) ===\n');
      
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.sync}'),
        headers: headers,
        body: json.encode(payload),
      );

      print('Sync Response Status: ${response.statusCode}');
      print('Sync Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Sync failed with status ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Sync error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}
