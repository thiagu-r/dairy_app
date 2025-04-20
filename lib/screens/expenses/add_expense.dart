import 'package:flutter/material.dart';
import '../../models/expense.dart';
import '../../models/loading_order.dart';
import '../../services/offline_storage_service.dart';

class AddExpense extends StatefulWidget {
  final String date;
  final int? routeId;

  AddExpense({
    required this.date,
    this.routeId,
  });

  @override
  _AddExpenseState createState() => _AddExpenseState();
}

class _AddExpenseState extends State<AddExpense> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _storageService = OfflineStorageService();
  
  ExpenseType _selectedExpenseType = ExpenseType.fuel;
  bool _isLoading = false;
  LoadingOrder? _loadingOrder;
  
  @override
  void initState() {
    super.initState();
    if (widget.routeId == null) {
      _loadLoadingOrder();
    }
  }

  Future<void> _loadLoadingOrder() async {
    setState(() => _isLoading = true);
    try {
      final loadingOrders = await _storageService.getLoadingOrdersByDate(widget.date);
      if (loadingOrders.isEmpty) {
        throw Exception('No loading order found for today');
      }
      setState(() {
        _loadingOrder = loadingOrders.first;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final routeId = widget.routeId ?? _loadingOrder?.route;
    if (routeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No route found for today')),
      );
      return;
    }

    try {
      final expense = Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: widget.date,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text.isEmpty 
            ? null 
            : _descriptionController.text,
        route: routeId,
        expenseType: _selectedExpenseType,
      );

      await _storageService.addExpense(expense);
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save expense: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Add Expense')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Expense'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<ExpenseType>(
                decoration: InputDecoration(
                  labelText: 'Expense Type',
                  border: OutlineInputBorder(),
                ),
                value: _selectedExpenseType,
                items: ExpenseType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (ExpenseType? value) {
                  if (value != null) {
                    setState(() => _selectedExpenseType = value);
                  }
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveExpense,
                child: Text('Save Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
