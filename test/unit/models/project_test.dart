// test/unit/models/project_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nm_gen/domain/entities/project.dart';

void main() {
  group('Project сущность', () {
    // ============================================================
    // 1. ТЕСТЫ КОНСТРУКТОРА И СОЗДАНИЯ
    // ============================================================

    group('Создание Project', () {
      test('создает Project с корректными данными через конструктор', () {
        // Arrange
        final now = DateTime.now();
        const id = 'project_1';
        const name = 'Мое древо';
        const description = 'Основное генеалогическое древо';
        const personCount = 5;
        const familyCount = 2;
        const isDefault = true;

        // Act
        final project = Project(
          id: id,
          name: name,
          description: description,
          createdAt: now,
          updatedAt: now,
          personCount: personCount,
          familyCount: familyCount,
          isDefault: isDefault,
        );

        // Assert
        expect(project.id, id);
        expect(project.name, name);
        expect(project.description, description);
        expect(project.createdAt, now);
        expect(project.updatedAt, now);
        expect(project.personCount, personCount);
        expect(project.familyCount, familyCount);
        expect(project.isDefault, isDefault);
      });

      test('Project.create создает проект с автоматической генерацией ID', () {
        // Act
        final project = Project.create(
          name: 'Новое древо',
          description: 'Тестовое древо',
          isDefault: false,
        );

        // Assert
        expect(project.id.isNotEmpty, true);
        expect(project.name, 'Новое древо');
        expect(project.description, 'Тестовое древо');
        expect(project.isDefault, false);
        expect(project.createdAt, isNotNull);
        expect(project.updatedAt, isNotNull);
        expect(project.personCount, 0);
        expect(project.familyCount, 0);
      });

      test('Project.create создает проект с isDefault по умолчанию false', () {
        // Act
        final project = Project.create(name: 'Обычное древо');

        // Assert
        expect(project.isDefault, false);
      });

      test('Project.empty создает пустой проект', () {
        // Act
        final project = Project.empty();

        // Assert
        expect(project.id, '');
        expect(project.name, '');
        expect(project.description, null);
        expect(project.createdAt, null);
        expect(project.updatedAt, null);
        expect(project.personCount, 0);
        expect(project.familyCount, 0);
        expect(project.isDefault, false);
      });
    });

    // ============================================================
    // 2. ТЕСТЫ COPYWITH
    // ============================================================

    group('copyWith', () {
      test('копирует Project с изменением полей', () {
        // Arrange
        final original = Project.create(
          name: 'Старое имя',
          description: 'Старое описание',
        );
        final newDate = DateTime.now();

        // Act
        final updated = original.copyWith(
          name: 'Новое имя',
          description: 'Новое описание',
          personCount: 10,
          familyCount: 3,
          isDefault: true,
          updatedAt: newDate,
        );

        // Assert
        expect(updated.id, original.id);
        expect(updated.name, 'Новое имя');
        expect(updated.description, 'Новое описание');
        expect(updated.personCount, 10);
        expect(updated.familyCount, 3);
        expect(updated.isDefault, true);
        expect(updated.updatedAt, newDate);
        expect(updated.createdAt, original.createdAt);
      });

      test('copyWith сохраняет неизмененные поля', () {
        // Arrange
        final original = Project.create(
          name: 'Мое древо',
          description: 'Описание',
        );

        // Act
        final updated = original.copyWith(name: 'Новое древо');

        // Assert
        expect(updated.description, original.description);
        expect(updated.personCount, original.personCount);
        expect(updated.familyCount, original.familyCount);
        expect(updated.isDefault, original.isDefault);
        expect(updated.createdAt, original.createdAt);
        expect(updated.id, original.id);
      });
    });

    // ============================================================
    // 3. ТЕСТЫ EQUATABLE
    // ============================================================

    group('Equatable', () {
      test('два одинаковых Project равны', () {
        // Arrange
        final now = DateTime.now();
        final project1 = Project(
          id: 'p1',
          name: 'Древо',
          description: 'Описание',
          createdAt: now,
          updatedAt: now,
          personCount: 5,
          familyCount: 2,
          isDefault: true,
        );
        final project2 = Project(
          id: 'p1',
          name: 'Древо',
          description: 'Описание',
          createdAt: now,
          updatedAt: now,
          personCount: 5,
          familyCount: 2,
          isDefault: true,
        );

        // Assert
        expect(project1 == project2, true);
        expect(project1.hashCode, project2.hashCode);
      });

      test('два разных Project не равны', () {
        // Arrange
        final now = DateTime.now();
        final project1 = Project(
          id: 'p1',
          name: 'Древо 1',
          description: 'Описание 1',
          createdAt: now,
          updatedAt: now,
          personCount: 5,
          familyCount: 2,
          isDefault: true,
        );
        final project2 = Project(
          id: 'p2',
          name: 'Древо 2',
          description: 'Описание 2',
          createdAt: now,
          updatedAt: now,
          personCount: 3,
          familyCount: 1,
          isDefault: false,
        );

        // Assert
        expect(project1 == project2, false);
        expect(project1.hashCode, isNot(project2.hashCode));
      });

      test('Project сравнивается по всем полям из props', () {
        // Arrange
        final project = Project.create(name: 'Древо');

        // Assert
        expect(project.props.length, 8); // Количество полей в props
      });
    });

    // ============================================================
    // 4. ТЕСТЫ TOSTRING
    // ============================================================

    group('toString', () {
      test('возвращает имя проекта', () {
        // Arrange
        final project = Project.create(name: 'Мое древо');

        // Assert
        expect(project.toString(), 'Мое древо');
      });
    });
  });
}
