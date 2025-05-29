import 'package:flutter/material.dart';

class DenominationScreen extends StatefulWidget {
  final double amount;
  const DenominationScreen({Key? key, required this.amount}) : super(key: key);

  @override
  State<DenominationScreen> createState() => _DenominationScreenState();
}

class _DenominationScreenState extends State<DenominationScreen> {
  final List<int> denominations = [2000, 1000, 500, 200, 100, 50, 20, 10, 5, 2, 1];
  final Map<int, TextEditingController> controllers = {};
  double denominationTotal = 0;

  @override
  void initState() {
    super.initState();
    for (var denom in denominations) {
      controllers[denom] = TextEditingController();
      controllers[denom]!.addListener(_updateTotal);
    }
  }

  @override
  void dispose() {
    for (var ctrl in controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _updateTotal() {
    double total = 0;
    for (var denom in denominations) {
      int count = int.tryParse(controllers[denom]?.text ?? '') ?? 0;
      total += denom * count;
    }
    setState(() {
      denominationTotal = total;
    });
  }

  Map<int, int> _getDenominationMap() {
    final map = <int, int>{};
    for (var denom in denominations) {
      int count = int.tryParse(controllers[denom]?.text ?? '') ?? 0;
      if (count > 0) map[denom] = count;
    }
    return map;
  }

  void _onSavePressed() {
    Navigator.pop(context, _getDenominationMap());
  }

  @override
  Widget build(BuildContext context) {
    final difference = denominationTotal - widget.amount;
    return Scaffold(
      appBar: AppBar(
        title: Text('Denomination Entry'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _onSavePressed,
            tooltip: 'Save Denomination',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            // Summary Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                            Text('Rs.${widget.amount.toStringAsFixed(2)}', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Expenses', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Rs.0.00', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('Expected Cash: Rs.${widget.amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold)),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Denomination Details', style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 12),
                    ...denominations.map((denom) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          Text('No. of Rs.$denom', style: TextStyle(fontSize: 16)),
                          Spacer(),
                          SizedBox(
                            width: 70,
                            child: TextField(
                              controller: controllers[denom],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: true,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Rs.${(denom * (int.tryParse(controllers[denom]?.text ?? '') ?? 0)).toStringAsFixed(2)}'),
                        ],
                      ),
                    )),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Rs.${denominationTotal.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Difference:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          'Rs.${difference.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: difference.abs() < 0.01 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
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