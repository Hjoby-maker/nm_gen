// lib/core/errors/media_failures.dart
import 'failures.dart';

/// Базовый класс для ошибок медиа-модуля
abstract class MediaFailure extends Failure {
  const MediaFailure(String message, {String? code})
    : super(message, code: code);
}

/// Ошибка файловой системы
class FileSystemFailure extends MediaFailure {
  const FileSystemFailure(this.path, {String? message, String? code})
    : super(message ?? 'Ошибка работы с файлом: $path', code: code);
  final String path;

  @override
  List<Object?> get props => <Object?>[path, message, code];
}

/// Ошибка при сохранении файла
class FileSaveFailure extends MediaFailure {
  const FileSaveFailure(this.fileName, {String? message, String? code})
    : super(message ?? 'Не удалось сохранить файл: $fileName', code: code);
  final String fileName;

  @override
  List<Object?> get props => <Object?>[fileName, message, code];
}

/// Ошибка при удалении файла
class FileDeleteFailure extends MediaFailure {
  const FileDeleteFailure(this.path, {String? message, String? code})
    : super(message ?? 'Не удалось удалить файл: $path', code: code);
  final String path;

  @override
  List<Object?> get props => <Object?>[path, message, code];
}

/// Ошибка валидации файла
class MediaValidationFailure extends MediaFailure {
  const MediaValidationFailure(this.validationMessage, {String? code})
    : super(validationMessage, code: code);
  final String validationMessage;

  @override
  List<Object?> get props => <Object?>[validationMessage, code];
}

/// Ошибка при работе с БД медиа
class MediaDatabaseFailure extends MediaFailure {
  const MediaDatabaseFailure({String? message, String? code})
    : super(message ?? 'Ошибка базы данных медиа', code: code);

  @override
  List<Object?> get props => <Object?>[message, code];
}

/// Ошибка, когда файл не найден
class MediaNotFoundFailure extends MediaFailure {
  const MediaNotFoundFailure(this.id, {String? message, String? code})
    : super(message ?? 'Медиа-файл не найден: $id', code: code);
  final String id;

  @override
  List<Object?> get props => <Object?>[id, message, code];
}

/// Ошибка генерации миниатюры
class ThumbnailGenerationFailure extends MediaFailure {
  const ThumbnailGenerationFailure(this.path, {String? message, String? code})
    : super(message ?? 'Не удалось создать миниатюру для: $path', code: code);
  final String path;

  @override
  List<Object?> get props => <Object?>[path, message, code];
}

/// Ошибка при загрузке медиа
class MediaLoadFailure extends MediaFailure {
  const MediaLoadFailure({String? message, String? code})
    : super(message ?? 'Не удалось загрузить медиа-файлы', code: code);

  @override
  List<Object?> get props => <Object?>[message, code];
}

/// Ошибка при сохранении медиа в БД
class MediaSaveFailure extends MediaFailure {
  const MediaSaveFailure({String? message, String? code})
    : super(message ?? 'Не удалось сохранить медиа-файл', code: code);

  @override
  List<Object?> get props => <Object?>[message, code];
}
