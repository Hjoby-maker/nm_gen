// test/unit/models/event_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nm_gen/domain/entities/event.dart';

void main() {
  group('Event сущность', () {
    // ============================================================
    // 1. ТЕСТЫ КОНСТРУКТОРА И СОЗДАНИЯ
    // ============================================================

    group('Создание Event', () {
      test('создает Event с корректными данными через конструктор', () {
        // Arrange
        final now = DateTime.now();
        const id = 'event_1';
        const personId = 'person_1';
        const treeId = 'tree_1';
        const type = EventType.birth;
        const title = 'Рождение Ивана';
        const description = 'Родился в Москве';
        final startDate = DateTime(1980, 1, 1);
        final endDate = DateTime(1980, 1, 2);
        const place = 'Москва';
        const notes = 'Родился в роддоме №1';

        // Act
        final event = Event(
          id: id,
          personId: personId,
          treeId: treeId,
          type: type,
          title: title,
          description: description,
          startDate: startDate,
          endDate: endDate,
          place: place,
          notes: notes,
          createdAt: now,
          updatedAt: now,
        );

        // Assert
        expect(event.id, id);
        expect(event.personId, personId);
        expect(event.treeId, treeId);
        expect(event.type, type);
        expect(event.title, title);
        expect(event.description, description);
        expect(event.startDate, startDate);
        expect(event.endDate, endDate);
        expect(event.place, place);
        expect(event.notes, notes);
        expect(event.createdAt, now);
        expect(event.updatedAt, now);
      });

      test('Event.create создает событие с автоматической генерацией ID', () {
        // Act
        final event = Event.create(
          personId: 'person_1',
          treeId: 'tree_1',
          type: EventType.education,
          title: 'Окончание университета',
          description: 'МГТУ им. Баумана',
          startDate: DateTime(2002, 6, 30),
          place: 'Москва',
        );

        // Assert
        expect(event.id.isNotEmpty, true);
        expect(event.personId, 'person_1');
        expect(event.treeId, 'tree_1');
        expect(event.type, EventType.education);
        expect(event.title, 'Окончание университета');
        expect(event.description, 'МГТУ им. Баумана');
        expect(event.startDate, DateTime(2002, 6, 30));
        expect(event.endDate, null);
        expect(event.place, 'Москва');
        expect(event.notes, null);
        expect(event.createdAt, isNotNull);
        expect(event.updatedAt, isNotNull);
      });

      test('Event.create создает событие с опциональными полями', () {
        // Act
        final event = Event.create(
          personId: 'person_1',
          treeId: 'tree_1',
          type: EventType.other,
          title: 'Тестовое событие',
        );

        // Assert
        expect(event.title, 'Тестовое событие');
        expect(event.description, null);
        expect(event.startDate, null);
        expect(event.endDate, null);
        expect(event.place, null);
        expect(event.notes, null);
      });
    });

    // ============================================================
    // 2. ТЕСТЫ ГЕТТЕРОВ
    // ============================================================

    group('Геттеры Event', () {
      test('mediaDirectoryName возвращает правильное имя директории', () {
        // Arrange
        final event = Event.create(
          personId: 'person_1',
          treeId: 'tree_1',
          type: EventType.birth,
          title: 'Тест',
        );

        // Assert
        expect(event.mediaDirectoryName, 'event_${event.id}');
      });

      test(
        'hasAttachments возвращает false (будет обновляться из репозитория)',
        () {
          // Arrange
          final event = Event.create(
            personId: 'person_1',
            treeId: 'tree_1',
            type: EventType.birth,
            title: 'Тест',
          );

          // Assert
          expect(event.hasAttachments, false);
        },
      );

      test('canAddMedia возвращает true если id не пустой', () {
        // Arrange
        final event = Event.create(
          personId: 'person_1',
          treeId: 'tree_1',
          type: EventType.birth,
          title: 'Тест',
        );

        // Assert
        expect(event.canAddMedia, true);
      });

      test('displayTitle возвращает название с датой', () {
        // Arrange
        final event = Event.create(
          personId: 'person_1',
          treeId: 'tree_1',
          type: EventType.birth,
          title: 'Рождение Ивана',
          startDate: DateTime(1980, 1, 1),
        );

        // Assert
        expect(
          event.displayTitle,
          'EventType.birth: Рождение Ивана (1 янв 1980)',
        );
      });

      test('displayTitle возвращает название без даты', () {
        // Arrange
        final event = Event.create(
          personId: 'person_1',
          treeId: 'tree_1',
          type: EventType.birth,
          title: 'Рождение Ивана',
        );

        // Assert
        expect(event.displayTitle, 'EventType.birth: Рождение Ивана');
      });

      test('shortDescription возвращает место и дату', () {
        // Arrange
        final event = Event.create(
          personId: 'person_1',
          treeId: 'tree_1',
          type: EventType.birth,
          title: 'Рождение Ивана',
          startDate: DateTime(1980, 1, 1),
          place: 'Москва',
        );

        // Assert
        expect(event.shortDescription, 'Москва, 1 янв 1980');
      });

      test('shortDescription возвращает только место', () {
        // Arrange
        final event = Event.create(
          personId: 'person_1',
          treeId: 'tree_1',
          type: EventType.birth,
          title: 'Рождение Ивана',
          place: 'Москва',
        );

        // Assert
        expect(event.shortDescription, 'Москва');
      });

      test('shortDescription возвращает только дату', () {
        // Arrange
        final event = Event.create(
          personId: 'person_1',
          treeId: 'tree_1',
          type: EventType.birth,
          title: 'Рождение Ивана',
          startDate: DateTime(1980, 1, 1),
        );

        // Assert
        expect(event.shortDescription, '1 янв 1980');
      });

      test('shortDescription возвращает сообщение если нет данных', () {
        // Arrange
        final event = Event.create(
          personId: 'person_1',
          treeId: 'tree_1',
          type: EventType.birth,
          title: 'Рождение Ивана',
        );

        // Assert
        expect(event.shortDescription, 'Нет дополнительной информации');
      });

      test('colorHex возвращает цвет для типа события', () {
        expect(
          Event.create(
            type: EventType.birth,
            personId: 'p1',
            treeId: 't1',
            title: 't',
          ).colorHex,
          '#4CAF50',
        );
        expect(
          Event.create(
            type: EventType.death,
            personId: 'p1',
            treeId: 't1',
            title: 't',
          ).colorHex,
          '#F44336',
        );
        expect(
          Event.create(
            type: EventType.baptism,
            personId: 'p1',
            treeId: 't1',
            title: 't',
          ).colorHex,
          '#2196F3',
        );
        expect(
          Event.create(
            type: EventType.burial,
            personId: 'p1',
            treeId: 't1',
            title: 't',
          ).colorHex,
          '#9E9E9E',
        );
        expect(
          Event.create(
            type: EventType.education,
            personId: 'p1',
            treeId: 't1',
            title: 't',
          ).colorHex,
          '#FF9800',
        );
        expect(
          Event.create(
            type: EventType.occupation,
            personId: 'p1',
            treeId: 't1',
            title: 't',
          ).colorHex,
          '#795548',
        );
        expect(
          Event.create(
            type: EventType.relocation,
            personId: 'p1',
            treeId: 't1',
            title: 't',
          ).colorHex,
          '#9C27B0',
        );
        expect(
          Event.create(
            type: EventType.other,
            personId: 'p1',
            treeId: 't1',
            title: 't',
          ).colorHex,
          '#607D8B',
        );
      });
    });

    // ============================================================
    // 3. ТЕСТЫ COPYWITH
    // ============================================================

    group('copyWith', () {
      test('копирует Event с изменением полей', () {
        // Arrange
        final original = Event.create(
          personId: 'person_1',
          treeId: 'tree_1',
          type: EventType.birth,
          title: 'Старое название',
          description: 'Старое описание',
          startDate: DateTime(1980, 1, 1),
          place: 'Москва',
        );
        final newUpdatedAt = DateTime.now().add(
          const Duration(milliseconds: 100),
        );

        // Act
        final updated = original.copyWith(
          title: 'Новое название',
          description: 'Новое описание',
          startDate: DateTime(1990, 2, 2),
          place: 'Санкт-Петербург',
          type: EventType.education,
          updatedAt: newUpdatedAt,
        );

        // Assert
        expect(updated.id, original.id);
        expect(updated.personId, original.personId);
        expect(updated.treeId, original.treeId);
        expect(updated.title, 'Новое название');
        expect(updated.description, 'Новое описание');
        expect(updated.startDate, DateTime(1990, 2, 2));
        expect(updated.place, 'Санкт-Петербург');
        expect(updated.type, EventType.education);
        expect(updated.createdAt, original.createdAt);
        expect(updated.updatedAt, newUpdatedAt);
        expect(
          updated.updatedAt?.isAfter(original.updatedAt ?? DateTime.now()),
          true,
        );
      });

      test(
        'copyWith сохраняет неизмененные поля (updatedAt остается прежним)',
        () {
          // Arrange
          final original = Event.create(
            personId: 'person_1',
            treeId: 'tree_1',
            type: EventType.birth,
            title: 'Тест',
            startDate: DateTime(1980, 1, 1),
          );

          // Act
          final updated = original.copyWith(title: 'Новое название');

          // Assert
          expect(updated.personId, original.personId);
          expect(updated.type, original.type);
          expect(updated.startDate, original.startDate);
          expect(updated.createdAt, original.createdAt);
          expect(updated.updatedAt, original.updatedAt);
        },
      );

      test('copyWith позволяет явно задать updatedAt', () {
        // Arrange
        final original = Event.create(
          personId: 'person_1',
          treeId: 'tree_1',
          type: EventType.birth,
          title: 'Тест',
        );
        final fixedDate = DateTime(2020, 1, 1);

        // Act
        final updated = original.copyWith(
          title: 'Новое название',
          updatedAt: fixedDate,
        );

        // Assert
        expect(updated.updatedAt, fixedDate);
      });
    });

    // ============================================================
    // 4. ТЕСТЫ EQUATABLE
    // ============================================================

    group('Equatable', () {
      test('два одинаковых Event равны', () {
        // Arrange
        final now = DateTime.now();
        final event1 = Event(
          id: 'e1',
          personId: 'p1',
          treeId: 't1',
          type: EventType.birth,
          title: 'Тест',
          createdAt: now,
          updatedAt: now,
        );
        final event2 = Event(
          id: 'e1',
          personId: 'p1',
          treeId: 't1',
          type: EventType.birth,
          title: 'Тест',
          createdAt: now,
          updatedAt: now,
        );

        // Assert
        expect(event1 == event2, true);
        expect(event1.hashCode, event2.hashCode);
      });

      test('два разных Event не равны', () {
        // Arrange
        final now = DateTime.now();
        final event1 = Event(
          id: 'e1',
          personId: 'p1',
          treeId: 't1',
          type: EventType.birth,
          title: 'Тест 1',
          createdAt: now,
          updatedAt: now,
        );
        final event2 = Event(
          id: 'e2',
          personId: 'p1',
          treeId: 't1',
          type: EventType.death,
          title: 'Тест 2',
          createdAt: now,
          updatedAt: now,
        );

        // Assert
        expect(event1 == event2, false);
        expect(event1.hashCode, isNot(event2.hashCode));
      });

      test('Event сравнивается по всем полям из props', () {
        // Arrange
        final event = Event.create(
          personId: 'p1',
          treeId: 't1',
          type: EventType.birth,
          title: 'Тест',
        );

        // Assert
        expect(event.props.length, 12);
      });
    });

    // ============================================================
    // 5. ТЕСТЫ TOSTRING
    // ============================================================

    test('toString возвращает тип и название', () {
      // Arrange
      final event = Event.create(
        personId: 'p1',
        treeId: 't1',
        type: EventType.birth,
        title: 'Рождение Ивана',
      );

      // Assert
      expect(event.toString(), 'EventType.birth: Рождение Ивана');
    });
  });
}
