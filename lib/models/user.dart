// lib/models/user.dart

import 'package:hive/hive.dart';

part 'user.g.dart'; // This will be generated with 'flutter pub run build_runner build'

@HiveType(typeId: 0)
class User {
  @HiveField(0)
  final int id;
  
  @HiveField(1)
  final String username;
  
  @HiveField(2)
  final String email;
  
  @HiveField(3)
  final String firstName;
  
  @HiveField(4)
  final String lastName;
  
  @HiveField(5)
  final String role;
  
  @HiveField(6)
  final DateTime lastLogin;
  
  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.lastLogin,
  });
  
  String get fullName => '$firstName $lastName';
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: json['role'] ?? '',
      lastLogin: DateTime.now(), // Since it's not in the response, we'll use current time
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'lastLogin': lastLogin.toIso8601String(),
    };
  }
}
