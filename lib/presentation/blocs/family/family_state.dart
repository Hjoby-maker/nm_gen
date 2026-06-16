import 'package:equatable/equatable.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/use_cases/family/get_family_with_details.dart';

abstract class FamilyState extends Equatable {
  const FamilyState();

  @override
  List<Object?> get props => [];
}

class FamilyInitial extends FamilyState {}

class FamilyLoading extends FamilyState {}

/// Состояние со списком семей
class FamiliesLoaded extends FamilyState {
  final List<Family> families;
  final Map<String, Person> persons;
  final String? selectedFamilyId;

  const FamiliesLoaded({
    required this.families,
    this.persons = const {},
    this.selectedFamilyId,
  });

  Family? get selectedFamily {
    try {
      return families.firstWhere((f) => f.id == selectedFamilyId);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [families, persons, selectedFamilyId];
}

/// Состояние с деталями семьи
class FamilyDetailsLoaded extends FamilyState {
  final FamilyDetails details;

  const FamilyDetailsLoaded(this.details);

  @override
  List<Object?> get props => [details];
}

class FamilyOperationSuccess extends FamilyState {
  final String message;
  const FamilyOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class FamilyError extends FamilyState {
  final String message;
  const FamilyError(this.message);

  @override
  List<Object?> get props => [message];
}
