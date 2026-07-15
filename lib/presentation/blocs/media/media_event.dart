// lib/presentation/blocs/media/media_event.dart
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../../data/models/media_filter.dart';
import '../../../data/models/media_sort.dart';

/// Базовый класс для событий медиа-блока
abstract class MediaEvent extends Equatable {
  const MediaEvent();

  @override
  List<Object?> get props => [];
}

/// Загрузить медиа для человека
class LoadMediaForPerson extends MediaEvent {
  final String personId;
  final MediaFilter? filter;
  final MediaSortOrder sortOrder;

  const LoadMediaForPerson({
    required this.personId,
    this.filter,
    this.sortOrder = MediaSortOrder.newestFirst,
  });

  @override
  List<Object?> get props => [personId, filter, sortOrder];
}

/// Загрузить медиа для события
class LoadMediaForEvent extends MediaEvent {
  final String eventId;
  final MediaFilter? filter;
  final MediaSortOrder sortOrder;

  const LoadMediaForEvent({
    required this.eventId,
    this.filter,
    this.sortOrder = MediaSortOrder.newestFirst,
  });

  @override
  List<Object?> get props => [eventId, filter, sortOrder];
}

/// Загрузить основной портрет человека
class LoadPrimaryPortrait extends MediaEvent {
  final String personId;

  const LoadPrimaryPortrait(this.personId);

  @override
  List<Object?> get props => [personId];
}

/// Добавить новый медиа-файл
class AddMediaFile extends MediaEvent {
  final Uint8List fileData;
  final String fileName;
  final String mimeType;
  final String description;
  final String? personId;
  final String? eventId;
  final bool setAsPrimary;
  final bool generateThumbnail;

  const AddMediaFile({
    required this.fileData,
    required this.fileName,
    required this.mimeType,
    required this.description,
    this.personId,
    this.eventId,
    this.setAsPrimary = false,
    this.generateThumbnail = true,
  });

  @override
  List<Object?> get props => [
    fileData,
    fileName,
    mimeType,
    description,
    personId,
    eventId,
    setAsPrimary,
    generateThumbnail,
  ];
}

/// Обновить описание медиа-файла
class UpdateMediaDescription extends MediaEvent {
  final String mediaId;
  final String newDescription;

  const UpdateMediaDescription({
    required this.mediaId,
    required this.newDescription,
  });

  @override
  List<Object?> get props => [mediaId, newDescription];
}

/// Установить файл как основной портрет
class SetAsPrimaryPortrait extends MediaEvent {
  final String mediaId;
  final String personId;

  const SetAsPrimaryPortrait({required this.mediaId, required this.personId});

  @override
  List<Object?> get props => [mediaId, personId];
}

/// Удалить медиа-файл
class DeleteMediaFile extends MediaEvent {
  final String mediaId;

  const DeleteMediaFile(this.mediaId);

  @override
  List<Object?> get props => [mediaId];
}

/// Удалить все медиа человека
class DeleteAllMediaForPerson extends MediaEvent {
  final String personId;

  const DeleteAllMediaForPerson(this.personId);

  @override
  List<Object?> get props => [personId];
}

/// Удалить все медиа события
class DeleteAllMediaForEvent extends MediaEvent {
  final String eventId;

  const DeleteAllMediaForEvent(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

/// Применить фильтр
class ApplyMediaFilter extends MediaEvent {
  final MediaFilter? filter;

  const ApplyMediaFilter(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// Применить сортировку
class ApplyMediaSort extends MediaEvent {
  final MediaSortOrder sortOrder;

  const ApplyMediaSort(this.sortOrder);

  @override
  List<Object?> get props => [sortOrder];
}

/// Очистить состояние
class ClearMediaState extends MediaEvent {}

/// Загрузить статистику
class LoadMediaStatistics extends MediaEvent {
  final String? personId;
  final String? eventId;

  const LoadMediaStatistics({this.personId, this.eventId});

  @override
  List<Object?> get props => [personId, eventId];
}

/// Переместить медиа-файл
class MoveMediaFile extends MediaEvent {
  final String mediaId;
  final String? newPersonId;
  final String? newEventId;

  const MoveMediaFile({
    required this.mediaId,
    this.newPersonId,
    this.newEventId,
  });

  @override
  List<Object?> get props => [mediaId, newPersonId, newEventId];
}
