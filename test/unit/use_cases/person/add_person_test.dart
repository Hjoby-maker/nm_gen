// test/unit/use_cases/person/add_person_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';
import 'package:nm_gen/domain/use_cases/person/add_person.dart';
import 'package:nm_gen/domain/use_cases/person/sync_person_events.dart';
import '../../../test_utils/test_helpers.dart';
import '../../../test_utils/mocks.dart';

void main() {
  late MockPersonRepository mockPersonRepository;
  late MockEventRepository mockEventRepository;
  late SyncPersonEventsUseCase syncUseCase;
  late AddPersonUseCase useCase;

  setUpAll(() {
    // Регистрируем fallback значения для типов, которые используются в any()
    registerFallbackValue(createTestEvent());
    registerFallbackValue(createTestPerson());
  });

  setUp(() {
    mockPersonRepository = MockPersonRepository();
    mockEventRepository = MockEventRepository();
    syncUseCase = SyncPersonEventsUseCase(mockEventRepository);
    useCase = AddPersonUseCase(mockPersonRepository, syncUseCase);

    // Мокаем для синхронизации событий
    when(
      () => mockEventRepository.getEventsByPersonId(
        any(),
        treeId: any(named: 'treeId'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => mockEventRepository.addEvent(any()),
    ).thenAnswer((_) async => createTestEvent());
  });

  group('AddPersonUseCase', () {
    test('успешно добавляет человека с корректными данными', () async {
      // Arrange
      final newPerson = createTestPerson(
        id: 'new_person',
        firstName: 'Алексей',
        lastName: 'Петров',
      );
      final savedPerson = Person(
        id: newPerson.id,
        treeId: newPerson.treeId,
        firstName: newPerson.firstName,
        lastName: newPerson.lastName,
        middleName: newPerson.middleName,
        gender: newPerson.gender,
        birthDate: newPerson.birthDate,
        deathDate: newPerson.deathDate,
        birthPlace: newPerson.birthPlace,
        deathPlace: newPerson.deathPlace,
        occupation: newPerson.occupation,
        biography: newPerson.biography,
        photoUrls: newPerson.photoUrls,
        photoPath: newPerson.photoPath,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(
        () => mockPersonRepository.addPerson(any()),
      ).thenAnswer((_) async => savedPerson);

      // Act
      final result = await useCase.execute(newPerson, treeId: 'tree_1');

      // Assert
      expect(result.isRight(), true);
      final person = result.getOrElse(() => Person.empty());
      expect(person.firstName, 'Алексей');
      expect(person.lastName, 'Петров');
      verify(() => mockPersonRepository.addPerson(any())).called(1);
    });

    test('возвращает Left с ValidationFailure при пустом имени', () async {
      // Arrange
      final invalidPerson = createTestPerson(firstName: '', lastName: 'Тестов');

      // Act
      final result = await useCase.execute(invalidPerson);

      // Assert
      expect(result.isLeft(), true);
      expect(
        result.fold(
          (failure) =>
              failure is ValidationFailure &&
              failure.message.contains('Имя и фамилия обязательны'),
          (_) => false,
        ),
        true,
      );
      verifyNever(() => mockPersonRepository.addPerson(any()));
    });

    test('возвращает Left с ValidationFailure при пустой фамилии', () async {
      // Arrange
      final invalidPerson = createTestPerson(firstName: 'Тест', lastName: '');

      // Act
      final result = await useCase.execute(invalidPerson);

      // Assert
      expect(result.isLeft(), true);
      expect(
        result.fold(
          (failure) =>
              failure is ValidationFailure &&
              failure.message.contains('Имя и фамилия обязательны'),
          (_) => false,
        ),
        true,
      );
      verifyNever(() => mockPersonRepository.addPerson(any()));
    });

    test(
      'устанавливает treeId по умолчанию "default", если не передан',
      () async {
        // Arrange
        final newPerson = createTestPerson(
          id: 'new_person',
          treeId: '',
          firstName: 'Тест',
          lastName: 'Тестов',
        );
        final savedPerson = Person(
          id: newPerson.id,
          treeId: 'default',
          firstName: newPerson.firstName,
          lastName: newPerson.lastName,
          middleName: newPerson.middleName,
          gender: newPerson.gender,
          birthDate: newPerson.birthDate,
          deathDate: newPerson.deathDate,
          birthPlace: newPerson.birthPlace,
          deathPlace: newPerson.deathPlace,
          occupation: newPerson.occupation,
          biography: newPerson.biography,
          photoUrls: newPerson.photoUrls,
          photoPath: newPerson.photoPath,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(
          () => mockPersonRepository.addPerson(any()),
        ).thenAnswer((_) async => savedPerson);

        // Act
        final result = await useCase.execute(newPerson);

        // Assert
        expect(result.isRight(), true);
        final person = result.getOrElse(() => Person.empty());
        expect(person.treeId, 'default');
      },
    );

    test('использует переданный treeId, если он есть', () async {
      // Arrange
      const treeId = 'custom_tree';
      final newPerson = createTestPerson(
        id: 'new_person',
        treeId: treeId,
        firstName: 'Тест',
        lastName: 'Тестов',
      );
      final savedPerson = Person(
        id: newPerson.id,
        treeId: treeId,
        firstName: newPerson.firstName,
        lastName: newPerson.lastName,
        middleName: newPerson.middleName,
        gender: newPerson.gender,
        birthDate: newPerson.birthDate,
        deathDate: newPerson.deathDate,
        birthPlace: newPerson.birthPlace,
        deathPlace: newPerson.deathPlace,
        occupation: newPerson.occupation,
        biography: newPerson.biography,
        photoUrls: newPerson.photoUrls,
        photoPath: newPerson.photoPath,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(
        () => mockPersonRepository.addPerson(any()),
      ).thenAnswer((_) async => savedPerson);

      // Act
      final result = await useCase.execute(newPerson, treeId: treeId);

      // Assert
      expect(result.isRight(), true);
      final person = result.getOrElse(() => Person.empty());
      expect(person.treeId, treeId);
    });

    test('вызывает синхронизацию событий после сохранения человека', () async {
      // Arrange
      final newPerson = createTestPerson(firstName: 'Тест', lastName: 'Тестов');
      final savedPerson = Person(
        id: newPerson.id,
        treeId: newPerson.treeId,
        firstName: newPerson.firstName,
        lastName: newPerson.lastName,
        middleName: newPerson.middleName,
        gender: newPerson.gender,
        birthDate: newPerson.birthDate,
        deathDate: newPerson.deathDate,
        birthPlace: newPerson.birthPlace,
        deathPlace: newPerson.deathPlace,
        occupation: newPerson.occupation,
        biography: newPerson.biography,
        photoUrls: newPerson.photoUrls,
        photoPath: newPerson.photoPath,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(
        () => mockPersonRepository.addPerson(any()),
      ).thenAnswer((_) async => savedPerson);

      // Act
      await useCase.execute(newPerson);

      // Assert
      verify(
        () => mockEventRepository.addEvent(any()),
      ).called(greaterThanOrEqualTo(1));
    });

    test('возвращает Left с ServerFailure при ошибке репозитория', () async {
      // Arrange
      final newPerson = createTestPerson(firstName: 'Тест', lastName: 'Тестов');

      when(
        () => mockPersonRepository.addPerson(any()),
      ).thenThrow(Exception('Database error'));

      // Act
      final result = await useCase.execute(newPerson);

      // Assert
      expect(result.isLeft(), true);
      expect(
        result.fold((failure) => failure is ServerFailure, (_) => false),
        true,
      );
    });
  });
}
