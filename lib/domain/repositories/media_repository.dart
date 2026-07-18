// lib/domain/repositories/media_repository.dart
import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../data/models/media_filter.dart';
import '../../data/models/media_sort.dart';
import '../entities/media_attachment.dart';

/// Абстрактный репозиторий для работы с медиа-файлами
abstract class MediaRepository {
  /// Получить все медиа-файлы для человека
  Future<Either<Failure, List<MediaAttachment>>> getMediaByPerson(
    String personId, {
    MediaFilter? filter,
    MediaSortOrder sortOrder = MediaSortOrder.newestFirst,
  });

  /// Получить все медиа-файлы для события
  Future<Either<Failure, List<MediaAttachment>>> getMediaByEvent(
    String eventId, {
    MediaFilter? filter,
    MediaSortOrder sortOrder = MediaSortOrder.newestFirst,
  });

  /// Получить основной портрет человека
  Future<Either<Failure, MediaAttachment?>> getPrimaryPortrait(String personId);

  /// Получить один медиа-файл по ID
  Future<Either<Failure, MediaAttachment>> getMediaById(String id);

  /// Добавить новый медиа-файл
  Future<Either<Failure, MediaAttachment>> addMedia({
    required Uint8List fileData,
    required String fileName,
    required String mimeType,
    required String description,
    String? personId,
    String? eventId,
    bool setAsPrimary = false,
    bool generateThumbnail = true,
  });

  /// Прикрепить файл, физически находящийся на устройстве вне приложения
  /// (НЕ копируем содержимое - только запоминаем путь). Best-effort:
  /// доступность файла в будущем не гарантируется (пользователь может
  /// переместить/удалить оригинал; на Android разрешение может не
  /// пережить перезапуск процесса, если не запрошен persistable доступ).
  Future<Either<Failure, MediaAttachment>> addDeviceFileReference({
    required String filePath,
    required String fileName,
    required String mimeType,
    required int fileSize,
    required String description,
    String? personId,
    String? eventId,
  });

  /// Прикрепить внешнюю ссылку (URL). Локального файла нет вообще.
  Future<Either<Failure, MediaAttachment>> addExternalLink({
    required String url,
    required String description,
    String? title,
    String? personId,
    String? eventId,
  });

  /// Обновить описание медиа-файла
  Future<Either<Failure, MediaAttachment>> updateMediaDescription(
    String mediaId,
    String newDescription,
  );

  /// Установить файл как основной портрет человека
  Future<Either<Failure, MediaAttachment>> setAsPrimaryPortrait(
    String mediaId,
    String personId,
  );

  /// Удалить медиа-файл
  Future<Either<Failure, void>> deleteMedia(String mediaId);

  /// Удалить все медиа-файлы человека
  Future<Either<Failure, void>> deleteAllMediaByPerson(String personId);

  /// Удалить все медиа-файлы события
  Future<Either<Failure, void>> deleteAllMediaByEvent(String eventId);

  /// Переместить файл от человека к событию (или наоборот)
  Future<Either<Failure, MediaAttachment>> moveMedia({
    required String mediaId,
    String? newPersonId,
    String? newEventId,
  });

  /// Получить статистику по медиа-файлам
  Future<Either<Failure, MediaStatistics>> getStatistics({
    String? personId,
    String? eventId,
  });

  /// Очистить неиспользуемые файлы на диске
  Future<Either<Failure, int>> cleanUnusedFiles();
}

/// Статистика по медиа-файлам
class MediaStatistics {
  const MediaStatistics({
    required this.totalCount,
    required this.totalSize,
    required this.imageCount,
    required this.videoCount,
    required this.audioCount,
    required this.documentCount,
    required this.otherCount,
    required this.primaryPortraits,
  });
  final int totalCount;
  final int totalSize;
  final int imageCount;
  final int videoCount;
  final int audioCount;
  final int documentCount;
  final int otherCount;
  final int primaryPortraits;

  String get formattedTotalSize {
    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    }
    if (totalSize < 1024 * 1024 * 1024) {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}