import 'dart:io';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:nm_gen/core/utils/file_helper.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/presentation/blocs/media/media_bloc.dart';
import 'package:nm_gen/presentation/blocs/media/media_event.dart';

enum _PendingAttachmentType { copy, deviceReference, link }

/// Вложение, выбранное пользователем ДО того, как событие сохранено (у
/// события ещё нет id). Реально прикрепляется к MediaBloc уже после
/// успешного сохранения события, когда его id гарантированно существует.
class _PendingAttachment {
  _PendingAttachment.copy({
    required this.fileName,
    required this.mimeType,
    required Uint8List data,
  }) : type = _PendingAttachmentType.copy,
       fileData = data,
       filePath = null,
       fileSize = data.length,
       url = null;

  _PendingAttachment.deviceReference({
    required this.fileName,
    required this.mimeType,
    required String path,
    required int size,
  }) : type = _PendingAttachmentType.deviceReference,
       filePath = path,
       fileData = null,
       fileSize = size,
       url = null;

  _PendingAttachment.link({required String linkUrl})
    : type = _PendingAttachmentType.link,
      url = linkUrl,
      fileName = linkUrl,
      mimeType = 'text/uri-list',
      fileData = null,
      filePath = null,
      fileSize = 0;

  final _PendingAttachmentType type;
  final String fileName;
  final String mimeType;
  final Uint8List? fileData;
  final String? filePath;
  final int fileSize;
  final String? url;
}

class EventFormDialog extends StatefulWidget {
  const EventFormDialog({
    super.key,
    this.existingEvent,
    required this.personId,
    required this.treeId,
    required this.onSave,
    required this.mediaBloc,
  });

  final Event? existingEvent;
  final String personId;
  final String treeId;
  final Function(Event) onSave;

