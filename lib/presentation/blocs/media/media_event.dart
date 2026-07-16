// lib/presentation/blocs/media/media_event.dart
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../../data/models/media_filter.dart';
import '../../../data/models/media_sort.dart';

/// Базовый класс для событий медиа-блока
abstract class MediaEvent extends Equatable {
  const MediaEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Загрузить медиа для человека
class LoadMediaForPerson extends MediaEvent {
  const LoadMediaForPerson({
    required this.personId,
    this.filter,
    this.sortOrder = MediaSortOrder.newestFirst,
  });
  final String personId;
  final MediaFilter? filter;
  final MediaSortOrder sortOrder;

  @override
  List<Object?> get props => <Object?>[personId, filter, sortOrder];
}

/// Загрузить медиа для события
class LoadMediaForEvent extends MediaEvent {
  const LoadMediaForEvent({
    required this.eventId,
    this.filter,
    this.sortOrder = MediaSortOrder.newestFirst,
  });
  final String eventId;
  final MediaFilter? filter;
  final MediaSortOrder sortOrder;

  @override
  List<Object?> get props => <Object?>[eventId, filter, sortOrder];
}

/// Загрузить основной портрет человека
class LoadPrimaryPortrait extends MediaEvent {
  const LoadPrimaryPortrait(this.personId);
  final String personId;

  @override
  List<Object?> get props => <Object?>[personId];
}

/// Добавить новый медиа-файл
class AddMediaFile extends MediaEvent {
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
  final Uint8List fileData;
  final String fileName;
  final String mimeType;
  final String description;
  final String? personId;
  final String? eventId;
  final bool setAsPrimary;
  final bool generateThumbnail;

  @override
  List<Object?> get props => <Object?>[
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
  const UpdateMediaDescription({
    required this.mediaId,
    required this.newDescription,
  });
  final String mediaId;
  final String newDescription;

  @override
  List<Object?> get props => <Object?>[mediaId, newDescription];
}

/// Установить файл как основной портрет
class SetAsPrimaryPortrait extends MediaEvent {
  const SetAsPrimaryPortrait({required this.mediaId, required this.personId});
  final String mediaId;
  final String personId;

  @override
  List<Object?> get props => <Object?>[mediaId, personId];
}

/// Удалить медиа-файл
class DeleteMediaFile extends MediaEvent {
  const DeleteMediaFile(this.mediaId);
  final String mediaId;

  @override
  List<Object?> get props => <Object?>[mediaId];
}

/// Удалить все медиа человека
class DeleteAllMediaForPerson extends MediaEvent {
  const DeleteAllMediaForPerson(this.personId);
  final String personId;

  @override
  List<Object?> get props => <Object?>[personId];
}

/// Удалить все медиа события
class DeleteAllMediaForEvent extends MediaEvent {
  const DeleteAllMediaForEvent(this.eventId);
  final String eventId;

  @override
  List<Object?> get props => <Object?>[eventId];
}

/// Применить фильтр
class ApplyMediaFilter extends MediaEvent {
  const ApplyMediaFilter(this.filter);
  final MediaFilter? filter;

  @override
  List<Object?> get props => <Object?>[filter];
}

/// Применить сортировку
class ApplyMediaSort extends MediaEvent {
  const ApplyMediaSort(this.sortOrder);
  final MediaSortOrder sortOrder;

  @override
  List<Object?> get props => <Object?>[sortOrder];
}

/// Очистить состояние
class ClearMediaState extends MediaEvent {}

/// Загрузить статистику
class LoadMediaStatistics extends MediaEvent {
  const LoadMediaStatistics({this.personId, this.eventId});
  final String? personId;
  final String? eventId;

  @override
  List<Object?> get props => <Object?>[personId, eventId];
}

/// Переместить медиа-файл
class MoveMediaFile extends MediaEvent {
  const MoveMediaFile({
    required this.mediaId,
    this.newPersonId,
    this.newEventId,
  });
  final String mediaId;
  final String? newPersonId;
  final String? newEventId;

  @override
  List<Object?> get props => <Object?>[mediaId, newPersonId, newEventId];
}
