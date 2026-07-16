// lib/presentation/blocs/media/media_state.dart
import 'package:equatable/equatable.dart';

import '../../../data/models/media_filter.dart';
import '../../../data/models/media_sort.dart';
import '../../../domain/entities/media_attachment.dart';
import '../../../domain/repositories/media_repository.dart';

/// Базовое состояние медиа-блока
abstract class MediaState extends Equatable {
  const MediaState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Начальное состояние (ничего не загружено)
class MediaInitial extends MediaState {}

/// Состояние загрузки
class MediaLoading extends MediaState {}

/// Состояние загрузки с прогрессом
class MediaLoadingWithProgress extends MediaState {
  const MediaLoadingWithProgress({
    this.progress = 0.0,
    this.message = 'Загрузка...',
  });
  final double progress;
  final String message;

  @override
  List<Object?> get props => <Object?>[progress, message];
}

/// Состояние успешной загрузки списка медиа
class MediaLoaded extends MediaState {
  const MediaLoaded({
    required this.mediaList,
    this.appliedFilter,
    this.sortOrder = MediaSortOrder.newestFirst,
    this.totalCount = 0,
  });
  final List<MediaAttachment> mediaList;
  final MediaFilter? appliedFilter;
  final MediaSortOrder sortOrder;
  final int totalCount;

  /// Получить отфильтрованный список (если фильтр применен)
  List<MediaAttachment> get filteredList {
    if (appliedFilter == null) return mediaList;
    return mediaList
        .where((MediaAttachment media) => appliedFilter!.matches(media))
        .toList();
  }

  @override
  List<Object?> get props => <Object?>[
    mediaList,
    appliedFilter,
    sortOrder,
    totalCount,
  ];
}

/// Состояние с основным портретом
class PrimaryPortraitLoaded extends MediaState {
  const PrimaryPortraitLoaded({required this.portrait, required this.personId});
  final MediaAttachment? portrait;
  final String personId;

  @override
  List<Object?> get props => <Object?>[portrait, personId];
}

/// Состояние успешного добавления файла
class MediaFileAdded extends MediaState {
  const MediaFileAdded(this.media);
  final MediaAttachment media;

  @override
  List<Object?> get props => <Object?>[media];
}

/// Состояние успешного обновления
class MediaUpdated extends MediaState {
  const MediaUpdated(this.media);
  final MediaAttachment media;

  @override
  List<Object?> get props => <Object?>[media];
}

/// Состояние успешного удаления
class MediaDeleted extends MediaState {
  const MediaDeleted(this.mediaId);
  final String mediaId;

  @override
  List<Object?> get props => <Object?>[mediaId];
}

/// Состояние с загруженной статистикой
class MediaStatisticsLoaded extends MediaState {
  const MediaStatisticsLoaded(this.statistics);
  final MediaStatistics statistics;

  @override
  List<Object?> get props => <Object?>[statistics];
}

/// Состояние ошибки
class MediaError extends MediaState {
  const MediaError({required this.message, this.code, this.details});
  final String message;
  final String? code;
  final String? details;

  @override
  List<Object?> get props => <Object?>[message, code, details];
}

/// Состояние успешной операции (без данных)
class MediaOperationSuccess extends MediaState {
  const MediaOperationSuccess(this.message);
  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
