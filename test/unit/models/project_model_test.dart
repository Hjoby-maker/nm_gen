// test/unit/models/project_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nm_gen/data/datasources/local/database/project_model.dart';
import 'package:nm_gen/domain/entities/project.dart';

void main() {
  group('ProjectModel', () {
    final now = DateTime.now();
    // Округляем время до миллисекунд, чтобы избежать проблем с микросекундами
    final roundedNow = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
      now.millisecond,
    );
    const projectId = 'project_1';
    const projectName = 'Мое древо';
    const projectDescription = 'Основное древо';

    test('fromDomain конвертирует Project в ProjectModel', () {
      // Arrange
      final project = Project(
        id: projectId,
        name: projectName,
        description: projectDescription,
        createdAt: roundedNow,
        updatedAt: roundedNow,
        personCount: 5,
        familyCount: 2,
        isDefault: true,
      );

      // Act
      final model = ProjectModel.fromDomain(project);

      // Assert
      expect(model.id, projectId);
      expect(model.name, projectName);
      expect(model.description, projectDescription);
      expect(model.createdAt, roundedNow.millisecondsSinceEpoch);
      expect(model.updatedAt, roundedNow.millisecondsSinceEpoch);
      expect(model.isDefault, true);
    });

    test('fromMap создает ProjectModel из Map (SQLite)', () {
      // Arrange
      final map = {
        'id': projectId,
        'name': projectName,
        'description': projectDescription,
        'created_at': roundedNow.millisecondsSinceEpoch,
        'updated_at': roundedNow.millisecondsSinceEpoch,
        'is_default': 1,
      };

      // Act
      final model = ProjectModel.fromMap(map);

      // Assert
      expect(model.id, projectId);
      expect(model.name, projectName);
      expect(model.description, projectDescription);
      expect(model.createdAt, roundedNow.millisecondsSinceEpoch);
      expect(model.updatedAt, roundedNow.millisecondsSinceEpoch);
      expect(model.isDefault, true);
    });

    test('toMap конвертирует ProjectModel в Map для SQLite', () {
      // Arrange
      final model = ProjectModel(
        id: projectId,
        name: projectName,
        description: projectDescription,
        createdAt: roundedNow.millisecondsSinceEpoch,
        updatedAt: roundedNow.millisecondsSinceEpoch,
        isDefault: true,
      );

      // Act
      final map = model.toMap();

      // Assert
      expect(map['id'], projectId);
      expect(map['name'], projectName);
      expect(map['description'], projectDescription);
      expect(map['created_at'], roundedNow.millisecondsSinceEpoch);
      expect(map['updated_at'], roundedNow.millisecondsSinceEpoch);
      expect(map['is_default'], 1);
    });

    test('toDomain конвертирует ProjectModel в Project', () {
      // Arrange
      final model = ProjectModel(
        id: projectId,
        name: projectName,
        description: projectDescription,
        createdAt: roundedNow.millisecondsSinceEpoch,
        updatedAt: roundedNow.millisecondsSinceEpoch,
        isDefault: true,
      );

      // Act
      final project = model.toDomain(personCount: 5, familyCount: 2);

      // Assert
      expect(project.id, projectId);
      expect(project.name, projectName);
      expect(project.description, projectDescription);
      // Сравниваем только год/месяц/день/час/минуту/секунду (без микросекунд)
      expect(project.createdAt?.year, roundedNow.year);
      expect(project.createdAt?.month, roundedNow.month);
      expect(project.createdAt?.day, roundedNow.day);
      expect(project.createdAt?.hour, roundedNow.hour);
      expect(project.createdAt?.minute, roundedNow.minute);
      expect(project.createdAt?.second, roundedNow.second);
      expect(project.updatedAt?.year, roundedNow.year);
      expect(project.updatedAt?.month, roundedNow.month);
      expect(project.updatedAt?.day, roundedNow.day);
      expect(project.updatedAt?.hour, roundedNow.hour);
      expect(project.updatedAt?.minute, roundedNow.minute);
      expect(project.updatedAt?.second, roundedNow.second);
      expect(project.personCount, 5);
      expect(project.familyCount, 2);
      expect(project.isDefault, true);
    });

    test('toDomain обрабатывает null даты', () {
      // Arrange
      final model = ProjectModel(
        id: projectId,
        name: projectName,
        description: projectDescription,
        createdAt: null,
        updatedAt: null,
        isDefault: false,
      );

      // Act
      final project = model.toDomain();

      // Assert
      expect(project.createdAt, null);
      expect(project.updatedAt, null);
    });

    test('fromMap обрабатывает is_default как 0', () {
      // Arrange
      final map = {
        'id': projectId,
        'name': projectName,
        'description': projectDescription,
        'created_at': roundedNow.millisecondsSinceEpoch,
        'updated_at': roundedNow.millisecondsSinceEpoch,
        'is_default': 0,
      };

      // Act
      final model = ProjectModel.fromMap(map);

      // Assert
      expect(model.isDefault, false);
    });

    test('fromMap обрабатывает is_default как 1', () {
      // Arrange
      final map = {
        'id': projectId,
        'name': projectName,
        'description': projectDescription,
        'created_at': roundedNow.millisecondsSinceEpoch,
        'updated_at': roundedNow.millisecondsSinceEpoch,
        'is_default': 1,
      };

      // Act
      final model = ProjectModel.fromMap(map);

      // Assert
      expect(model.isDefault, true);
    });
  });
}
