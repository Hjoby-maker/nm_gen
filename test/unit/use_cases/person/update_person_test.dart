// test/unit/use_cases/person/update_person_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';
import 'package:nm_gen/domain/use_cases/person/update_person.dart';
import 'package:nm_gen/domain/use_cases/person/sync_person_events.dart';
import '../../../test_utils/test_helpers.dart';
import '../../../test_utils/mocks.dart';

void main() {
  late MockPersonRepository mockPersonRepository;
  late MockEventRepository mockEventRepository;
  late SyncPersonEventsUseCase syncUseCase;
  late UpdatePersonUseCase useCase;

  setUpAll(() {
    registerFallbackValue(createTestEvent());
    registerFallbackValue(createTestPerson());
  });

  setUp(() {
    mockPersonRepository = MockPersonRepository();
    mockEventRepository = MockEventRepository();
    syncUseCase = SyncPersonEventsUseCase(mockEventRepository);
    useCase = UpdatePersonUseCase(mockPersonRepository, syncUseCase);

    when(
      () => mockEventRepository.getEventsByPersonId(
        any(),
        treeId: any(named: 'treeId'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => mockEventRepository.updateEvent(any<Event>()),
    ).thenAnswer((_) async => createTestEvent());
    when(
      () => mockEventRepository.addEvent(any<Event>()),
    ).thenAnswer((_) async => createTestEvent());
  });

  group('UpdatePersonUseCase', () {
    test('успешно обновляет человека с корректными данными', () async {
      // Arrange
      final person = createTestPerson(
        id: 'p1',
        firstName: 'Иван',
        lastName: 'Иванов',
        birthDate: DateTime(1980, 1, 1),
      );
      final updatedPerson = person.copyWith(
        firstName: 'Петр',
        lastName: 'Петров',
        updatedAt: DateTime.now(),
      );

      when(
        () => mockPersonRepository.updatePerson(any()),
      ).thenAnswer((_) async => updatedPerson);

      // Act
      final result = await useCase.execute(updatedPerson);

      // Assert
      expect(result.isRight(), true);
      final personResult = result.getOrElse(() => Person.empty());
      expect(personResult.firstName, 'Петр');
      expect(personResult.lastName, 'Петров');
      verify(() => mockPersonRepository.updatePerson(any())).called(1);
    });

    test('возвращает Left с ValidationFailure при пустом ID', () async {
      // Arrange
      final invalidPerson = createTestPerson(id: '');

      // Act
      final result = await useCase.execute(invalidPerson);

      // Assert
      expect(result.isLeft(), true);
      expect(
        result.fold(
          (failure) =>
              failure is ValidationFailure &&
              failure.message.contains('ID человека не может быть пустым'),
          (_) => false,
        ),
        true,
      );
      verifyNever(() => mockPersonRepository.updatePerson(any()));
    });

    test('возвращает Left с ValidationFailure при пустом имени', () async {
      // Arrange
      final invalidPerson = createTestPerson(
        id: 'p1',
        firstName: '',
        lastName: 'Тестов',
      );

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
      verifyNever(() => mockPersonRepository.updatePerson(any()));
    });

    test('возвращает Left с ValidationFailure при пустой фамилии', () async {
      // Arrange
      final invalidPerson = createTestPerson(
        id: 'p1',
        firstName: 'Тест',
        lastName: '',
      );

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
      verifyNever(() => mockPersonRepository.updatePerson(any()));
    });

    test('обновляет treeId, если передан новый', () async {
      // Arrange
      const newTreeId = 'new_tree';
      final person = createTestPerson(
        id: 'p1',
        treeId: 'old_tree',
        firstName: 'Иван',
        lastName: 'Иванов',
      );
      final updatedPerson = person.copyWith(
        treeId: newTreeId,
        updatedAt: DateTime.now(),
      );

      when(
        () => mockPersonRepository.updatePerson(any()),
      ).thenAnswer((_) async => updatedPerson);

      // Act
      final result = await useCase.execute(person, treeId: newTreeId);

      // Assert
      expect(result.isRight(), true);
      final personResult = result.getOrElse(() => Person.empty());
      expect(personResult.treeId, newTreeId);
    });

    test('вызывает синхронизацию событий после обновления человека', () async {
      // Arrange
      final person = createTestPerson(
        id: 'p1',
        firstName: 'Иван',
        lastName: 'Иванов',
        birthDate: DateTime(1980, 1, 1),
      );
      final updatedPerson = person.copyWith(
        birthDate: DateTime(1980, 2, 2),
        updatedAt: DateTime.now(),
      );

      // Мокаем существующее событие рождения
      final existingEvent = createTestEvent(
        id: 'e1',
        personId: person.id,
        type: EventType.birth,
        title: 'Рождение ${person.displayName}',
      );

      when(
        () => mockEventRepository.getEventsByPersonId(
          person.id,
          treeId: person.treeId,
        ),
      ).thenAnswer((_) async => [existingEvent]);

      when(
        () => mockPersonRepository.updatePerson(any()),
      ).thenAnswer((_) async => updatedPerson);

      // Act
      await useCase.execute(updatedPerson);

      // Assert
      verify(
        () => mockEventRepository.getEventsByPersonId(
          person.id,
          treeId: person.treeId,
        ),
      ).called(1);
      // Проверяем, что updateEvent был вызван (для обновления события рождения)
      verify(() => mockEventRepository.updateEvent(any<Event>())).called(1);
    });

    test('возвращает Left с ServerFailure при ошибке репозитория', () async {
      // Arrange
      final person = createTestPerson(
        id: 'p1',
        firstName: 'Иван',
        lastName: 'Иванов',
      );

      when(
        () => mockPersonRepository.updatePerson(any()),
      ).thenThrow(Exception('Database error'));

      // Act
      final result = await useCase.execute(person);

      // Assert
      expect(result.isLeft(), true);
      expect(
        result.fold((failure) => failure is ServerFailure, (_) => false),
        true,
      );
    });
  });
}
