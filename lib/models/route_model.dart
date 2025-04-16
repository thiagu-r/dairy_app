// lib/models/route_model.dart

class RouteModel {
  final int id;
  final String name;
  final String code;
  
  RouteModel({
    required this.id,
    required this.name,
    required this.code,
  });
  
  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'],
      name: json['name'],
      code: json['code'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
    };
  }

  @override
  String toString() => '$name ($code)';
}
