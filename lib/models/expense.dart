import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 17)
enum ExpenseType {
  @HiveField(0)
  food, // Food/Snacks
  @HiveField(1)
  vehicle, // Vehicle Repair/Maintenance
  @HiveField(2)
  fuel, // Fuel
  @HiveField(3)
  other, // Other Expenses
  @HiveField(4)
  allowance, // Daily Allowance
}

@HiveType(typeId: 16)
class Expense extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String date;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  String syncStatus;

  @HiveField(5)
  final String localId;

  @HiveField(6)
  final int route;

  @HiveField(7)
  final ExpenseType expenseType;

  Expense({
    required this.id,
    required this.date,
    this.description,
    required this.amount,
    required this.route,
    required this.expenseType,
    this.syncStatus = 'pending',
    String? localId,
  }) : this.localId = localId ?? 'mobile-exp-${DateTime.now().millisecondsSinceEpoch}';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'description': description,
      'amount': amount,
      'route': route,
      'expense_type': expenseType.toString().split('.').last,  // Convert enum to string format expected by API
      'sync_status': syncStatus,
      'local_id': localId,
    };
  }
}
