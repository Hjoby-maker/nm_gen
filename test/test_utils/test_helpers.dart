// test/test_utils/test_helpers.dart
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';

/// Создает тестового человека
Person createTestPerson({
  String id = 'test_person_1',
  String treeId = 'tree_1',
  String firstName = 'Иван',
  String lastName = 'Иванов',
  String? middleName = 'Петрович',
  Gender gender = Gender.male,
  DateTime? birthDate, // ← теперь может быть null
  DateTime? deathDate,
  String? birthPlace = 'Москва',
  String? deathPlace,
  String? occupation = 'Инженер',
  String? biography = 'Тестовый человек',
  List<String> photoUrls = const [],
  String? photoPath,
}) {
  final now = DateTime.now();
  return Person(
    id: id,
    treeId: treeId,
    firstName: firstName,
    lastName: lastName,
    middleName: middleName,
    gender: gender,
    birthDate: birthDate, // ← НЕ заменяем на значение по умолчанию
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
}

/// Создает тестовое событие
Event createTestEvent({
  String id = 'test_event_1',
  String personId = 'test_person_1',
  String treeId = 'tree_1',
  EventType type = EventType.birth,
  String title = 'Тестовое событие',
  DateTime? startDate,
  String? place,
}) {
  final now = DateTime.now();
  return Event(
    id: id,
    personId: personId,
    treeId: treeId,
    type: type,
    title: title,
    description: 'Тестовое описание',
    startDate: startDate ?? DateTime(1980, 1, 1),
    endDate: null,
    place: place ?? 'Москва',
    notes: 'Тестовые заметки',
    createdAt: now,
    updatedAt: now,
  );
}

/// Создает тестовую семью
Family createTestFamily({
  String id = 'test_family_1',
  String treeId = 'tree_1',
  String? husbandId = 'test_person_1',
  String? wifeId = 'test_person_2',
  List<String> childrenIds = const [],
  DateTime? marriageDate,
  DateTime? divorceDate,
  String? marriagePlace = 'Москва',
  String? notes = 'Тестовая семья',
}) {
  return Family(
    id: id,
    treeId: treeId,
    husbandId: husbandId,
    wifeId: wifeId,
    childrenIds: childrenIds,
    marriageDate: marriageDate ?? DateTime(2000, 1, 1),
    divorceDate: divorceDate,
    marriagePlace: marriagePlace,
    notes: notes,
  );
}
