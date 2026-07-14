// lib/data/models/media_sort.dart
import '../../domain/entities/media_attachment.dart';

/// Способы сортировки медиа-файлов
enum MediaSortOrder {
  newestFirst,
  oldestFirst,
  nameAsc,
  nameDesc,
  sizeAsc,
  sizeDesc,
}

extension MediaSortOrderExtension on MediaSortOrder {
  String get displayName {
    switch (this) {
      case MediaSortOrder.newestFirst:
        return 'Сначала новые';
      case MediaSortOrder.oldestFirst:
        return 'Сначала старые';
      case MediaSortOrder.nameAsc:
        return 'По имени (А-Я)';
      case MediaSortOrder.nameDesc:
        return 'По имени (Я-А)';
      case MediaSortOrder.sizeAsc:
        return 'По размеру (возр.)';
      case MediaSortOrder.sizeDesc:
        return 'По размеру (убыв.)';
    }
  }

  /// Сортировка списка медиа
  List<MediaAttachment> sort(List<MediaAttachment> media) {
    final sorted = [...media];
    switch (this) {
      case MediaSortOrder.newestFirst:
        sorted.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        ); // ← createdAt не null
        break;
      case MediaSortOrder.oldestFirst:
        sorted.sort(
          (a, b) => a.createdAt.compareTo(b.createdAt),
        ); // ← createdAt не null
        break;
      case MediaSortOrder.nameAsc:
        sorted.sort(
          (a, b) => a.fileName.compareTo(b.fileName),
        ); // ← fileName не null
        break;
      case MediaSortOrder.nameDesc:
        sorted.sort(
          (a, b) => b.fileName.compareTo(a.fileName),
        ); // ← fileName не null
        break;
      case MediaSortOrder.sizeAsc:
        sorted.sort(
          (a, b) => a.fileSize.compareTo(b.fileSize),
        ); // ← fileSize не null
        break;
      case MediaSortOrder.sizeDesc:
        sorted.sort(
          (a, b) => b.fileSize.compareTo(a.fileSize),
        ); // ← fileSize не null
        break;
    }
    return sorted;
  }
}
