import 'package:flutter/material.dart';
import 'delivery_orders_screen.dart';
import 'list_delivery_orders.dart';
import 'fetch_delivery_orders.dart';
import 'package:hive/hive.dart';
import '../../models/delivery_order.dart';

class DeliveryOrdersDashboard extends StatefulWidget {
  @override
  _DeliveryOrdersDashboardState createState() => _DeliveryOrdersDashboardState();
}

class _DeliveryOrdersDashboardState extends State<DeliveryOrdersDashboard> {
  double _todaysCashCollection = 0.0;
  int _todaysDeliveryCount = 0;
  double _todaysDeliveryAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTodaysSummary();
  }

  Future<void> _loadTodaysSummary() async {
    final currentDate = DateTime.now().toString().split(' ')[0];
    final deliveryOrdersBox = await Hive.openBox<DeliveryOrder>('deliveryOrders');
    
    final todaysOrders = deliveryOrdersBox.values.where((order) => 
      order.deliveryDate == currentDate && 
      order.actualDeliveryDate != null
    ).toList();

    double cashCollection = 0.0;
    double totalAmount = 0.0;

    for (var order in todaysOrders) {
      if (order.paymentMethod == 'cash') {
        cashCollection += double.parse(order.amountCollected);
      }
      totalAmount += double.parse(order.totalPrice);
    }

    setState(() {
      _todaysCashCollection = cashCollection;
      _todaysDeliveryCount = todaysOrders.length;
      _todaysDeliveryAmount = totalAmount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery Orders'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Summary",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                _buildCountCard(
                  'Cash Collection',
                  'Rs.${_todaysCashCollection.toStringAsFixed(2)}',
                  Colors.green,
                ),
                SizedBox(width: 16),
                _buildCountCard(
                  'Deliveries',
                  _todaysDeliveryCount.toString(),
                  Colors.blue,
                ),
                SizedBox(width: 16),
                _buildCountCard(
                  'Total Amount',
                  'Rs.${_todaysDeliveryAmount.toStringAsFixed(2)}',
                  Colors.orange,
                ),
              ],
            ),
            SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
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
          ],
        ),
      ),
    );
  }

  Widget _buildCountCard(String title, String count, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
