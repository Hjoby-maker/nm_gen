import 'package:equatable/equatable.dart';
import 'package:nm_gen/domain/entities/family.dart';

abstract class FamilyEvent extends Equatable {
  const FamilyEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Загрузить семьи человека
class LoadFamiliesEvent extends FamilyEvent {
  const LoadFamiliesEvent(this.personId, {this.treeId});
  final String personId;
  final String? treeId; // <-- ДОБАВЛЯЕМ

  @override
  List<Object?> get props => <Object?>[personId, treeId];
}

/// Загрузить детали семьи
class LoadFamilyDetailsEvent extends FamilyEvent {
  const LoadFamilyDetailsEvent(this.familyId, {this.treeId});
  final String familyId;
  final String? treeId; // <-- ДОБАВЛЯЕМ

  @override
  List<Object?> get props => <Object?>[familyId, treeId];
}

/// Добавить семью
class AddFamilyEvent extends FamilyEvent {
  const AddFamilyEvent(this.family, {this.treeId});
  final Family family;
  final String? treeId; // <-- ДОБАВЛЯЕМ

  @override
  List<Object?> get props => <Object?>[family, treeId];
}

/// Обновить семью
class UpdateFamilyEvent extends FamilyEvent {
  const UpdateFamilyEvent(this.family, {this.treeId});
  final Family family;
  final String? treeId; // <-- ДОБАВЛЯЕМ

  @override
  List<Object?> get props => <Object?>[family, treeId];
}

/// Удалить семью
class DeleteFamilyEvent extends FamilyEvent {
  const DeleteFamilyEvent(this.familyId, {this.treeId});
  final String familyId;
  final String? treeId; // <-- ДОБАВЛЯЕМ

  @override
  List<Object?> get props => <Object?>[familyId, treeId];
}

/// Добавить ребенка в семью
class AddChildToFamilyEvent extends FamilyEvent {
  const AddChildToFamilyEvent(this.familyId, this.childId, {this.treeId});
  final String familyId;
  final String childId;
  final String? treeId; // <-- ДОБАВЛЯЕМ

  @override
  List<Object?> get props => <Object?>[familyId, childId, treeId];
}

/// Удалить ребенка из семьи
class RemoveChildFromFamilyEvent extends FamilyEvent {
  const RemoveChildFromFamilyEvent(this.familyId, this.childId, {this.treeId});
  final String familyId;
  final String childId;
  final String? treeId; // <-- ДОБАВЛЯЕМ

  @override
  List<Object?> get props => <Object?>[familyId, childId, treeId];
}

/// Выбрать семью для просмотра
class SelectFamilyEvent extends FamilyEvent {
  const SelectFamilyEvent(this.familyId, {this.treeId});
  final String familyId;
  final String? treeId; // <-- ДОБАВЛЯЕМ

  @override
  List<Object?> get props => <Object?>[familyId, treeId];
}
