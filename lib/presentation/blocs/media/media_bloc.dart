// lib/presentation/blocs/media/media_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/core/errors/media_failures.dart';
import 'package:nm_gen/data/models/media_filter.dart';
import 'package:nm_gen/data/models/media_sort.dart';
import 'package:nm_gen/domain/entities/media_attachment.dart';
import 'package:nm_gen/domain/repositories/media_repository.dart';
import 'media_event.dart';
import 'media_state.dart';

/// BLoC для управления медиа-файлами
class MediaBloc extends Bloc<MediaEvent, MediaState> {
  final MediaRepository _repository;

  MediaBloc(this._repository) : super(MediaInitial()) {
    // Регистрация обработчиков событий
    on<LoadMediaForPerson>(_onLoadMediaForPerson);
    on<LoadMediaForEvent>(_onLoadMediaForEvent);
    on<LoadPrimaryPortrait>(_onLoadPrimaryPortrait);
    on<AddMediaFile>(_onAddMediaFile);
    on<UpdateMediaDescription>(_onUpdateMediaDescription);
    on<SetAsPrimaryPortrait>(_onSetAsPrimaryPortrait);
    on<DeleteMediaFile>(_onDeleteMediaFile);
    on<DeleteAllMediaForPerson>(_onDeleteAllMediaForPerson);
    on<DeleteAllMediaForEvent>(_onDeleteAllMediaForEvent);
    on<ApplyMediaFilter>(_onApplyMediaFilter);
    on<ApplyMediaSort>(_onApplyMediaSort);
    on<ClearMediaState>(_onClearMediaState);
    on<LoadMediaStatistics>(_onLoadMediaStatistics);
    on<MoveMediaFile>(_onMoveMediaFile);
  }

  /// Обработчик загрузки медиа для человека
  Future<void> _onLoadMediaForPerson(
    LoadMediaForPerson event,
    Emitter<MediaState> emit,
  ) async {
    try {
      emit(MediaLoading());

      final result = await _repository.getMediaByPerson(
        event.personId,
        filter: event.filter,
        sortOrder: event.sortOrder,
      );

      await result.fold(
        (failure) async {
          emit(
            MediaError(
              message: _getErrorMessage(failure),
              code: _getErrorCode(failure),
              details: _getErrorDetails(failure),
            ),
          );
        },
        (mediaList) async {
          emit(
            MediaLoaded(
              mediaList: mediaList,
              appliedFilter: event.filter,
              sortOrder: event.sortOrder,
              totalCount: mediaList.length,
            ),
          );
        },
      );
    } catch (e) {
      emit(MediaError(message: 'Неизвестная ошибка при загрузке медиа: $e'));
    }
  }

  /// Обработчик загрузки медиа для события
  Future<void> _onLoadMediaForEvent(
    LoadMediaForEvent event,
    Emitter<MediaState> emit,
  ) async {
    try {
      emit(MediaLoading());

      final result = await _repository.getMediaByEvent(
        event.eventId,
        filter: event.filter,
        sortOrder: event.sortOrder,
      );

      await result.fold(
        (failure) async {
          emit(
            MediaError(
              message: _getErrorMessage(failure),
              code: _getErrorCode(failure),
              details: _getErrorDetails(failure),
            ),
          );
        },
        (mediaList) async {
          emit(
            MediaLoaded(
              mediaList: mediaList,
              appliedFilter: event.filter,
              sortOrder: event.sortOrder,
              totalCount: mediaList.length,
            ),
          );
        },
      );
    } catch (e) {
      emit(MediaError(message: 'Неизвестная ошибка при загрузке медиа: $e'));
    }
  }

  /// Обработчик загрузки основного портрета
  Future<void> _onLoadPrimaryPortrait(
    LoadPrimaryPortrait event,
    Emitter<MediaState> emit,
  ) async {
    try {
      emit(MediaLoading());

      final result = await _repository.getPrimaryPortrait(event.personId);

      await result.fold(
        (failure) async {
          emit(
            MediaError(
              message: _getErrorMessage(failure),
              code: _getErrorCode(failure),
              details: _getErrorDetails(failure),
            ),
          );
        },
        (portrait) async {
          emit(
            PrimaryPortraitLoaded(portrait: portrait, personId: event.personId),
          );
        },
      );
    } catch (e) {
      emit(MediaError(message: 'Неизвестная ошибка при загрузке портрета: $e'));
    }
  }

