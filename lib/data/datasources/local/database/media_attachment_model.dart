// lib/data/datasources/local/database/media_attachment_model.dart
import 'package:nm_gen/domain/entities/media_attachment.dart';
import 'package:uuid/uuid.dart';

/// Модель медиа-вложения для работы с SQLite
class MediaAttachmentModel {
  final String id;
  final String? personId;
  final String? eventId;
  final String fileName;
  final String localPath;
  final String? remoteUrl;
  final String mimeType;
  final int fileSize;
  final String description;
  final int isPrimary; // SQLite использует 0/1 вместо bool
  final String? thumbnailPath;
  final int createdAt;
  final int? updatedAt;

  const MediaAttachmentModel({
    required this.id,
    this.personId,
    this.eventId,
    required this.fileName,
    required this.localPath,
    this.remoteUrl,
    required this.mimeType,
    required this.fileSize,
    required this.description,
    required this.isPrimary,
    this.thumbnailPath,
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
      createdAt: entity.createdAt.millisecondsSinceEpoch,
      updatedAt: entity.updatedAt?.millisecondsSinceEpoch,
    );
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
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: updatedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(updatedAt!)
          : null,
    );
  }

  /// Преобразование в Map для SQLite
  Map<String, dynamic> toMap() {
    return {
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
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Создание из Map (из SQLite)
  factory MediaAttachmentModel.fromMap(Map<String, dynamic> map) {
    return MediaAttachmentModel(
      id: map['id'] as String,
      personId: map['person_id'] as String?,
      eventId: map['event_id'] as String?,
      fileName: map['file_name'] as String,
      localPath: map['local_path'] as String,
      remoteUrl: map['remote_url'] as String?,
      mimeType: map['mime_type'] as String,
      fileSize: map['file_size'] as int,
      description: map['description'] as String,
      isPrimary: map['is_primary'] as int,
      thumbnailPath: map['thumbnail_path'] as String?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int?,
    );
  }

  /// Создание для нового файла (генерация ID)
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
      (personId != null && eventId == null) ||
          (personId == null && eventId != null),
      'Файл должен быть привязан либо к Person, либо к Event',
    );

    final now = DateTime.now().millisecondsSinceEpoch;

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
      createdAt: now,
      updatedAt: null,
    );
  }
}
