import 'package:equatable/equatable.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/use_cases/family/get_family_with_details.dart';

abstract class FamilyState extends Equatable {
  const FamilyState();

  @override
  List<Object?> get props => <Object?>[];
}

class FamilyInitial extends FamilyState {}

class FamilyLoading extends FamilyState {}

/// Состояние со списком семей
class FamiliesLoaded extends FamilyState {
  const FamiliesLoaded({
    required this.families,
    this.persons = const {},
    this.selectedFamilyId,
  });
  final List<Family> families;
  final Map<String, Person> persons;
  final String? selectedFamilyId;

  Family? get selectedFamily {
    try {
      return families.firstWhere((Family f) => f.id == selectedFamilyId);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => <Object?>[families, persons, selectedFamilyId];
}

/// Состояние с деталями семьи
class FamilyDetailsLoaded extends FamilyState {
  const FamilyDetailsLoaded(this.details);
  final FamilyDetails details;

  @override
  List<Object?> get props => <Object?>[details];
}

class FamilyOperationSuccess extends FamilyState {
  const FamilyOperationSuccess(this.message);
  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

class FamilyError extends FamilyState {
  const FamilyError(this.message);
  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
