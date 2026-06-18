import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/domain/entities/person.dart';

/// Класс для парсинга GEDCOM файлов
class GedcomParser {
  /// Парсит GEDCOM строку в список людей и семей
  static GedcomData parse(String content) {
    final lines = content.split('\n');
    final individuals = <String, GedcomIndividual>{};
    final families = <String, GedcomFamily>{};

    String? currentId;
    String? currentType;
    final buffer = <String>[];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      final parts = line.split(' ');
      if (parts.length < 2) continue;

      final level = int.tryParse(parts[0]) ?? 0;
      final tag = parts[1];
      final value = parts.length > 2 ? parts.sublist(2).join(' ') : '';

      if (level == 0) {
        // Сохраняем предыдущий объект
        if (currentId != null && currentType == 'INDI') {
          _saveIndividual(buffer, individuals, currentId);
        } else if (currentId != null && currentType == 'FAM') {
          _saveFamily(buffer, families, currentId);
        }

        // Начинаем новый объект
        currentId = tag.startsWith('@') ? tag : null;
        currentType = value;
        buffer.clear();

        if (currentId != null) {
          buffer.add(line);
        }
      } else {
        if (currentId != null) {
          buffer.add(line);
        }
      }
    }

    // Сохраняем последний объект
    if (currentId != null && currentType == 'INDI') {
      _saveIndividual(buffer, individuals, currentId);
    } else if (currentId != null && currentType == 'FAM') {
      _saveFamily(buffer, families, currentId);
    }

    return GedcomData(
      individuals: individuals.values.toList(),
      families: families.values.toList(),
    );
  }

  static void _saveIndividual(
    List<String> buffer,
    Map<String, GedcomIndividual> individuals,
    String id,
  ) {
    final data = <String, String>{};
    for (final line in buffer) {
      final parts = line.split(' ');
      if (parts.length < 2) continue;
      final tag = parts[1];
      final value = parts.length > 2 ? parts.sublist(2).join(' ') : '';
      if (!data.containsKey(tag)) {
        data[tag] = value;
      }
    }

    final individual = GedcomIndividual(
      id: id,
      name: data['NAME'] ?? '',
      gender: data['SEX'] ?? '',
      birthDate: data['BIRT'] ?? '',
      deathDate: data['DEAT'] ?? '',
      birthPlace: data['_BIRT_PLACE'] ?? '',
      deathPlace: data['_DEAT_PLACE'] ?? '',
      occupation: data['OCCU'] ?? '',
      familyId: data['FAMC'] ?? '',
      spouseFamilyId: data['FAMS'] ?? '',
    );
    individuals[id] = individual;
  }

  static void _saveFamily(
    List<String> buffer,
    Map<String, GedcomFamily> families,
    String id,
  ) {
    var husbandId = '';
    var wifeId = '';
    final childrenIds = <String>[];
    String? marriageDate;
    String? divorceDate;

    for (final line in buffer) {
      final parts = line.split(' ');
      if (parts.length < 2) continue;
      final tag = parts[1];
      final value = parts.length > 2 ? parts.sublist(2).join(' ') : '';

      if (tag == 'HUSB') {
        husbandId = value;
      } else if (tag == 'WIFE') {
        wifeId = value;
      } else if (tag == 'CHIL') {
        childrenIds.add(value);
      } else if (tag == 'MARR') {
        marriageDate = value;
      } else if (tag == 'DIV') {
        divorceDate = value;
      }
    }

    final family = GedcomFamily(
      id: id,
      husbandId: husbandId,
      wifeId: wifeId,
      childrenIds: childrenIds,
      marriageDate: marriageDate,
      divorceDate: divorceDate,
    );
    families[id] = family;
  }

  /// Конвертирует GedcomIndividual в Person
  static Person toPerson(GedcomIndividual individual) {
    return Person.create(
      firstName: _extractFirstName(individual.name),
      lastName: _extractLastName(individual.name),
      gender: _parseGender(individual.gender),
      birthDate: _parseDate(individual.birthDate),
      deathDate: _parseDate(individual.deathDate),
      birthPlace: individual.birthPlace.isNotEmpty
          ? individual.birthPlace
          : null,
      deathPlace: individual.deathPlace.isNotEmpty
          ? individual.deathPlace
          : null,
      occupation: individual.occupation.isNotEmpty
          ? individual.occupation
          : null,
    );
  }

  static String _extractFirstName(String name) {
    // Формат GEDCOM: "John /Smith/"
    final parts = name.split('/');
    if (parts.isEmpty) return name.trim();
    return parts[0].trim();
  }

  static String _extractLastName(String name) {
    final parts = name.split('/');
    if (parts.length < 2) return '';
    return parts[1].trim();
  }

  static Gender _parseGender(String gender) {
    switch (gender.toUpperCase()) {
      case 'M':
        return Gender.male;
      case 'F':
        return Gender.female;
      default:
        return Gender.unknown;
    }
  }

  static DateTime? _parseDate(String date) {
    if (date.isEmpty) return null;
    // Простой парсинг даты в формате DD MMM YYYY
    // Например: "15 JAN 1980"
    final months = {
      'JAN': 1,
      'FEB': 2,
      'MAR': 3,
      'APR': 4,
      'MAY': 5,
      'JUN': 6,
      'JUL': 7,
      'AUG': 8,
      'SEP': 9,
      'OCT': 10,
      'NOV': 11,
      'DEC': 12,
    };

    final parts = date.split(' ');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = months[parts[1].toUpperCase()];
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }
}

/// Данные из GEDCOM файла
class GedcomData {
  final List<GedcomIndividual> individuals;
  final List<GedcomFamily> families;

  GedcomData({required this.individuals, required this.families});
}

/// GEDCOM человек
class GedcomIndividual {
  final String id;
  final String name;
  final String gender;
  final String birthDate;
  final String deathDate;
  final String birthPlace;
  final String deathPlace;
  final String occupation;
  final String familyId;
  final String spouseFamilyId;

  GedcomIndividual({
    required this.id,
    required this.name,
    required this.gender,
    required this.birthDate,
    required this.deathDate,
    required this.birthPlace,
    required this.deathPlace,
    required this.occupation,
    required this.familyId,
    required this.spouseFamilyId,
  });
}

/// GEDCOM семья
class GedcomFamily {
  final String id;
  final String husbandId;
  final String wifeId;
  final List<String> childrenIds;
  final String? marriageDate;
  final String? divorceDate;

  GedcomFamily({
    required this.id,
    required this.husbandId,
    required this.wifeId,
    required this.childrenIds,
    this.marriageDate,
    this.divorceDate,
  });
}
