import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/offline_storage_service.dart';
import '../../models/public_sale.dart';
import 'add_public_sale.dart';

class ListPublicSales extends StatefulWidget {
  @override
  _ListPublicSalesState createState() => _ListPublicSalesState();
}

class _ListPublicSalesState extends State<ListPublicSales> {
  final OfflineStorageService _storageService = OfflineStorageService();
  List<PublicSale> _publicSales = [];
  bool _isLoading = true;
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      final sales = await _storageService.getPublicSalesByDate(_selectedDate);
      setState(() {
        _publicSales = sales;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load sales: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_selectedDate),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateFormat('yyyy-MM-dd').format(picked);
      });
      _loadSales();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Public Sales'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _publicSales.length,
              itemBuilder: (context, index) {
                final sale = _publicSales[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(sale.customerName ?? 'Walk-in Customer'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Time: ${sale.saleTime ?? "N/A"}'),
                        Text('Total: ${sale.totalPrice}'),
                        Text('Payment: ${sale.paymentMethod}'),
                      ],
                    ),
                    trailing: Text(
                      sale.syncStatus == 'pending' ? '🔄' : '✓',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPublicSale(saleDate: _selectedDate),
            ),
          );
          if (result == true) {
            _loadSales();
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}