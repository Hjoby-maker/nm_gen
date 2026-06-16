import 'package:equatable/equatable.dart';
import 'package:nm_gen/domain/entities/person.dart';

/// Базовый класс для всех событий Person
abstract class PersonEvent extends Equatable {
  const PersonEvent();

  @override
  List<Object?> get props => [];
}

/// Событие: Загрузить всех людей
class LoadPersonsEvent extends PersonEvent {
  const LoadPersonsEvent(); // <-- Добавляем const

  @override
  List<Object?> get props => [];
}

/// Событие: Добавить человека
class AddPersonEvent extends PersonEvent {
  final Person person;
  const AddPersonEvent(this.person); // <-- Добавляем const

  @override
  List<Object?> get props => [person];
}

/// Событие: Обновить человека
class UpdatePersonEvent extends PersonEvent {
  final Person person;
  const UpdatePersonEvent(this.person); // <-- Добавляем const

  @override
  List<Object?> get props => [person];
}

/// Событие: Удалить человека
class DeletePersonEvent extends PersonEvent {
  final String personId;
  const DeletePersonEvent(this.personId); // <-- Добавляем const

  @override
  List<Object?> get props => [personId];
}

/// Событие: Поиск людей
class SearchPersonsEvent extends PersonEvent {
  final String query;
  const SearchPersonsEvent(this.query); // <-- Добавляем const

  @override
  List<Object?> get props => [query];
}

/// Событие: Очистить поиск
class ClearSearchEvent extends PersonEvent {
  const ClearSearchEvent(); // <-- Добавляем const

  @override
  List<Object?> get props => [];
}
