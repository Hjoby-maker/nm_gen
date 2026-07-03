import 'package:flutter/material.dart';
import 'package:nm_gen/domain/entities/event.dart';

class EventTile extends StatelessWidget {
  const EventTile({
    super.key,
    required this.event,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final Event event;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(event.type),
          child: Icon(_getTypeIcon(event.type), color: Colors.white, size: 20),
        ),
        title: Text(event.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.startDate != null || event.endDate != null)
              Text(
                _formatDateRange(event),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            if (event.place != null && event.place!.isNotEmpty)
              Text(
                event.place!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: onDelete,
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatDateRange(Event event) {
    final start = event.startDate;
    final end = event.endDate;

    if (start == null && end == null) return 'Даты не указаны';
    if (start != null && end == null) return _formatDate(start);
    if (start == null && end != null) return '... - ${_formatDate(end)}';
    return '${_formatDate(start!)} - ${_formatDate(end!)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  Color _getTypeColor(EventType type) {
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

  IconData _getTypeIcon(EventType type) {
    switch (type) {
      case EventType.birth:
        return Icons.child_care;
      case EventType.death:
        return Icons.warning;
      case EventType.baptism:
        return Icons.auto_awesome;
      case EventType.burial:
        return Icons.church;
      case EventType.education:
        return Icons.school;
      case EventType.occupation:
        return Icons.work;
      case EventType.relocation:
        return Icons.location_on;
      default:
        return Icons.event;
    }
  }
}
