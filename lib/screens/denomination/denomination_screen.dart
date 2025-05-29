import 'package:flutter/material.dart';
import '../../services/offline_storage_service.dart';
import '../../models/delivery_order.dart';
import '../../models/expense.dart';
import '../../models/denomination.dart';

class DenominationScreen extends StatefulWidget {
  @override
  _DenominationScreenState createState() => _DenominationScreenState();
}

class _DenominationScreenState extends State<DenominationScreen> {
  final _storageService = OfflineStorageService();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for denomination counts
  final _500Controller = TextEditingController(text: '0');
  final _200Controller = TextEditingController(text: '0');
  final _100Controller = TextEditingController(text: '0');
  final _50Controller = TextEditingController(text: '0');
  final _20Controller = TextEditingController(text: '0');
  final _10Controller = TextEditingController(text: '0');
  final _coin1Controller = TextEditingController(text: '0');
  final _coin2Controller = TextEditingController(text: '0');
  final _coin5Controller = TextEditingController(text: '0');

  double _totalCashCollected = 0.0;
  double _totalExpenses = 0.0;
  double _denominationTotal = 0.0;
  double _difference = 0.0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _500Controller.dispose();
    _200Controller.dispose();
    _100Controller.dispose();
    _50Controller.dispose();
    _20Controller.dispose();
    _10Controller.dispose();
    _coin1Controller.dispose();
    _coin2Controller.dispose();
    _coin5Controller.dispose();
    super.dispose();
  }

  Future<void> _saveDenomination() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final currentDate = DateTime.now().toString().split(' ')[0];
      
      final denomination = Denomination(
        date: currentDate,
        note500: int.tryParse(_500Controller.text) ?? 0,
        note200: int.tryParse(_200Controller.text) ?? 0,
        note100: int.tryParse(_100Controller.text) ?? 0,
        note50: int.tryParse(_50Controller.text) ?? 0,
        note20: int.tryParse(_20Controller.text) ?? 0,
        note10: int.tryParse(_10Controller.text) ?? 0,
        coin1: int.tryParse(_coin1Controller.text) ?? 0,
        coin2: int.tryParse(_coin2Controller.text) ?? 0,
        coin5: int.tryParse(_coin5Controller.text) ?? 0,
        totalCashCollected: _totalCashCollected,
        totalExpenses: _totalExpenses,
        denominationTotal: _denominationTotal,
        difference: _difference,
      );

      await _storageService.saveDenomination(denomination);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Denomination details saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save denomination details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final currentDate = DateTime.now().toString().split(' ')[0];
      
      // Get all delivery orders for today
      final deliveryOrders = await _storageService.getDeliveryOrdersByDate(currentDate);
      
      // Get all public sales for today
      final publicSales = await _storageService.getPublicSalesByDate(currentDate);
      
      // Calculate total cash collected from delivery orders
      double cashFromDeliveryOrders = deliveryOrders
          .where((order) => order.paymentMethod == 'cash')
          .fold(0.0, (sum, order) => sum + double.parse(order.amountCollected));

      // Calculate total cash collected from public sales
      double cashFromPublicSales = publicSales
          .where((sale) => sale.paymentMethod == 'cash')
          .fold(0.0, (sum, sale) => sum + double.parse(sale.amountCollected));

      // Set total cash collected
      _totalCashCollected = cashFromDeliveryOrders + cashFromPublicSales;

      // Get all expenses for today
      final expenses = await _storageService.getExpensesByDate(currentDate);
      
      // Calculate total expenses
      _totalExpenses = expenses.fold(0.0, (sum, expense) => sum + expense.amount);

      // Load saved denomination if exists
      final savedDenomination = await _storageService.getDenominationByDate(currentDate);
      if (savedDenomination != null) {
        _500Controller.text = savedDenomination.note500.toString();
        _200Controller.text = savedDenomination.note200.toString();
        _100Controller.text = savedDenomination.note100.toString();
        _50Controller.text = savedDenomination.note50.toString();
        _20Controller.text = savedDenomination.note20.toString();
        _10Controller.text = savedDenomination.note10.toString();
        _coin1Controller.text = savedDenomination.coin1.toString();
        _coin2Controller.text = savedDenomination.coin2.toString();
        _coin5Controller.text = savedDenomination.coin5.toString();
      }

      _calculateTotals();
      
      setState(() => _isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _calculateTotals() {
    _denominationTotal = 
      (int.tryParse(_500Controller.text) ?? 0) * 500.0 +
      (int.tryParse(_200Controller.text) ?? 0) * 200.0 +
      (int.tryParse(_100Controller.text) ?? 0) * 100.0 +
      (int.tryParse(_50Controller.text) ?? 0) * 50.0 +
      (int.tryParse(_20Controller.text) ?? 0) * 20.0 +
      (int.tryParse(_10Controller.text) ?? 0) * 10.0 +
      (int.tryParse(_coin5Controller.text) ?? 0) * 5.0 +
      (int.tryParse(_coin2Controller.text) ?? 0) * 2.0 +
      (int.tryParse(_coin1Controller.text) ?? 0) * 1.0;

    _difference = _denominationTotal - (_totalCashCollected - _totalExpenses);
    
    setState(() {});
  }

  Widget _buildDenominationInput(String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'No. of Rs.$label',
              style: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(
            width: 70,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              textAlign: TextAlign.center,
              onChanged: (_) => _calculateTotals(),
            ),
          ),
          SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              'Rs.${((int.tryParse(controller.text) ?? 0) * int.parse(label)).toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Denomination Details')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final differenceColor = _difference.abs() < 0.01 ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text('Denomination Entry'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveDenomination,
            tooltip: 'Save Denomination',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: ListView(
          children: [
            // Summary Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Summary', style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cash Collection', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Rs.${_totalCashCollected.toStringAsFixed(2)}', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Expenses', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Rs.${_totalExpenses.toStringAsFixed(2)}', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('Expected Cash: Rs.${(_totalCashCollected - _totalExpenses).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            // Denomination Details Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Denomination Details', style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 12),
                    _buildDenominationInput('500', _500Controller),
                    _buildDenominationInput('200', _200Controller),
                    _buildDenominationInput('100', _100Controller),
                    _buildDenominationInput('50', _50Controller),
                    _buildDenominationInput('20', _20Controller),
                    _buildDenominationInput('10', _10Controller),
                    _buildDenominationInput('5', _coin5Controller),
                    _buildDenominationInput('2', _coin2Controller),
                    _buildDenominationInput('1', _coin1Controller),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            // Total and Difference Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Rs.${_denominationTotal.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Difference:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          'Rs.${_difference.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: differenceColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
