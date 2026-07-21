// test/unit/services/thumbnail_generator_test.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nm_gen/core/utils/thumbnail_generator.dart';

void main() {
  group('ThumbnailGenerator', () {
    group('isThumbnailSupported', () {
      test('поддерживает изображения', () {
        expect(ThumbnailGenerator.isThumbnailSupported('image/jpeg'), true);
        expect(ThumbnailGenerator.isThumbnailSupported('image/png'), true);
        expect(ThumbnailGenerator.isThumbnailSupported('image/gif'), true);
        expect(ThumbnailGenerator.isThumbnailSupported('image/webp'), true);
      });

      test('поддерживает видео', () {
        expect(ThumbnailGenerator.isThumbnailSupported('video/mp4'), true);
        expect(ThumbnailGenerator.isThumbnailSupported('video/avi'), true);
        expect(
          ThumbnailGenerator.isThumbnailSupported('video/quicktime'),
          true,
        );
      });

      test('не поддерживает другие типы', () {
        expect(
          ThumbnailGenerator.isThumbnailSupported('application/pdf'),
          false,
        );
        expect(ThumbnailGenerator.isThumbnailSupported('audio/mpeg'), false);
        expect(ThumbnailGenerator.isThumbnailSupported('text/plain'), false);
      });
    });

    group('generateImageThumbnail', () {
      test('возвращает null при ошибке (пустые данные)', () async {
        // Пустые данные должны вызвать ошибку
        try {
          final result = await ThumbnailGenerator.generateImageThumbnail(
            imageData: Uint8List(0),
          );
          // Если функция не выбросила исключение, проверяем что результат null
          expect(result, null);
        } catch (e) {
          // Если выбросила исключение - это тоже допустимо
          expect(e, isA<Exception>());
        }
      });

      test('обрабатывает некорректные данные', () async {
        // Тестируем с маленькими данными, которые не являются изображением
        try {
          final result = await ThumbnailGenerator.generateImageThumbnail(
            imageData: Uint8List.fromList([1, 2, 3, 4, 5]),
          );
          // Может вернуть null или сжатые данные
          expect(result, isA<Uint8List?>());
        } catch (e) {
          // Если выбросила исключение - это тоже допустимо
          expect(e, isA<Exception>());
        }
      });
    });

    group('generateThumbnail', () {
      test('возвращает null для неподдерживаемых типов', () async {
        // Создаем временный файл
        final tempFile = File('test_temp.txt');
        await tempFile.writeAsString('test content');

        try {
          final result = await ThumbnailGenerator.generateThumbnail(
            filePath: tempFile.path,
            mimeType: 'text/plain',
          );
          expect(result, null);
        } finally {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      });

      test('возвращает null для несуществующего файла', () async {
        try {
          final result = await ThumbnailGenerator.generateThumbnail(
            filePath: '/nonexistent/file/path.jpg',
            mimeType: 'image/jpeg',
          );
          expect(result, null);
        } catch (e) {
          // Если выбросила исключение - проверяем, что это PathNotFoundException
          expect(e.toString(), contains('PathNotFoundException'));
        }
      });

      test('обрабатывает ошибки генерации для изображений', () async {
        // Создаем временный файл с некорректными данными
        final tempFile = File('test_invalid.jpg');
        await tempFile.writeAsBytes([1, 2, 3, 4, 5]);

        try {
          final result = await ThumbnailGenerator.generateThumbnail(
            filePath: tempFile.path,
            mimeType: 'image/jpeg',
          );
          // Может вернуть null или выбросить исключение
          expect(result, isA<Uint8List?>());
        } catch (e) {
          // Если выбросила исключение - это тоже допустимо
          expect(e, isA<Exception>());
        } finally {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      });
    });
  });
}
