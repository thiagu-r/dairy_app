import 'package:flutter/material.dart';
import 'list_expenses.dart';
import 'add_expense.dart';
import 'package:intl/intl.dart';

class ExpensesDashboard extends StatefulWidget {
  @override
  _ExpensesDashboardState createState() => _ExpensesDashboardState();
}

class _ExpensesDashboardState extends State<ExpensesDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expenses Dashboard'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Expenses',
              style: Theme.of(context).textTheme.headlineSmall,
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
                  'List Expenses',
                  Icons.list_alt,
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ListExpenses(),
                    ),
                  ),
                ),
                _buildOptionCard(
                  context,
                  'Add Expense',
                  Icons.add_circle,
                  Colors.green,
                  () {
                    final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddExpense(
                          date: currentDate,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
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
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
