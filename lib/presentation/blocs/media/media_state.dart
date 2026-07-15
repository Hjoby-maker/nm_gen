// lib/presentation/blocs/media/media_state.dart
import 'package:equatable/equatable.dart';
import '../../../domain/entities/media_attachment.dart';
import '../../../domain/repositories/media_repository.dart';
import '../../../data/models/media_sort.dart';
import '../../../data/models/media_filter.dart';

/// Базовое состояние медиа-блока
abstract class MediaState extends Equatable {
  const MediaState();

  @override
  List<Object?> get props => [];
}

/// Начальное состояние (ничего не загружено)
class MediaInitial extends MediaState {}

/// Состояние загрузки
class MediaLoading extends MediaState {}

/// Состояние загрузки с прогрессом
class MediaLoadingWithProgress extends MediaState {
  final double progress;
  final String message;

  const MediaLoadingWithProgress({
    this.progress = 0.0,
    this.message = 'Загрузка...',
  });

  @override
  List<Object?> get props => [progress, message];
}

/// Состояние успешной загрузки списка медиа
class MediaLoaded extends MediaState {
  final List<MediaAttachment> mediaList;
  final MediaFilter? appliedFilter;
  final MediaSortOrder sortOrder;
  final int totalCount;

  const MediaLoaded({
    required this.mediaList,
    this.appliedFilter,
    this.sortOrder = MediaSortOrder.newestFirst,
    this.totalCount = 0,
  });

  /// Получить отфильтрованный список (если фильтр применен)
  List<MediaAttachment> get filteredList {
    if (appliedFilter == null) return mediaList;
    return mediaList.where((media) => appliedFilter!.matches(media)).toList();
  }

  @override
  List<Object?> get props => [mediaList, appliedFilter, sortOrder, totalCount];
}

/// Состояние с основным портретом
class PrimaryPortraitLoaded extends MediaState {
  final MediaAttachment? portrait;
  final String personId;

  const PrimaryPortraitLoaded({required this.portrait, required this.personId});

  @override
  List<Object?> get props => [portrait, personId];
}

/// Состояние успешного добавления файла
class MediaFileAdded extends MediaState {
  final MediaAttachment media;

  const MediaFileAdded(this.media);

  @override
  List<Object?> get props => [media];
}

/// Состояние успешного обновления
class MediaUpdated extends MediaState {
  final MediaAttachment media;

  const MediaUpdated(this.media);

  @override
  List<Object?> get props => [media];
}

/// Состояние успешного удаления
class MediaDeleted extends MediaState {
  final String mediaId;

  const MediaDeleted(this.mediaId);

  @override
  List<Object?> get props => [mediaId];
}

/// Состояние с загруженной статистикой
class MediaStatisticsLoaded extends MediaState {
  final MediaStatistics statistics;

  const MediaStatisticsLoaded(this.statistics);

  @override
  List<Object?> get props => [statistics];
}

/// Состояние ошибки
class MediaError extends MediaState {
  final String message;
  final String? code;
  final String? details;

  const MediaError({required this.message, this.code, this.details});

  @override
  List<Object?> get props => [message, code, details];
}

/// Состояние успешной операции (без данных)
class MediaOperationSuccess extends MediaState {
  final String message;

  const MediaOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
