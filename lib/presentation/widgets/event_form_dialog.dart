import 'package:flutter/material.dart';
import 'package:nm_gen/domain/entities/event.dart';

class EventFormDialog extends StatefulWidget {
  const EventFormDialog({
    super.key,
    this.existingEvent,
    required this.personId,
    required this.treeId,
    required this.onSave,
  });

  final Event? existingEvent;
  final String personId;
  final String treeId;
  final Function(Event) onSave;

  @override
  State<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<EventFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _placeController;
  late final TextEditingController _notesController;
  late EventType _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;

  bool get isEditing => widget.existingEvent != null;

  @override
  void initState() {
    super.initState();
    final event = widget.existingEvent;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    _placeController = TextEditingController(text: event?.place ?? '');
    _notesController = TextEditingController(text: event?.notes ?? '');
    _selectedType = event?.type ?? EventType.other;
    _startDate = event?.startDate;
    _endDate = event?.endDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _placeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Редактировать событие' : 'Добавить событие'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Тип события — используем только доступные типы
            DropdownButtonFormField<EventType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Тип события *',
                border: OutlineInputBorder(),
              ),
              items: EventType.availableTypes.map((type) {
                return DropdownMenuItem<EventType>(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedType = value);
              },
            ),
            const SizedBox(height: 8),
            // Название
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Название *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            // Описание
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            // Дата начала
            _buildDatePicker(
              label: 'Дата начала',
              date: _startDate,
              onChanged: (date) => setState(() => _startDate = date),
              onClear: () => setState(() => _startDate = null),
            ),
            // Дата окончания
            _buildDatePicker(
              label: 'Дата окончания',
              date: _endDate,
              onChanged: (date) => setState(() => _endDate = date),
              onClear: () => setState(() => _endDate = null),
            ),
            const SizedBox(height: 8),
            // Место
            TextField(
              controller: _placeController,
              decoration: const InputDecoration(
                labelText: 'Место',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            // Заметки
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Заметки',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _saveEvent,
          child: Text(isEditing ? 'Сохранить' : 'Добавить'),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required Function(DateTime?) onChanged,
    required VoidCallback onClear,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        date != null ? '$label: ${_formatDate(date)}' : '$label не указана',
        style: TextStyle(
          color: date != null ? Colors.black : Colors.grey.shade600,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (date != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: onClear,
            ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context, onChanged),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    Function(DateTime?) onChanged,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1800),
      lastDate: DateTime.now(),
    );
    if (picked != null) onChanged(picked);
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  void _saveEvent() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите название события'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final event = Event(
      id:
          widget.existingEvent?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      personId: widget.personId,
      treeId: widget.treeId,
      type: _selectedType,
      title: title,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      startDate: _startDate,
      endDate: _endDate,
      place: _placeController.text.trim().isNotEmpty
          ? _placeController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      createdAt: widget.existingEvent?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSave(event);
    Navigator.pop(context);
  }
}
