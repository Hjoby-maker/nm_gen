// lib/core/services/thumbnail_generator.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Сервис для генерации миниатюр
class ThumbnailGenerator {
  static const int maxThumbnailSize = 512;

  /// Генерация миниатюры для изображения
  static Future<Uint8List?> generateImageThumbnail({
    required Uint8List imageData,
    int maxSize = maxThumbnailSize,
    int quality = 85,
  }) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        imageData,
        minWidth: maxSize,
        minHeight: maxSize,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      return result;
    } catch (e) {
      print('Ошибка генерации миниатюры изображения: $e');
      return null;
    }
  }

  /// Генерация миниатюры для видео
  static Future<Uint8List?> generateVideoThumbnail({
    required String videoPath,
    int quality = 50,
    int maxWidth = 512,
    int maxHeight = 512,
  }) async {
    try {
      final uint8list = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      );
      return uint8list;
    } catch (e) {
      print('Ошибка генерации миниатюры видео: $e');
      return null;
    }
  }

  /// Генерация миниатюры из файла (автоматическое определение типа)
  static Future<Uint8List?> generateThumbnail({
    required String filePath,
    required String mimeType,
    Uint8List? fileData,
    int maxSize = maxThumbnailSize,
  }) async {
    try {
      final data = fileData ?? await File(filePath).readAsBytes();

      if (mimeType.startsWith('image/')) {
        return await generateImageThumbnail(imageData: data, maxSize: maxSize);
      }

      if (mimeType.startsWith('video/')) {
        return await generateVideoThumbnail(
          videoPath: filePath,
          maxWidth: maxSize,
          maxHeight: maxSize,
        );
      }

      return null;
    } catch (e) {
      print('Ошибка генерации миниатюры: $e');
      return null;
    }
  }

  /// Проверка, поддерживается ли генерация миниатюр для данного типа
  static bool isThumbnailSupported(String mimeType) {
    return mimeType.startsWith('image/') || mimeType.startsWith('video/');
  }
}
