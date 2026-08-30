// lib/domain/entities/person_relatives.dart
import 'package:equatable/equatable.dart';

import 'person.dart';

/// Ближайшее родственное окружение человека: родители, супруг(и), дети и
/// братья/сёстры. Используется HUD-компасом на экране деталей человека
/// (person_relatives_compass.dart) - каждая категория рисуется в своей
/// зоне экрана, поэтому важно, чтобы списки были уже разделены по типу
/// родства, а не свалены в одну кучу.
class PersonRelatives extends Equatable {
  const PersonRelatives({
    this.parents = const <Person>[],
    this.spouses = const <Person>[],
    this.children = const <Person>[],
    this.siblings = const <Person>[],
  });

  final List<Person> parents;
  final List<Person> spouses;
  final List<Person> children;
  final List<Person> siblings;

  bool get isEmpty =>
      parents.isEmpty &&
      spouses.isEmpty &&
      children.isEmpty &&
      siblings.isEmpty;

  static const PersonRelatives empty = PersonRelatives();

  @override
  List<Object?> get props => <Object?>[parents, spouses, children, siblings];
}