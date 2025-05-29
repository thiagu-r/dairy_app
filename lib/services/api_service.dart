// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../config/api_config.dart';
import '../models/route_model.dart';
import '../models/delivery_order.dart';
import '../models/broken_order.dart';
import '../services/offline_storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
      
      // Debug: Print original payload structure
      print('\n=== SYNC PAYLOAD DEBUG ===');
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      
      // Create a formatted string of the payload
      String prettyJson = encoder.convert(payload);
      
      // Print payload in chunks for better readability
      print('\nFull Sync Payload:');
      const int chunkSize = 1000;
      for (var i = 0; i < prettyJson.length; i += chunkSize) {
        var end = (i + chunkSize < prettyJson.length) ? i + chunkSize : prettyJson.length;
        print(prettyJson.substring(i, end));
        // Add a small delay between chunks for better console readability
        await Future.delayed(Duration(milliseconds: 100));
      }
      
      // Save payload to file for debugging (optional)
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/last_sync_payload.json');
        await file.writeAsString(prettyJson);
        print('\nPayload saved to: ${file.path}');
      } catch (e) {
        print('Failed to save payload to file: $e');
      }

      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.sync}'),
        headers: headers,
        body: json.encode(payload),
      );

      print('\n=== API RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body:');
      if (response.body.isNotEmpty) {
        try {
          String prettyResponse = encoder.convert(json.decode(response.body));
          print(prettyResponse);
        } catch (e) {
          print(response.body);
        }
      }

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
    } catch (e, stackTrace) {
      print('\n=== ERROR DETAILS ===');
      print('Error: $e');
      print('Stack trace:');
      print(stackTrace.toString().split('\n').take(10).join('\n')); // Print first 10 lines of stack trace
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}
