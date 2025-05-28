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
  final int coin1;

  @HiveField(8)
  final int coin2;

  @HiveField(9)
  final int coin5;

  @HiveField(10)
  final double totalCashCollected;

  @HiveField(11)
  final double totalExpenses;

  @HiveField(12)
  final double denominationTotal;

  @HiveField(13)
  final double difference;

  @HiveField(14)
  final String localId;

  @HiveField(15)
  String syncStatus;

  Denomination({
    required this.date,
    required this.note500,
    required this.note200,
    required this.note100,
    required this.note50,
    required this.note20,
    required this.note10,
    required this.coin1,
    required this.coin2,
    required this.coin5,
    required this.totalCashCollected,
    required this.totalExpenses,
    required this.denominationTotal,
    required this.difference,
    String? localId,
    this.syncStatus = 'pending',
  }) : this.localId = localId ?? 'mobile-den-${DateTime.now().millisecondsSinceEpoch}';

  List<Map<String, dynamic>> toJson() {
    return [
      {
        'id': null,
        'denomination': 500,
        'count': note500,
        'total_amount': (500 * note500).toStringAsFixed(2),
        'local_id': '${localId}-500',
      },
      {
        'id': null,
        'denomination': 200,
        'count': note200,
        'total_amount': (200 * note200).toStringAsFixed(2),
        'local_id': '${localId}-200',
      },
      {
        'id': null,
        'denomination': 100,
        'count': note100,
        'total_amount': (100 * note100).toStringAsFixed(2),
        'local_id': '${localId}-100',
      },
      {
        'id': null,
        'denomination': 50,
        'count': note50,
        'total_amount': (50 * note50).toStringAsFixed(2),
        'local_id': '${localId}-50',
      },
      {
        'id': null,
        'denomination': 20,
        'count': note20,
        'total_amount': (20 * note20).toStringAsFixed(2),
        'local_id': '${localId}-20',
      },
      {
        'id': null,
        'denomination': 10,
        'count': note10,
        'total_amount': (10 * note10).toStringAsFixed(2),
        'local_id': '${localId}-10',
      },
      {
        'id': null,
        'denomination': 5,
        'count': coin5,
        'total_amount': (5 * coin5).toStringAsFixed(2),
        'local_id': '${localId}-5',
      },
      {
        'id': null,
        'denomination': 2,
        'count': coin2,
        'total_amount': (2 * coin2).toStringAsFixed(2),
        'local_id': '${localId}-2',
      },
      {
        'id': null,
        'denomination': 1,
        'count': coin1,
        'total_amount': (1 * coin1).toStringAsFixed(2),
        'local_id': '${localId}-1',
      },
    ];
  }
}
