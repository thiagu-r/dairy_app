// lib/screens/home_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart';
// import '../providers/network_provider.dart';

// class HomeScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Dairy Delivery'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.logout),
//             onPressed: () {
//               Provider.of<AuthProvider>(context, listen: false).logout();
//             },
//           ),
//         ],
//       ),
//       body: _buildHomeContent(context),
//     );
//   }

//   Widget _buildHomeContent(BuildContext context) {
//     final networkProvider = Provider.of<NetworkProvider>(context);
    
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Network status indicator
//           if (!networkProvider.isOnline)
//             Container(
//               padding: EdgeInsets.all(12),
//               margin: EdgeInsets.only(bottom: 16),
//               decoration: BoxDecoration(
//                 color: Colors.orange.shade50,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.orange.shade200),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.wifi_off, color: Colors.orange.shade800),
//                   SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       'You are currently offline. Some features may be limited.',
//                       style: TextStyle(color: Colors.orange.shade800),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
            
//           Text(
//             'Dashboard',
//             style: Theme.of(context).textTheme.headlineMedium,
//           ),
//           SizedBox(height: 16),
          
//           Expanded(
//             child: GridView.count(
//               crossAxisCount: 2,
//               crossAxisSpacing: 16,
//               mainAxisSpacing: 16,
//               children: [
//                 _buildMenuCard(
//                   context,
//                   'Load Orders',
//                   Icons.downloading,
//                   Colors.blue,
//                   () => _showComingSoonDialog(context),
//                 ),
//                 _buildMenuCard(
//                   context,
//                   'Delivery Orders',
//                   Icons.local_shipping,
//                   Colors.green,
//                   () => _showComingSoonDialog(context),
//                 ),
//                 _buildMenuCard(
//                   context,
//                   'Broken Orders',
//                   Icons.broken_image,
//                   Colors.red,
//                   () => _showComingSoonDialog(context),
//                 ),
//                 _buildMenuCard(
//                   context,
//                   'Returned Orders',
//                   Icons.assignment_return,
//                   Colors.orange,
//                   () => _showComingSoonDialog(context),
//                 ),
//                 _buildMenuCard(
//                   context,
//                   'Public Sales',
//                   Icons.storefront,
//                   Colors.purple,
//                   () => _showComingSoonDialog(context),
//                 ),
//                 _buildMenuCard(
//                   context,
//                   'Denominations',
//                   Icons.attach_money,
//                   Colors.teal,
//                   () => _showComingSoonDialog(context),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
  
//   Widget _buildMenuCard(
//     BuildContext context,
//     String title,
//     IconData icon,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return Card(
//       elevation: 4,
//       margin: EdgeInsets.all(8),
//       child: InkWell(
//         onTap: onTap,
//         child: Padding(
//           padding: EdgeInsets.all(16),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(icon, size: 48, color: color),
//               SizedBox(height: 8),
//               Text(
//                 title,
//                 textAlign: TextAlign.center,
//                 style: Theme.of(context).textTheme.titleMedium,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
  
//   void _showComingSoonDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Coming Soon'),
//         content: Text('This feature is under development and will be available soon.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/network_provider.dart';
import 'load_orders/load_orders_dashboard.dart';
import 'delivery_orders/delivery_orders_dashboard.dart';
import 'public_sales/public_sales_dashboard.dart';
import 'broken_orders/broken_orders_screen.dart';
import 'expenses/expenses_dashboard.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Remove the OfflineStorageService and getCurrentRouteId method since we don't need them

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bharat Dairy Delivery'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              final networkProvider = Provider.of<NetworkProvider>(context, listen: false);
              
              // Show confirmation dialog
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Logout'),
                  content: Text(
                    networkProvider.isOnline 
                      ? 'Are you sure you want to logout?' 
                      : 'You are currently offline. Any unsynced data will remain on the device until you reconnect. Are you sure you want to logout?'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('Logout'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                // Perform local logout regardless of network status
                await Provider.of<AuthProvider>(context, listen: false).logout();
                
                // Navigate to login screen
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: _buildHomeContent(context),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    final networkProvider = Provider.of<NetworkProvider>(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Network status indicator
          if (!networkProvider.isOnline)
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.orange.shade800),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You are currently offline. Some features may be limited.',
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),
            
          Text(
            'Dashboard',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 16),
          
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildMenuCard(
                  context,
                  'Load Orders',
                  Icons.downloading,
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoadOrdersDashboard()),
                  ),
                ),
                _buildMenuCard(
                  context,
                  'Delivery Orders',
                  Icons.local_shipping,
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeliveryOrdersDashboard(),
                    ),
                  ),
                ),
                _buildMenuCard(
                  context,
                  'Public Sales',
                  Icons.store,
                  Colors.purple,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PublicSalesDashboard(),
                    ),
                  ),
                ),
                _buildMenuCard(
                  context,
                  'Broken Orders',
                  Icons.broken_image,
                  Colors.red,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BrokenOrdersScreen(),
                    ),
                  ),
                ),
                _buildMenuCard(
                  context,
                  'Returned Orders',
                  Icons.assignment_return,
                  Colors.orange,
                  () => _showComingSoonDialog(context),
                ),
                _buildMenuCard(
                  context,
                  'Denominations',
                  Icons.attach_money,
                  Colors.teal,
                  () => _showComingSoonDialog(context),
                ),
                _buildMenuCard(
                  context,
                  'Expenses',
                  Icons.account_balance_wallet,
                  Colors.indigo,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExpensesDashboard(),  // Remove routeId parameter
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Coming Soon'),
        content: Text('This feature is under development and will be available soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
