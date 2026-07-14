// lib/data/models/media_filter.dart
import '../../domain/entities/media_attachment.dart';

/// Модель фильтрации медиа-файлов
class MediaFilter {
  final MediaType? mediaType;
  final String? searchQuery;
  final bool? isPrimaryOnly;
  final DateTime? fromDate;
  final DateTime? toDate;

  const MediaFilter({
    this.mediaType,
    this.searchQuery,
    this.isPrimaryOnly,
    this.fromDate,
    this.toDate,
  });

  /// Проверка, соответствует ли файл фильтру
  bool matches(MediaAttachment media) {
    if (mediaType != null && media.mediaType != mediaType) return false;
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      final name = media.fileName.toLowerCase();
      final desc = media.description.toLowerCase();
      if (!name.contains(query) && !desc.contains(query)) return false;
    }
    if (isPrimaryOnly == true && !media.isPrimary) return false;
    if (fromDate != null && media.createdAt.isBefore(fromDate!)) return false;
    if (toDate != null && media.createdAt.isAfter(toDate!)) return false;
    return true;
  }
}
