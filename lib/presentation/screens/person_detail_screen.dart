// lib/presentation/screens/person_detail_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/core/utils/file_helper.dart';
import 'package:nm_gen/core/utils/image_picker_service.dart';
import 'package:nm_gen/di/injector.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/entities/media_attachment.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/presentation/blocs/event/event_bloc.dart';
import 'package:nm_gen/presentation/blocs/event/event_event.dart';
import 'package:nm_gen/presentation/blocs/event/event_state.dart';
import 'package:nm_gen/presentation/blocs/media/media_bloc.dart';
import 'package:nm_gen/presentation/blocs/media/media_event.dart';
import 'package:nm_gen/presentation/blocs/media/media_state.dart';
import 'package:nm_gen/presentation/blocs/person/person_bloc.dart';
import 'package:nm_gen/presentation/blocs/person/person_event.dart';
import 'package:nm_gen/presentation/blocs/person/person_state.dart';
import 'package:nm_gen/presentation/widgets/event_form_dialog.dart';
import 'package:nm_gen/presentation/widgets/event_tile.dart';
import 'package:nm_gen/presentation/widgets/media_section.dart';
import 'package:nm_gen/presentation/widgets/person_avatar.dart';
import 'package:nm_gen/presentation/widgets/person_form_dialog.dart';

