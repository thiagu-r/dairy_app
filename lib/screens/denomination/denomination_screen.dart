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
  final _coinsController = TextEditingController(text: '0');

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
    _coinsController.dispose();
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
        coins: double.tryParse(_coinsController.text) ?? 0.0,
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
        _coinsController.text = savedDenomination.coins.toString();
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
      (double.tryParse(_coinsController.text) ?? 0.0);

    _difference = _denominationTotal - (_totalCashCollected - _totalExpenses);
    
    setState(() {});
  }

  Widget _buildDenominationInput(String label, TextEditingController controller, {bool isCoins = false}) {
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
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: isCoins 
                  ? TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (_) => _calculateTotals(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                'Rs.${(isCoins ? double.tryParse(controller.text) ?? 0 : (int.tryParse(controller.text) ?? 0) * int.parse(label)).toStringAsFixed(2)}',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.right,
              ),
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Denomination Entry'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cash Collection',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Rs.${_totalCashCollected.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Expenses',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Rs.${_totalExpenses.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Divider(height: 24),
                      Text(
                        'Expected Cash: Rs.${(_totalCashCollected - _totalExpenses).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Denomination Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              _buildDenominationInput('500', _500Controller),
              _buildDenominationInput('200', _200Controller),
              _buildDenominationInput('100', _100Controller),
              _buildDenominationInput('50', _50Controller),
              _buildDenominationInput('20', _20Controller),
              _buildDenominationInput('10', _10Controller),
              _buildDenominationInput('Coins', _coinsController, isCoins: true),
              SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Total Amount: Rs.${_denominationTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Difference: Rs.${_difference.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _difference != 0 ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saveDenomination,
                  icon: Icon(Icons.save),
                  label: Text('Save Denomination'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
