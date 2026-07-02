import 'package:nm_gen/domain/entities/project.dart';

/// Модель Project для SQLite
class ProjectModel {
  ProjectModel({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.isDefault = false,
  });

  /// Конвертация из Domain Entity
  factory ProjectModel.fromDomain(Project project) {
    return ProjectModel(
      id: project.id,
      name: project.name,
      description: project.description,
      createdAt: project.createdAt?.millisecondsSinceEpoch,
      updatedAt: project.updatedAt?.millisecondsSinceEpoch,
      isDefault: project.isDefault,
    );
  }

  /// Создание из Map (для SQLite)
  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: map['created_at'] as int?,
      updatedAt: map['updated_at'] as int?,
      isDefault: map['is_default'] == 1,
    );
  }

  final String id;
  final String name;
  final String? description;
  final int? createdAt;
  final int? updatedAt;
  final bool isDefault;

  /// Конвертация в Domain Entity
  Project toDomain({int personCount = 0, int familyCount = 0}) {
    return Project(
      id: id,
      name: name,
      description: description,
      createdAt: createdAt != null
          ? DateTime.fromMillisecondsSinceEpoch(createdAt!)
          : null,
      updatedAt: updatedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(updatedAt!)
          : null,
      personCount: personCount,
      familyCount: familyCount,
      isDefault: isDefault,
    );
  }

  /// Конвертация в Map (для SQLite)
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_default': isDefault ? 1 : 0,
    };
  }
}
