import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:nm_gen/data/datasources/local/database/db_helper.dart';
import 'package:nm_gen/data/datasources/local/family_local_datasource.dart';
import 'package:nm_gen/data/datasources/local/person_local_datasource.dart';
import 'package:nm_gen/data/repositories/family_repository_impl.dart';
import 'package:nm_gen/data/repositories/person_repository_impl.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';
import 'package:nm_gen/domain/use_cases/family/add_child_to_family.dart';
import 'package:nm_gen/domain/use_cases/family/add_family.dart';
import 'package:nm_gen/domain/use_cases/family/get_families_by_person.dart';
import 'package:nm_gen/domain/use_cases/family/get_family_with_details.dart';
import 'package:nm_gen/domain/use_cases/family/remove_child_from_family.dart';
import 'package:nm_gen/domain/use_cases/gedcom/export_gedcom.dart';
import 'package:nm_gen/domain/use_cases/gedcom/import_gedcom.dart';
import 'package:nm_gen/domain/use_cases/person/add_person.dart';
import 'package:nm_gen/domain/use_cases/person/delete_person.dart';
import 'package:nm_gen/domain/use_cases/person/get_all_persons.dart';
import 'package:nm_gen/domain/use_cases/person/get_person.dart';
import 'package:nm_gen/domain/use_cases/person/search_persons.dart';
import 'package:nm_gen/domain/use_cases/person/update_person.dart';
import 'package:nm_gen/domain/use_cases/tree/get_family_tree.dart';
import 'package:nm_gen/presentation/blocs/family/family_bloc.dart';
import 'package:nm_gen/presentation/blocs/person/person_bloc.dart';
import 'package:nm_gen/presentation/blocs/tree/tree_bloc.dart';
import 'injector.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: r'$initGetIt',
  preferRelativeImports: true,
  asExtension: true,
)
void configureDependencies() => getIt.$initGetIt();

