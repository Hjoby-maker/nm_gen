import 'package:equatable/equatable.dart';
import 'package:nm_gen/domain/entities/person.dart';

/// Базовый класс для всех событий Person
abstract class PersonEvent extends Equatable {
  const PersonEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Событие: Загрузить всех людей
class LoadPersonsEvent extends PersonEvent {
  const LoadPersonsEvent(); // <-- Добавляем const

  @override
  List<Object?> get props => <Object?>[];
}

/// Событие: Добавить человека
class AddPersonEvent extends PersonEvent {
  const AddPersonEvent(this.person);
  final Person person; // <-- Добавляем const

  @override
  List<Object?> get props => <Object?>[person];
}

/// Событие: Обновить человека
class UpdatePersonEvent extends PersonEvent {
  const UpdatePersonEvent(this.person);
  final Person person; // <-- Добавляем const

  @override
  List<Object?> get props => <Object?>[person];
}

/// Событие: Удалить человека
class DeletePersonEvent extends PersonEvent {
  const DeletePersonEvent(this.personId);
  final String personId; // <-- Добавляем const

  @override
  List<Object?> get props => <Object?>[personId];
}

/// Событие: Поиск людей
class SearchPersonsEvent extends PersonEvent {
  const SearchPersonsEvent(this.query);
  final String query; // <-- Добавляем const

  @override
  List<Object?> get props => <Object?>[query];
}

/// Событие: Очистить поиск
class ClearSearchEvent extends PersonEvent {
  const ClearSearchEvent(); // <-- Добавляем const

  @override
  List<Object?> get props => <Object?>[];
}

/// Событие: Удалить всех людей
class DeleteAllPersonsEvent extends PersonEvent {
  const DeleteAllPersonsEvent();

  @override
  List<Object?> get props => [];
}
