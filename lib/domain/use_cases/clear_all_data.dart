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
    try {
      // 1. Удаляем события (дочерняя таблица)
      await _eventRepository.deleteAllEvents();

      // 2. Удаляем медиа (дочерняя таблица)
      final mediaResult = await _mediaRepository.deleteAllMedia();
      if (mediaResult.isLeft()) {
        final failure = mediaResult.fold(
          (l) => l,
          (r) => const ServerFailure('Неизвестная ошибка при удалении медиа'),
        );
        return Left(failure);
      }

      // 3. Удаляем семьи
      await _familyRepository.deleteAllFamilies();

      // 4. Удаляем людей
      await _personRepository.deleteAllPersons();

      // 5. Удаляем проекты
      await _projectRepository.deleteAllProjects();

      // 6. Очищаем файлы на диске
      final clearResult = await _mediaRepository.clearAllFiles();
      if (clearResult.isLeft()) {
        final failure = clearResult.fold(
          (l) => l,
          (r) => const ServerFailure('Неизвестная ошибка при очистке файлов'),
        );
        return Left(failure);
      }

      return const Right(unit);
    } catch (e) {
      // Используем ServerFailure для ошибок сервера/БД
      return Left(ServerFailure('Ошибка при очистке данных: $e'));
    }
  }
}
