import 'package:equatable/equatable.dart';

/// Сущность проекта (генеалогического древа)
class Project extends Equatable {
  const Project({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.personCount = 0,
    this.familyCount = 0,
    this.isDefault = false,
  });

  /// Создать новый проект
  factory Project.create({
    required String name,
    String? description,
    bool isDefault = false,
  }) {
    final DateTime now = DateTime.now();
    return Project(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      createdAt: now,
      updatedAt: now,
      isDefault: isDefault,
    );
  }

  final String id;
  final String name;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int personCount;
  final int familyCount;
  final bool isDefault;

  Project copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? personCount,
    int? familyCount,
    bool? isDefault,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      personCount: personCount ?? this.personCount,
      familyCount: familyCount ?? this.familyCount,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    description,
    createdAt,
    updatedAt,
    personCount,
    familyCount,
    isDefault,
  ];

  /// Пустой проект
  static Project empty() => const Project(id: '', name: '', isDefault: false);

  @override
  String toString() => name;
}
