// lib/data/repositories/media_repository_impl.dart
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../domain/entities/media_attachment.dart';
import '../../domain/repositories/media_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/media_failures.dart';
import 'package:nm_gen/core/utils/file_storage_service.dart';
import 'package:nm_gen/core/utils/thumbnail_generator.dart';
import '../datasources/local/media_local_datasource.dart';
import '../datasources/local/database/media_attachment_model.dart';
import '../models/media_filter.dart';
import '../models/media_sort.dart';

/// Реализация репозитория медиа-файлов
class MediaRepositoryImpl implements MediaRepository {
  MediaRepositoryImpl(this._dataSource, this._fileStorage);
  final MediaLocalDataSource _dataSource;
  final FileStorageService _fileStorage;

  @override
  Future<Either<Failure, List<MediaAttachment>>> getMediaByPerson(
    String personId, {
    MediaFilter? filter,
    MediaSortOrder sortOrder = MediaSortOrder.newestFirst,
  }) async {
    try {
      final List<MediaAttachmentModel> models = await _dataSource.getByPersonId(
        personId,
      );
      var entities = models
          .map((MediaAttachmentModel model) => model.toEntity())
          .toList();

      // Применяем фильтр
      if (filter != null) {
        entities = entities.where(filter.matches).toList();
      }

      // Применяем сортировку
      entities = sortOrder.sort(entities);

      return Right(entities);
    } catch (e) {
      return Left(
        MediaDatabaseFailure(message: 'Ошибка загрузки медиа для человека: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<MediaAttachment>>> getMediaByEvent(
    String eventId, {
    MediaFilter? filter,
    MediaSortOrder sortOrder = MediaSortOrder.newestFirst,
  }) async {
    try {
      final List<MediaAttachmentModel> models = await _dataSource.getByEventId(
        eventId,
      );
      var entities = models
          .map((MediaAttachmentModel model) => model.toEntity())
          .toList();

      if (filter != null) {
        entities = entities.where(filter.matches).toList();
      }

      entities = sortOrder.sort(entities);

      return Right(entities);
    } catch (e) {
      return Left(
        MediaDatabaseFailure(message: 'Ошибка загрузки медиа для события: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, MediaAttachment?>> getPrimaryPortrait(
    String personId,
  ) async {
    try {
      final MediaAttachmentModel? model = await _dataSource.getPrimaryPortrait(
        personId,
      );
      return Right(model?.toEntity());
    } catch (e) {
      return Left(
        MediaDatabaseFailure(message: 'Ошибка загрузки основного портрета: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, MediaAttachment>> getMediaById(String id) async {
    try {
      final MediaAttachmentModel? model = await _dataSource.getById(id);
      if (model == null) {
        return Left(MediaNotFoundFailure(id, message: 'Медиа-файл не найден'));
      }
      return Right(model.toEntity());
    } catch (e) {
      return Left(
        MediaDatabaseFailure(message: 'Ошибка загрузки медиа по ID: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, MediaAttachment>> addMedia({
    required Uint8List fileData,
    required String fileName,
    required String mimeType,
    required String description,
    String? personId,
    String? eventId,
    bool setAsPrimary = false,
    bool generateThumbnail = true,
  }) async {
    try {
      // Валидация
      if (fileData.isEmpty) {
        return Left(
          const MediaValidationFailure('Файл пустой', code: 'EMPTY_FILE'),
        );
      }

      if (fileData.length > 50 * 1024 * 1024) {
        return Left(
          const MediaValidationFailure(
            'Файл слишком большой (макс. 50 МБ)',
            code: 'FILE_TOO_LARGE',
          ),
        );
      }

      if (description.trim().isEmpty) {
        return Left(
          const MediaValidationFailure(
            'Описание не может быть пустым',
            code: 'EMPTY_DESCRIPTION',
          ),
        );
      }

      // Определяем поддиректорию
      final String subDir = personId != null
          ? 'person_$personId'
          : 'event_$eventId';

      // Сохраняем файл
      final filePath = await _fileStorage.saveFile(
        fileData: fileData,
        fileName: fileName,
        subDirectory: subDir,
      );

      // Генерируем миниатюру
      String? thumbnailPath;
      if (generateThumbnail &&
          ThumbnailGenerator.isThumbnailSupported(mimeType)) {
        final thumbnailData = await ThumbnailGenerator.generateThumbnail(
          filePath: filePath,
          mimeType: mimeType,
          fileData: fileData,
        );
        if (thumbnailData != null) {
          thumbnailPath = await _fileStorage.saveThumbnail(
            thumbnailData: thumbnailData,
            originalFilePath: filePath,
          );
        }
      }

      // Если устанавливаем как основной портрет, сбрасываем старые
      if (setAsPrimary && personId != null) {
        await _dataSource.clearPrimaryPortrait(personId);
      }

      // Создаем модель
      final MediaAttachmentModel model = MediaAttachmentModel.create(
        fileName: fileName,
        localPath: filePath,
        mimeType: mimeType,
        fileSize: fileData.length,
        description: description,
        personId: personId,
        eventId: eventId,
        isPrimary: setAsPrimary && personId != null,
        thumbnailPath: thumbnailPath,
      );

      // Сохраняем в БД
      await _dataSource.save(model);

      return Right(model.toEntity());
    } on MediaValidationFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        FileSaveFailure(
          fileName,
          message: 'Ошибка сохранения медиа: $e',
          code: 'SAVE_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, MediaAttachment>> addDeviceFileReference({
    required String filePath,
    required String fileName,
    required String mimeType,
    required int fileSize,
    required String description,
    String? personId,
    String? eventId,
  }) async {
    try {
      if (description.trim().isEmpty) {
        return Left(
          const MediaValidationFailure(
            'Описание не может быть пустым',
            code: 'EMPTY_DESCRIPTION',
          ),
        );
      }
      if (filePath.trim().isEmpty) {
        return Left(
          const MediaValidationFailure(
            'Не указан путь к файлу',
            code: 'EMPTY_PATH',
          ),
        );
      }

      // ⚠️ НЕ копируем файл - только сохраняем ссылку на путь. Best-effort:
      // файл может позже стать недоступен (перемещён/удалён пользователем,
      // либо на Android слетело разрешение после перезапуска процесса) -
      // это осознанно принятое поведение, а не забытая проверка. UI
      // (MediaCard) должен аккуратно обработать отсутствие файла при показе.
      final MediaAttachmentModel model = MediaAttachmentModel.createDeviceReference(
        fileName: fileName,
        filePath: filePath,
        mimeType: mimeType,
        fileSize: fileSize,
        description: description,
        personId: personId,
        eventId: eventId,
      );

      await _dataSource.save(model);

      return Right(model.toEntity());
    } on MediaValidationFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        MediaDatabaseFailure(
          message: 'Ошибка прикрепления файла с устройства: $e',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, MediaAttachment>> addExternalLink({
    required String url,
    required String description,
    String? title,
    String? personId,
    String? eventId,
  }) async {
    try {
      if (description.trim().isEmpty) {
        return Left(
          const MediaValidationFailure(
            'Описание не может быть пустым',
            code: 'EMPTY_DESCRIPTION',
          ),
        );
      }

      final String trimmedUrl = url.trim();
      final Uri? parsed = Uri.tryParse(trimmedUrl);
      final bool isValid =
          parsed != null &&
          (parsed.isScheme('HTTP') || parsed.isScheme('HTTPS')) &&
          parsed.host.isNotEmpty;
      if (!isValid) {
        return Left(
          const MediaValidationFailure(
            'Некорректная ссылка - укажите полный адрес, начиная с http:// или https://',
            code: 'INVALID_URL',
          ),
        );
      }

      final MediaAttachmentModel model = MediaAttachmentModel.createExternalLink(
        url: trimmedUrl,
        description: description,
        title: title,
        personId: personId,
        eventId: eventId,
      );

      await _dataSource.save(model);

      return Right(model.toEntity());
    } on MediaValidationFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        MediaDatabaseFailure(message: 'Ошибка прикрепления ссылки: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, MediaAttachment>> linkMediaToEvent({
    required String mediaId,
    required String? eventId,
  }) async {
    try {
      final MediaAttachmentModel? model = await _dataSource.getById(mediaId);
      if (model == null) {
        return Left(
          MediaNotFoundFailure(mediaId, message: 'Медиа-файл не найден'),
        );
      }

      // ⚠️ Файл должен остаться привязан хотя бы к чему-то одному. Если у
      // него personId уже null (например, файл изначально был создан
      // напрямую под событие) и мы пытаемся отвязать его от события
      // (eventId: null) - он "потеряется" без единого владельца. Такое
      // отвязывание запрещаем.
      if (eventId == null && model.personId == null) {
        return Left(
          const MediaValidationFailure(
            'Нельзя отвязать файл от события - у него нет владельца-человека, '
            'файл останется ничей',
            code: 'ORPHAN_ATTACHMENT',
          ),
        );
      }

      final MediaAttachmentModel updatedModel = MediaAttachmentModel(
        id: model.id,
        personId: model.personId,
        eventId: eventId,
        fileName: model.fileName,
        localPath: model.localPath,
        remoteUrl: model.remoteUrl,
        mimeType: model.mimeType,
        fileSize: model.fileSize,
        description: model.description,
        isPrimary: model.isPrimary,
        thumbnailPath: model.thumbnailPath,
        source: model.source,
        createdAt: model.createdAt,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _dataSource.update(updatedModel);

      return Right(updatedModel.toEntity());
    } on MediaNotFoundFailure catch (e) {
      return Left(e);
    } on MediaValidationFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        MediaDatabaseFailure(message: 'Ошибка привязки файла к событию: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, MediaAttachment>> updateMediaDescription(
    String mediaId,
    String newDescription,
  ) async {
    try {
      if (newDescription.trim().isEmpty) {
        return Left(
          const MediaValidationFailure(
            'Описание не может быть пустым',
            code: 'EMPTY_DESCRIPTION',
          ),
        );
      }

      final MediaAttachmentModel? model = await _dataSource.getById(mediaId);
      if (model == null) {
        return Left(
          MediaNotFoundFailure(mediaId, message: 'Медиа-файл не найден'),
        );
      }

      final MediaAttachmentModel updatedModel = MediaAttachmentModel(
        id: model.id,
        personId: model.personId,
        eventId: model.eventId,
        fileName: model.fileName,
        localPath: model.localPath,
        remoteUrl: model.remoteUrl,
        mimeType: model.mimeType,
        fileSize: model.fileSize,
        description: newDescription.trim(),
        isPrimary: model.isPrimary,
        thumbnailPath: model.thumbnailPath,
        source: model.source,
        createdAt: model.createdAt,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _dataSource.update(updatedModel);

      return Right(updatedModel.toEntity());
    } on MediaNotFoundFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        MediaDatabaseFailure(message: 'Ошибка обновления описания: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, MediaAttachment>> setAsPrimaryPortrait(
    String mediaId,
    String personId,
  ) async {
    try {
      final MediaAttachmentModel? model = await _dataSource.getById(mediaId);
      if (model == null) {
        return Left(
          MediaNotFoundFailure(mediaId, message: 'Медиа-файл не найден'),
        );
      }

      // Проверяем, что файл принадлежит этому человеку
      if (model.personId != personId) {
        return Left(
          const MediaValidationFailure(
            'Файл не принадлежит этому человеку',
            code: 'WRONG_OWNER',
          ),
        );
      }

      // Сбрасываем старый основной портрет
      await _dataSource.clearPrimaryPortrait(personId);

      // Устанавливаем новый
      final MediaAttachmentModel updatedModel = MediaAttachmentModel(
        id: model.id,
        personId: model.personId,
        eventId: model.eventId,
        fileName: model.fileName,
        localPath: model.localPath,
        remoteUrl: model.remoteUrl,
        mimeType: model.mimeType,
        fileSize: model.fileSize,
        description: model.description,
        isPrimary: 1,
        thumbnailPath: model.thumbnailPath,
        source: model.source,
        createdAt: model.createdAt,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _dataSource.update(updatedModel);

      return Right(updatedModel.toEntity());
    } on MediaNotFoundFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        MediaDatabaseFailure(
          message: 'Ошибка установки основного портрета: $e',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteMedia(String mediaId) async {
    try {
      final MediaAttachmentModel? model = await _dataSource.getById(mediaId);
      if (model == null) {
        return Left(
          MediaNotFoundFailure(mediaId, message: 'Медиа-файл не найден'),
        );
      }

      // Удаляем из БД
      await _dataSource.deleteById(mediaId);

      // ⚠️ Файл с диска стираем ТОЛЬКО если приложение сам его туда
      // скопировало (source == appStorage). Для deviceReference это чужой
      // файл пользователя вне песочницы приложения - трогать его нельзя.
      // Для externalLink localPath вообще null - стирать нечего.
      if (model.source == 'appStorage' && model.localPath != null) {
        await _fileStorage.deleteFile(model.localPath!);

        // Удаляем миниатюру
        if (model.thumbnailPath != null) {
          await _fileStorage.deleteFile(model.thumbnailPath!);
        }
      }

      return const Right(null);
    } on MediaNotFoundFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        FileDeleteFailure(
          mediaId,
          message: 'Ошибка удаления медиа: $e',
          code: 'DELETE_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteAllMediaByPerson(String personId) async {
    try {
      // Получаем все файлы для удаления с диска
      final List<MediaAttachmentModel> models = await _dataSource.getByPersonId(
        personId,
      );

      // Удаляем из БД
      await _dataSource.deleteByPersonId(personId);

      // Удаляем директорию с диска
      final dirPath = await _fileStorage.getDirectoryPath('person_$personId');
      if (dirPath != null) {
        await _fileStorage.deleteDirectory(dirPath);
      }

      return const Right(null);
    } catch (e) {
      return Left(
        MediaDatabaseFailure(
          message: 'Ошибка удаления всех медиа человека: $e',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteAllMediaByEvent(String eventId) async {
    try {
      await _dataSource.deleteByEventId(eventId);

      final dirPath = await _fileStorage.getDirectoryPath('event_$eventId');
      if (dirPath != null) {
        await _fileStorage.deleteDirectory(dirPath);
      }

      return const Right(null);
    } catch (e) {
      return Left(
        MediaDatabaseFailure(message: 'Ошибка удаления всех медиа события: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, MediaAttachment>> moveMedia({
    required String mediaId,
    String? newPersonId,
    String? newEventId,
  }) async {
    try {
      // Проверяем, что новый владелец указан
      if (newPersonId == null && newEventId == null) {
        return Left(
          const MediaValidationFailure(
            'Не указан новый владелец',
            code: 'NO_NEW_OWNER',
          ),
        );
      }

      // Проверяем, что указан только один владелец
      if (newPersonId != null && newEventId != null) {
        return Left(
          const MediaValidationFailure(
            'Файл должен принадлежать либо Person, либо Event',
            code: 'MULTIPLE_OWNERS',
          ),
        );
      }

      final MediaAttachmentModel? model = await _dataSource.getById(mediaId);
      if (model == null) {
        return Left(
          MediaNotFoundFailure(mediaId, message: 'Медиа-файл не найден'),
        );
      }

      // Перемещаем файл на диске
      final String oldDir = model.personId != null
          ? 'person_${model.personId}'
          : 'event_${model.eventId}';
      final String newDir = newPersonId != null
          ? 'person_$newPersonId'
          : 'event_$newEventId';

      if (oldDir != newDir) {
        // ⚠️ Физически перемещаем файл на диске ТОЛЬКО для appStorage
        // (это единственный случай, когда файл вообще существует в
        // песочнице приложения и когда мы им владеем). Для
        // deviceReference файл лежит вне приложения и трогать его нельзя,
        // для externalLink localPath вообще null - просто переносим
        // "владельца" (person_id/event_id) в БД, без файловых операций.
        String? newPath = model.localPath;
        if (model.source == 'appStorage' && model.localPath != null) {
          newPath = await _fileStorage.moveFile(
            sourcePath: model.localPath!,
            newSubDirectory: newDir,
          );
        }

        // Обновляем путь в модели
        final MediaAttachmentModel updatedModel = MediaAttachmentModel(
          id: model.id,
          personId: newPersonId,
          eventId: newEventId,
          fileName: model.fileName,
          localPath: newPath,
          remoteUrl: model.remoteUrl,
          mimeType: model.mimeType,
          fileSize: model.fileSize,
          description: model.description,
          isPrimary: 0, // Сбрасываем основной портрет при перемещении
          thumbnailPath: model.thumbnailPath,
          source: model.source,
          createdAt: model.createdAt,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        await _dataSource.update(updatedModel);
        return Right(updatedModel.toEntity());
      }

      return Right(model.toEntity());
    } on MediaNotFoundFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        MediaDatabaseFailure(message: 'Ошибка перемещения медиа: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, MediaStatistics>> getStatistics({
    String? personId,
    String? eventId,
  }) async {
    try {
      final Map<String, dynamic> stats = await _dataSource.getStatistics(
        personId: personId,
        eventId: eventId,
      );

      return Right(
        MediaStatistics(
          totalCount: stats['total_count'] ?? 0,
          totalSize: stats['total_size'] ?? 0,
          imageCount: stats['image_count'] ?? 0,
          videoCount: stats['video_count'] ?? 0,
          audioCount: stats['audio_count'] ?? 0,
          documentCount: stats['document_count'] ?? 0,
          otherCount: stats['other_count'] ?? 0,
          primaryPortraits: stats['primary_count'] ?? 0,
        ),
      );
    } catch (e) {
      return Left(
        MediaDatabaseFailure(message: 'Ошибка получения статистики: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, int>> cleanUnusedFiles() async {
    try {
      final List<String> validPaths = await _dataSource.getAllFilePaths();
      final deletedCount = await _fileStorage.cleanUnusedFiles(
        validPaths.toSet(),
      );
      return Right(deletedCount);
    } catch (e) {
      return Left(
        FileSystemFailure('cleanup', message: 'Ошибка очистки файлов: $e'),
      );
    }
  }
}