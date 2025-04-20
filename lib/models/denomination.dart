import 'package:hive/hive.dart';

part 'denomination.g.dart';

@HiveType(typeId: 11)
class Denomination extends HiveObject {
  @HiveField(0)
  final String date;

  @HiveField(1)
  final int note500;

  @HiveField(2)
  final int note200;

  @HiveField(3)
  final int note100;

  @HiveField(4)
  final int note50;

  @HiveField(5)
  final int note20;

  @HiveField(6)
  final int note10;

  @HiveField(7)
  final double coins;

  @HiveField(8)
  final double totalCashCollected;

  @HiveField(9)
  final double totalExpenses;

  @HiveField(10)
  final double denominationTotal;

  @HiveField(11)
  final double difference;

  @HiveField(12)
  final String localId;

  @HiveField(13)
  String syncStatus;

  Denomination({
    required this.date,
    required this.note500,
    required this.note200,
    required this.note100,
    required this.note50,
    required this.note20,
    required this.note10,
    required this.coins,
    required this.totalCashCollected,
    required this.totalExpenses,
    required this.denominationTotal,
    required this.difference,
    String? localId,
    this.syncStatus = 'pending',
  }) : this.localId = localId ?? 'mobile-den-${DateTime.now().millisecondsSinceEpoch}';

  List<Map<String, dynamic>> toJson() {
    List<Map<String, dynamic>> denominations = [];
    
    if (note500 > 0) {
      denominations.add({
        'id': null,
        'denomination': 500,
        'count': note500,
        'total_amount': (500 * note500).toStringAsFixed(2),
        'local_id': '${localId}-500',
      });
    }
    // Add similar blocks for other denominations
    if (note200 > 0) {
      denominations.add({
        'id': null,
        'denomination': 200,
        'count': note200,
        'total_amount': (200 * note200).toStringAsFixed(2),
        'local_id': '${localId}-200',
      });
    }
    // Continue for other denominations...

    return denominations;
  }
}
