import 'package:flutter/material.dart';
import '../../models/expense.dart';
import '../../models/loading_order.dart';
import '../../services/offline_storage_service.dart';
import 'add_expense.dart';
import 'package:intl/intl.dart';

class ListExpenses extends StatefulWidget {
  @override
  _ListExpensesState createState() => _ListExpensesState();
}

class _ListExpensesState extends State<ListExpenses> {
  final _storageService = OfflineStorageService();
  List<Expense> _expenses = [];
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  bool _isLoading = false;
  LoadingOrder? _loadingOrder;

  @override
  void initState() {
    super.initState();
    _loadLoadingOrderAndExpenses();
  }

  Future<void> _loadLoadingOrderAndExpenses() async {
    setState(() => _isLoading = true);
    try {
      // First get loading order for current date
      final loadingOrders = await _storageService.getLoadingOrdersByDate(_selectedDate);
      if (loadingOrders.isEmpty) {
        throw Exception('No loading order found for today');
      }
      _loadingOrder = loadingOrders.first;

      // Then get expenses for this date and route
      final expenses = await _storageService.getExpensesByDateAndRoute(
        _selectedDate,
        _loadingOrder!.route,
      );

      setState(() {
        _expenses = expenses;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load expenses: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expenses List'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _loadingOrder == null
              ? Center(child: Text('No loading order found for today'))
              : Column(
                  children: [
                    Expanded(
                      child: _expenses.isEmpty
                          ? Center(child: Text('No expenses found'))
                          : ListView.separated(
                              itemCount: _expenses.length,
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              separatorBuilder: (context, index) => SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final expense = _expenses[index];
                                return Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                    child: Row(
                                      children: [
                                        _expenseTypeIcon(expense.expenseType),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _expenseTypeLabel(expense.expenseType),
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                              ),
                                              if (expense.description != null && expense.description!.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4.0),
                                                  child: Text(
                                                    expense.description!,
                                                    style: Theme.of(context).textTheme.bodyMedium,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          '₹${expense.amount.toStringAsFixed(2)}',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total:',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '₹${_calculateTotal()}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: _loadingOrder == null
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddExpense(
                      date: _selectedDate,
                      routeId: _loadingOrder!.route,
                    ),
                  ),
                );
                if (result == true) {
                  _loadLoadingOrderAndExpenses();
                }
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  String _calculateTotal() {
    double total = _expenses.fold(
      0,
      (sum, expense) => sum + expense.amount,
    );
    return total.toStringAsFixed(2);
  }

  String _expenseTypeLabel(ExpenseType type) {
    switch (type) {
      case ExpenseType.food:
        return 'Food/Snacks';
      case ExpenseType.vehicle:
        return 'Vehicle Repair/Maintenance';
      case ExpenseType.fuel:
        return 'Fuel';
      case ExpenseType.other:
        return 'Other Expenses';
      case ExpenseType.allowance:
        return 'Daily Allowance';
    }
  }

  Widget _expenseTypeIcon(ExpenseType type) {
    Color color;
    IconData icon;
    switch (type) {
      case ExpenseType.food:
        color = Colors.orange;
        icon = Icons.fastfood;
        break;
      case ExpenseType.vehicle:
        color = Colors.blue;
        icon = Icons.build;
        break;
      case ExpenseType.fuel:
        color = Colors.teal;
        icon = Icons.local_gas_station;
        break;
      case ExpenseType.other:
        color = Colors.grey;
        icon = Icons.miscellaneous_services;
        break;
      case ExpenseType.allowance:
        color = Colors.green;
        icon = Icons.attach_money;
        break;
    }
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.15),
      child: Icon(icon, color: color),
    );
  }
}
