import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:nm_gen/data/datasources/local/database/db_helper.dart';
import 'package:nm_gen/data/datasources/local/family_local_datasource.dart';
import 'package:nm_gen/data/datasources/local/person_local_datasource.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';
import 'package:nm_gen/domain/use_cases/family/add_child_to_family.dart';
import 'package:nm_gen/domain/use_cases/family/add_family.dart';
import 'package:nm_gen/domain/use_cases/family/get_families_by_person.dart';
import 'package:nm_gen/domain/use_cases/family/remove_child_from_family.dart'; // <-- Добавляем импорт
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
import 'package:nm_gen/domain/use_cases/family/get_family_with_details.dart';
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

  // Регистрируем репозитории (уже зарегистрированы через @Injectable аннотации)
  // Получаем репозитории из контейнера
  final personRepo = getIt<PersonRepository>();
  final familyRepo = getIt<FamilyRepository>();

  // Регистрируем Use Cases для Person
  final addPersonUseCase = AddPersonUseCase(personRepo);
  final getPersonUseCase = GetPersonUseCase(personRepo);
  final getAllPersonsUseCase = GetAllPersonsUseCase(personRepo);
  final updatePersonUseCase = UpdatePersonUseCase(personRepo);
  final deletePersonUseCase = DeletePersonUseCase(personRepo);
  final searchPersonsUseCase = SearchPersonsUseCase(personRepo);

  getIt.registerLazySingleton(() => addPersonUseCase);
  getIt.registerLazySingleton(() => getPersonUseCase);
  getIt.registerLazySingleton(() => getAllPersonsUseCase);
  getIt.registerLazySingleton(() => updatePersonUseCase);
  getIt.registerLazySingleton(() => deletePersonUseCase);
  getIt.registerLazySingleton(() => searchPersonsUseCase);

  // Регистрируем Use Cases для Family
  final addFamilyUseCase = AddFamilyUseCase(familyRepo);
  final addChildToFamilyUseCase = AddChildToFamilyUseCase(familyRepo);
  final removeChildFromFamilyUseCase = RemoveChildFromFamilyUseCase(
    familyRepo,
  ); // <-- Добавляем
  final getFamiliesByPersonUseCase = GetFamiliesByPersonUseCase(familyRepo);

  getIt.registerLazySingleton(() => addFamilyUseCase);
  getIt.registerLazySingleton(() => addChildToFamilyUseCase);
  getIt.registerLazySingleton(
    () => removeChildFromFamilyUseCase,
  ); // <-- Регистрируем
  getIt.registerLazySingleton(() => getFamiliesByPersonUseCase);

  // Регистрируем Use Case для Tree
  final getFamilyTreeUseCase = GetFamilyTreeUseCase(
    personRepository: personRepo,
    familyRepository: familyRepo,
  );
  getIt.registerLazySingleton(() => getFamilyTreeUseCase);

  // Регистрируем BLoC
  getIt.registerFactory(
    () => PersonBloc(
      getAllPersonsUseCase: getAllPersonsUseCase,
      addPersonUseCase: addPersonUseCase,
      updatePersonUseCase: updatePersonUseCase,
      deletePersonUseCase: deletePersonUseCase,
      searchPersonsUseCase: searchPersonsUseCase,
    ),
  );

  getIt.registerFactory(
    () => TreeBloc(getFamilyTreeUseCase: getFamilyTreeUseCase),
  );

  final getFamilyWithDetailsUseCase = GetFamilyWithDetailsUseCase(
    familyRepository: familyRepo,
    personRepository: personRepo,
  );
  getIt.registerLazySingleton(() => getFamilyWithDetailsUseCase);

  // Регистрируем FamilyBloc
  getIt.registerFactory(
    () => FamilyBloc(
      getFamiliesByPersonUseCase: getFamiliesByPersonUseCase,
      getFamilyWithDetailsUseCase: getFamilyWithDetailsUseCase, // <-- Добавляем
      addFamilyUseCase: addFamilyUseCase,
      addChildToFamilyUseCase: addChildToFamilyUseCase,
      removeChildFromFamilyUseCase: removeChildFromFamilyUseCase,
      personRepository: personRepo,
      familyRepository: familyRepo, // <-- Добавляем
    ),
  );
}
