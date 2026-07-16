import 'package:equatable/equatable.dart';
import 'package:nm_gen/domain/entities/person.dart';

// ============================================================
// БАЗОВЫЕ СОБЫТИЯ
// ============================================================

abstract class PersonEvent extends Equatable {
  const PersonEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class LoadPersonsEvent extends PersonEvent {
  const LoadPersonsEvent({this.treeId});
  final String? treeId;

  @override
  List<Object?> get props => <Object?>[treeId];
}

class AddPersonEvent extends PersonEvent {
  const AddPersonEvent(this.person, {this.treeId});
  final Person person;
  final String? treeId;

  @override
  List<Object?> get props => <Object?>[person, treeId];
}

class UpdatePersonEvent extends PersonEvent {
  const UpdatePersonEvent(this.person, {this.treeId});
  final Person person;
  final String? treeId;

  @override
  List<Object?> get props => <Object?>[person, treeId];
}

class DeletePersonEvent extends PersonEvent {
  const DeletePersonEvent(this.personId, {this.treeId});
  final String personId;
  final String? treeId;

  @override
  List<Object?> get props => <Object?>[personId, treeId];
}

class DeleteAllPersonsEvent extends PersonEvent {
  const DeleteAllPersonsEvent({this.treeId});
  final String? treeId;

  @override
  List<Object?> get props => <Object?>[treeId];
}

class SearchPersonsEvent extends PersonEvent {
  const SearchPersonsEvent(this.query, {this.treeId});
  final String query;
  final String? treeId;

  @override
  List<Object?> get props => <Object?>[query, treeId];
}

class ClearSearchEvent extends PersonEvent {
  const ClearSearchEvent();
}

class SelectPersonEvent extends PersonEvent {
  const SelectPersonEvent(this.personId, {this.treeId});
  final String personId;
  final String? treeId;

  @override
  List<Object?> get props => <Object?>[personId, treeId];
}
