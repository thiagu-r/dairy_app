// lib/providers/network_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkProvider with ChangeNotifier {
  final Connectivity _connectivity;
  bool _isOnline = true;
  StreamSubscription? _connectivitySubscription;
  
  NetworkProvider(this._connectivity) {
    initConnectivity();
  }
  
  bool get isOnline => _isOnline;
  
  // Initial connectivity check
  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    
    try {
      result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      
      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    } catch (e) {
      print('Connectivity check failed: $e');
    }
  }
  
  // Update connection status based on connectivity result
  void _updateConnectionStatus(ConnectivityResult result) {
    bool wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;
    
    // Only notify listeners if the status changed
    if (wasOnline != _isOnline) {
      notifyListeners();
      
      // Here you could trigger sync operations when coming back online
      if (_isOnline && !wasOnline) {
        _syncOfflineData();
      }
    }
  }
  
  // Sync offline data when coming back online
  Future<void> _syncOfflineData() async {
    // This would be implemented to sync offline changes when coming back online
    print('Network restored. Starting data synchronization...');
    
    // In a real app, you would:
    // 1. Get pending sync items from local storage
    // 2. Send them to the server
    // 3. Update local records with server responses
  }
  
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}