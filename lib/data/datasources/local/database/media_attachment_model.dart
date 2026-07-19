// lib/data/datasources/local/database/media_attachment_model.dart
import 'package:nm_gen/domain/entities/media_attachment.dart';
import 'package:uuid/uuid.dart';

/// Модель медиа-вложения для работы с SQLite
class MediaAttachmentModel {
  const MediaAttachmentModel({
    required this.id,
    this.personId,
    this.eventId,
    required this.fileName,
    this.localPath,
    this.remoteUrl,
    required this.mimeType,
    required this.fileSize,
    required this.description,
    required this.isPrimary,
    this.thumbnailPath,
    this.source = 'appStorage',
    required this.createdAt,
    this.updatedAt,
  });

  /// Создание из доменной сущности
  factory MediaAttachmentModel.fromEntity(MediaAttachment entity) {
    return MediaAttachmentModel(
      id: entity.id,
      personId: entity.personId,
      eventId: entity.eventId,
      fileName: entity.fileName,
      localPath: entity.localPath,
      remoteUrl: entity.remoteUrl,
      mimeType: entity.mimeType,
      fileSize: entity.fileSize,
      description: entity.description,
      isPrimary: entity.isPrimary ? 1 : 0,
      thumbnailPath: entity.thumbnailPath,
      source: entity.source.name,
      createdAt: entity.createdAt.millisecondsSinceEpoch,
      updatedAt: entity.updatedAt?.millisecondsSinceEpoch,
    );
  }

  /// Создание из Map (из SQLite)
  factory MediaAttachmentModel.fromMap(Map<String, dynamic> map) {
    return MediaAttachmentModel(
      id: map['id'] as String,
      personId: map['person_id'] as String?,
      eventId: map['event_id'] as String?,
      fileName: map['file_name'] as String,
      localPath: map['local_path'] as String?,
      remoteUrl: map['remote_url'] as String?,
      mimeType: map['mime_type'] as String,
      fileSize: map['file_size'] as int,
      description: map['description'] as String,
      isPrimary: map['is_primary'] as int,
      thumbnailPath: map['thumbnail_path'] as String?,
      // ⚠️ Столбца 'source' не было в старых записях (до этой фичи) - если
      // его нет в Map (старая строка БД до миграции) или он null, считаем
      // это обычным скопированным файлом, как было раньше. См. миграцию в
      // db_helper.dart, которую нужно добавить отдельно (см. заметку в
      // ответе) - без неё этот столбец будет отсутствовать в SELECT *.
      source: map['source'] as String? ?? 'appStorage',
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int?,
    );
  }

  /// Создание для нового файла-копии (существующий сценарий, без изменений
  /// поведения)
  factory MediaAttachmentModel.create({
    required String fileName,
    required String localPath,
    required String mimeType,
    required int fileSize,
    required String description,
    String? personId,
    String? eventId,
    bool isPrimary = false,
    String? thumbnailPath,
    String? remoteUrl,
    String? id,
  }) {
    assert(
      personId != null || eventId != null,
      'Файл должен быть привязан хотя бы к одному из: Person, Event '
      '(разрешено быть привязанным сразу к обоим - например, файл, '
      'прикреплённый через форму события, виден и в файлах человека)',
    );

    final int now = DateTime.now().millisecondsSinceEpoch;

    return MediaAttachmentModel(
      id: id ?? const Uuid().v4(),
      personId: personId,
      eventId: eventId,
      fileName: fileName,
      localPath: localPath,
      remoteUrl: remoteUrl,
      mimeType: mimeType,
      fileSize: fileSize,
      description: description.trim(),
      isPrimary: isPrimary ? 1 : 0,
      thumbnailPath: thumbnailPath,
      source: 'appStorage',
      createdAt: now,
      updatedAt: null,
    );
  }

