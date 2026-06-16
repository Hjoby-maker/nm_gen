import 'package:equatable/equatable.dart';
import 'package:nm_gen/domain/entities/family_tree.dart';
import 'package:nm_gen/domain/entities/person.dart';

/// Базовое состояние Tree
abstract class TreeState extends Equatable {
  const TreeState();

  @override
  List<Object?> get props => [];
}

/// Начальное состояние
class TreeInitial extends TreeState {}

/// Состояние загрузки
class TreeLoading extends TreeState {}

/// Состояние с загруженным древом
class TreeLoaded extends TreeState {
  final FamilyTree familyTree;
  final String rootPersonId;

  const TreeLoaded({required this.familyTree, required this.rootPersonId});

  /// Получить корневого человека
  Person get rootPerson => familyTree.rootPerson;

  /// Получить всех людей в древе
  List<Person> get allPersons => familyTree.allPersons;

  /// Получить количество людей
  int get personCount => familyTree.personCount;

  /// Получить количество семей
  int get familyCount => familyTree.familyCount;

  @override
  List<Object?> get props => [familyTree, rootPersonId];
}

/// Состояние ошибки
class TreeError extends TreeState {
  final String message;
  const TreeError(this.message);

  @override
  List<Object?> get props => [message];
}
