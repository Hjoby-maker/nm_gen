// lib/core/services/file_storage_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

/// Сервис для работы с файловой системой
class FileStorageService {
  static const String mediaDirName = 'media';
  static const String thumbnailsDirName = 'thumbnails';

  /// Получение корневой директории приложения
  Future<Directory> _getAppDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  /// Получение директории для медиа-файлов
  Future<Directory> _getMediaDirectory() async {
    final appDir = await _getAppDirectory();
    final mediaDir = Directory(path.join(appDir.path, mediaDirName));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir;
  }

  /// Получение директории для миниатюр
  Future<Directory> _getThumbnailsDirectory() async {
    final appDir = await _getAppDirectory();
    final thumbnailsDir = Directory(path.join(appDir.path, thumbnailsDirName));
    if (!await thumbnailsDir.exists()) {
      await thumbnailsDir.create(recursive: true);
    }
    return thumbnailsDir;
  }

  /// Генерация уникального имени файла
  String _generateUniqueFileName(String originalFileName) {
    final extension = path.extension(originalFileName);
    final nameWithoutExt = path.basenameWithoutExtension(originalFileName);
    final uuid = const Uuid().v4().substring(0, 8);
    return '${nameWithoutExt}_$uuid$extension';
  }

  /// Сохранение файла на диск
  Future<String> saveFile({
    required Uint8List fileData,
    required String fileName,
    required String subDirectory,
  }) async {
    try {
      final mediaDir = await _getMediaDirectory();

      final subDir = Directory(path.join(mediaDir.path, subDirectory));
      if (!await subDir.exists()) {
        await subDir.create(recursive: true);
      }

      final uniqueName = _generateUniqueFileName(fileName);
      final filePath = path.join(subDir.path, uniqueName);

      final file = File(filePath);
      await file.writeAsBytes(fileData);

      return filePath;
    } catch (e) {
      throw Exception('Ошибка сохранения файла: $e');
    }
  }

  /// Сохранение миниатюры
  Future<String?> saveThumbnail({
    required Uint8List thumbnailData,
    required String originalFilePath,
  }) async {
    try {
      final thumbnailsDir = await _getThumbnailsDirectory();

      final originalName = path.basename(originalFilePath);
      final thumbnailName =
          'thumb_${path.basenameWithoutExtension(originalName)}.jpg';
      final thumbnailPath = path.join(thumbnailsDir.path, thumbnailName);

      final file = File(thumbnailPath);
      await file.writeAsBytes(thumbnailData);

      return thumbnailPath;
    } catch (e) {
      print('Ошибка сохранения миниатюры: $e');
      return null;
    }
  }