  /// Создание для ссылки на файл, физически лежащий на устройстве вне
  /// приложения (НЕ копируем содержимое, только путь).
  factory MediaAttachmentModel.createDeviceReference({
    required String fileName,
    required String filePath,
    required String mimeType,
    required int fileSize,
    required String description,
    String? personId,
    String? eventId,
    String? id,
  }) {
    assert(
      personId != null || eventId != null,
      'Файл должен быть привязан хотя бы к одному из: Person, Event '
      '(разрешено быть привязанным сразу к обоим - например, файл, '
      'прикреплённый через форму события, виден и в файлах человека)',
    );

    final int now = DateTime.now().millisecondsSinceEpoch;

    return MediaAttachmentModel(
      id: id ?? const Uuid().v4(),
      personId: personId,
      eventId: eventId,
      fileName: fileName,
      localPath: filePath,
      remoteUrl: null,
      mimeType: mimeType,
      fileSize: fileSize,
      description: description.trim(),
      isPrimary: 0,
      thumbnailPath: null,
      source: 'deviceReference',
      createdAt: now,
      updatedAt: null,
    );
  }

  /// Создание для внешней ссылки (URL). Локального файла нет.
  factory MediaAttachmentModel.createExternalLink({
    required String url,
    required String description,
    String? title,
    String? personId,
    String? eventId,
    String? id,
  }) {
    assert(
      personId != null || eventId != null,
      'Файл должен быть привязан хотя бы к одному из: Person, Event '
      '(разрешено быть привязанным сразу к обоим - например, файл, '
      'прикреплённый через форму события, виден и в файлах человека)',
    );

    final int now = DateTime.now().millisecondsSinceEpoch;

    return MediaAttachmentModel(
      id: id ?? const Uuid().v4(),
      personId: personId,
      eventId: eventId,
      fileName: (title != null && title.trim().isNotEmpty) ? title.trim() : url,
      localPath: null,
      remoteUrl: url,
      // text/uri-list - нейтральный mime-тип для "это ссылка, не файл",
      // используется, чтобы mediaType не пытался её классифицировать как
      // изображение/видео/документ по расширению урла (ненадёжно).
      mimeType: 'text/uri-list',
      fileSize: 0,
      description: description.trim(),
      isPrimary: 0,
      thumbnailPath: null,
      source: 'externalLink',
      createdAt: now,
      updatedAt: null,
    );
  }
  final String id;
  final String? personId;
  final String? eventId;
  final String fileName;

  /// Null для externalLink.
  final String? localPath;
  final String? remoteUrl;
  final String mimeType;
  final int fileSize;
  final String description;
  final int isPrimary; // SQLite использует 0/1 вместо bool
  final String? thumbnailPath;

  /// Хранится как TEXT в SQLite: 'appStorage' | 'deviceReference' |
  /// 'externalLink'. Строка, а не индекс enum - устойчиво к переупорядочиванию
  /// значений enum в будущем.
  final String source;
  final int createdAt;
  final int? updatedAt;

  AttachmentSource get _sourceEnum {
    switch (source) {
      case 'deviceReference':
        return AttachmentSource.deviceReference;
      case 'externalLink':
        return AttachmentSource.externalLink;
      case 'appStorage':
      default:
        return AttachmentSource.appStorage;
    }
  }

  /// Преобразование в доменную сущность
  MediaAttachment toEntity() {
    return MediaAttachment(
      id: id,
      personId: personId,
      eventId: eventId,
      fileName: fileName,
      localPath: localPath,
      remoteUrl: remoteUrl,
      mimeType: mimeType,
      fileSize: fileSize,
      description: description,
      isPrimary: isPrimary == 1,
      thumbnailPath: thumbnailPath,
      source: _sourceEnum,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: updatedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(updatedAt!)
          : null,
    );
  }

  /// Преобразование в Map для SQLite
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'person_id': personId,
      'event_id': eventId,
      'file_name': fileName,
      'local_path': localPath,
      'remote_url': remoteUrl,
      'mime_type': mimeType,
      'file_size': fileSize,
      'description': description,
      'is_primary': isPrimary,
      'thumbnail_path': thumbnailPath,
      'source': source,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}