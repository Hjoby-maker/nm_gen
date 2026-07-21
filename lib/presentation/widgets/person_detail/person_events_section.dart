// lib/presentation/widgets/person_detail/person_events_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/presentation/blocs/event/event_bloc.dart';
import 'package:nm_gen/presentation/blocs/event/event_event.dart';
import 'package:nm_gen/presentation/blocs/event/event_state.dart';
import 'package:nm_gen/presentation/blocs/media/media_bloc.dart';
import 'package:nm_gen/presentation/widgets/event_form_dialog.dart';
import 'package:nm_gen/presentation/widgets/event_tile.dart';
import 'package:nm_gen/presentation/widgets/person_detail/event_details_sheet.dart';

/// Секция "События" на вкладке "Информация": список событий человека со
/// свайпом (влево - редактировать, вправо - удалить), плюс запуск формы
/// добавления/редактирования события и шторки с деталями.
///
/// Читает EventBloc из context самостоятельно (он уже предоставлен на
/// уровне экрана через MultiBlocProvider) - явно прокидывать его не нужно,
/// в отличие от mediaBloc, который нужен EventFormDialog явным параметром
/// (см. комментарий там же про showDialog/useRootNavigator).
class PersonEventsSection extends StatelessWidget {
  const PersonEventsSection({
    super.key,
    required this.personId,
    required this.treeId,
    required this.mediaBloc,
  });

  final String personId;
  final String treeId;
  final MediaBloc mediaBloc;

  @override
  Widget build(BuildContext context) {
    final EventBloc eventBloc = context.read<EventBloc>();

    return BlocConsumer<EventBloc, EventState>(
      listener: (context, state) {
        if (state is EventOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          eventBloc.add(LoadPersonEventsEvent(personId, treeId: treeId));
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
                  ? _buildEmptyEvents(context)
                  : _buildEventsList(context, state.events)
            else if (state is EventError)
              _buildErrorState(context, state.message)
            else
              const SizedBox.shrink(),
          ],
        );
      },
    );
  }

  Widget _buildEmptyEvents(BuildContext context) {
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

  Widget _buildEventsList(BuildContext context, List<Event> events) {
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
            onTap: () => showEventDetailsSheet(
              context,
              event: event,
              onEdit: () => _showEditEventDialog(context, event),
              onDelete: () => _confirmDeleteEvent(context, event.id),
              mediaBloc: mediaBloc,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
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
                context.read<EventBloc>().add(
                  LoadPersonEventsEvent(personId, treeId: treeId),
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

  void _showAddEventDialog(BuildContext context) {
    final EventBloc eventBloc = context.read<EventBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => EventFormDialog(
        personId: personId,
        treeId: treeId,
        mediaBloc: mediaBloc,
        onSave: (event) {
          eventBloc.add(AddEventEvent(event));
        },
      ),
    );
  }

  void _showEditEventDialog(BuildContext context, Event event) {
    final EventBloc eventBloc = context.read<EventBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => EventFormDialog(
        existingEvent: event,
        personId: personId,
        treeId: treeId,
        mediaBloc: mediaBloc,
        onSave: (updatedEvent) {
          eventBloc.add(UpdateEventEvent(updatedEvent));
        },
      ),
    );
  }

  Future<bool> _confirmDeleteEvent(BuildContext context, String eventId) async {
    final EventBloc eventBloc = context.read<EventBloc>();
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
              eventBloc.add(DeleteEventEvent(eventId));
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
}
