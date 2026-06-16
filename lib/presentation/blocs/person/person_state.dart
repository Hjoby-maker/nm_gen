import 'package:equatable/equatable.dart';
import 'package:nm_gen/domain/entities/person.dart';

/// Базовое состояние Person
abstract class PersonState extends Equatable {
  const PersonState();

  @override
  List<Object?> get props => [];
}

/// Начальное состояние (пустое)
class PersonInitial extends PersonState {}

/// Состояние загрузки
class PersonLoading extends PersonState {}

/// Состояние успешной загрузки списка
class PersonsLoaded extends PersonState {
  final List<Person> persons;
  final bool isSearching;
  final String? searchQuery;

  const PersonsLoaded({
    required this.persons,
    this.isSearching = false,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [persons, isSearching, searchQuery];
}

/// Состояние успешного добавления/обновления
class PersonOperationSuccess extends PersonState {
  final String message;
  const PersonOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// Состояние ошибки
class PersonError extends PersonState {
  final String message;
  const PersonError(this.message);

  @override
  List<Object?> get props => [message];
}
