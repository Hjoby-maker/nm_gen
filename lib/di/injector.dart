// lib/di/injector.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:nm_gen/core/utils/file_storage_service.dart';
import 'package:nm_gen/core/utils/thumbnail_generator.dart';
import 'package:nm_gen/data/datasources/local/database/db_helper.dart';
import 'package:nm_gen/data/datasources/local/event_local_datasource.dart';
import 'package:nm_gen/data/datasources/local/family_local_datasource.dart';
import 'package:nm_gen/data/datasources/local/media_local_datasource.dart';
import 'package:nm_gen/data/datasources/local/person_local_datasource.dart';
import 'package:nm_gen/data/datasources/local/project_local_datasource.dart';
import 'package:nm_gen/data/repositories/event_repository_impl.dart';
import 'package:nm_gen/data/repositories/family_repository_impl.dart';
import 'package:nm_gen/data/repositories/media_repository_impl.dart';
import 'package:nm_gen/data/repositories/person_repository_impl.dart';
import 'package:nm_gen/data/repositories/project_repository_impl.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/repositories/media_repository.dart';
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
import 'package:nm_gen/domain/use_cases/person/sync_person_events.dart';
import 'package:nm_gen/domain/use_cases/person/update_person.dart';
import 'package:nm_gen/domain/use_cases/tree/get_family_tree.dart';
import 'package:nm_gen/domain/use_cases/tree/get_full_tree.dart';
import 'package:nm_gen/presentation/blocs/event/event_bloc.dart';
import 'package:nm_gen/presentation/blocs/family/family_bloc.dart';
import 'package:nm_gen/presentation/blocs/media/media_bloc.dart';
import 'package:nm_gen/presentation/blocs/person/person_bloc.dart';
import 'package:nm_gen/presentation/blocs/project/project_bloc.dart';
import 'package:nm_gen/presentation/blocs/tree/tree_bloc.dart';
// Импорты Use Cases для Event ← ДОБАВЛЯЕМ
import 'package:nm_gen/domain/use_cases/event/add_event.dart';
import 'package:nm_gen/domain/use_cases/event/get_events_by_person.dart';
import 'package:nm_gen/domain/use_cases/event/get_all_events.dart';
import 'package:nm_gen/domain/use_cases/event/update_event.dart';
import 'package:nm_gen/domain/use_cases/event/delete_event.dart';
import 'package:nm_gen/domain/use_cases/event/delete_all_person_events.dart';
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
  // 1. РЕГИСТРАЦИЯ DATA SOURCES
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

  registerLazySingletonIfNotRegistered<EventLocalDataSource>(
    () => EventLocalDataSource(getIt<DatabaseHelper>()),
  );

  // ============================================================
  // 2. РЕГИСТРАЦИЯ СЕРВИСОВ
  // ============================================================
  registerLazySingletonIfNotRegistered<FileStorageService>(
    () => FileStorageService(),
  );

  registerLazySingletonIfNotRegistered<ThumbnailGenerator>(
    () => ThumbnailGenerator(),
  );

  // ============================================================
  // 3. РЕГИСТРАЦИЯ MEDIA DATA SOURCE
  // ============================================================
  registerLazySingletonIfNotRegistered<MediaLocalDataSource>(
    () => MediaLocalDataSourceImpl(getIt<DatabaseHelper>()),
  );

  // ============================================================
  // 4. РЕГИСТРАЦИЯ РЕПОЗИТОРИЕВ
  // ============================================================
  registerLazySingletonIfNotRegistered<PersonRepository>(
    () => PersonRepositoryImpl(getIt<PersonLocalDataSource>()),
  );

  registerLazySingletonIfNotRegistered<FamilyRepository>(
    () => FamilyRepositoryImpl(getIt<FamilyLocalDataSource>()),
  );

  registerLazySingletonIfNotRegistered<ProjectRepository>(
    () => ProjectRepositoryImpl(getIt<ProjectLocalDataSource>()),
  );

  registerLazySingletonIfNotRegistered<EventRepository>(
    () => EventRepositoryImpl(getIt<EventLocalDataSource>()),
  );

  // ============================================================
  // 5. РЕГИСТРАЦИЯ MEDIA REPOSITORY
  // ============================================================
  registerLazySingletonIfNotRegistered<MediaRepository>(
    () => MediaRepositoryImpl(
      getIt<MediaLocalDataSource>(),
      getIt<FileStorageService>(),
    ),
  );

  // ============================================================
  // 6. РЕГИСТРАЦИЯ USE CASE SyncPersonEventsUseCase
  // ============================================================
  registerFactoryIfNotRegistered<SyncPersonEventsUseCase>(
    () => SyncPersonEventsUseCase(getIt<EventRepository>()),
  );

  // ============================================================
  // 7. ПОЛУЧАЕМ РЕПОЗИТОРИИ ИЗ КОНТЕЙНЕРА
  // ============================================================
  final PersonRepository personRepo = getIt<PersonRepository>();
  final FamilyRepository familyRepo = getIt<FamilyRepository>();
  final MediaRepository mediaRepo = getIt<MediaRepository>();

  // ============================================================
  // 8. РЕГИСТРАЦИЯ USE CASES ДЛЯ PERSON
  // ============================================================
  registerFactoryIfNotRegistered<AddPersonUseCase>(
    () => AddPersonUseCase(personRepo, getIt<SyncPersonEventsUseCase>()),
  );

  registerFactoryIfNotRegistered<GetPersonUseCase>(
    () => GetPersonUseCase(personRepo),
  );

  registerFactoryIfNotRegistered<GetAllPersonsUseCase>(
    () => GetAllPersonsUseCase(personRepo),
  );

  registerFactoryIfNotRegistered<UpdatePersonUseCase>(
    () => UpdatePersonUseCase(personRepo, getIt<SyncPersonEventsUseCase>()),
  );

  registerFactoryIfNotRegistered<DeletePersonUseCase>(
    () => DeletePersonUseCase(personRepo),
  );

  registerFactoryIfNotRegistered<SearchPersonsUseCase>(
    () => SearchPersonsUseCase(personRepo),
  );

  // ============================================================
  // 9. РЕГИСТРАЦИЯ USE CASES ДЛЯ FAMILY
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
  // 10. РЕГИСТРАЦИЯ USE CASES ДЛЯ GEDCOM
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
  // 11. РЕГИСТРАЦИЯ USE CASES ДЛЯ TREE
  // ============================================================
  registerFactoryIfNotRegistered<GetFamilyTreeUseCase>(
    () => GetFamilyTreeUseCase(
      personRepository: personRepo,
      familyRepository: familyRepo,
    ),
  );

  registerFactoryIfNotRegistered<GetFullTreeUseCase>(
    () => GetFullTreeUseCase(
      personRepository: personRepo,
      familyRepository: familyRepo,
    ),
  );

  // ============================================================
  // 12. РЕГИСТРАЦИЯ USE CASES ДЛЯ MEDIA
  // ============================================================
  // Здесь можно добавить use cases для медиа, если они понадобятся
  // Например:
  // registerFactoryIfNotRegistered<AddMediaUseCase>(
  //   () => AddMediaUseCase(mediaRepo),
  // );
  // registerFactoryIfNotRegistered<GetMediaForPersonUseCase>(
  //   () => GetMediaForPersonUseCase(mediaRepo),
  // );
  // registerFactoryIfNotRegistered<DeleteMediaUseCase>(
  //   () => DeleteMediaUseCase(mediaRepo),
  // );

  // ============================================================
  // РЕГИСТРАЦИЯ USE CASES ДЛЯ EVENT
  // ============================================================
  registerFactoryIfNotRegistered<AddEventUseCase>(
    () => AddEventUseCase(getIt<EventRepository>()),
  );

  registerFactoryIfNotRegistered<GetEventsByPersonUseCase>(
    () => GetEventsByPersonUseCase(getIt<EventRepository>()),
  );

  registerFactoryIfNotRegistered<GetAllEventsUseCase>(
    () => GetAllEventsUseCase(getIt<EventRepository>()),
  );

  registerFactoryIfNotRegistered<UpdateEventUseCase>(
    () => UpdateEventUseCase(getIt<EventRepository>()),
  );

  registerFactoryIfNotRegistered<DeleteEventUseCase>(
    () => DeleteEventUseCase(getIt<EventRepository>()),
  );

  registerFactoryIfNotRegistered<DeleteAllPersonEventsUseCase>(
    () => DeleteAllPersonEventsUseCase(getIt<EventRepository>()),
  );

  // ============================================================
  // 13. РЕГИСТРАЦИЯ BLOC
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

  registerFactoryIfNotRegistered<TreeBloc>(() => TreeBloc());

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
  // 14. РЕГИСТРАЦИЯ MEDIA BLOC
  // ============================================================
  registerFactoryIfNotRegistered<MediaBloc>(() => MediaBloc(mediaRepo));

  // ============================================================
  // 15. РЕГИСТРАЦИЯ PROJECT BLOC
  // ============================================================
  registerFactoryIfNotRegistered<ProjectBloc>(() => ProjectBloc());

  // ============================================================
  // 16. РЕГИСТРАЦИЯ EVENT BLOC
  // ============================================================
  registerFactoryIfNotRegistered<EventBloc>(() => EventBloc());
}
