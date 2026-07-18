// lib/presentation/widgets/media/media_picker_sheet.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nm_gen/core/utils/file_helper.dart';
import 'package:nm_gen/presentation/blocs/media/media_bloc.dart';
import 'package:nm_gen/presentation/blocs/media/media_event.dart';

/// Типы файлов для выбора
class FileTypes {
  static const XTypeGroup images = XTypeGroup(
    label: 'Изображения',
    extensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic', 'heif'],
    mimeTypes: ['image/*'],
  );

  static const XTypeGroup videos = XTypeGroup(
    label: 'Видео',
    extensions: ['mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv', 'webm'],
    mimeTypes: ['video/*'],
  );

  static const XTypeGroup audios = XTypeGroup(
    label: 'Аудио',
    extensions: ['mp3', 'wav', 'ogg', 'aac', 'flac', 'm4a'],
    mimeTypes: ['audio/*'],
  );

  static const XTypeGroup documents = XTypeGroup(
    label: 'Документы',
    extensions: [
      'pdf', 'doc', 'docx', 'txt', 'rtf',
      'xls', 'xlsx', 'ppt', 'pptx',
      'odt', 'ods', 'odp',
    ],
    mimeTypes: [
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'text/plain',
    ],
  );

  static const List<XTypeGroup> all = [images, videos, audios, documents];
}

/// Способ прикрепления вложения. См. AttachmentSource в доменной модели -
/// это презентационный аналог того же выбора.
enum _AttachMode {
  /// Файл копируется в песочницу приложения (существующее поведение).
  copy,

  /// Ссылка на файл, физически лежащий на устройстве - НЕ копируем.
  deviceReference,

  /// Внешняя ссылка (URL).
  link,
}

/// Нижний лист для выбора и добавления медиа-файлов
class MediaPickerSheet extends StatefulWidget {
  final String? personId;
  final String? eventId;
  final MediaBloc? mediaBloc; // ← Добавляем параметр

  const MediaPickerSheet({
    super.key,
    this.personId,
    this.eventId,
    this.mediaBloc, // ← Добавляем
  });

  @override
  State<MediaPickerSheet> createState() => _MediaPickerSheetState();

  static Future<void> show({
    required BuildContext context,
    String? personId,
    String? eventId,
    MediaBloc? mediaBloc, // ← Добавляем параметр
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MediaPickerSheet(
        personId: personId,
        eventId: eventId,
        mediaBloc: mediaBloc ?? context.read<MediaBloc>(), // ← Получаем из контекста если не передан
      ),
    );
  }
}

