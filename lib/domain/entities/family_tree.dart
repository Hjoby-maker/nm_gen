import 'package:equatable/equatable.dart';
import 'person.dart';
import 'family.dart';

/// Полное генеалогическое древо
class FamilyTree extends Equatable {
  final Person rootPerson;
  final List<Person> allPersons;
  final List<Family> families;

  const FamilyTree({
    required this.rootPerson,
    this.allPersons = const [],
    this.families = const [],
  });

  /// Найти человека по ID
  Person? findPerson(String id) {
    try {
      return allPersons.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Найти семью по ID
  Family? findFamily(String id) {
    try {
      return families.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Получить детей человека
  List<Person> getChildren(String personId) {
    final children = <Person>[];
    for (final family in families) {
      if (family.parentIds.contains(personId)) {
        for (final childId in family.childrenIds) {
          final child = findPerson(childId);
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
    final parents = <Person>[];
    for (final family in families) {
      if (family.childrenIds.contains(personId)) {
        for (final parentId in family.parentIds) {
          final parent = findPerson(parentId);
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
    final spouses = <Person>[];
    for (final family in families) {
      if (family.husbandId == personId) {
        final spouse = findPerson(family.wifeId ?? '');
        if (spouse != null) spouses.add(spouse);
      } else if (family.wifeId == personId) {
        final spouse = findPerson(family.husbandId ?? '');
        if (spouse != null) spouses.add(spouse);
      }
    }
    return spouses;
  }

  /// Получить все семьи, где участвует человек
  List<Family> getFamiliesForPerson(String personId) {
    return families
        .where(
          (f) =>
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
  List<Object?> get props => [rootPerson, allPersons, families];
}
