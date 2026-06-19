import 'package:equatable/equatable.dart';
import 'package:nm_gen/domain/entities/family.dart';

abstract class FamilyEvent extends Equatable {
  const FamilyEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Загрузить семьи человека
class LoadFamiliesEvent extends FamilyEvent {
  const LoadFamiliesEvent(this.personId);
  final String personId;

  @override
  List<Object?> get props => <Object?>[personId];
}

/// Загрузить детали семьи
class LoadFamilyDetailsEvent extends FamilyEvent {
  const LoadFamilyDetailsEvent(this.familyId);
  final String familyId;

  @override
  List<Object?> get props => <Object?>[familyId];
}

/// Добавить семью
class AddFamilyEvent extends FamilyEvent {
  const AddFamilyEvent(this.family);
  final Family family;

  @override
  List<Object?> get props => <Object?>[family];
}

/// Обновить семью
class UpdateFamilyEvent extends FamilyEvent {
  const UpdateFamilyEvent(this.family);
  final Family family;

  @override
  List<Object?> get props => <Object?>[family];
}

/// Удалить семью
class DeleteFamilyEvent extends FamilyEvent {
  const DeleteFamilyEvent(this.familyId);
  final String familyId;

  @override
  List<Object?> get props => <Object?>[familyId];
}

/// Добавить ребенка в семью
class AddChildToFamilyEvent extends FamilyEvent {
  const AddChildToFamilyEvent(this.familyId, this.childId);
  final String familyId;
  final String childId;

  @override
  List<Object?> get props => <Object?>[familyId, childId];
}

/// Удалить ребенка из семьи
class RemoveChildFromFamilyEvent extends FamilyEvent {
  const RemoveChildFromFamilyEvent(this.familyId, this.childId);
  final String familyId;
  final String childId;

  @override
  List<Object?> get props => <Object?>[familyId, childId];
}

/// Выбрать семью для просмотра
class SelectFamilyEvent extends FamilyEvent {
  const SelectFamilyEvent(this.familyId);
  final String familyId;

  @override
  List<Object?> get props => <Object?>[familyId];
}
