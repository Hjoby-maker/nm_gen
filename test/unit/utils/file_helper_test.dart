// test/unit/utils/file_helper_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nm_gen/core/utils/file_helper.dart';

void main() {
  group('FileHelper', () {
    group('formatFileSize', () {
      test('форматирует байты в читаемый формат', () {
        expect(FileHelper.formatFileSize(0), '0 B');
        expect(FileHelper.formatFileSize(500), '500 B');
        expect(FileHelper.formatFileSize(1024), '1.0 KB');
        expect(FileHelper.formatFileSize(1536), '1.5 KB');
        expect(FileHelper.formatFileSize(1048576), '1.0 MB');
        expect(FileHelper.formatFileSize(1073741824), '1.0 GB');
      });
    });

    group('getFileExtension', () {
      test('возвращает расширение файла', () {
        expect(FileHelper.getFileExtension('image.jpg'), 'jpg');
        expect(FileHelper.getFileExtension('document.pdf'), 'pdf');
        expect(FileHelper.getFileExtension('file'), '');
        expect(FileHelper.getFileExtension('file.tar.gz'), 'gz');
      });
    });

    group('isImageByExtension', () {
      test('определяет изображения по расширению', () {
        expect(FileHelper.isImageByExtension('photo.jpg'), true);
        expect(FileHelper.isImageByExtension('photo.png'), true);
        expect(FileHelper.isImageByExtension('photo.gif'), true);
        expect(FileHelper.isImageByExtension('photo.webp'), true);
        expect(FileHelper.isImageByExtension('video.mp4'), false);
        expect(FileHelper.isImageByExtension('document.pdf'), false);
      });
    });

    group('isVideoByExtension', () {
      test('определяет видео по расширению', () {
        expect(FileHelper.isVideoByExtension('video.mp4'), true);
        expect(FileHelper.isVideoByExtension('video.avi'), true);
        expect(FileHelper.isVideoByExtension('video.mov'), true);
        expect(FileHelper.isVideoByExtension('photo.jpg'), false);
        expect(FileHelper.isVideoByExtension('document.pdf'), false);
      });
    });

    group('isAudioByExtension', () {
      test('определяет аудио по расширению', () {
        expect(FileHelper.isAudioByExtension('audio.mp3'), true);
        expect(FileHelper.isAudioByExtension('audio.wav'), true);
        expect(FileHelper.isAudioByExtension('audio.flac'), true);
        expect(FileHelper.isAudioByExtension('photo.jpg'), false);
        expect(FileHelper.isAudioByExtension('video.mp4'), false);
      });
    });

    group('isDocumentByExtension', () {
      test('определяет документы по расширению', () {
        expect(FileHelper.isDocumentByExtension('document.pdf'), true);
        expect(FileHelper.isDocumentByExtension('document.docx'), true);
        expect(FileHelper.isDocumentByExtension('document.txt'), true);
        expect(FileHelper.isDocumentByExtension('photo.jpg'), false);
        expect(FileHelper.isDocumentByExtension('video.mp4'), false);
      });
    });

    group('isThumbnailSupported', () {
      test('определяет поддерживаемые типы для миниатюр', () {
        expect(FileHelper.isThumbnailSupported('image/jpeg'), true);
        expect(FileHelper.isThumbnailSupported('image/png'), true);
        expect(FileHelper.isThumbnailSupported('video/mp4'), true);
        expect(FileHelper.isThumbnailSupported('application/pdf'), false);
        expect(FileHelper.isThumbnailSupported('audio/mpeg'), false);
      });
    });

    group('getMimeTypeFromExtension', () {
      test('возвращает MIME-тип по расширению', () {
        expect(FileHelper.getMimeTypeFromExtension('image.jpg'), 'image/jpeg');
        expect(FileHelper.getMimeTypeFromExtension('image.png'), 'image/png');
        expect(FileHelper.getMimeTypeFromExtension('video.mp4'), 'video/mp4');
        expect(
          FileHelper.getMimeTypeFromExtension('document.pdf'),
          'application/pdf',
        );
        expect(
          FileHelper.getMimeTypeFromExtension('unknown.xyz'),
          'application/octet-stream',
        );
      });
    });

    group('createTypeGroup', () {
      test('создает XTypeGroup с правильными параметрами', () {
        final group = FileHelper.createTypeGroup(
          label: 'Images',
          extensions: ['jpg', 'png'],
          mimeTypes: ['image/*'],
        );

        expect(group.label, 'Images');
        expect(group.extensions, ['jpg', 'png']);
        expect(group.mimeTypes, ['image/*']);
      });

      test('создает XTypeGroup с пустыми mimeTypes если не указаны', () {
        final group = FileHelper.createTypeGroup(
          label: 'Files',
          extensions: ['*'],
        );

        expect(group.mimeTypes, isEmpty);
      });
    });
  });
}
