import 'package:hive/hive.dart';

part 'route.g.dart';

@HiveType(typeId: 9)
class Route extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  Route({
    required this.id,
    required this.name,
    this.description,
  });

  @override
  String toString() => name;
}