  /// Обработчик добавления медиа-файла
  Future<void> _onAddMediaFile(
    AddMediaFile event,
    Emitter<MediaState> emit,
  ) async {
    try {
      emit(
        MediaLoadingWithProgress(progress: 0.0, message: 'Сохранение файла...'),
      );

      final result = await _repository.addMedia(
        fileData: event.fileData,
        fileName: event.fileName,
        mimeType: event.mimeType,
        description: event.description,
        personId: event.personId,
        eventId: event.eventId,
        setAsPrimary: event.setAsPrimary,
        generateThumbnail: event.generateThumbnail,
      );

      await result.fold(
        (failure) async {
          emit(
            MediaError(
              message: _getErrorMessage(failure),
              code: _getErrorCode(failure),
              details: _getErrorDetails(failure),
            ),
          );
        },
        (media) async {
          emit(MediaFileAdded(media));

          // Если файл добавлен к человеку, обновляем список
          if (event.personId != null) {
            add(LoadMediaForPerson(personId: event.personId!));
          } else if (event.eventId != null) {
            add(LoadMediaForEvent(eventId: event.eventId!));
          }
        },
      );
    } catch (e) {
      emit(MediaError(message: 'Неизвестная ошибка при добавлении файла: $e'));
    }
  }

  /// Обработчик обновления описания
  Future<void> _onUpdateMediaDescription(
    UpdateMediaDescription event,
    Emitter<MediaState> emit,
  ) async {
    try {
      emit(MediaLoading());

      final result = await _repository.updateMediaDescription(
        event.mediaId,
        event.newDescription,
      );

      await result.fold(
        (failure) async {
          emit(
            MediaError(
              message: _getErrorMessage(failure),
              code: _getErrorCode(failure),
              details: _getErrorDetails(failure),
            ),
          );
        },
        (media) async {
          emit(MediaUpdated(media));
          // Обновляем текущий список, если есть
          if (state is MediaLoaded) {
            final currentState = state as MediaLoaded;
            final updatedList = currentState.mediaList.map((m) {
              return m.id == media.id ? media : m;
            }).toList();
            emit(
              MediaLoaded(
                mediaList: updatedList,
                appliedFilter: currentState.appliedFilter,
                sortOrder: currentState.sortOrder,
                totalCount: updatedList.length,
              ),
            );
          }
        },
      );
    } catch (e) {
      emit(
        MediaError(message: 'Неизвестная ошибка при обновлении описания: $e'),
      );
    }
  }

  /// Обработчик установки основного портрета
  Future<void> _onSetAsPrimaryPortrait(
    SetAsPrimaryPortrait event,
    Emitter<MediaState> emit,
  ) async {
    try {
      emit(MediaLoading());

      final result = await _repository.setAsPrimaryPortrait(
        event.mediaId,
        event.personId,
      );

      await result.fold(
        (failure) async {
          emit(
            MediaError(
              message: _getErrorMessage(failure),
              code: _getErrorCode(failure),
              details: _getErrorDetails(failure),
            ),
          );
        },
        (media) async {
          emit(MediaUpdated(media));

          // Обновляем портрет
          add(LoadPrimaryPortrait(event.personId));

          // Обновляем список
          if (state is MediaLoaded) {
            final currentState = state as MediaLoaded;
            final updatedList = currentState.mediaList.map((m) {
              return m.id == media.id ? media : m.copyWith(isPrimary: false);
            }).toList();
            emit(
              MediaLoaded(
                mediaList: updatedList,
                appliedFilter: currentState.appliedFilter,
                sortOrder: currentState.sortOrder,
                totalCount: updatedList.length,
              ),
            );
          }
        },
      );
    } catch (e) {
      emit(
        MediaError(message: 'Неизвестная ошибка при установке портрета: $e'),
      );
    }
  }

  /// Обработчик удаления медиа-файла
  Future<void> _onDeleteMediaFile(
    DeleteMediaFile event,
    Emitter<MediaState> emit,
  ) async {
    try {
      emit(MediaLoading());

      final result = await _repository.deleteMedia(event.mediaId);

      await result.fold(
        (failure) async {
          emit(
            MediaError(
              message: _getErrorMessage(failure),
              code: _getErrorCode(failure),
              details: _getErrorDetails(failure),
            ),
          );
        },
        (_) async {
          emit(MediaDeleted(event.mediaId));

          // Обновляем текущий список, если есть
          if (state is MediaLoaded) {
            final currentState = state as MediaLoaded;
            final updatedList = currentState.mediaList
                .where((m) => m.id != event.mediaId)
                .toList();
            emit(
              MediaLoaded(
                mediaList: updatedList,
                appliedFilter: currentState.appliedFilter,
                sortOrder: currentState.sortOrder,
                totalCount: updatedList.length,
              ),
            );
          }
        },
      );
    } catch (e) {
      emit(MediaError(message: 'Неизвестная ошибка при удалении файла: $e'));
    }
  }

  /// Обработчик удаления всех медиа человека
  Future<void> _onDeleteAllMediaForPerson(
    DeleteAllMediaForPerson event,
    Emitter<MediaState> emit,
  ) async {
    try {
      emit(MediaLoading());

      final result = await _repository.deleteAllMediaByPerson(event.personId);

      await result.fold(
        (failure) async {
          emit(
            MediaError(
              message: _getErrorMessage(failure),
              code: _getErrorCode(failure),
              details: _getErrorDetails(failure),
            ),
          );
        },
        (_) async {
          emit(MediaOperationSuccess('Все медиа-файлы человека удалены'));
          // Очищаем список
          emit(MediaLoaded(mediaList: []));
        },
      );
    } catch (e) {
      emit(
        MediaError(message: 'Неизвестная ошибка при удалении всех файлов: $e'),
      );
    }
  }

