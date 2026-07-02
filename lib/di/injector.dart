import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:nm_gen/data/datasources/local/database/db_helper.dart';
import 'package:nm_gen/data/datasources/local/family_local_datasource.dart';
import 'package:nm_gen/data/datasources/local/person_local_datasource.dart';
import 'package:nm_gen/data/datasources/local/project_local_datasource.dart';
import 'package:nm_gen/data/repositories/family_repository_impl.dart';
import 'package:nm_gen/data/repositories/person_repository_impl.dart';
import 'package:nm_gen/data/repositories/project_repository_impl.dart'; // <-- БЕЗ ПРЕФИКСА
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';
import 'package:nm_gen/domain/repositories/project_repository.dart';
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
import 'package:nm_gen/presentation/blocs/project/project_bloc.dart';
import 'package:nm_gen/presentation/blocs/tree/tree_bloc.dart';
import 'injector.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: r'$initGetIt',
  preferRelativeImports: true,
  asExtension: true,
)
void configureDependencies() => getIt.$initGetIt();

/// Вспомогательная функция для безопасной регистрации LazySingleton
void registerLazySingletonIfNotRegistered<T extends Object>(
  T Function() factory, {
  String? instanceName,
}) {
  if (!getIt.isRegistered<T>(instanceName: instanceName)) {
    getIt.registerLazySingleton<T>(factory, instanceName: instanceName);
  } else {
    print('⚠️ $T уже зарегистрирован как LazySingleton, пропускаем');
  }
}

/// Вспомогательная функция для безопасной регистрации Factory
void registerFactoryIfNotRegistered<T extends Object>(
  T Function() factory, {
  String? instanceName,
}) {
  if (!getIt.isRegistered<T>(instanceName: instanceName)) {
    getIt.registerFactory<T>(factory, instanceName: instanceName);
  } else {
    print('⚠️ $T уже зарегистрирован как Factory, пропускаем');
  }
}

