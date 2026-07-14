// lib/core/errors/media_failures.dart
import 'failures.dart';

/// Базовый класс для ошибок медиа-модуля
abstract class MediaFailure extends Failure {
  const MediaFailure(String message, {String? code})
    : super(message, code: code);
}

/// Ошибка файловой системы
class FileSystemFailure extends MediaFailure {
  final String path;

  const FileSystemFailure(this.path, {String? message, String? code})
    : super(message ?? 'Ошибка работы с файлом: $path', code: code);

  @override
  List<Object?> get props => [path, message, code];
}

/// Ошибка при сохранении файла
class FileSaveFailure extends MediaFailure {
  final String fileName;

  const FileSaveFailure(this.fileName, {String? message, String? code})
    : super(message ?? 'Не удалось сохранить файл: $fileName', code: code);

  @override
  List<Object?> get props => [fileName, message, code];
}

/// Ошибка при удалении файла
class FileDeleteFailure extends MediaFailure {
  final String path;

  const FileDeleteFailure(this.path, {String? message, String? code})
    : super(message ?? 'Не удалось удалить файл: $path', code: code);

  @override
  List<Object?> get props => [path, message, code];
}

/// Ошибка валидации файла
class MediaValidationFailure extends MediaFailure {
  final String validationMessage;

  const MediaValidationFailure(this.validationMessage, {String? code})
    : super(validationMessage, code: code);

  @override
  List<Object?> get props => [validationMessage, code];
}

/// Ошибка при работе с БД медиа
class MediaDatabaseFailure extends MediaFailure {
  const MediaDatabaseFailure({String? message, String? code})
    : super(message ?? 'Ошибка базы данных медиа', code: code);

  @override
  List<Object?> get props => [message, code];
}

/// Ошибка, когда файл не найден
class MediaNotFoundFailure extends MediaFailure {
  final String id;

  const MediaNotFoundFailure(this.id, {String? message, String? code})
    : super(message ?? 'Медиа-файл не найден: $id', code: code);

  @override
  List<Object?> get props => [id, message, code];
}

/// Ошибка генерации миниатюры
class ThumbnailGenerationFailure extends MediaFailure {
  final String path;

  const ThumbnailGenerationFailure(this.path, {String? message, String? code})
    : super(message ?? 'Не удалось создать миниатюру для: $path', code: code);

  @override
  List<Object?> get props => [path, message, code];
}

/// Ошибка при загрузке медиа
class MediaLoadFailure extends MediaFailure {
  const MediaLoadFailure({String? message, String? code})
    : super(message ?? 'Не удалось загрузить медиа-файлы', code: code);

  @override
  List<Object?> get props => [message, code];
}

/// Ошибка при сохранении медиа в БД
class MediaSaveFailure extends MediaFailure {
  const MediaSaveFailure({String? message, String? code})
    : super(message ?? 'Не удалось сохранить медиа-файл', code: code);

  @override
  List<Object?> get props => [message, code];
}
