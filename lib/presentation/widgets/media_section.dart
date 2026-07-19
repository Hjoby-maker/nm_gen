// lib/presentation/widgets/media/media_section.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/entities/media_attachment.dart';
import 'package:nm_gen/presentation/blocs/event/event_bloc.dart';
import 'package:nm_gen/presentation/blocs/event/event_event.dart';
import 'package:nm_gen/presentation/blocs/event/event_state.dart';
import 'package:nm_gen/presentation/blocs/media/media_bloc.dart';
import 'package:nm_gen/presentation/blocs/media/media_event.dart';
import 'package:nm_gen/presentation/blocs/media/media_state.dart';
import 'package:nm_gen/presentation/widgets/media_card.dart';
import 'package:nm_gen/presentation/widgets/media_picker_sheet.dart';

/// Секция с медиа-файлами для отображения в профиле человека или события
class MediaSection extends StatefulWidget {
  const MediaSection({
    super.key,
    this.personId,
    this.eventId,
    this.showPrimaryBadge = true,
  });
  final String? personId;
  final String? eventId;
  final bool showPrimaryBadge;

  @override
  State<MediaSection> createState() => _MediaSectionState();
}

class _MediaSectionState extends State<MediaSection> {
  // ✅ Кэш последнего известного списка файлов ЭТОЙ секции. MediaBloc общий
  // на весь экран - через него проходят и не относящиеся к списку файлов
  // состояния (успех операции, статистика и т.д.). Раньше _buildContent
  // для любого "непрофильного" состояния возвращал SizedBox.shrink()
  // (пустоту) - теперь в таких случаях показываем последний известный
  // список вместо пустого экрана.
  List<MediaAttachment>? _cachedMediaList;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  void _loadMedia() {
    final bloc = context.read<MediaBloc>();
    if (widget.personId != null) {
      bloc.add(LoadMediaForPerson(personId: widget.personId!));
    } else if (widget.eventId != null) {
      bloc.add(LoadMediaForEvent(eventId: widget.eventId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MediaBloc, MediaState>(
      listener: (context, state) {
        if (state is MediaLoaded) {
          _cachedMediaList = state.mediaList;
        }
        if (state is MediaError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
        if (state is MediaOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          _loadMedia();
        }
        if (state is MediaFileAdded ||
            state is MediaDeleted ||
            state is MediaUpdated) {
          _loadMedia();
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с кнопкой добавления
            _buildHeader(context),
            const SizedBox(height: 8),
            // Содержимое
            _buildContent(context, state),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Файлы',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () => _showAddMediaSheet(context),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Добавить'),
          style: TextButton.styleFrom(foregroundColor: Colors.green),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, MediaState state) {
    if (state is MediaLoading || state is MediaLoadingWithProgress) {
      // Если уже есть закэшированный список - продолжаем его показывать
      // вместо того, чтобы схлопывать в спиннер на пустом месте при каждой
      // фоновой перезагрузке (после добавления/удаления файла и т.п.).
      if (_cachedMediaList != null && _cachedMediaList!.isNotEmpty) {
        return _buildGrid(context, _cachedMediaList!);
      }
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state is MediaError) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(child: Text(state.message)),
              TextButton(onPressed: _loadMedia, child: const Text('Повторить')),
            ],
          ),
        ),
      );
    }

    if (state is MediaLoaded) {
      if (state.mediaList.isEmpty) {
        return _buildEmptyState(context);
      }
      return _buildGrid(context, state.mediaList);
    }

    // ✅ Любое другое состояние MediaBloc (PrimaryPortraitLoaded,
    // MediaFileAdded, MediaUpdated, MediaDeleted, MediaOperationSuccess,
    // MediaInitial и т.д.) не имеет отношения к списку файлов ЭТОЙ секции -
    // это НЕ повод показывать пустоту. Показываем последний известный
    // список, если он есть.
    if (_cachedMediaList != null) {
      if (_cachedMediaList!.isEmpty) {
        return _buildEmptyState(context);
      }
      return _buildGrid(context, _cachedMediaList!);
    }

    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<MediaAttachment> mediaList) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: mediaList.length,
      itemBuilder: (context, index) {
        final media = mediaList[index];
        return MediaCard(
          media: media,
          isPrimary: widget.showPrimaryBadge && media.isPrimary,
          onTap: () => _showMediaDetails(context, media),
          onDelete: () => _confirmDelete(context, media.id),
          onSetPrimary: widget.personId != null
              ? () => _setPrimaryPortrait(context, media.id)
              : null,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 8),
              Text('Нет файлов', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _showAddMediaSheet(context),
                child: const Text('Добавить файл'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMediaSheet(BuildContext context) {
    final mediaBloc = context.read<MediaBloc>();
    MediaPickerSheet.show(
      context: context,
      personId: widget.personId,
      eventId: widget.eventId,
      mediaBloc: mediaBloc,
    );
  }

  void _showMediaDetails(BuildContext context, MediaAttachment media) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Превью
              Expanded(child: Center(child: _buildPreview(media))),
              const SizedBox(height: 16),
              // Информация
              Text(
                media.description,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Имя файла: ${media.fileName}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              Text(
                'Размер: ${media.formattedSize}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              Text(
                'Добавлен: ${_formatDate(media.createdAt)}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              // ✅ Кнопка "Открыть" - для внешней ссылки открывает браузер,
              // для файла с устройства - пытается открыть его во внешнем
              // приложении (best-effort, см. _openAttachment).
              if (media.isExternalLink || media.isDeviceReference)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openAttachment(context, media),
                      icon: Icon(
                        media.isExternalLink
                            ? Icons.open_in_new
                            : Icons.folder_open,
                      ),
                      label: Text(
                        media.isExternalLink ? 'Открыть ссылку' : 'Открыть файл',
                      ),
                    ),
                  ),
                ),
              // ✅ "Связать с событием" - только для файлов, у которых есть
              // personId (файл с личной вкладки "Файлы"). Файлы, созданные
              // напрямую в форме события, уже привязаны к нему.
              if (widget.personId != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showLinkToEventPicker(context, media),
                      icon: const Icon(Icons.event_note),
                      label: Text(
                        media.eventId != null
                            ? 'Изменить привязку к событию'
                            : 'Связать с событием',
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  if (widget.personId != null && !media.isPrimary)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _setPrimaryPortrait(context, media.id);
                        },
                        icon: const Icon(Icons.star_border),
                        label: const Text('Сделать основным'),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditDescriptionDialog(context, media);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Редактировать'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDelete(context, media.id);
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        'Удалить',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(MediaAttachment media) {
    // ✅ Внешняя ссылка - локального файла нет вообще.
    if (media.isExternalLink) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link, size: 64, color: Colors.blue.shade400),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              media.remoteUrl ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
            ),
          ),
        ],
      );
    }

    // ✅ Файл-ссылка с устройства, которого сейчас нет на диске.
    final bool fileMissing =
        media.localPath == null || !File(media.localPath!).existsSync();
    if (media.isDeviceReference && fileMissing) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link_off, size: 64, color: Colors.orange.shade400),
          const SizedBox(height: 8),
          Text(
            'Файл недоступен',
            style: TextStyle(color: Colors.orange.shade800),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Возможно, он был перемещён или удалён на устройстве',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        ],
      );
    }

    if (media.isImage && media.localPath != null) {
      return Image.file(
        File(media.localPath!),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 64),
      );
    } else if (media.isVideo) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.play_circle_filled, size: 64, color: Colors.blue),
          const SizedBox(height: 8),
          Text('Видео: ${media.fileName}'),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file, size: 64, color: Colors.grey),
          const SizedBox(height: 8),
          Text('${media.mediaType.displayName}: ${media.fileName}'),
        ],
      );
    }
  }

  /// Открыть вложение: внешнюю ссылку - в браузере, файл с устройства -
  /// во внешнем приложении по умолчанию для этого типа файла.
  /// Best-effort: для файла с устройства нет гарантии, что он всё ещё
  /// существует или что на платформе найдётся приложение, способное его
  /// открыть - в этом случае просто показываем понятную ошибку.
  Future<void> _openAttachment(BuildContext context, MediaAttachment media) async {
    try {
      if (media.isExternalLink) {
        final Uri? uri = Uri.tryParse(media.remoteUrl ?? '');
        if (uri == null) {
          _showOpenError(context, 'Некорректная ссылка');
          return;
        }
        final bool launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched && context.mounted) {
          _showOpenError(context, 'Не удалось открыть ссылку');
        }
        return;
      }

      // deviceReference
      final String? path = media.localPath;
      if (path == null || !File(path).existsSync()) {
        if (context.mounted) {
          _showOpenError(
            context,
            'Файл недоступен - возможно, он был перемещён или удалён на устройстве',
          );
        }
        return;
      }

      final Uri fileUri = Uri.file(path);
      final bool launched = await launchUrl(fileUri);
      if (!launched && context.mounted) {
        _showOpenError(
          context,
          'Не найдено приложение, способное открыть этот файл',
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showOpenError(context, 'Ошибка открытия: $e');
      }
    }
  }

  void _showOpenError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }

  /// Показывает список событий человека и позволяет выбрать, к какому из
  /// них привязать файл (или отвязать, если уже привязан).
  void _showLinkToEventPicker(BuildContext context, MediaAttachment media) {
    final EventBloc eventBloc = context.read<EventBloc>();
    // Событий может быть ещё не загружено (если пользователь не открывал
    // вкладку "События") - подгружаем на всякий случай, BlocBuilder ниже
    // сам обновится, когда придёт EventsLoaded.
    if (widget.personId != null) {
      eventBloc.add(LoadPersonEventsEvent(widget.personId!));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (sheetContext, scrollController) {
          return BlocBuilder<EventBloc, EventState>(
            bloc: eventBloc,
            builder: (context, state) {
              if (state is EventLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is! EventsLoaded) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Не удалось загрузить список событий'),
                  ),
                );
              }

              final List<Event> events = state.events;

              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Связать с событием',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (media.eventId != null)
                    ListTile(
                      leading: const Icon(Icons.link_off, color: Colors.red),
                      title: const Text('Отвязать от события'),
                      onTap: () {
                        _mediaBloc.add(
                          LinkMediaToEvent(mediaId: media.id, eventId: null),
                        );
                        Navigator.pop(sheetContext);
                      },
                    ),
                  if (events.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'У этого человека пока нет событий',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...events.map((Event evt) {
                      final bool isCurrent = evt.id == media.eventId;
                      return ListTile(
                        leading: Icon(
                          Icons.event,
                          color: isCurrent ? Colors.green : Colors.grey.shade700,
                        ),
                        title: Text(evt.title),
                        trailing: isCurrent
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                        onTap: () {
                          _mediaBloc.add(
                            LinkMediaToEvent(mediaId: media.id, eventId: evt.id),
                          );
                          Navigator.pop(sheetContext);
                        },
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  MediaBloc get _mediaBloc => context.read<MediaBloc>();

  void _showEditDescriptionDialog(BuildContext context, MediaAttachment media) {
    final controller = TextEditingController(text: media.description);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать описание'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Описание',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<MediaBloc>().add(
                  UpdateMediaDescription(
                    mediaId: media.id,
                    newDescription: controller.text.trim(),
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _setPrimaryPortrait(BuildContext context, String mediaId) {
    if (widget.personId != null) {
      context.read<MediaBloc>().add(
        SetAsPrimaryPortrait(mediaId: mediaId, personId: widget.personId!),
      );
    }
  }

  void _confirmDelete(BuildContext context, String mediaId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить файл?'),
        content: const Text('Вы уверены, что хотите удалить этот файл?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              context.read<MediaBloc>().add(DeleteMediaFile(mediaId));
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}