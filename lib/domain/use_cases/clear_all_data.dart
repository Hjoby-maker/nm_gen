import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';
import 'package:nm_gen/domain/repositories/media_repository.dart';
import 'package:nm_gen/domain/repositories/project_repository.dart';

/// Use Case: Полная очистка всех данных приложения
class ClearAllDataUseCase {
  final PersonRepository _personRepository;
  final FamilyRepository _familyRepository;
  final EventRepository _eventRepository;
  final MediaRepository _mediaRepository;
  final ProjectRepository _projectRepository;

  ClearAllDataUseCase({
    required PersonRepository personRepository,
    required FamilyRepository familyRepository,
    required EventRepository eventRepository,
    required MediaRepository mediaRepository,
    required ProjectRepository projectRepository,
  }) : _personRepository = personRepository,
       _familyRepository = familyRepository,
       _eventRepository = eventRepository,
       _mediaRepository = mediaRepository,
       _projectRepository = projectRepository;

  Future<Either<Failure, Unit>> execute() async {
    print('🔄 [ClearAllData] Начало очистки данных...');

    try {
      // 1. Удаляем события (дочерняя таблица)
      print('📌 [ClearAllData] Шаг 1: Удаление событий...');
      await _eventRepository.deleteAllEvents();
      print('✅ [ClearAllData] Шаг 1: События удалены');

      // 2. Удаляем медиа (дочерняя таблица)
      print('📌 [ClearAllData] Шаг 2: Удаление медиа...');
      final mediaResult = await _mediaRepository.deleteAllMedia();
      if (mediaResult.isLeft()) {
        print(
          '❌ [ClearAllData] Ошибка при удалении медиа: ${mediaResult.fold((l) => l, (r) => '')}',
        );
        final failure = mediaResult.fold(
          (l) => l,
          (r) => const ServerFailure('Неизвестная ошибка при удалении медиа'),
        );
        return Left(failure);
      }
      print('✅ [ClearAllData] Шаг 2: Медиа удалены');

      // 3. Удаляем семьи
      print('📌 [ClearAllData] Шаг 3: Удаление семей...');
      await _familyRepository.deleteAllFamilies();
      print('✅ [ClearAllData] Шаг 3: Семьи удалены');

      // 4. Удаляем людей
      print('📌 [ClearAllData] Шаг 4: Удаление людей...');
      await _personRepository.deleteAllPersons();
      print('✅ [ClearAllData] Шаг 4: Люди удалены');

      // 5. Удаляем проекты
      print('📌 [ClearAllData] Шаг 5: Удаление проектов...');
      await _projectRepository.deleteAllProjects();
      print('✅ [ClearAllData] Шаг 5: Проекты удалены');

      // 6. Очищаем файлы на диске
      print('📌 [ClearAllData] Шаг 6: Очистка файлов на диске...');
      final clearResult = await _mediaRepository.clearAllFiles();
      if (clearResult.isLeft()) {
        print(
          '❌ [ClearAllData] Ошибка при очистке файлов: ${clearResult.fold((l) => l, (r) => '')}',
        );
        final failure = clearResult.fold(
          (l) => l,
          (r) => const ServerFailure('Неизвестная ошибка при очистке файлов'),
        );
        return Left(failure);
      }
      print('✅ [ClearAllData] Шаг 6: Файлы очищены');

      print('✅ [ClearAllData] Все данные успешно очищены!');
      return const Right(unit);
    } catch (e, stackTrace) {
      print('❌ [ClearAllData] КРИТИЧЕСКАЯ ОШИБКА: $e');
      print('📚 [ClearAllData] StackTrace: $stackTrace');
      return Left(ServerFailure('Ошибка при очистке данных: $e'));
    }
  }
}
