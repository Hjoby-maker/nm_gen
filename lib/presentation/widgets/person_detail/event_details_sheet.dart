// lib/presentation/widgets/person_detail/event_details_sheet.dart
import 'package:flutter/material.dart';
import 'package:nm_gen/core/utils/date_formatters.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/presentation/widgets/media_section.dart';

/// Показывает шторку с полными деталями события: тип, даты, место,
/// описание, заметки и прикреплённые файлы (MediaSection(eventId: ...)).
///
/// [onEdit]/[onDelete] вызываются уже ПОСЛЕ того, как шторка сама себя
/// закрывает - вызывающая сторона (обычно PersonEventsSection) решает,
/// что конкретно делать (открыть форму редактирования, показать диалог
/// подтверждения удаления и т.д.) - эта шторка ничего не знает про
/// EventBloc и прочую бизнес-логику, только показывает и делегирует.
void showEventDetailsSheet(
  BuildContext context, {
  required Event event,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(16),
        // scrollController обязательно подключаем к реальному
        // прокручиваемому виджету (ListView) - иначе контент, который не
        // помещается по высоте, будет просто обрезан без возможности
        // прокрутки.
        child: ListView(
          controller: scrollController,
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
                    onEdit();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              event.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (event.startDate != null || event.endDate != null) ...[
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    formatDateRange(event.startDate, event.endDate),
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
            if (event.description != null && event.description!.isNotEmpty) ...[
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
            const Divider(height: 24),
            MediaSection(eventId: event.id, showPrimaryBadge: false),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
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