class PersonDetailScreen extends StatefulWidget {
  const PersonDetailScreen({Key? key, required this.personId})
    : super(key: key);
  final String personId;

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen>
    with SingleTickerProviderStateMixin {
  Person? _person;
  bool _isLoading = true;
  String? _treeId;
  late TabController _tabController;

  late final PersonBloc _personBloc;
  late final EventBloc _eventBloc;
  late final MediaBloc _mediaBloc;
  final ImagePickerService _imagePickerService = ImagePickerService();

  @override
  void initState() {
    super.initState();
    _personBloc = getIt<PersonBloc>();
    _eventBloc = getIt<EventBloc>();
    _mediaBloc = getIt<MediaBloc>();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final personState = _personBloc.state;
    if (personState is! PersonsLoaded || personState.treeId != _treeId) {
      _personBloc.add(LoadPersonsEvent(treeId: _treeId));
      await Future.delayed(const Duration(milliseconds: 300));
    }

    final updatedState = _personBloc.state;
    if (updatedState is PersonsLoaded) {
      setState(() {
        _person = updatedState.persons.firstWhere(
          (p) => p.id == widget.personId,
          orElse: () => Person.empty(),
        );
        _treeId = updatedState.treeId ?? 'default';
        _isLoading = false;
      });

      _eventBloc.add(LoadPersonEventsEvent(widget.personId, treeId: _treeId));
      _mediaBloc.add(LoadMediaForPerson(personId: widget.personId));
      _mediaBloc.add(LoadPrimaryPortrait(widget.personId));
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _personBloc),
        BlocProvider.value(value: _eventBloc),
        BlocProvider.value(value: _mediaBloc),
      ],
      child: BlocListener<MediaBloc, MediaState>(
        // ⚠️ PersonAvatar рисует фото из person.photoPath, а не из
        // MediaBloc (и не может из него читать напрямую - тот же виджет
        // используется в списках для разных людей одновременно, а у
        // MediaBloc только одно текущее состояние на весь bloc). Поэтому
        // здесь, как только основной портрет успешно сохранён или
        // назначен, синхронизируем photoPath на самом Person - именно
        // это поле PersonAvatar показывает везде в приложении.
        listener: (context, state) {
          MediaAttachment? updatedPortrait;
          if (state is MediaFileAdded && state.media.isPrimary) {
            updatedPortrait = state.media;
          } else if (state is MediaUpdated && state.media.isPrimary) {
            updatedPortrait = state.media;
          }

          if (updatedPortrait != null &&
              updatedPortrait.personId == widget.personId &&
              _person != null) {
            final Person updatedPerson = _person!.copyWith(
              photoPath: updatedPortrait.localPath,
            );
            _personBloc.add(UpdatePersonEvent(updatedPerson));
            setState(() {
              _person = updatedPerson;
            });
          }
        },
          child: Scaffold(
          appBar: AppBar(
            title: Text(_person?.displayName ?? 'Загрузка...'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(icon: Icon(Icons.info), text: 'Информация'),
                Tab(icon: Icon(Icons.folder), text: 'Файлы'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _person != null && _person!.id.isNotEmpty
                    ? () => _showEditPersonDialog(context)
                    : null,
                tooltip: 'Редактировать',
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _person != null && _person!.id.isNotEmpty
                    ? () => _showAddEventDialog(context)
                    : null,
                tooltip: 'Добавить событие',
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _person == null || _person!.id.isEmpty
              ? _buildNotFoundView()
              : TabBarView(
                  controller: _tabController,
                  children: [_buildInfoTab(), _buildMediaTab()],
                ),
          floatingActionButton: FloatingActionButton(
            // ⚠️ Раньше здесь был Hero(tag: 'fab_detail_screen', child:
            // FloatingActionButton(...)) - но FloatingActionButton САМ уже
            // оборачивает себя в Hero, поэтому получался Hero внутри Hero.
            // Замена на heroTag: 'fab_detail_screen' решала это, но
            // ломалась снова, если где-то в стеке навигатора (например,
            // на PersonsScreen под этим экраном) оказывался ДРУГОЙ FAB без
            // уникального тега - Flutter ищет дубли тегов по всему
            // Navigator Overlay, а не только в текущем экране. heroTag:
            // null полностью отключает Hero-обёртку для этой кнопки -
            // никакой анимации перелёта нам тут и не нужно, а коллизий
            // тегов с любым другим экраном/диалогом больше в принципе не
            // может быть.
            heroTag: null,
            onPressed: _person != null && _person!.id.isNotEmpty
                ? () => _showAddEventDialog(context)
                : null,
            tooltip: 'Добавить событие',
            child: const Icon(Icons.add),
        ),
        ),
      ),
    );
  }

  // =========================================================================
  // ВКЛАДКА "ИНФОРМАЦИЯ"
  // =========================================================================

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildEventsSection(),
        ],
      ),
    );
  }

  // =========================================================================
  // ВКЛАДКА "ФАЙЛЫ"
  // =========================================================================

  Widget _buildMediaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: MediaSection(personId: widget.personId, showPrimaryBadge: true),
    );
  }

  // =========================================================================
  // ОСТАЛЬНЫЕ МЕТОДЫ
  // =========================================================================

  Widget _buildNotFoundView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Человек не найден',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Назад'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final person = _person!;
    final String age = person.age != null
        ? '${person.age} лет'
        : 'Возраст неизвестен';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _pickAndSetAvatar(context),
              child: Stack(
                children: [
                  PersonAvatar(person: person, radius: 50),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            person.gender == Gender.male
                                ? Icons.male
                                : person.gender == Gender.female
                                ? Icons.female
                                : Icons.person,
                            size: 16,
                            color: person.gender == Gender.male
                                ? Colors.blue
                                : Colors.pink,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            person.gender.displayName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        age,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (person.occupation != null)
                        Text(
                          person.occupation!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  if (person.birthDate != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      children: [
                        const Icon(Icons.cake, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Дата рождения: ${_formatDate(person.birthDate!)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (person.deathDate != null) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      children: [
                        const Icon(Icons.warning, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Дата смерти: ${_formatDate(person.deathDate!)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (person.birthPlace != null) ...[
                    const SizedBox(height: 4),
                    // ⚠️ Раньше здесь был Wrap(...) - но внутри был Expanded,
                    // а Expanded требует прямого предка Row/Column/Flex,
                    // Wrap для этого не подходит ("Incorrect use of
                    // ParentDataWidget"). По смыслу это одна строка
                    // "иконка + текст", а не переносимый поток элементов,
                    // поэтому меняем на Row.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            person.birthPlace!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (person.biography != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        person.biography!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsSection() {
    return BlocConsumer<EventBloc, EventState>(
      listener: (context, state) {
        if (state is EventOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          _eventBloc.add(
            LoadPersonEventsEvent(widget.personId, treeId: _treeId),
          );
        } else if (state is EventError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'События',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAddEventDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Добавить'),
                  style: TextButton.styleFrom(foregroundColor: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state is EventLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (state is EventsLoaded)
              state.events.isEmpty
                  ? _buildEmptyEvents()
                  : _buildEventsList(state.events)
            else if (state is EventError)
              _buildErrorState(state.message)
            else
              const SizedBox.shrink(),
          ],
        );
      },
    );
  }

  Widget _buildEmptyEvents() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.event_note, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                'Нет событий',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsList(List<Event> events) {
    return Column(
      children: events.map((event) {
        return Dismissible(
          key: Key(event.id),
          direction: DismissDirection.horizontal,
          background: _buildSwipeRightBackground(),
          secondaryBackground: _buildSwipeLeftBackground(),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              return _confirmDeleteEvent(context, event.id);
            } else if (direction == DismissDirection.endToStart) {
              _showEditEventDialog(context, event);
              return false;
            }
            return false;
          },
          child: EventTile(
            event: event,
            onTap: () => _showEventDetails(context, event),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorState(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
            TextButton(
              onPressed: () {
                _eventBloc.add(
                  LoadPersonEventsEvent(widget.personId, treeId: _treeId),
                );
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeRightBackground() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      child: const Row(
        children: [
          Icon(Icons.delete_forever, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Text(
            'Удалить',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeLeftBackground() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerRight,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Редактировать',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          SizedBox(width: 12),
          Icon(Icons.edit, color: Colors.white, size: 28),
        ],
      ),
    );
  }

  // =========================================================================
  // ДИАЛОГИ
  // =========================================================================

  void _showAddEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => EventFormDialog(
        personId: widget.personId,
        treeId: _treeId ?? 'default',
        onSave: (event) {
          _eventBloc.add(AddEventEvent(event));
        },
      ),
    );
  }

  void _showEditEventDialog(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (dialogContext) => EventFormDialog(
        existingEvent: event,
        personId: widget.personId,
        treeId: _treeId ?? 'default',
        onSave: (updatedEvent) {
          _eventBloc.add(UpdateEventEvent(updatedEvent));
        },
      ),
    );
  }

  void _showEventDetails(BuildContext context, Event event) {
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getEventTypeColor(event.type).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.type.displayName,
                      style: TextStyle(
                        color: _getEventTypeColor(event.type),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditEventDialog(context, event);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDeleteEvent(context, event.id);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (event.startDate != null || event.endDate != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDateRange(event),
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (event.place != null && event.place!.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      event.place!,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (event.description != null &&
                  event.description!.isNotEmpty) ...[
                const Divider(),
                Text(
                  event.description!,
                  style: TextStyle(color: Colors.grey.shade800, height: 1.5),
                ),
              ],
              if (event.notes != null && event.notes!.isNotEmpty) ...[
                const Divider(),
                Text(
                  '📝 ${event.notes!}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDeleteEvent(BuildContext context, String eventId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удаление события'),
        content: const Text('Вы уверены, что хотите удалить это событие?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              _eventBloc.add(DeleteEventEvent(eventId));
              Navigator.pop(dialogContext, true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Выбор фото (камера/галерея) и сохранение его как основного портрета
  /// человека. Реально сохраняется на диск через FileStorageService (внутри
  /// MediaRepository.addMedia -> FileStorageService.saveFile), путь и
  /// метаданные пишутся в MediaAttachment с setAsPrimary: true.
  Future<void> _pickAndSetAvatar(BuildContext context) async {
    if (_person == null || _person!.id.isEmpty) return;

    // showDeleteOption: false - удаление текущего портрета уже доступно
    // на вкладке "Файлы" (кнопка удаления на карточке медиа с пометкой
    // "Основной"), так что здесь не нужно решать неоднозначность между
    // "отмена" и "удалить" (оба варианта ImagePickerService.pickImage
    // возвращают null).
    final File? picked = await _imagePickerService.pickImage(
      context,
      showDeleteOption: false,
    );

    if (picked == null || !mounted) return; // пользователь отменил выбор

    try {
      final Uint8List bytes = await picked.readAsBytes();
      final String fileName = picked.path.split(Platform.pathSeparator).last;
      final String mimeType = FileHelper.getMimeTypeFromExtension(fileName);

      _mediaBloc.add(
        AddMediaFile(
          fileData: bytes,
          fileName: fileName,
          mimeType: mimeType,
          description: 'Портрет',
          personId: widget.personId,
          setAsPrimary: true,
          generateThumbnail: true,
        ),
      );
      // MediaSection (вкладка "Файлы") уже подписан на этот же MediaBloc
      // через BlocConsumer и сам покажет SnackBar об успехе/ошибке и
      // обновит список - здесь дублировать не нужно.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки фото: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditPersonDialog(BuildContext context) {
    if (_person == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => PersonFormDialog(
        existingPerson: _person!,
        treeId: _treeId ?? 'default',
        onSave: (updatedPerson) {
          _personBloc.add(UpdatePersonEvent(updatedPerson));
          setState(() {
            _person = updatedPerson;
          });
        },
      ),
    );
  }

  // =========================================================================
  // УТИЛИТЫ
  // =========================================================================

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatDateRange(Event event) {
    final start = event.startDate;
    final end = event.endDate;
    if (start == null && end == null) return 'Даты не указаны';
    if (start != null && end == null) return _formatDate(start);
    if (start == null && end != null) return '... - ${_formatDate(end)}';
    return '${_formatDate(start!)} - ${_formatDate(end!)}';
  }

  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.birth:
        return Colors.green;
      case EventType.death:
        return Colors.grey;
      case EventType.baptism:
        return Colors.blue;
      case EventType.burial:
        return Colors.grey;
      case EventType.education:
        return Colors.purple;
      case EventType.occupation:
        return Colors.teal;
      case EventType.relocation:
        return Colors.amber;
      default:
        return Colors.blueGrey;
    }
  }
}