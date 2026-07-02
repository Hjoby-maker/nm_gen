import 'package:equatable/equatable.dart';
import 'package:nm_gen/domain/entities/person.dart';

// ============================================================
// БАЗОВЫЕ СОБЫТИЯ
// ============================================================

abstract class PersonEvent extends Equatable {
  const PersonEvent();

  @override
  List<Object?> get props => [];
}

class LoadPersonsEvent extends PersonEvent {
  final String? treeId;

  const LoadPersonsEvent({this.treeId});

  @override
  List<Object?> get props => [treeId];
}

class AddPersonEvent extends PersonEvent {
  final Person person;
  final String? treeId;

  const AddPersonEvent(this.person, {this.treeId});

  @override
  List<Object?> get props => [person, treeId];
}

class UpdatePersonEvent extends PersonEvent {
  final Person person;
  final String? treeId;

  const UpdatePersonEvent(this.person, {this.treeId});

  @override
  List<Object?> get props => [person, treeId];
}

class DeletePersonEvent extends PersonEvent {
  final String personId;
  final String? treeId;

  const DeletePersonEvent(this.personId, {this.treeId});

  @override
  List<Object?> get props => [personId, treeId];
}

class DeleteAllPersonsEvent extends PersonEvent {
  final String? treeId;

  const DeleteAllPersonsEvent({this.treeId});

  @override
  List<Object?> get props => [treeId];
}

class SearchPersonsEvent extends PersonEvent {
  final String query;
  final String? treeId;

  const SearchPersonsEvent(this.query, {this.treeId});

  @override
  List<Object?> get props => [query, treeId];
}

class ClearSearchEvent extends PersonEvent {
  const ClearSearchEvent();
}

class SelectPersonEvent extends PersonEvent {
  final String personId;
  final String? treeId;

  const SelectPersonEvent(this.personId, {this.treeId});

  @override
  List<Object?> get props => [personId, treeId];
}