/// Ручная регистрация Use Cases и BLoC
void registerUseCasesAndBlocs() {
  // ============================================================
  // 1. РЕГИСТРАЦИЯ DATA SOURCES (если не зарегистрированы injectable)
  // ============================================================
  registerLazySingletonIfNotRegistered<DatabaseHelper>(() => DatabaseHelper());

  registerLazySingletonIfNotRegistered<PersonLocalDataSource>(
    () => PersonLocalDataSource(getIt<DatabaseHelper>()),
  );

  registerLazySingletonIfNotRegistered<FamilyLocalDataSource>(
    () => FamilyLocalDataSource(getIt<DatabaseHelper>()),
  );

  registerLazySingletonIfNotRegistered<ProjectLocalDataSource>(
    () => ProjectLocalDataSource(getIt<DatabaseHelper>()),
  );

  // ============================================================
  // 2. РЕГИСТРАЦИЯ РЕПОЗИТОРИЕВ
  // ============================================================
  registerLazySingletonIfNotRegistered<PersonRepository>(
    () => PersonRepositoryImpl(getIt<PersonLocalDataSource>()),
  );

  registerLazySingletonIfNotRegistered<FamilyRepository>(
    () => FamilyRepositoryImpl(getIt<FamilyLocalDataSource>()),
  );

  // Строка 98 - теперь без префикса
  registerLazySingletonIfNotRegistered<ProjectRepository>(
    () => ProjectRepositoryImpl(getIt<ProjectLocalDataSource>()),
  );

  // ============================================================
  // 3. ПОЛУЧАЕМ РЕПОЗИТОРИИ ИЗ КОНТЕЙНЕРА
  // ============================================================
  final PersonRepository personRepo = getIt<PersonRepository>();
  final FamilyRepository familyRepo = getIt<FamilyRepository>();

  // ============================================================
  // 4. РЕГИСТРАЦИЯ USE CASES ДЛЯ PERSON
  // ============================================================
  registerFactoryIfNotRegistered<AddPersonUseCase>(
    () => AddPersonUseCase(personRepo),
  );
  registerFactoryIfNotRegistered<GetPersonUseCase>(
    () => GetPersonUseCase(personRepo),
  );
  registerFactoryIfNotRegistered<GetAllPersonsUseCase>(
    () => GetAllPersonsUseCase(personRepo),
  );
  registerFactoryIfNotRegistered<UpdatePersonUseCase>(
    () => UpdatePersonUseCase(personRepo),
  );
  registerFactoryIfNotRegistered<DeletePersonUseCase>(
    () => DeletePersonUseCase(personRepo),
  );
  registerFactoryIfNotRegistered<SearchPersonsUseCase>(
    () => SearchPersonsUseCase(personRepo),
  );

  // ============================================================
  // 5. РЕГИСТРАЦИЯ USE CASES ДЛЯ FAMILY
  // ============================================================
  registerFactoryIfNotRegistered<AddFamilyUseCase>(
    () => AddFamilyUseCase(familyRepo),
  );
  registerFactoryIfNotRegistered<AddChildToFamilyUseCase>(
    () => AddChildToFamilyUseCase(familyRepo),
  );
  registerFactoryIfNotRegistered<RemoveChildFromFamilyUseCase>(
    () => RemoveChildFromFamilyUseCase(familyRepo),
  );
  registerFactoryIfNotRegistered<GetFamiliesByPersonUseCase>(
    () => GetFamiliesByPersonUseCase(familyRepo),
  );
  registerFactoryIfNotRegistered<GetFamilyWithDetailsUseCase>(
    () => GetFamilyWithDetailsUseCase(
      familyRepository: familyRepo,
      personRepository: personRepo,
    ),
  );

  // ============================================================
  // 6. РЕГИСТРАЦИЯ USE CASES ДЛЯ GEDCOM
  // ============================================================
  registerFactoryIfNotRegistered<ImportGedcomUseCase>(
    () => ImportGedcomUseCase(
      personRepository: personRepo,
      familyRepository: familyRepo,
    ),
  );

  registerFactoryIfNotRegistered<ExportGedcomUseCase>(
    () => ExportGedcomUseCase(
      personRepository: personRepo,
      familyRepository: familyRepo,
    ),
  );

  // ============================================================
  // 7. РЕГИСТРАЦИЯ USE CASES ДЛЯ TREE
  // ============================================================
  registerFactoryIfNotRegistered<GetFamilyTreeUseCase>(
    () => GetFamilyTreeUseCase(
      personRepository: personRepo,
      familyRepository: familyRepo,
    ),
  );

  // ============================================================
  // 8. РЕГИСТРАЦИЯ BLOC (всегда Factory!)
  // ============================================================
  final getAllPersonsUseCase = getIt<GetAllPersonsUseCase>();
  final addPersonUseCase = getIt<AddPersonUseCase>();
  final updatePersonUseCase = getIt<UpdatePersonUseCase>();
  final deletePersonUseCase = getIt<DeletePersonUseCase>();
  final searchPersonsUseCase = getIt<SearchPersonsUseCase>();
  final getFamiliesByPersonUseCase = getIt<GetFamiliesByPersonUseCase>();
  final getFamilyWithDetailsUseCase = getIt<GetFamilyWithDetailsUseCase>();
  final addFamilyUseCase = getIt<AddFamilyUseCase>();
  final addChildToFamilyUseCase = getIt<AddChildToFamilyUseCase>();
  final removeChildFromFamilyUseCase = getIt<RemoveChildFromFamilyUseCase>();
  final getFamilyTreeUseCase = getIt<GetFamilyTreeUseCase>();

  registerFactoryIfNotRegistered<PersonBloc>(
    () => PersonBloc(
      getAllPersonsUseCase: getAllPersonsUseCase,
      addPersonUseCase: addPersonUseCase,
      updatePersonUseCase: updatePersonUseCase,
      deletePersonUseCase: deletePersonUseCase,
      searchPersonsUseCase: searchPersonsUseCase,
      familyRepository: familyRepo,
      personRepository: personRepo,
    ),
  );

  registerFactoryIfNotRegistered<TreeBloc>(
    () => TreeBloc(getFamilyTreeUseCase: getFamilyTreeUseCase),
  );

  registerFactoryIfNotRegistered<FamilyBloc>(
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

  // ============================================================
  // 9. РЕГИСТРАЦИЯ PROJECT BLOC
  // ============================================================
  registerFactoryIfNotRegistered<ProjectBloc>(() => ProjectBloc());
}
