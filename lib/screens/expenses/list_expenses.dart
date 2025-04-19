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
                      child: ListView.builder(
                        itemCount: _expenses.length,
                        itemBuilder: (context, index) {
                          final expense = _expenses[index];
                          return ListTile(
                            title: Text('${expense.expenseType} - ₹${expense.amount}'),
                            subtitle: Text(expense.description ?? ''),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Total: ₹${_calculateTotal()}',
                        style: Theme.of(context).textTheme.titleLarge,
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
              child: Icon(Icons.add),
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
}
