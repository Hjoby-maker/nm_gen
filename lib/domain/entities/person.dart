import 'package:equatable/equatable.dart';
import 'package:nm_gen/core/enums/gender.dart';

/// Сущность человека в генеалогическом древе
class Person extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? middleName;
  final Gender gender;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String? birthPlace;
  final String? deathPlace;
  final String? occupation;
  final String? biography;
  final List<String> photoUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Person({
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
    this.photoUrls = const [],
    required this.createdAt, // Теперь обязательный параметр
    required this.updatedAt, // Теперь обязательный параметр
  });

  /// Полное имя (Фамилия Имя Отчество)
  String get fullName {
    final parts = <String>[];
    if (lastName.isNotEmpty) parts.add(lastName);
    if (firstName.isNotEmpty) parts.add(firstName);
    if (middleName != null && middleName!.isNotEmpty) parts.add(middleName!);
    return parts.join(' ');
  }

  /// Имя для отображения
  String get displayName {
    final parts = <String>[];
    if (firstName.isNotEmpty) parts.add(firstName);
    if (lastName.isNotEmpty) parts.add(lastName);
    return parts.join(' ');
  }

  /// Жив ли человек
  bool get isAlive => deathDate == null;

  /// Возраст (целыми годами)
  int? get age {
    final birth = birthDate;
    if (birth == null) return null;

    final endDate = deathDate ?? DateTime.now();
    int age = endDate.year - birth.year;
    if (endDate.month < birth.month ||
        (endDate.month == birth.month && endDate.day < birth.day)) {
      age--;
    }
    return age;
  }

  /// Форматированный возраст с указанием "лет/год/года"
  String get formattedAge {
    final years = age;
    if (years == null) return 'Возраст неизвестен';

    if (!isAlive) {
      return '$years лет (умер)';
    }
    return '$years лет';
  }

  Person copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? middleName,
    Gender? gender,
    DateTime? birthDate,
    DateTime? deathDate,
    String? birthPlace,
    String? deathPlace,
    String? occupation,
    String? biography,
    List<String>? photoUrls,
    DateTime? updatedAt,
  }) {
    return Person(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      deathDate: deathDate ?? this.deathDate,
      birthPlace: birthPlace ?? this.birthPlace,
      deathPlace: deathPlace ?? this.deathPlace,
      occupation: occupation ?? this.occupation,
      biography: biography ?? this.biography,
      photoUrls: photoUrls ?? this.photoUrls,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    middleName,
    gender,
    birthDate,
    deathDate,
    birthPlace,
    deathPlace,
    occupation,
    biography,
    photoUrls,
    createdAt,
    updatedAt,
  ];

  /// Пустой человек (для начального состояния)
  static Person empty() => Person(
    id: '',
    firstName: '',
    lastName: '',
    gender: Gender.unknown,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  /// Создать нового человека с автоматической генерацией ID
  factory Person.create({
    required String firstName,
    required String lastName,
    String? middleName,
    required Gender gender,
    DateTime? birthDate,
    DateTime? deathDate,
    String? birthPlace,
    String? deathPlace,
    String? occupation,
    String? biography,
    List<String>? photoUrls,
  }) {
    final now = DateTime.now();
    return Person(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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
      photoUrls: photoUrls ?? const [],
      createdAt: now,
      updatedAt: now,
    );
  }
}
