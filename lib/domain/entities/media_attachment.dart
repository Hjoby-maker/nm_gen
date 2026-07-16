// lib/domain/entities/media_attachment.dart
import 'package:equatable/equatable.dart';

/// Типы медиа-файлов
enum MediaType { image, video, audio, document, other }

extension MediaTypeExtension on MediaType {
  String get displayName {
    switch (this) {
      case MediaType.image:
        return 'Фото';
      case MediaType.video:
        return 'Видео';
      case MediaType.audio:
        return 'Аудио';
      case MediaType.document:
        return 'Документ';
      case MediaType.other:
        return 'Другое';
    }
  }

  String get iconEmoji {
    switch (this) {
      case MediaType.image:
        return '🖼️';
      case MediaType.video:
        return '🎬';
      case MediaType.audio:
        return '🎵';
      case MediaType.document:
        return '📄';
      case MediaType.other:
        return '📎';
    }
  }
}

/// Сущность медиа-вложения (доменная модель)
class MediaAttachment extends Equatable {
  const MediaAttachment({
    required this.id,
    this.personId,
    this.eventId,
    required this.fileName,
    required this.localPath,
    this.remoteUrl,
    required this.mimeType,
    required this.fileSize,
    required this.description,
    this.isPrimary = false,
    this.thumbnailPath,
    required this.createdAt,
    this.updatedAt,
  });
  final String id;
  final String? personId;
  final String? eventId;
  final String fileName;
  final String localPath;
  final String? remoteUrl;
  final String mimeType;
  final int fileSize;
  final String description;
  final bool isPrimary;
  final String? thumbnailPath;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Определение типа медиа по mimeType
  MediaType get mediaType {
    if (mimeType.startsWith('image/')) return MediaType.image;
    if (mimeType.startsWith('video/')) return MediaType.video;
    if (mimeType.startsWith('audio/')) return MediaType.audio;
    if (mimeType == 'application/pdf' ||
        mimeType == 'application/msword' ||
        mimeType ==
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document' ||
        mimeType == 'text/plain') {
      return MediaType.document;
    }
    return MediaType.other;
  }

  bool get isImage => mediaType == MediaType.image;
  bool get isVideo => mediaType == MediaType.video;
  bool get isAudio => mediaType == MediaType.audio;
  bool get isDocument => mediaType == MediaType.document;

  String get fileExtension {
    final List<String> parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  MediaAttachment copyWith({
    String? id,
    String? personId,
    String? eventId,
    String? fileName,
    String? localPath,
    String? remoteUrl,
    String? mimeType,
    int? fileSize,
    String? description,
    bool? isPrimary,
    String? thumbnailPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MediaAttachment(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      eventId: eventId ?? this.eventId,
      fileName: fileName ?? this.fileName,
      localPath: localPath ?? this.localPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      description: description ?? this.description,
      isPrimary: isPrimary ?? this.isPrimary,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    personId,
    eventId,
    fileName,
    localPath,
    remoteUrl,
    mimeType,
    fileSize,
    description,
    isPrimary,
    thumbnailPath,
    createdAt,
    updatedAt,
  ];
}
