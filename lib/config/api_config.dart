// lib/config/api_config.dart

class ApiConfig {
  // Base URL for API
  static const String baseUrl = 'https://bharatdairy.pythonanywhere.com/apiapp';
  
  // API endpoints
  static const String login = '/auth/login/';
  static const String routes = '/routes/';
  static const String checkPurchaseOrder = '/loading-orders/check-purchase-order';
  static const String createLoadingOrder = '/loading-orders/create/';
  static const String sync = '/sync/';
  
  // Headers
  static Map<String, String> getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';  // Changed from 'Token' to 'Bearer'
    }

    return headers;
  }
}
