// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'models/user.dart';
import 'models/loading_order.dart';
import 'models/delivery_order.dart';
import 'providers/auth_provider.dart';
import 'providers/network_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Register adapters for custom objects
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(LoadingOrderAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(LoadingOrderItemAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(DeliveryOrderAdapter());
  }
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(DeliveryOrderItemAdapter());
  }
  
  // Open Hive boxes
  await Hive.openBox('authBox');
  await Hive.openBox('ordersBox');
  await Hive.openBox('productsBox');
  await Hive.openBox('customersBox');
  await Hive.openBox('syncBox');
  await Hive.openBox('loadingOrders');
  await Hive.openBox('deliveryOrders');
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Network provider to detect and handle online/offline status
        ChangeNotifierProvider(
          create: (_) => NetworkProvider(Connectivity()),
        ),
        
        // Auth provider for user authentication and management
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        
        // Add other providers as needed
        // ChangeNotifierProvider(create: (_) => OrdersProvider()),
        // ChangeNotifierProvider(create: (_) => ProductsProvider()),
      ],
      child: DairyDeliveryApp(),
    );
  }
}

class DairyDeliveryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Initialize network listener when app starts
    final networkProvider = Provider.of<NetworkProvider>(context, listen: false);
    networkProvider.initConnectivity();
    
    return MaterialApp(
      title: 'Dairy Delivery Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Follows system theme by default
      home: SplashScreen(),
    );
  }
}