  /// Передаётся явно, а не через context.read<MediaBloc>() внутри диалога -
  /// showDialog по умолчанию использует useRootNavigator: true, и Provider
  /// из локального дерева экрана не гарантированно доступен в контексте
  /// диалога (та же причина, по которой раньше ловили Hero-конфликты).
  final MediaBloc mediaBloc;

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
  final List<_PendingAttachment> _pendingAttachments = [];

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
              onChanged: (DateTime? date) => setState(() => _startDate = date),
              onClear: () => setState(() => _startDate = null),
            ),
            // Дата окончания
            _buildDatePicker(
              label: 'Дата окончания',
              date: _endDate,
              onChanged: (DateTime? date) => setState(() => _endDate = date),
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
            const SizedBox(height: 12),
            _buildAttachmentsSection(),
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

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Вложения', style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton.icon(
              onPressed: _showAttachmentPicker,
              icon: const Icon(Icons.attach_file, size: 18),
              label: const Text('Добавить'),
            ),
          ],
        ),
        if (_pendingAttachments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Файлы будут прикреплены после сохранения события',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          )
        else
          ..._pendingAttachments.asMap().entries.map((entry) {
            final int index = entry.key;
            final _PendingAttachment att = entry.value;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(_iconForAttachment(att.type)),
              title: Text(
                att.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                switch (att.type) {
                  _PendingAttachmentType.copy => 'Будет скопирован в приложение',
                  _PendingAttachmentType.deviceReference => 'Останется на устройстве',
                  _PendingAttachmentType.link => 'Внешняя ссылка',
                },
                style: const TextStyle(fontSize: 11),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _pendingAttachments.removeAt(index)),
              ),
            );
          }),
      ],
    );
  }

  IconData _iconForAttachment(_PendingAttachmentType type) {
    switch (type) {
      case _PendingAttachmentType.copy:
        return Icons.insert_drive_file;
      case _PendingAttachmentType.deviceReference:
        return Icons.smartphone;
      case _PendingAttachmentType.link:
        return Icons.link;
    }
  }

  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Камера'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Галерея'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Файл (копия в приложение)'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickFileCopy();
              },
            ),
            ListTile(
              leading: const Icon(Icons.smartphone),
              title: const Text('Файл на устройстве (без копирования)'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickDeviceFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Ссылка'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickLink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 90,
      );
      if (picked == null) return;
      final Uint8List bytes = await picked.readAsBytes();
      setState(() {
        _pendingAttachments.add(
          _PendingAttachment.copy(
            fileName: picked.name,
            mimeType: FileHelper.getMimeTypeFromExtension(picked.name),
            data: bytes,
          ),
        );
      });
    } catch (e) {
      _showAttachmentError('Ошибка выбора изображения: $e');
    }
  }

  Future<void> _pickFileCopy() async {
    try {
      final XFile? file = await openFile();
      if (file == null) return;
      final Uint8List bytes = await file.readAsBytes();
      setState(() {
        _pendingAttachments.add(
          _PendingAttachment.copy(
            fileName: file.name,
            mimeType: file.mimeType ?? FileHelper.getMimeTypeFromExtension(file.name),
            data: bytes,
          ),
        );
      });
    } catch (e) {
      _showAttachmentError('Ошибка выбора файла: $e');
    }
  }

  Future<void> _pickDeviceFile() async {
    try {
      final XFile? file = await openFile();
      if (file == null) return;
      final int size = await File(file.path).length();
      setState(() {
        _pendingAttachments.add(
          _PendingAttachment.deviceReference(
            fileName: file.name,
            mimeType: file.mimeType ?? FileHelper.getMimeTypeFromExtension(file.name),
            path: file.path,
            size: size,
          ),
        );
      });
    } catch (e) {
      _showAttachmentError('Ошибка выбора файла: $e');
    }
  }

  Future<void> _pickLink() async {
    final TextEditingController linkController = TextEditingController();
    final String? url = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Добавить ссылку'),
        content: TextField(
          controller: linkController,
          decoration: const InputDecoration(
            labelText: 'Ссылка *',
            hintText: 'https://...',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, linkController.text.trim()),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );

    if (url == null || url.isEmpty) return;

    final Uri? parsed = Uri.tryParse(url);
    final bool isValid =
        parsed != null &&
        (parsed.isScheme('HTTP') || parsed.isScheme('HTTPS')) &&
        parsed.host.isNotEmpty;
    if (!isValid) {
      _showAttachmentError('Некорректная ссылка - укажите адрес, начиная с http:// или https://');
      return;
    }

    setState(() {
      _pendingAttachments.add(_PendingAttachment.link(linkUrl: url));
    });
  }

  void _showAttachmentError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }

  /// Реально прикрепляет все отложенные вложения к событию. Вызывается
  /// ПОСЛЕ того, как событие сохранено (id уже гарантированно существует
  /// в БД) - иначе вставка media-строки с несуществующим event_id по
  /// смыслу некорректна, даже если сама SQLite сейчас не проверяет
  /// внешние ключи строго.
  void _attachPendingFiles(String eventId) {
    for (final _PendingAttachment att in _pendingAttachments) {
      switch (att.type) {
        case _PendingAttachmentType.copy:
          widget.mediaBloc.add(
            AddMediaFile(
              fileData: att.fileData!,
              fileName: att.fileName,
              mimeType: att.mimeType,
              description: att.fileName,
              personId: widget.personId,
              eventId: eventId,
              generateThumbnail: true,
            ),
          );
          break;
        case _PendingAttachmentType.deviceReference:
          widget.mediaBloc.add(
            AddDeviceFileReference(
              filePath: att.filePath!,
              fileName: att.fileName,
              mimeType: att.mimeType,
              fileSize: att.fileSize,
              description: att.fileName,
              personId: widget.personId,
              eventId: eventId,
            ),
          );
          break;
        case _PendingAttachmentType.link:
          widget.mediaBloc.add(
            AddExternalLink(
              url: att.url!,
              description: att.url!,
              personId: widget.personId,
              eventId: eventId,
            ),
          );
          break;
      }
    }
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

    // event.id уже известен (сгенерирован выше, ДО вызова onSave) - поэтому
    // можно сразу прикрепить отложенные вложения, не дожидаясь отдельного
    // подтверждения от EventBloc. Соответствует уже принятому в проекте
    // стилю "fire-and-forget" (сам onSave тоже не awaited).
    if (_pendingAttachments.isNotEmpty) {
      _attachPendingFiles(event.id);
    }

    Navigator.pop(context);
  }
}