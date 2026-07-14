// lib/data/models/add_media_request.dart
import 'dart:typed_data';

/// DTO для добавления нового медиа-файла (из презентационного слоя)
class AddMediaRequest {
  final Uint8List fileData;
  final String fileName;
  final String mimeType;
  final String description;
  final String? personId;
  final String? eventId;
  final bool setAsPrimary;
  final bool generateThumbnail;

  const AddMediaRequest({
    required this.fileData,
    required this.fileName,
    required this.mimeType,
    required this.description,
    this.personId,
    this.eventId,
    this.setAsPrimary = false,
    this.generateThumbnail = true,
  }) : assert(
         (personId != null && eventId == null) ||
             (personId == null && eventId != null),
         'Файл должен быть привязан либо к Person, либо к Event',
       );

  bool get isValidSize => fileData.length <= 50 * 1024 * 1024;
  bool get isImage => mimeType.startsWith('image/');
  bool get isVideo => mimeType.startsWith('video/');

  String get safeFileName {
    final cleaned = fileName.replaceAll(RegExp(r'[^\w\s.-]'), '');
    return cleaned.isNotEmpty
        ? cleaned
        : 'file_${DateTime.now().millisecondsSinceEpoch}';
  }
}
