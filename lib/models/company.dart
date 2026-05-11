import 'package:uuid/uuid.dart';

class Company {
  final String id;
  final String name;
  final DateTime createdAt;

  Company({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory Company.create({required String name}) {
    return Company(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now(),
    );
  }

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
