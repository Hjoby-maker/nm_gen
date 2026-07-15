// lib/core/utils/file_helper.dart
import 'dart:io';
import 'package:file_selector/file_selector.dart';

/// Вспомогательный класс для работы с файлами
class FileHelper {
  /// Форматирование размера файла
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Получение расширения файла
  static String getFileExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Проверка, является ли файл изображением по расширению
  static bool isImageByExtension(String fileName) {
    const imageExtensions = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp',
      'heic',
      'heif',
    ];
    return imageExtensions.contains(getFileExtension(fileName));
  }

  /// Проверка, является ли файл видео по расширению
  static bool isVideoByExtension(String fileName) {
    const videoExtensions = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv', 'webm'];
    return videoExtensions.contains(getFileExtension(fileName));
  }

  /// Проверка, является ли файл аудио по расширению
  static bool isAudioByExtension(String fileName) {
    const audioExtensions = ['mp3', 'wav', 'ogg', 'aac', 'flac', 'm4a'];
    return audioExtensions.contains(getFileExtension(fileName));
  }

  /// Проверка, является ли файл документом по расширению
  static bool isDocumentByExtension(String fileName) {
    const documentExtensions = [
      'pdf',
      'doc',
      'docx',
      'txt',
      'rtf',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
      'odt',
      'ods',
      'odp',
    ];
    return documentExtensions.contains(getFileExtension(fileName));
  }

  /// Проверка, поддерживается ли создание миниатюры для файла
  static bool isThumbnailSupported(String mimeType) {
    return mimeType.startsWith('image/') || mimeType.startsWith('video/');
  }

  /// Определение MIME-типа по расширению файла
  static String getMimeTypeFromExtension(String fileName) {
    const mimeTypes = {
      // Изображения
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'bmp': 'image/bmp',
      'webp': 'image/webp',
      'heic': 'image/heic',
      'heif': 'image/heif',
      // Видео
      'mp4': 'video/mp4',
      'avi': 'video/x-msvideo',
      'mov': 'video/quicktime',
      'wmv': 'video/x-ms-wmv',
      'flv': 'video/x-flv',
      'mkv': 'video/x-matroska',
      'webm': 'video/webm',
      // Аудио
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'aac': 'audio/aac',
      'flac': 'audio/flac',
      'm4a': 'audio/mp4',
      // Документы
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'rtf': 'application/rtf',
      'odt': 'application/vnd.oasis.opendocument.text',
      'ods': 'application/vnd.oasis.opendocument.spreadsheet',
      'odp': 'application/vnd.oasis.opendocument.presentation',
    };
    final extension = getFileExtension(fileName);
    return mimeTypes[extension] ?? 'application/octet-stream';
  }

  /// Определение MIME-типа из XFile
  static String getMimeTypeFromXFile(XFile file) {
    return file.mimeType ?? getMimeTypeFromExtension(file.name);
  }

  /// Создание XTypeGroup для фильтрации файлов
  static XTypeGroup createTypeGroup({
    required String label,
    required List<String> extensions,
    List<String>? mimeTypes,
  }) {
    return XTypeGroup(
      label: label,
      extensions: extensions,
      mimeTypes: mimeTypes ?? [],
    );
  }
}