/// Ручная регистрация Use Cases и BLoC
void registerUseCasesAndBlocs() {
  // Регистрируем Database Helper как синглтон
  getIt.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());

  // Регистрируем Local Data Sources
  getIt.registerLazySingleton<PersonLocalDataSource>(
    () => PersonLocalDataSource(getIt<DatabaseHelper>()),
  );
  getIt.registerLazySingleton<FamilyLocalDataSource>(
    () => FamilyLocalDataSource(getIt<DatabaseHelper>()),
  );

  // ============================================================
  // РЕГИСТРАЦИЯ РЕПОЗИТОРИЕВ
  // ============================================================
  // Регистрируем PersonRepository - передаем как позиционный аргумент
  getIt.registerLazySingleton<PersonRepository>(
    () => PersonRepositoryImpl(
      getIt<PersonLocalDataSource>(), // <-- позиционный аргумент
    ),
  );

  // Регистрируем FamilyRepository - передаем как позиционный аргумент
  getIt.registerLazySingleton<FamilyRepository>(
    () => FamilyRepositoryImpl(
      getIt<FamilyLocalDataSource>(), // <-- позиционный аргумент
    ),
  );

  // Получаем репозитории из контейнера
  final PersonRepository personRepo = getIt<PersonRepository>();
  final FamilyRepository familyRepo = getIt<FamilyRepository>();

  // ============================================================
  // РЕГИСТРАЦИЯ USE CASES ДЛЯ PERSON
  // ============================================================
  final AddPersonUseCase addPersonUseCase = AddPersonUseCase(personRepo);
  final GetPersonUseCase getPersonUseCase = GetPersonUseCase(personRepo);
  final GetAllPersonsUseCase getAllPersonsUseCase = GetAllPersonsUseCase(
    personRepo,
  );
  final UpdatePersonUseCase updatePersonUseCase = UpdatePersonUseCase(
    personRepo,
  );
  final DeletePersonUseCase deletePersonUseCase = DeletePersonUseCase(
    personRepo,
  );
  final SearchPersonsUseCase searchPersonsUseCase = SearchPersonsUseCase(
    personRepo,
  );

  getIt.registerLazySingleton(() => addPersonUseCase);
  getIt.registerLazySingleton(() => getPersonUseCase);
  getIt.registerLazySingleton(() => getAllPersonsUseCase);
  getIt.registerLazySingleton(() => updatePersonUseCase);
  getIt.registerLazySingleton(() => deletePersonUseCase);
  getIt.registerLazySingleton(() => searchPersonsUseCase);

  // ============================================================
  // РЕГИСТРАЦИЯ USE CASES ДЛЯ FAMILY
  // ============================================================
  final AddFamilyUseCase addFamilyUseCase = AddFamilyUseCase(familyRepo);
  final AddChildToFamilyUseCase addChildToFamilyUseCase =
      AddChildToFamilyUseCase(familyRepo);
  final RemoveChildFromFamilyUseCase removeChildFromFamilyUseCase =
      RemoveChildFromFamilyUseCase(familyRepo);
  final GetFamiliesByPersonUseCase getFamiliesByPersonUseCase =
      GetFamiliesByPersonUseCase(familyRepo);
  final GetFamilyWithDetailsUseCase getFamilyWithDetailsUseCase =
      GetFamilyWithDetailsUseCase(
        familyRepository: familyRepo,
        personRepository: personRepo,
      );

  getIt.registerLazySingleton(() => addFamilyUseCase);
  getIt.registerLazySingleton(() => addChildToFamilyUseCase);
  getIt.registerLazySingleton(() => removeChildFromFamilyUseCase);
  getIt.registerLazySingleton(() => getFamiliesByPersonUseCase);
  getIt.registerLazySingleton(() => getFamilyWithDetailsUseCase);

  // ============================================================
  // РЕГИСТРАЦИЯ USE CASES ДЛЯ GEDCOM
  // ============================================================
  final ImportGedcomUseCase importGedcomUseCase = ImportGedcomUseCase(
    personRepository: personRepo,
    familyRepository: familyRepo,
  );
  getIt.registerLazySingleton(() => importGedcomUseCase);

  final ExportGedcomUseCase exportGedcomUseCase = ExportGedcomUseCase(
    personRepository: personRepo,
    familyRepository: familyRepo,
  );
  getIt.registerLazySingleton(() => exportGedcomUseCase);

  // ============================================================
  // РЕГИСТРАЦИЯ USE CASES ДЛЯ TREE
  // ============================================================
  final GetFamilyTreeUseCase getFamilyTreeUseCase = GetFamilyTreeUseCase(
    personRepository: personRepo,
    familyRepository: familyRepo,
  );
  getIt.registerLazySingleton(() => getFamilyTreeUseCase);

  // ============================================================
  // РЕГИСТРАЦИЯ BLOC
  // ============================================================
  getIt.registerFactory<PersonBloc>(
    () => PersonBloc(
      getAllPersonsUseCase: getAllPersonsUseCase,
      addPersonUseCase: addPersonUseCase,
      updatePersonUseCase: updatePersonUseCase,
      deletePersonUseCase: deletePersonUseCase,
      searchPersonsUseCase: searchPersonsUseCase,
    ),
  );

  getIt.registerFactory<TreeBloc>(
    () => TreeBloc(getFamilyTreeUseCase: getFamilyTreeUseCase),
  );

  getIt.registerFactory<FamilyBloc>(
    () => FamilyBloc(
      getFamiliesByPersonUseCase: getFamiliesByPersonUseCase,
      getFamilyWithDetailsUseCase: getFamilyWithDetailsUseCase,
      addFamilyUseCase: addFamilyUseCase,
      addChildToFamilyUseCase: addChildToFamilyUseCase,
      removeChildFromFamilyUseCase: removeChildFromFamilyUseCase,
      personRepository: personRepo,
      familyRepository: familyRepo,
    ),
  );
}
