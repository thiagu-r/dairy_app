import 'package:flutter/material.dart';
import '../../models/loading_order.dart';

class ReturnOrderCard extends StatelessWidget {
  final Map<int, double> availableExtras;
  final List<LoadingOrderItem> loadingOrderItems;

  ReturnOrderCard({
    required this.availableExtras,
    required this.loadingOrderItems,
  });

  List<LoadingOrderItem> _getReturnItems() {
    return loadingOrderItems.where((item) {
      final availableQuantity = availableExtras[item.product] ?? 0;
      return availableQuantity > 0;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final returnItems = _getReturnItems();

    if (returnItems.isEmpty) {
      return Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No items to return'),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Return Order Items',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Product')),
                    DataColumn(label: Text('Return Qty')),
                    DataColumn(label: Text('Unit Price')),
                    DataColumn(label: Text('Total')),
                  ],
                  rows: returnItems.map((item) {
                    final returnQty = availableExtras[item.product] ?? 0;
                    final unitPrice = double.tryParse(item.unitPrice ?? '0') ?? 0;
                    final totalPrice = returnQty * unitPrice;

                    return DataRow(
                      cells: [
                        DataCell(Text(item.productName)),
                        DataCell(Text(returnQty.toStringAsFixed(3))),
                        DataCell(Text('₹${unitPrice.toStringAsFixed(2)}')),
                        DataCell(Text('₹${totalPrice.toStringAsFixed(2)}')),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Total Return Value: ₹${_calculateTotalReturnValue(returnItems).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotalReturnValue(List<LoadingOrderItem> returnItems) {
    return returnItems.fold(0, (total, item) {
      final returnQty = availableExtras[item.product] ?? 0;
      final unitPrice = double.tryParse(item.unitPrice ?? '0') ?? 0;
      return total + (returnQty * unitPrice);
    });
  }
}