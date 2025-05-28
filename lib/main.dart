// lib/main.dart

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'models/user.dart';
import 'models/loading_order.dart';
import 'models/delivery_order.dart';
import 'models/public_sale.dart';
import 'models/expense.dart';
import 'models/route.dart' as route_model;
import 'models/denomination.dart';
import 'models/broken_order.dart';
import 'models/return_order.dart';
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
  
  // Register Hive Adapters with consistent typeIds
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(UserAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(LoadingOrderAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(LoadingOrderItemAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(DeliveryOrderAdapter());
  }
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(DeliveryOrderItemAdapter());
  }
  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(PublicSaleAdapter());
  }
  if (!Hive.isAdapterRegistered(7)) {
    Hive.registerAdapter(PublicSaleItemAdapter());
  }
  if (!Hive.isAdapterRegistered(8)) {
    Hive.registerAdapter(ExpenseAdapter());
  }
  if (!Hive.isAdapterRegistered(9)) {
    Hive.registerAdapter(route_model.RouteAdapter());
  }
  if (!Hive.isAdapterRegistered(11)) {  // Changed from 6 to 11
    Hive.registerAdapter(DenominationAdapter());
  }
  if (!Hive.isAdapterRegistered(12)) {
    Hive.registerAdapter(BrokenOrderAdapter());
  }
  if (!Hive.isAdapterRegistered(13)) {
    Hive.registerAdapter(BrokenOrderItemAdapter());
  }
  if (!Hive.isAdapterRegistered(14)) {
    Hive.registerAdapter(ReturnOrderAdapter());
  }
  if (!Hive.isAdapterRegistered(15)) {
    Hive.registerAdapter(ReturnOrderItemAdapter());
  }
  if (!Hive.isAdapterRegistered(16)) {
    Hive.registerAdapter(ExpenseAdapter());
  }
  if (!Hive.isAdapterRegistered(17)) {
    Hive.registerAdapter(ExpenseTypeAdapter());
  }
  
  // Delete the denominations box before opening it (for development only!)
  await Hive.deleteBoxFromDisk('denominations');

  // Open Hive boxes without clearing them
  await Future.wait([
    Hive.openBox('authBox'),
    Hive.openBox('ordersBox'),
    Hive.openBox('productsBox'),
    Hive.openBox('customersBox'),
    Hive.openBox('syncBox'),
    Hive.openBox<LoadingOrder>('loadingOrders'),
    Hive.openBox<DeliveryOrder>('deliveryOrders'),
    Hive.openBox<PublicSale>('publicSales'),
    Hive.openBox<Expense>('expenses'),
    Hive.openBox<route_model.Route>('routes'),
    Hive.openBox<Denomination>('denominations'),
    Hive.openBox<ReturnOrder>('returnOrders'),
  ]);
  
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
