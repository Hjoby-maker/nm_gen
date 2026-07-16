// test/unit/models/person_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/domain/entities/person.dart';

void main() {
  group('Person сущность', () {
    // ============================================================
    // 1. ТЕСТЫ КОНСТРУКТОРА И СОЗДАНИЯ
    // ============================================================

    group('Создание Person', () {
      test('создает Person с корректными данными через конструктор', () {
        // Arrange
        final now = DateTime.now();
        const id = 'test_id';
        const treeId = 'tree_1';
        const firstName = 'Иван';
        const lastName = 'Иванов';
        const middleName = 'Петрович';
        const gender = Gender.male;
        final birthDate = DateTime(1980, 1, 1);
        final deathDate = DateTime(2050, 1, 1);
        const birthPlace = 'Москва';
        const deathPlace = 'Санкт-Петербург';
        const occupation = 'Инженер';
        const biography = 'Тестовая биография';
        const photoUrls = ['url1', 'url2'];
        const photoPath = '/path/to/photo.jpg';

        // Act
        final person = Person(
          id: id,
          treeId: treeId,
          firstName: firstName,
          lastName: lastName,
          middleName: middleName,
          gender: gender,
          birthDate: birthDate,
          deathDate: deathDate,
          birthPlace: birthPlace,
          deathPlace: deathPlace,
          occupation: occupation,
          biography: biography,
          photoUrls: photoUrls,
          photoPath: photoPath,
          createdAt: now,
          updatedAt: now,
        );

        // Assert
        expect(person.id, id);
        expect(person.treeId, treeId);
        expect(person.firstName, firstName);
        expect(person.lastName, lastName);
        expect(person.middleName, middleName);
        expect(person.gender, gender);
        expect(person.birthDate, birthDate);
        expect(person.deathDate, deathDate);
        expect(person.birthPlace, birthPlace);
        expect(person.deathPlace, deathPlace);
        expect(person.occupation, occupation);
        expect(person.biography, biography);
        expect(person.photoUrls, photoUrls);
        expect(person.photoPath, photoPath);
        expect(person.createdAt, now);
        expect(person.updatedAt, now);
      });

      test('Person.create создает человека с автоматической генерацией ID', () {
        // Act
        final person = Person.create(
          firstName: 'Анна',
          lastName: 'Петрова',
          middleName: 'Сергеевна',
          gender: Gender.female,
          treeId: 'tree_1',
          birthDate: DateTime(1990, 5, 15),
          birthPlace: 'Москва',
          occupation: 'Врач',
        );

        // Assert
        expect(person.id.isNotEmpty, true);
        expect(person.treeId, 'tree_1');
        expect(person.firstName, 'Анна');
        expect(person.lastName, 'Петрова');
        expect(person.middleName, 'Сергеевна');
        expect(person.gender, Gender.female);
        expect(person.birthDate, DateTime(1990, 5, 15));
        expect(person.birthPlace, 'Москва');
        expect(person.occupation, 'Врач');
        expect(person.createdAt, isNotNull);
        expect(person.updatedAt, isNotNull);
      });

      test('Person.create использует treeId по умолчанию "default"', () {
        // Act
        final person = Person.create(
          firstName: 'Тест',
          lastName: 'Тестов',
          gender: Gender.male,
        );

        // Assert
        expect(person.treeId, 'default');
      });

      test('Person.empty создает пустого человека', () {
        // Act
        final person = Person.empty();

        // Assert
        expect(person.id, '');
        expect(person.treeId, '');
        expect(person.firstName, '');
        expect(person.lastName, '');
        expect(person.middleName, null);
        expect(person.gender, Gender.unknown);
        expect(person.birthDate, null);
        expect(person.deathDate, null);
        expect(person.birthPlace, null);
        expect(person.deathPlace, null);
        expect(person.occupation, null);
        expect(person.biography, null);
        expect(person.photoUrls, isEmpty);
        expect(person.photoPath, null);
      });
    });

    // ============================================================
    // 2. ТЕСТЫ ГЕТТЕРОВ
    // ============================================================

    group('Геттеры Person', () {
      group('fullName', () {
        test('возвращает полное имя (Фамилия Имя Отчество)', () {
          // Arrange
          final person = Person.create(
            firstName: 'Иван',
            lastName: 'Иванов',
            middleName: 'Петрович',
            gender: Gender.male,
          );

          // Assert
          expect(person.fullName, 'Иванов Иван Петрович');
        });

        test('возвращает имя без отчества, если middleName отсутствует', () {
          // Arrange
          final person = Person.create(
            firstName: 'Иван',
            lastName: 'Иванов',
            gender: Gender.male,
          );

          // Assert
          expect(person.fullName, 'Иванов Иван');
        });

        test(
          'возвращает только имя и фамилию, если отчество пустая строка',
          () {
            // Arrange
            final person = Person.create(
              firstName: 'Иван',
              lastName: 'Иванов',
              middleName: '',
              gender: Gender.male,
            );

            // Assert
            expect(person.fullName, 'Иванов Иван');
          },
        );
      });

      group('displayName', () {
        test('возвращает Имя Фамилия для отображения', () {
          // Arrange
          final person = Person.create(
            firstName: 'Иван',
            lastName: 'Иванов',
            gender: Gender.male,
          );

          // Assert
          expect(person.displayName, 'Иван Иванов');
        });

        test('возвращает только имя, если фамилия пустая', () {
          // Arrange
          final person = Person.create(
            firstName: 'Иван',
            lastName: '',
            gender: Gender.male,
          );

          // Assert
          expect(person.displayName, 'Иван');
        });

        test('возвращает только фамилию, если имя пустое', () {
          // Arrange
          final person = Person.create(
            firstName: '',
            lastName: 'Иванов',
            gender: Gender.male,
          );

          // Assert
          expect(person.displayName, 'Иванов');
        });
      });

      group('isAlive', () {
        test('возвращает true, если deathDate отсутствует', () {
          // Arrange
          final person = Person.create(
            firstName: 'Иван',
            lastName: 'Иванов',
            gender: Gender.male,
          );

          // Assert
          expect(person.isAlive, true);
        });

        test('возвращает false, если deathDate указан', () {
          // Arrange
          final person = Person.create(
            firstName: 'Иван',
            lastName: 'Иванов',
            gender: Gender.male,
            deathDate: DateTime(2000, 1, 1),
          );

          // Assert
          expect(person.isAlive, false);
        });
      });

      group('age', () {
        test('возвращает возраст, если birthDate указан', () {
          // Arrange
          final person = Person.create(
            firstName: 'Иван',
            lastName: 'Иванов',
            gender: Gender.male,
            birthDate: DateTime(1980, 1, 1),
          );
          final expectedAge = DateTime.now().year - 1980;

          // Assert
          expect(person.age, expectedAge);
        });

        test('возвращает null, если birthDate отсутствует', () {
          // Arrange
          final person = Person.create(
            firstName: 'Иван',
            lastName: 'Иванов',
            gender: Gender.male,
            birthDate: null,
          );

          // Assert
          expect(person.age, null);
        });

        test('правильно рассчитывает возраст с учетом дня рождения', () {
          // Arrange
          final birthDate = DateTime(1980, 1, 1);
          final person = Person.create(
            firstName: 'Иван',
            lastName: 'Иванов',
            gender: Gender.male,
            birthDate: birthDate,
          );

          // Act
          final age = person.age;

          // Assert
          final now = DateTime.now();
          int expectedAge = now.year - 1980;
          if (now.month < 1 || (now.month == 1 && now.day < 1)) {
            expectedAge--;
          }
          expect(age, expectedAge);
        });

        test('учитывает смерть при расчете возраста', () {
          // Arrange
          final person = Person.create(
            firstName: 'Иван',
            lastName: 'Иванов',
            gender: Gender.male,
            birthDate: DateTime(1980, 1, 1),
            deathDate: DateTime(2020, 6, 1),
          );

          // Assert
          expect(person.age, 40);
        });
      });

      group('formattedAge', () {
        test('возвращает "Возраст неизвестен", если birthDate отсутствует', () {
          // Arrange
          final person = Person.create(
            firstName: 'Иван',
            lastName: 'Иванов',
            gender: Gender.male,
            birthDate: null,
          );

          // Assert
          expect(person.formattedAge, 'Возраст неизвестен');
        });

        test('возвращает возраст с "лет" для живого человека', () {
          // Arrange
          final person = Person.create(
            firstName: 'Иван',
            lastName: 'Иванов',
            gender: Gender.male,
            birthDate: DateTime(1980, 1, 1),
          );

          // Assert
          expect(person.formattedAge, '${person.age} лет');
        });

        test('возвращает возраст с "(умер)" для умершего человека', () {
          // Arrange
          final person = Person.create(
            firstName: 'Иван',
            lastName: 'Иванов',
            gender: Gender.male,
            birthDate: DateTime(1980, 1, 1),
            deathDate: DateTime(2020, 1, 1),
          );

          // Assert
          expect(person.formattedAge, '${person.age} лет (умер)');
        });
      });

      group('Медиа-геттеры', () {
        test('mediaDirectoryName возвращает правильное имя директории', () {
          // Arrange
          final person = Person.create(
            firstName: 'Иван',
            lastName: 'Иванов',
            gender: Gender.male,
          );

          // Assert
          expect(person.mediaDirectoryName, 'person_${person.id}');
        });

        test('hasPrimaryPortrait возвращает true если photoPath есть', () {
          // Arrange
          final person = Person.create(
            firstName: 'Иван',
            lastName: 'Иванов',
            gender: Gender.male,
            photoPath: '/path/to/photo.jpg',
          );

          // Assert
          expect(person.hasPrimaryPortrait, true);
        });

        test(
          'hasPrimaryPortrait возвращает false если photoPath отсутствует',
          () {
            // Arrange
            final person = Person.create(
              firstName: 'Иван',
              lastName: 'Иванов',
              gender: Gender.male,
              photoPath: null,
            );

            // Assert
            expect(person.hasPrimaryPortrait, false);
          },
        );

        test('canAddMedia возвращает true если id не пустой', () {
          // Arrange
          final person = Person.create(
            firstName: 'Иван',
            lastName: 'Иванов',
            gender: Gender.male,
          );

          // Assert
          expect(person.canAddMedia, true);
        });

        test('canAddMedia возвращает false если id пустой', () {
          // Arrange
          final person = Person.empty();

          // Assert
          expect(person.canAddMedia, false);
        });

        test('mediaCount возвращает количество медиа-файлов', () {
          // Arrange
          final person = Person.create(
            firstName: 'Иван',
            lastName: 'Иванов',
            gender: Gender.male,
            photoUrls: ['url1', 'url2', 'url3'],
            photoPath: '/path/to/photo.jpg',
          );

          // Assert
          expect(person.mediaCount, 4); // 3 photoUrls + 1 photoPath
        });

        test('mediaTypes возвращает типы медиа', () {
          // Arrange
          final person = Person.create(
            firstName: 'Иван',
            lastName: 'Иванов',
            gender: Gender.male,
            photoUrls: ['url1', 'url2'],
            photoPath: '/path/to/photo.jpg',
          );

          // Assert
          expect(person.mediaTypes.contains('photos'), true);
          expect(person.mediaTypes.contains('portrait'), true);
        });
      });
    });

    // ============================================================
    // 3. ТЕСТЫ COPYWITH
    // ============================================================

    group('copyWith', () {
      test('копирует Person с изменением полей', () {
        // Arrange
        final original = Person.create(
          firstName: 'Иван',
          lastName: 'Иванов',
          middleName: 'Петрович',
          gender: Gender.male,
          birthDate: DateTime(1980, 1, 1),
          birthPlace: 'Москва',
          occupation: 'Инженер',
        );

        // Act
        final updated = original.copyWith(
          firstName: 'Петр',
          lastName: 'Петров',
          middleName: 'Иванович',
          birthDate: DateTime(1990, 2, 2),
          birthPlace: 'Санкт-Петербург',
          occupation: 'Врач',
        );

        // Assert
        expect(updated.id, original.id); // id не изменился
        expect(updated.treeId, original.treeId); // treeId не изменился
        expect(updated.firstName, 'Петр');
        expect(updated.lastName, 'Петров');
        expect(updated.middleName, 'Иванович');
        expect(updated.birthDate, DateTime(1990, 2, 2));
        expect(updated.birthPlace, 'Санкт-Петербург');
        expect(updated.occupation, 'Врач');
        expect(updated.createdAt, original.createdAt); // createdAt не изменился
        expect(
          updated.updatedAt,
          isNot(original.updatedAt),
        ); // updatedAt обновился
      });

      test('copyWith сохраняет неизмененные поля', () {
        // Arrange
        final original = Person.create(
          firstName: 'Иван',
          lastName: 'Иванов',
          gender: Gender.male,
          birthDate: DateTime(1980, 1, 1),
        );

        // Act
        final updated = original.copyWith(firstName: 'Петр');

        // Assert
        expect(updated.lastName, original.lastName);
        expect(updated.gender, original.gender);
        expect(updated.birthDate, original.birthDate);
        expect(updated.createdAt, original.createdAt);
      });

      test('copyWith обновляет updatedAt по умолчанию', () async {
        // Arrange
        final original = Person.create(
          firstName: 'Иван',
          lastName: 'Иванов',
          gender: Gender.male,
        );
        final oldUpdatedAt = original.updatedAt;

        // Небольшая задержка, чтобы гарантировать изменение времени
        await Future.delayed(const Duration(milliseconds: 10));

        // Act
        final updated = original.copyWith(firstName: 'Петр');

        // Assert
        expect(updated.updatedAt.isAfter(oldUpdatedAt), true);
        expect(updated.updatedAt, isNot(oldUpdatedAt));
      });

      test('copyWith позволяет явно задать updatedAt', () {
        // Arrange
        final original = Person.create(
          firstName: 'Иван',
          lastName: 'Иванов',
          gender: Gender.male,
        );
        final fixedDate = DateTime(2020, 1, 1);

        // Act
        final updated = original.copyWith(
          firstName: 'Петр',
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
      test('два одинаковых Person равны', () {
        // Arrange
        final now = DateTime.now();
        final person1 = Person(
          id: 'id1',
          treeId: 'tree1',
          firstName: 'Иван',
          lastName: 'Иванов',
          gender: Gender.male,
          createdAt: now,
          updatedAt: now,
        );
        final person2 = Person(
          id: 'id1',
          treeId: 'tree1',
          firstName: 'Иван',
          lastName: 'Иванов',
          gender: Gender.male,
          createdAt: now,
          updatedAt: now,
        );

        // Assert
        expect(person1 == person2, true);
        expect(person1.hashCode, person2.hashCode);
      });

      test('два разных Person не равны', () {
        // Arrange
        final now = DateTime.now();
        final person1 = Person(
          id: 'id1',
          treeId: 'tree1',
          firstName: 'Иван',
          lastName: 'Иванов',
          gender: Gender.male,
          createdAt: now,
          updatedAt: now,
        );
        final person2 = Person(
          id: 'id2',
          treeId: 'tree1',
          firstName: 'Петр',
          lastName: 'Иванов',
          gender: Gender.male,
          createdAt: now,
          updatedAt: now,
        );

        // Assert
        expect(person1 == person2, false);
        expect(person1.hashCode, isNot(person2.hashCode));
      });

      test('Person сравнивается по всем полям из props', () {
        // Arrange
        final person = Person.create(
          firstName: 'Иван',
          lastName: 'Иванов',
          gender: Gender.male,
        );

        // Assert
        expect(person.props.length, 16); // Количество полей в props
      });
    });

    // ============================================================
    // 5. ТЕСТЫ МЕДИА-МЕТОДОВ
    // ============================================================

    group('Медиа-методы', () {
      test('primaryPortraitUrl возвращает photoPath', () {
        // Arrange
        final person = Person.create(
          firstName: 'Иван',
          lastName: 'Иванов',
          gender: Gender.male,
          photoPath: '/path/to/portrait.jpg',
        );

        // Assert
        expect(person.primaryPortraitUrl, '/path/to/portrait.jpg');
      });

      test('primaryPortraitUrl возвращает null если photoPath отсутствует', () {
        // Arrange
        final person = Person.create(
          firstName: 'Иван',
          lastName: 'Иванов',
          gender: Gender.male,
          photoPath: null,
        );

        // Assert
        expect(person.primaryPortraitUrl, null);
      });
    });
  });
}
