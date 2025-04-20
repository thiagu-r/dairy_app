import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 17)
enum ExpenseType {
  @HiveField(0)
  fuel,
  @HiveField(1)
  maintenance,
  @HiveField(2)
  repairs,
  @HiveField(3)
  food,
  @HiveField(4)
  other
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
      'expense_type': expenseType.toString().split('.').last,
      'local_id': localId,
    };
  }
}
