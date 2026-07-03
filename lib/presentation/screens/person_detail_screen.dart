import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/presentation/blocs/event/event_bloc.dart';
import 'package:nm_gen/presentation/blocs/event/event_event.dart';
import 'package:nm_gen/presentation/blocs/event/event_state.dart';
import 'package:nm_gen/presentation/blocs/person/person_bloc.dart';
import 'package:nm_gen/presentation/blocs/person/person_event.dart';
import 'package:nm_gen/presentation/blocs/person/person_state.dart';
import 'package:nm_gen/presentation/widgets/event_form_dialog.dart';
import 'package:nm_gen/presentation/widgets/event_tile.dart';
import 'package:nm_gen/presentation/widgets/person_avatar.dart';
import 'package:nm_gen/presentation/widgets/person_form_dialog.dart';
import 'package:nm_gen/di/injector.dart';

class PersonDetailScreen extends StatefulWidget {
  const PersonDetailScreen({Key? key, required this.personId})
    : super(key: key);
  final String personId;

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  Person? _person;
  bool _isLoading = true;
  String? _treeId;

  late final PersonBloc _personBloc;
  late final EventBloc _eventBloc;

  @override
  void initState() {
    super.initState();
    _personBloc = getIt<PersonBloc>();
    _eventBloc = getIt<EventBloc>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
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
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(_person?.displayName ?? 'Загрузка...'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _person != null && _person!.id.isNotEmpty
                  ? () => _showEditPersonDialog(context)
                  : null,
              tooltip: 'Редактировать',
            ),
            // Кнопка добавления события в AppBar (всегда доступна)
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
            : _buildContent(),
      ),
    );
  }

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

  Widget _buildContent() {
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
  // ЗАГОЛОВОК С ИНФОРМАЦИЕЙ О ЧЕЛОВЕКЕ
  // =========================================================================

  Widget _buildHeader() {
    final person = _person!;
    final age = person.age != null ? '${person.age} лет' : 'Возраст неизвестен';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PersonAvatar(person: person, radius: 50),
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
                  ),
                  const SizedBox(height: 8),
                  Row(
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
                      const SizedBox(width: 12),
                      Text(
                        age,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  if (person.occupation != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      person.occupation!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  if (person.birthDate != null) ...[
                    const SizedBox(height: 8),
                    Row(
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
                    Row(
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
                    Row(
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

  // =========================================================================
  // СЕКЦИЯ СОБЫТИЙ
  // =========================================================================

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
            // Заголовок с кнопкой добавления
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
              return await _confirmDeleteEvent(context, event.id);
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

  // =========================================================================
  // СВАЙП-ДЕЙСТВИЯ ДЛЯ СОБЫТИЙ
  // =========================================================================

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
