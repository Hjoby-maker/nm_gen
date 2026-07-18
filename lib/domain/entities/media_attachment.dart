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

/// Откуда взято вложение и кто "владеет" его файлом.
///
/// Это принципиально важно для двух вещей:
/// - удаление: файл с диска реально стираем только для [appStorage] (его
///   скопировало и владеет им само приложение). Для [deviceReference] мы
///   лишь ссылаемся на чужой файл - трогать его нельзя. Для [externalLink]
///   локального файла вообще нет.
/// - отображение: [deviceReference] может в любой момент "протухнуть"
///   (пользователь переместил/удалил файл, или на Android слетело
///   разрешение после перезапуска) - это осознанно принятый best-effort
///   сценарий, UI должен уметь показать это состояние, а не упасть.
enum AttachmentSource {
  /// Файл скопирован приложением в свою песочницу (FileStorageService).
  /// Приложение полностью владеет файлом: может его удалять, гарантирует
  /// доступность, пока сам файл не удалили из приложения.
  appStorage,

  /// Ссылка на файл, физически лежащий на устройстве вне приложения
  /// (выбран через файловый пикер, но НЕ скопирован). Доступность не
  /// гарантирована - файл может быть перемещён/удалён пользователем, а на
  /// Android разрешение на доступ может не пережить перезапуск процесса.
  deviceReference,

  /// Внешняя ссылка (URL) на ресурс в интернете. Локального файла нет
  /// вообще, есть только [MediaAttachment.remoteUrl].
  externalLink,
}

extension AttachmentSourceExtension on AttachmentSource {
  String get displayName {
    switch (this) {
      case AttachmentSource.appStorage:
        return 'Копия в приложении';
      case AttachmentSource.deviceReference:
        return 'Файл на устройстве';
      case AttachmentSource.externalLink:
        return 'Внешняя ссылка';
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
    this.localPath,
    this.remoteUrl,
    required this.mimeType,
    required this.fileSize,
    required this.description,
    this.isPrimary = false,
    this.thumbnailPath,
    this.source = AttachmentSource.appStorage,
    required this.createdAt,
    this.updatedAt,
  }) : assert(
         source != AttachmentSource.externalLink || remoteUrl != null,
         'Для AttachmentSource.externalLink обязателен remoteUrl',
       ),
       assert(
         source == AttachmentSource.externalLink || localPath != null,
         'Для appStorage/deviceReference обязателен localPath',
       );
  final String id;
  final String? personId;
  final String? eventId;
  final String fileName;

  /// Путь к файлу. Null только для [AttachmentSource.externalLink] - у
  /// внешней ссылки локального файла нет.
  final String? localPath;

  /// URL - заполнен для [AttachmentSource.externalLink]. Оставлен
  /// нетронутым как общее поле (было в исходной модели), не заводим
  /// отдельное новое поле специально под ссылки.
  final String? remoteUrl;
  final String mimeType;
  final int fileSize;
  final String description;
  final bool isPrimary;
  final String? thumbnailPath;

  /// Кто владеет файлом и откуда он взят. См. документацию у
  /// [AttachmentSource]. По умолчанию appStorage - сохраняет обратную
  /// совместимость со всеми уже существующими записями в БД, где такого
  /// столбца ещё нет (миграция должна проставлять именно это значение).
  final AttachmentSource source;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get isExternalLink => source == AttachmentSource.externalLink;
  bool get isDeviceReference => source == AttachmentSource.deviceReference;
  bool get isAppOwnedFile => source == AttachmentSource.appStorage;

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
    // У внешней ссылки размера в байтах нет и не может быть.
    if (isExternalLink) return '—';
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
    AttachmentSource? source,
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
      source: source ?? this.source,
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
    source,
    createdAt,
    updatedAt,
  ];
}