  /// Чтение файла с диска
  Future<Uint8List> readFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Файл не найден: $filePath');
      }
      return await file.readAsBytes();
    } catch (e) {
      throw Exception('Ошибка чтения файла: $e');
    }
  }

  /// Проверка существования файла
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Удаление файла
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Ошибка удаления файла: $e');
    }
  }

  /// Удаление всей директории с файлами
  Future<void> deleteDirectory(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      throw Exception('Ошибка удаления директории: $e');
    }
  }

  /// Получение размера файла
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Файл не найден: $filePath');
      }
      return await file.length();
    } catch (e) {
      throw Exception('Ошибка получения размера файла: $e');
    }
  }

  /// Получение всех файлов в директории (рекурсивно)
  Future<List<File>> getAllFilesInDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return [];

    final files = <File>[];
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        files.add(entity);
      }
    }
    return files;
  }

  /// Очистка неиспользуемых файлов
  Future<int> cleanUnusedFiles(Set<String> validPaths) async {
    try {
      final mediaDir = await _getMediaDirectory();
      final allFiles = await getAllFilesInDirectory(mediaDir.path);

      int deletedCount = 0;
      for (final file in allFiles) {
        if (!validPaths.contains(file.path)) {
          await file.delete();
          deletedCount++;
        }
      }

      final thumbnailsDir = await _getThumbnailsDirectory();
      final thumbFiles = await getAllFilesInDirectory(thumbnailsDir.path);

      // Удаляем миниатюры, у которых нет оригиналов
      for (final file in thumbFiles) {
        final originalName = file.path
            .replaceAll('thumb_', '')
            .replaceAll('.jpg', '');
        bool hasOriginal = validPaths.any(
          (path) => path.contains(originalName),
        );
        if (!hasOriginal) {
          await file.delete();
          deletedCount++;
        }
      }

      return deletedCount;
    } catch (e) {
      print('Ошибка очистки файлов: $e');
      return 0;
    }
  }

  /// Получить полный путь к директории
  Future<String?> getDirectoryPath(String subDirectory) async {
    try {
      final mediaDir = await _getMediaDirectory();
      final dir = Directory(path.join(mediaDir.path, subDirectory));
      if (await dir.exists()) {
        return dir.path;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Переместить файл в другую директорию
  Future<String> moveFile({
    required String sourcePath,
    required String newSubDirectory,
  }) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('Исходный файл не найден: $sourcePath');
      }

      final mediaDir = await _getMediaDirectory();
      final newDir = Directory(path.join(mediaDir.path, newSubDirectory));
      if (!await newDir.exists()) {
        await newDir.create(recursive: true);
      }

      final fileName = path.basename(sourcePath);
      final newPath = path.join(newDir.path, fileName);

      // Если файл уже существует в новом месте, генерируем новое имя
      if (await File(newPath).exists()) {
        final nameWithoutExt = path.basenameWithoutExtension(fileName);
        final extension = path.extension(fileName);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final uniqueName = '${nameWithoutExt}_$timestamp$extension';
        final finalPath = path.join(newDir.path, uniqueName);
        await sourceFile.copy(finalPath);
        await sourceFile.delete();
        return finalPath;
      }

      await sourceFile.copy(newPath);
      await sourceFile.delete();
      return newPath;
    } catch (e) {
      throw Exception('Ошибка перемещения файла: $e');
    }
  }

  /// Получить информацию о файле
  Future<FileInfo?> getFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final stat = await file.stat();
      return FileInfo(
        path: filePath,
        size: stat.size,
        modified: stat.modified,
        accessed: stat.accessed,
        isDirectory: stat.type == FileSystemEntityType.directory,
      );
    } catch (e) {
      print('Ошибка получения информации о файле: $e');
      return null;
    }
  }

  /// Копировать файл
  Future<String> copyFile({
    required String sourcePath,
    required String destinationDirectory,
    String? newFileName,
  }) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('Исходный файл не найден: $sourcePath');
      }

      final destDir = Directory(destinationDirectory);
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }

      final fileName = newFileName ?? path.basename(sourcePath);
      final destPath = path.join(destinationDirectory, fileName);

      if (await File(destPath).exists()) {
        final nameWithoutExt = path.basenameWithoutExtension(fileName);
        final extension = path.extension(fileName);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final uniqueName = '${nameWithoutExt}_$timestamp$extension';
        final finalPath = path.join(destinationDirectory, uniqueName);
        await sourceFile.copy(finalPath);
        return finalPath;
      }

      await sourceFile.copy(destPath);
      return destPath;
    } catch (e) {
      throw Exception('Ошибка копирования файла: $e');
    }
  }

  /// Получить размер директории (в байтах)
  Future<int> getDirectorySize(String dirPath) async {
    try {
      final files = await getAllFilesInDirectory(dirPath);
      int totalSize = 0;
      for (final file in files) {
        totalSize += await file.length();
      }
      return totalSize;
    } catch (e) {
      print('Ошибка получения размера директории: $e');
      return 0;
    }
  }
}

/// Информация о файле
class FileInfo {
  final String path;
  final int size;
  final DateTime modified;
  final DateTime accessed;
  final bool isDirectory;

  const FileInfo({
    required this.path,
    required this.size,
    required this.modified,
    required this.accessed,
    required this.isDirectory,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
