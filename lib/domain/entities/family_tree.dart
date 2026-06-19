import 'package:equatable/equatable.dart';
import 'person.dart';
import 'family.dart';

/// Полное генеалогическое древо
class FamilyTree extends Equatable {
  const FamilyTree({
    required this.rootPerson,
    this.allPersons = const [],
    this.families = const [],
  });
  final Person rootPerson;
  final List<Person> allPersons;
  final List<Family> families;

  /// Найти человека по ID
  Person? findPerson(String id) {
    try {
      return allPersons.firstWhere((Person p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Найти семью по ID
  Family? findFamily(String id) {
    try {
      return families.firstWhere((Family f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Получить детей человека
  List<Person> getChildren(String personId) {
    final List<Person> children = <Person>[];
    for (final Family family in families) {
      if (family.parentIds.contains(personId)) {
        for (final String childId in family.childrenIds) {
          final Person? child = findPerson(childId);
          if (child != null) {
            children.add(child);
          }
        }
      }
    }
    return children;
  }

  /// Получить родителей человека
  List<Person> getParents(String personId) {
    final List<Person> parents = <Person>[];
    for (final Family family in families) {
      if (family.childrenIds.contains(personId)) {
        for (final String parentId in family.parentIds) {
          final Person? parent = findPerson(parentId);
          if (parent != null) {
            parents.add(parent);
          }
        }
      }
    }
    return parents;
  }

  /// Получить супругов человека
  List<Person> getSpouses(String personId) {
    final List<Person> spouses = <Person>[];
    for (final Family family in families) {
      if (family.husbandId == personId) {
        final Person? spouse = findPerson(family.wifeId ?? '');
        if (spouse != null) spouses.add(spouse);
      } else if (family.wifeId == personId) {
        final Person? spouse = findPerson(family.husbandId ?? '');
        if (spouse != null) spouses.add(spouse);
      }
    }
    return spouses;
  }

  /// Получить все семьи, где участвует человек
  List<Family> getFamiliesForPerson(String personId) {
    return families
        .where(
          (Family f) =>
              f.parentIds.contains(personId) ||
              f.childrenIds.contains(personId),
        )
        .toList();
  }

  /// Количество людей в дереве
  int get personCount => allPersons.length;

  /// Количество семей
  int get familyCount => families.length;

  @override
  List<Object?> get props => <Object?>[rootPerson, allPersons, families];
}