  /// Обработчик удаления всех медиа события
  Future<void> _onDeleteAllMediaForEvent(
    DeleteAllMediaForEvent event,
    Emitter<MediaState> emit,
  ) async {
    try {
      emit(MediaLoading());

      final result = await _repository.deleteAllMediaByEvent(event.eventId);

      await result.fold(
        (failure) async {
          emit(
            MediaError(
              message: _getErrorMessage(failure),
              code: _getErrorCode(failure),
              details: _getErrorDetails(failure),
            ),
          );
        },
        (_) async {
          emit(MediaOperationSuccess('Все медиа-файлы события удалены'));
          emit(MediaLoaded(mediaList: []));
        },
      );
    } catch (e) {
      emit(
        MediaError(message: 'Неизвестная ошибка при удалении всех файлов: $e'),
      );
    }
  }

  /// Обработчик применения фильтра
  void _onApplyMediaFilter(ApplyMediaFilter event, Emitter<MediaState> emit) {
    if (state is MediaLoaded) {
      final currentState = state as MediaLoaded;
      final filteredList = event.filter != null
          ? currentState.mediaList
                .where((media) => event.filter!.matches(media))
                .toList()
          : currentState.mediaList;

      emit(
        MediaLoaded(
          mediaList: filteredList,
          appliedFilter: event.filter,
          sortOrder: currentState.sortOrder,
          totalCount: currentState.mediaList.length,
        ),
      );
    }
  }

  /// Обработчик применения сортировки
  void _onApplyMediaSort(ApplyMediaSort event, Emitter<MediaState> emit) {
    if (state is MediaLoaded) {
      final currentState = state as MediaLoaded;
      final sortedList = event.sortOrder.sort(currentState.mediaList);

      emit(
        MediaLoaded(
          mediaList: sortedList,
          appliedFilter: currentState.appliedFilter,
          sortOrder: event.sortOrder,
          totalCount: currentState.mediaList.length,
        ),
      );
    }
  }

  /// Обработчик очистки состояния
  void _onClearMediaState(ClearMediaState event, Emitter<MediaState> emit) {
    emit(MediaInitial());
  }

  /// Обработчик загрузки статистики
  Future<void> _onLoadMediaStatistics(
    LoadMediaStatistics event,
    Emitter<MediaState> emit,
  ) async {
    try {
      emit(MediaLoading());

      final result = await _repository.getStatistics(
        personId: event.personId,
        eventId: event.eventId,
      );

      await result.fold(
        (failure) async {
          emit(
            MediaError(
              message: _getErrorMessage(failure),
              code: _getErrorCode(failure),
              details: _getErrorDetails(failure),
            ),
          );
        },
        (statistics) async {
          emit(MediaStatisticsLoaded(statistics));
        },
      );
    } catch (e) {
      emit(
        MediaError(message: 'Неизвестная ошибка при загрузке статистики: $e'),
      );
    }
  }

  /// Обработчик перемещения медиа-файла
  Future<void> _onMoveMediaFile(
    MoveMediaFile event,
    Emitter<MediaState> emit,
  ) async {
    try {
      emit(MediaLoading());

      final result = await _repository.moveMedia(
        mediaId: event.mediaId,
        newPersonId: event.newPersonId,
        newEventId: event.newEventId,
      );

      await result.fold(
        (failure) async {
          emit(
            MediaError(
              message: _getErrorMessage(failure),
              code: _getErrorCode(failure),
              details: _getErrorDetails(failure),
            ),
          );
        },
        (media) async {
          emit(MediaUpdated(media));
          emit(MediaOperationSuccess('Файл успешно перемещен'));
        },
      );
    } catch (e) {
      emit(MediaError(message: 'Неизвестная ошибка при перемещении файла: $e'));
    }
  }

  // ============================================================
  // ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
  // ============================================================

  /// Получение сообщения об ошибке из Failure
  String _getErrorMessage(Failure failure) {
    if (failure is MediaFailure) {
      return failure.message;
    }
    return failure.toString();
  }

  /// Получение кода ошибки из Failure
  String? _getErrorCode(Failure failure) {
    if (failure is MediaValidationFailure) {
      return failure.code;
    }
    if (failure is FileSaveFailure) {
      return failure.code;
    }
    if (failure is FileDeleteFailure) {
      return failure.code;
    }
    return null;
  }

  /// Получение деталей ошибки из Failure
  String? _getErrorDetails(Failure failure) {
    if (failure is FileSystemFailure) {
      return 'Путь: ${failure.path}';
    }
    if (failure is FileSaveFailure) {
      return 'Файл: ${failure.fileName}';
    }
    if (failure is FileDeleteFailure) {
      return 'ID: ${failure.path}';
    }
    if (failure is MediaNotFoundFailure) {
      return 'ID: ${failure.id}';
    }
    return null;
  }
}
