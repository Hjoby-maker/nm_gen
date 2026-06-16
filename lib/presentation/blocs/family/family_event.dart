import 'package:equatable/equatable.dart';
import 'package:nm_gen/domain/entities/family.dart';

abstract class FamilyEvent extends Equatable {
  const FamilyEvent();

  @override
  List<Object?> get props => [];
}

/// Загрузить семьи человека
class LoadFamiliesEvent extends FamilyEvent {
  final String personId;
  const LoadFamiliesEvent(this.personId);

  @override
  List<Object?> get props => [personId];
}

/// Загрузить детали семьи
class LoadFamilyDetailsEvent extends FamilyEvent {
  final String familyId;
  const LoadFamilyDetailsEvent(this.familyId);

  @override
  List<Object?> get props => [familyId];
}

/// Добавить семью
class AddFamilyEvent extends FamilyEvent {
  final Family family;
  const AddFamilyEvent(this.family);

  @override
  List<Object?> get props => [family];
}

/// Обновить семью
class UpdateFamilyEvent extends FamilyEvent {
  final Family family;
  const UpdateFamilyEvent(this.family);

  @override
  List<Object?> get props => [family];
}

/// Удалить семью
class DeleteFamilyEvent extends FamilyEvent {
  final String familyId;
  const DeleteFamilyEvent(this.familyId);

  @override
  List<Object?> get props => [familyId];
}

/// Добавить ребенка в семью
class AddChildToFamilyEvent extends FamilyEvent {
  final String familyId;
  final String childId;
  const AddChildToFamilyEvent(this.familyId, this.childId);

  @override
  List<Object?> get props => [familyId, childId];
}

/// Удалить ребенка из семьи
class RemoveChildFromFamilyEvent extends FamilyEvent {
  final String familyId;
  final String childId;
  const RemoveChildFromFamilyEvent(this.familyId, this.childId);

  @override
  List<Object?> get props => [familyId, childId];
}

/// Выбрать семью для просмотра
class SelectFamilyEvent extends FamilyEvent {
  final String familyId;
  const SelectFamilyEvent(this.familyId);

  @override
  List<Object?> get props => [familyId];
}
