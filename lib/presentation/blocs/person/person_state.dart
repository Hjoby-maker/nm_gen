import 'package:equatable/equatable.dart';
import 'package:nm_gen/domain/entities/person.dart';

/// Базовое состояние Person
abstract class PersonState extends Equatable {
  const PersonState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Начальное состояние (пустое)
class PersonInitial extends PersonState {}

/// Состояние загрузки
class PersonLoading extends PersonState {}

/// Состояние успешной загрузки списка
class PersonsLoaded extends PersonState {
  const PersonsLoaded({
    required this.persons,
    this.isSearching = false,
    this.searchQuery,
    this.treeId, // <-- ДОБАВЛЯЕМ
  });
  final List<Person> persons;
  final bool isSearching;
  final String? searchQuery;
  final String? treeId; // <-- ДОБАВЛЯЕМ

  @override
  List<Object?> get props => <Object?>[
    persons,
    isSearching,
    searchQuery,
    treeId, // <-- ДОБАВЛЯЕМ
  ];
}

/// Состояние успешного добавления/обновления
class PersonOperationSuccess extends PersonState {
  const PersonOperationSuccess(this.message);
  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

/// Состояние ошибки
class PersonError extends PersonState {
  const PersonError(this.message);
  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
