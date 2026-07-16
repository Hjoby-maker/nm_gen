import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/entities/person.dart';

/// Класс для генерации GEDCOM файлов
class GedcomGenerator {
  /// Генерирует GEDCOM строку из списка людей и семей
  static String generate(List<Person> persons, List<Family> families) {
    final StringBuffer buffer = StringBuffer();

    // Заголовок
    buffer.writeln('0 HEAD');
    buffer.writeln('1 SOUR GEN');
    buffer.writeln('2 VERS 1.0');
    buffer.writeln('1 DEST DISKETTE');
    buffer.writeln('1 DATE ${_formatDate(DateTime.now())}');
    buffer.writeln('1 GEDC');
    buffer.writeln('2 VERS 5.5.1');
    buffer.writeln('2 FORM LINEAGE-LINKED');
    buffer.writeln('1 CHAR UTF-8');
    buffer.writeln('');

    // Индивидуумы
    for (final Person person in persons) {
      buffer.writeln(_generateIndividual(person));
    }

    // Семьи
    for (final Family family in families) {
      buffer.writeln(_generateFamily(family, persons));
    }

    // Завершение
    buffer.writeln('0 TRLR');

    return buffer.toString();
  }

  static String _generateIndividual(Person person) {
    final StringBuffer buffer = StringBuffer();
    final String id = _generateId(person.id);

    buffer.writeln('0 $id INDI');
    buffer.writeln('1 NAME ${person.firstName} /${person.lastName}/');
    buffer.writeln('1 SEX ${person.gender == Gender.male ? 'M' : 'F'}');

    if (person.birthDate != null) {
      buffer.writeln('1 BIRT');
      buffer.writeln('2 DATE ${_formatGedcomDate(person.birthDate!)}');
    }

    if (person.deathDate != null) {
      buffer.writeln('1 DEAT');
      buffer.writeln('2 DATE ${_formatGedcomDate(person.deathDate!)}');
    }

    if (person.birthPlace != null && person.birthPlace!.isNotEmpty) {
      buffer.writeln('1 _BIRT_PLACE ${person.birthPlace}');
    }

    if (person.deathPlace != null && person.deathPlace!.isNotEmpty) {
      buffer.writeln('1 _DEAT_PLACE ${person.deathPlace}');
    }

    if (person.occupation != null && person.occupation!.isNotEmpty) {
      buffer.writeln('1 OCCU ${person.occupation}');
    }

    buffer.writeln('');
    return buffer.toString();
  }

  static String _generateFamily(Family family, List<Person> allPersons) {
    final StringBuffer buffer = StringBuffer();
    final String id = _generateId(family.id);

    buffer.writeln('0 $id FAM');

    if (family.husbandId != null) {
      buffer.writeln('1 HUSB ${_generateId(family.husbandId!)}');
    }

    if (family.wifeId != null) {
      buffer.writeln('1 WIFE ${_generateId(family.wifeId!)}');
    }

    for (final String childId in family.childrenIds) {
      buffer.writeln('1 CHIL ${_generateId(childId)}');
    }

    if (family.marriageDate != null) {
      buffer.writeln('1 MARR');
      buffer.writeln('2 DATE ${_formatGedcomDate(family.marriageDate!)}');
    }

    if (family.divorceDate != null) {
      buffer.writeln('1 DIV');
      buffer.writeln('2 DATE ${_formatGedcomDate(family.divorceDate!)}');
    }

    buffer.writeln('');
    return buffer.toString();
  }

  static String _generateId(String id) {
    return '@$id@';
  }

  static String _formatGedcomDate(DateTime date) {
    const Map<int, String> months = <int, String>{
      1: 'JAN',
      2: 'FEB',
      3: 'MAR',
      4: 'APR',
      5: 'MAY',
      6: 'JUN',
      7: 'JUL',
      8: 'AUG',
      9: 'SEP',
      10: 'OCT',
      11: 'NOV',
      12: 'DEC',
    };
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month]} ${date.year}';
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} ${_formatGedcomDate(date)}';
  }
}
