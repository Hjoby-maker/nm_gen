// lib/domain/entities/person.dart
import 'package:equatable/equatable.dart';
import 'package:nm_gen/core/enums/gender.dart';

/// Сущность человека в генеалогическом древе
class Person extends Equatable {
  const Person({
    required this.id,
    required this.treeId,
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
    this.photoUrls = const <String>[],
    this.photoPath,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создать нового человека с автоматической генерацией ID
  factory Person.create({
    required String firstName,
    required String lastName,
    String? middleName,
    required Gender gender,
    String? treeId,
    DateTime? birthDate,
    DateTime? deathDate,
    String? birthPlace,
    String? deathPlace,
    String? occupation,
    String? biography,
    List<String>? photoUrls,
    String? photoPath,
  }) {
    final DateTime now = DateTime.now();
    return Person(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      treeId: treeId ?? 'default',
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
      photoUrls: photoUrls ?? const <String>[],
      photoPath: photoPath,
      createdAt: now,
      updatedAt: now,
    );
  }

  final String id;
  final String treeId;
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
  final String? photoPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Полное имя (Фамилия Имя Отчество)
  String get fullName {
    final List<String> parts = <String>[];
    if (lastName.isNotEmpty) parts.add(lastName);
    if (firstName.isNotEmpty) parts.add(firstName);
    if (middleName != null && middleName!.isNotEmpty) parts.add(middleName!);
    return parts.join(' ');
  }

  /// Имя для отображения
  String get displayName {
    final List<String> parts = <String>[];
    if (firstName.isNotEmpty) parts.add(firstName);
    if (lastName.isNotEmpty) parts.add(lastName);
    return parts.join(' ');
  }

  /// Жив ли человек
  bool get isAlive => deathDate == null;

  /// Возраст (целыми годами)
  int? get age {
    final DateTime? birth = birthDate;
    if (birth == null) return null;

    final DateTime endDate = deathDate ?? DateTime.now();
    int age = endDate.year - birth.year;
    if (endDate.month < birth.month ||
        (endDate.month == birth.month && endDate.day < birth.day)) {
      age--;
    }
    return age;
  }

  /// Форматированный возраст с указанием "лет/год/года"
  String get formattedAge {
    final int? years = age;
    if (years == null) return 'Возраст неизвестен';

    if (!isAlive) {
      return '$years лет (умер)';
    }
    return '$years лет';
  }

  /// ============================================
  /// МЕТОДЫ ДЛЯ РАБОТЫ С МЕДИА-ФАЙЛАМИ
  /// ============================================

  /// Получить имя директории для файлов этого человека
  String get mediaDirectoryName => 'person_$id';

  /// Проверить, есть ли у человека основной портрет
  bool get hasPrimaryPortrait => photoPath != null && photoPath!.isNotEmpty;

  /// Получить URL основного портрета (если есть)
  String? get primaryPortraitUrl => photoPath;

  /// Проверить, можно ли добавить медиа к этому человеку
  bool get canAddMedia => id.isNotEmpty;

  /// Получить все типы медиа, которые есть у человека
  Set<String> get mediaTypes {
    final Set<String> types = <String>{};
    if (photoUrls.isNotEmpty) types.add('photos');
    if (photoPath != null) types.add('portrait');
    return types;
  }

  /// Количество медиа-файлов (приблизительное)
  int get mediaCount => photoUrls.length + (photoPath != null ? 1 : 0);

  Person copyWith({
    String? id,
    String? treeId,
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
    String? photoPath,
    DateTime? updatedAt,
  }) {
    return Person(
      id: id ?? this.id,
      treeId: treeId ?? this.treeId,
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
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    treeId,
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
    photoPath,
    createdAt,
    updatedAt,
  ];

  /// Пустой человек (для начального состояния)
  static Person empty() => Person(
    id: '',
    treeId: '',
    firstName: '',
    lastName: '',
    gender: Gender.unknown,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
