import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 8)
class Expense extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String date;

  @HiveField(2)
  final String expenseType;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final String? description;

  @HiveField(5)
  final int route;

  Expense({
    required this.id,
    required this.date,
    required this.expenseType,
    required this.amount,
    this.description,
    required this.route,
  });
}

enum ExpenseType {
  fuel,
  repair,
  food,
  dailyAllowance,
  other,
}