class _MediaPickerSheetState extends State<MediaPickerSheet> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  bool _setAsPrimary = false;
  bool _isLoading = false;
  Uint8List? _selectedFileData;
  String? _selectedFileName;
  String? _selectedMimeType;

  // Новое: режим прикрепления и данные для двух новых способов.
  _AttachMode _mode = _AttachMode.copy;
  String? _selectedDevicePath;
  int? _selectedDeviceFileSize;

  // Получаем MediaBloc из параметров или из контекста
  MediaBloc get _mediaBloc => widget.mediaBloc ?? context.read<MediaBloc>();

  @override
  void dispose() {
    _descriptionController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildPickerButtons(),
            const SizedBox(height: 16),
            if (_mode == _AttachMode.link) _buildLinkField(),
            if (_mode == _AttachMode.link) const SizedBox(height: 16),
            if (_mode != _AttachMode.link && _selectedFileData != null)
              _buildPreview(),
            if (_mode != _AttachMode.link && _selectedFileData != null)
              const SizedBox(height: 16),
            if (_mode == _AttachMode.deviceReference &&
                _selectedDevicePath != null)
              _buildDeviceFilePreview(),
            if (_mode == _AttachMode.deviceReference &&
                _selectedDevicePath != null)
              const SizedBox(height: 16),
            _buildDescriptionField(),
            const SizedBox(height: 12),
            if (widget.personId != null && _mode == _AttachMode.copy)
              _buildPrimaryCheckbox(),
            if (widget.personId != null && _mode == _AttachMode.copy)
              const SizedBox(height: 12),
            _buildAddButton(),
          ],
        ),
      ),
    );
  }

  // ... остальные методы остаются без изменений, но используйте _mediaBloc вместо context.read<MediaBloc>()

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Добавить файл',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildPickerButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPickerButton(
            icon: Icons.photo_camera,
            label: 'Камера',
            onTap: () => _pickImage(ImageSource.camera),
          ),
          const SizedBox(width: 8),
          _buildPickerButton(
            icon: Icons.photo_library,
            label: 'Галерея',
            onTap: () => _pickImage(ImageSource.gallery),
          ),
          const SizedBox(width: 8),
          _buildPickerButton(
            icon: Icons.insert_drive_file,
            label: 'Файл (копия)',
            onTap: _pickFile,
          ),
          const SizedBox(width: 8),
          // ✅ Новое: файл на телефоне БЕЗ копирования в приложение.
          _buildPickerButton(
            icon: Icons.smartphone,
            label: 'На устройстве',
            onTap: _pickDeviceFileReference,
          ),
          const SizedBox(width: 8),
          // ✅ Новое: внешняя ссылка (URL).
          _buildPickerButton(
            icon: Icons.link,
            label: 'Ссылка',
            onTap: () => setState(() => _mode = _AttachMode.link),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: Colors.blue[700]),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  /// Поле ввода URL для режима "Ссылка".
  Widget _buildLinkField() {
    return TextField(
      controller: _linkController,
      decoration: const InputDecoration(
        labelText: 'Ссылка *',
        hintText: 'https://...',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.link),
      ),
      keyboardType: TextInputType.url,
      autofillHints: const [AutofillHints.url],
    );
  }

  /// Превью для файла на устройстве (режим deviceReference) - без данных
  /// файла в памяти, только имя/путь/размер.
  Widget _buildDeviceFilePreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.smartphone, size: 32, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedFileName ?? 'Файл',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedDeviceFileSize != null
                      ? FileHelper.formatFileSize(_selectedDeviceFileSize!)
                      : '',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  'Файл останется на устройстве, приложение его не копирует',
                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () {
              setState(() {
                _selectedDevicePath = null;
                _selectedFileName = null;
                _selectedMimeType = null;
                _selectedDeviceFileSize = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final isImage = _selectedMimeType?.startsWith('image/') ?? false;
    final isVideo = _selectedMimeType?.startsWith('video/') ?? false;
    final isAudio = _selectedMimeType?.startsWith('audio/') ?? false;

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: isImage
                ? Image.memory(
                    _selectedFileData!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[200],
                    child: Icon(
                      isVideo ? Icons.videocam : isAudio ? Icons.audiotrack : Icons.insert_drive_file,
                      size: 40,
                      color: Colors.grey[600],
                    ),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _selectedFileName ?? 'Файл',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    FileHelper.formatFileSize(_selectedFileData!.length),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    _selectedMimeType ?? 'Неизвестный тип',
                    style: TextStyle(color: Colors.grey[500], fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () {
              setState(() {
                _selectedFileData = null;
                _selectedFileName = null;
                _selectedMimeType = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Описание *',
        hintText: 'Например: Свидетельство о рождении, стр. 2',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
      ),
      maxLines: 2,
    );
  }

  Widget _buildPrimaryCheckbox() {
    return CheckboxListTile(
      value: _setAsPrimary,
      onChanged: (value) {
        setState(() {
          _setAsPrimary = value ?? false;
        });
      },
      title: const Text('Сделать основным портретом', style: TextStyle(fontWeight: FontWeight.w500)),
      subtitle: const Text(
        'Будет отображаться на главной карточке человека',
        style: TextStyle(fontSize: 12),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildAddButton() {
    final bool isValid;
    switch (_mode) {
      case _AttachMode.copy:
        isValid = _selectedFileData != null &&
            _descriptionController.text.trim().isNotEmpty;
        break;
      case _AttachMode.deviceReference:
        isValid = _selectedDevicePath != null &&
            _descriptionController.text.trim().isNotEmpty;
        break;
      case _AttachMode.link:
        isValid = _linkController.text.trim().isNotEmpty &&
            _descriptionController.text.trim().isNotEmpty;
        break;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading || !isValid ? null : _addMedia,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                _mode == _AttachMode.link ? 'Добавить ссылку' : 'Добавить файл',
                style: const TextStyle(fontSize: 16),
              ),
      ),
    );
  }

  // ============================================================
  // МЕТОДЫ ВЫБОРА ФАЙЛОВ
  // ============================================================

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 90,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _mode = _AttachMode.copy;
          _selectedDevicePath = null;
          _selectedDeviceFileSize = null;
          _selectedFileData = bytes;
          _selectedFileName = picked.name;
          _selectedMimeType = _getMimeTypeFromExtension(picked.path.split('.').last);
        });
      }
    } catch (e) {
      _showError('Ошибка выбора изображения: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final XFile? file = await openFile(acceptedTypeGroups: FileTypes.all);

      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _mode = _AttachMode.copy;
          _selectedDevicePath = null;
          _selectedDeviceFileSize = null;
          _selectedFileData = bytes;
          _selectedFileName = file.name;
          _selectedMimeType = file.mimeType ?? _getMimeTypeFromExtension(file.path.split('.').last);
        });
      }
    } catch (e) {
      _showError('Ошибка выбора файла: $e');
    }
  }

  /// ✅ Новое: выбор файла на устройстве БЕЗ чтения его содержимого в
  /// память и без копирования - запоминаем только путь. Это специально
  /// не читает bytes (в отличие от _pickFile), чтобы избежать лишней
  /// загрузки в память потенциально большого файла, который мы всё равно
  /// не будем копировать.
  Future<void> _pickDeviceFileReference() async {
    try {
      final XFile? file = await openFile(acceptedTypeGroups: FileTypes.all);
      if (file == null) return;

      final int size = await File(file.path).length();

      setState(() {
        _mode = _AttachMode.deviceReference;
        _selectedFileData = null;
        _selectedDevicePath = file.path;
        _selectedFileName = file.name;
        _selectedMimeType = file.mimeType ?? _getMimeTypeFromExtension(file.path.split('.').last);
        _selectedDeviceFileSize = size;
      });
    } catch (e) {
      _showError('Ошибка выбора файла: $e');
    }
  }

  String _getMimeTypeFromExtension(String extension) {
    const mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'bmp': 'image/bmp',
      'webp': 'image/webp',
      'heic': 'image/heic',
      'heif': 'image/heif',
      'mp4': 'video/mp4',
      'avi': 'video/x-msvideo',
      'mov': 'video/quicktime',
      'wmv': 'video/x-ms-wmv',
      'flv': 'video/x-flv',
      'mkv': 'video/x-matroska',
      'webm': 'video/webm',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'aac': 'audio/aac',
      'flac': 'audio/flac',
      'm4a': 'audio/mp4',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'rtf': 'application/rtf',
      'odt': 'application/vnd.oasis.opendocument.text',
      'ods': 'application/vnd.oasis.opendocument.spreadsheet',
      'odp': 'application/vnd.oasis.opendocument.presentation',
    };
    return mimeTypes[extension.toLowerCase()] ?? 'application/octet-stream';
  }

  // ============================================================
  // МЕТОД ДОБАВЛЕНИЯ МЕДИА
  // ============================================================

  Future<void> _addMedia() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      _showError('Пожалуйста, введите описание файла');
      return;
    }

    if (widget.personId == null && widget.eventId == null) {
      _showError('Не указан получатель файла');
      return;
    }

    switch (_mode) {
      case _AttachMode.copy:
        await _addCopiedFile(description);
        break;
      case _AttachMode.deviceReference:
        await _addDeviceReference(description);
        break;
      case _AttachMode.link:
        await _addLink(description);
        break;
    }
  }

  Future<void> _addCopiedFile(String description) async {
    if (_selectedFileData == null) return;
    if (_selectedFileData!.length > 50 * 1024 * 1024) {
      _showError('Файл слишком большой (макс. 50 МБ)');
      return;
    }

    setState(() => _isLoading = true);
    try {
      _mediaBloc.add(
        AddMediaFile(
          fileData: _selectedFileData!,
          fileName: _selectedFileName!,
          mimeType: _selectedMimeType!,
          description: description,
          personId: widget.personId,
          eventId: widget.eventId,
          setAsPrimary: _setAsPrimary && widget.personId != null,
          generateThumbnail: true,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Ошибка добавления файла: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addDeviceReference(String description) async {
    if (_selectedDevicePath == null) return;

    setState(() => _isLoading = true);
    try {
      _mediaBloc.add(
        AddDeviceFileReference(
          filePath: _selectedDevicePath!,
          fileName: _selectedFileName!,
          mimeType: _selectedMimeType ?? 'application/octet-stream',
          fileSize: _selectedDeviceFileSize ?? 0,
          description: description,
          personId: widget.personId,
          eventId: widget.eventId,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Ошибка прикрепления файла: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addLink(String description) async {
    final String url = _linkController.text.trim();
    final Uri? parsed = Uri.tryParse(url);
    final bool looksValid =
        parsed != null &&
        (parsed.isScheme('HTTP') || parsed.isScheme('HTTPS')) &&
        parsed.host.isNotEmpty;
    if (!looksValid) {
      _showError('Укажите корректную ссылку, начиная с http:// или https://');
      return;
    }

    setState(() => _isLoading = true);
    try {
      _mediaBloc.add(
        AddExternalLink(
          url: url,
          description: description,
          personId: widget.personId,
          eventId: widget.eventId,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Ошибка добавления ссылки: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}