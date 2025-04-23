import 'package:flutter/material.dart';
import 'delivery_orders_screen.dart';
import 'list_delivery_orders.dart';
import 'fetch_delivery_orders.dart';

class DeliveryOrdersDashboard extends StatefulWidget {
  @override
  _DeliveryOrdersDashboardState createState() => _DeliveryOrdersDashboardState();
}

class _DeliveryOrdersDashboardState extends State<DeliveryOrdersDashboard> {
  Widget _buildOptionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              SizedBox(height: 16),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery Orders'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildOptionCard(
              context,
              'List Delivery Orders',
              Icons.list_alt,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ListDeliveryOrders(),
                ),
              ),
            ),
            _buildOptionCard(
              context,
              'Fetch Delivery Orders',
              Icons.cloud_download,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FetchDeliveryOrders(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
