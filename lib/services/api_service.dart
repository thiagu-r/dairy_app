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
    final authBox = Hive.box('authBox');
    final accessToken = authBox.get('accessToken');  // Changed to directly get accessToken
    return accessToken;
  }
  
  // Create headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }
    return ApiConfig.getHeaders(token: token);
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
      final response = await http.get(
        Uri.parse('${baseUrl}/orders/delivery/?delivery_date=$deliveryDate&route=$routeId'),
        headers: headers,
      );
      
      print('Delivery Orders API Response - Status Code: ${response.statusCode}');
      print('Delivery Orders API Response - Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final orders = data.map((order) => DeliveryOrder.fromJson(order)).toList();
        
        // Store orders in offline storage
        final storageService = OfflineStorageService();
        await storageService.storeDeliveryOrders(orders);
        
        return orders;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error fetching delivery orders: $e');
      throw Exception('Failed to fetch delivery orders: $e');
    }
  }
}
