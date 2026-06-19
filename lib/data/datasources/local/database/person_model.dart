import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/domain/entities/person.dart';

/// Модель Person для SQLite
class PersonModel {
  PersonModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.gender,
    this.birthDate,
    this.deathDate,
    this.birthPlace,
    this.deathPlace,
    this.occupation,
    this.biography,
    required this.photoUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Конвертация из Domain Entity
  factory PersonModel.fromDomain(Person person) {
    return PersonModel(
      id: person.id,
      firstName: person.firstName,
      lastName: person.lastName,
      middleName: person.middleName,
      gender: person.gender.name, // Сохраняем как строку
      birthDate: person.birthDate?.millisecondsSinceEpoch,
      deathDate: person.deathDate?.millisecondsSinceEpoch,
      birthPlace: person.birthPlace,
      deathPlace: person.deathPlace,
      occupation: person.occupation,
      biography: person.biography,
      photoUrls: person.photoUrls.join(','), // Преобразуем список в строку
      createdAt: person.createdAt.millisecondsSinceEpoch,
      updatedAt: person.updatedAt.millisecondsSinceEpoch,
    );
  }

  /// Создание из Map (для SQLite)
  factory PersonModel.fromMap(Map<String, dynamic> map) {
    return PersonModel(
      id: map['id'] as String,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      middleName: map['middle_name'] as String?,
      gender: map['gender'] as String,
      birthDate: map['birth_date'] as int?,
      deathDate: map['death_date'] as int?,
      birthPlace: map['birth_place'] as String?,
      deathPlace: map['death_place'] as String?,
      occupation: map['occupation'] as String?,
      biography: map['biography'] as String?,
      photoUrls: map['photo_urls'] as String? ?? '',
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }
  final String id;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String gender; // Сохраняем как строку
  final int? birthDate; // Unix timestamp
  final int? deathDate; // Unix timestamp
  final String? birthPlace;
  final String? deathPlace;
  final String? occupation;
  final String? biography;
  final String photoUrls; // JSON строка
  final int createdAt;
  final int updatedAt;

  /// Конвертация в Domain Entity
  Person toDomain() {
    return Person(
      id: id,
      firstName: firstName,
      lastName: lastName,
      middleName: middleName,
      gender: Gender.values.firstWhere(
        (Gender g) => g.name == gender,
        orElse: () => Gender.unknown,
      ),
      birthDate: birthDate != null
          ? DateTime.fromMillisecondsSinceEpoch(birthDate!)
          : null,
      deathDate: deathDate != null
          ? DateTime.fromMillisecondsSinceEpoch(deathDate!)
          : null,
      birthPlace: birthPlace,
      deathPlace: deathPlace,
      occupation: occupation,
      biography: biography,
      photoUrls: photoUrls.isEmpty ? <String>[] : photoUrls.split(','),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
    );
  }

  /// Конвертация в Map (для SQLite)
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'gender': gender,
      'birth_date': birthDate,
      'death_date': deathDate,
      'birth_place': birthPlace,
      'death_place': deathPlace,
      'occupation': occupation,
      'biography': biography,
      'photo_urls': photoUrls,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
