// lib/data/datasources/local/media_local_datasource.dart
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'database/media_attachment_model.dart';

/// Локальный источник данных для медиа-файлов
abstract class MediaLocalDataSource {
  /// Получить все медиа по ID человека
  Future<List<MediaAttachmentModel>> getByPersonId(String personId);

  /// Получить все медиа по ID события
  Future<List<MediaAttachmentModel>> getByEventId(String eventId);

  /// Получить медиа по ID
  Future<MediaAttachmentModel?> getById(String id);

  /// Получить основной портрет человека
  Future<MediaAttachmentModel?> getPrimaryPortrait(String personId);

  /// Сохранить медиа
  Future<void> save(MediaAttachmentModel media);

  /// Обновить медиа
  Future<void> update(MediaAttachmentModel media);

  /// Удалить медиа по ID
  Future<void> deleteById(String id);

  /// Удалить все медиа человека
  Future<void> deleteByPersonId(String personId);

  /// Удалить все медиа события
  Future<void> deleteByEventId(String eventId);

  /// Сбросить основной портрет у всех файлов человека
  Future<void> clearPrimaryPortrait(String personId);

  /// Получить статистику по медиа
  Future<Map<String, dynamic>> getStatistics({
    String? personId,
    String? eventId,
  });

  /// Получить все пути файлов (для очистки)
  Future<List<String>> getAllFilePaths();

  /// Обновить файлы при перемещении
  Future<void> moveMedia({
    required String mediaId,
    String? newPersonId,
    String? newEventId,
  });
}

/// Реализация локального датасорса
class MediaLocalDataSourceImpl implements MediaLocalDataSource {
  final Database db;

  MediaLocalDataSourceImpl(this.db);

  @override
  Future<List<MediaAttachmentModel>> getByPersonId(String personId) async {
    final result = await db.query(
      'media_attachments',
      where: 'person_id = ?',
      whereArgs: [personId],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => MediaAttachmentModel.fromMap(map)).toList();
  }

  @override
  Future<List<MediaAttachmentModel>> getByEventId(String eventId) async {
    final result = await db.query(
      'media_attachments',
      where: 'event_id = ?',
      whereArgs: [eventId],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => MediaAttachmentModel.fromMap(map)).toList();
  }

  @override
  Future<MediaAttachmentModel?> getById(String id) async {
    final result = await db.query(
      'media_attachments',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return MediaAttachmentModel.fromMap(result.first);
  }

  @override
  Future<MediaAttachmentModel?> getPrimaryPortrait(String personId) async {
    final result = await db.query(
      'media_attachments',
      where: 'person_id = ? AND is_primary = 1',
      whereArgs: [personId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return MediaAttachmentModel.fromMap(result.first);
  }

  @override
  Future<void> save(MediaAttachmentModel media) async {
    await db.insert(
      'media_attachments',
      media.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> update(MediaAttachmentModel media) async {
    await db.update(
      'media_attachments',
      media.toMap(),
      where: 'id = ?',
      whereArgs: [media.id],
    );
  }

  @override
  Future<void> deleteById(String id) async {
    await db.delete('media_attachments', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteByPersonId(String personId) async {
    await db.delete(
      'media_attachments',
      where: 'person_id = ?',
      whereArgs: [personId],
    );
  }

  @override
  Future<void> deleteByEventId(String eventId) async {
    await db.delete(
      'media_attachments',
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
  }

  @override
  Future<void> clearPrimaryPortrait(String personId) async {
    await db.update(
      'media_attachments',
      {'is_primary': 0},
      where: 'person_id = ? AND is_primary = 1',
      whereArgs: [personId],
    );
  }

  @override
  Future<Map<String, dynamic>> getStatistics({
    String? personId,
    String? eventId,
  }) async {
    String where = '';
    List<Object?> whereArgs = [];

    if (personId != null) {
      where = 'person_id = ?';
      whereArgs = [personId];
    } else if (eventId != null) {
      where = 'event_id = ?';
      whereArgs = [eventId];
    }

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_count,
        SUM(file_size) as total_size,
        COUNT(CASE WHEN mime_type LIKE 'image/%' THEN 1 END) as image_count,
        COUNT(CASE WHEN mime_type LIKE 'video/%' THEN 1 END) as video_count,
        COUNT(CASE WHEN mime_type LIKE 'audio/%' THEN 1 END) as audio_count,
        COUNT(CASE WHEN mime_type IN ('application/pdf', 'application/msword', 'text/plain') THEN 1 END) as document_count,
        COUNT(CASE WHEN is_primary = 1 THEN 1 END) as primary_count
      FROM media_attachments
      ${where.isNotEmpty ? 'WHERE $where' : ''}
    ''', whereArgs);

    if (result.isEmpty) {
      return {
        'total_count': 0,
        'total_size': 0,
        'image_count': 0,
        'video_count': 0,
        'audio_count': 0,
        'document_count': 0,
        'primary_count': 0,
      };
    }

    return result.first;
  }

  @override
  Future<List<String>> getAllFilePaths() async {
    final result = await db.query('media_attachments');
    return result
        .map((map) => map['local_path'] as String)
        .where((path) => path.isNotEmpty)
        .toList();
  }

  @override
  Future<void> moveMedia({
    required String mediaId,
    String? newPersonId,
    String? newEventId,
  }) async {
    final updates = <String, dynamic>{};
    if (newPersonId != null) updates['person_id'] = newPersonId;
    if (newEventId != null) updates['event_id'] = newEventId;
    updates['updated_at'] = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      'media_attachments',
      updates,
      where: 'id = ?',
      whereArgs: [mediaId],
    );
  }
}
