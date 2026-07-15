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
import 'package:path_provider/path_provider.dart';

/// Типы файлов для выбора
class FileTypes {
  /// Все изображения
  static const XTypeGroup images = XTypeGroup(
    label: 'Изображения',
    extensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic', 'heif'],
    mimeTypes: ['image/*'],
  );

  /// Все видео
  static const XTypeGroup videos = XTypeGroup(
    label: 'Видео',
    extensions: ['mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv', 'webm'],
    mimeTypes: ['video/*'],
  );

  /// Все аудио
  static const XTypeGroup audios = XTypeGroup(
    label: 'Аудио',
    extensions: ['mp3', 'wav', 'ogg', 'aac', 'flac', 'm4a'],
    mimeTypes: ['audio/*'],
  );

  /// Все документы
  static const XTypeGroup documents = XTypeGroup(
    label: 'Документы',
    extensions: [
      'pdf',
      'doc',
      'docx',
      'txt',
      'rtf',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
      'odt',
      'ods',
      'odp',
    ],
    mimeTypes: [
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'text/plain',
    ],
  );

  /// Все типы файлов
  static const List<XTypeGroup> all = [images, videos, audios, documents];
}

/// Нижний лист для выбора и добавления медиа-файлов
class MediaPickerSheet extends StatefulWidget {
  final String? personId;
  final String? eventId;

  const MediaPickerSheet({super.key, this.personId, this.eventId});

  @override
  State<MediaPickerSheet> createState() => _MediaPickerSheetState();

  static Future<void> show({
    required BuildContext context,
    String? personId,
    String? eventId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          MediaPickerSheet(personId: personId, eventId: eventId),
    );
  }
}

class _MediaPickerSheetState extends State<MediaPickerSheet> {
  final TextEditingController _descriptionController = TextEditingController();
  bool _setAsPrimary = false;
  bool _isLoading = false;
  Uint8List? _selectedFileData;
  String? _selectedFileName;
  String? _selectedMimeType;

  @override
  void dispose() {
    _descriptionController.dispose();
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
            // Заголовок
            _buildHeader(),
            const SizedBox(height: 16),

            // Кнопки выбора файла
            _buildPickerButtons(),
            const SizedBox(height: 16),

            // Превью выбранного файла
            if (_selectedFileData != null) _buildPreview(),
            if (_selectedFileData != null) const SizedBox(height: 16),

            // Поле для описания
            _buildDescriptionField(),
            const SizedBox(height: 12),

            // Чекбокс "Сделать основным портретом" (только для человека)
            if (widget.personId != null) _buildPrimaryCheckbox(),
            if (widget.personId != null) const SizedBox(height: 12),

            // Кнопка добавления
            _buildAddButton(),
          ],
        ),
      ),
    );
  }

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
    return Row(
      children: [
        Expanded(
          child: _buildPickerButton(
            icon: Icons.photo_camera,
            label: 'Камера',
            onTap: () => _pickImage(ImageSource.camera),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPickerButton(
            icon: Icons.photo_library,
            label: 'Галерея',
            onTap: () => _pickImage(ImageSource.gallery),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPickerButton(
            icon: Icons.insert_drive_file,
            label: 'Файлы',
            onTap: _pickFile,
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.blue[700]),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
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
          // Превью
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
                      isVideo
                          ? Icons.videocam
                          : isAudio
                          ? Icons.audiotrack
                          : Icons.insert_drive_file,
                      size: 40,
                      color: Colors.grey[600],
                    ),
                  ),
          ),
          // Информация
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
          // Кнопка удаления выбранного файла
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
      title: const Text(
        'Сделать основным портретом',
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
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
    final isValid =
        _selectedFileData != null &&
        _descriptionController.text.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading || !isValid ? null : _addMedia,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Добавить файл', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  // ============================================================
  // МЕТОДЫ ВЫБОРА ФАЙЛОВ
  // ============================================================

  /// Выбор изображения через камеру или галерею
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
          _selectedFileData = bytes;
          _selectedFileName = picked.name;
          _selectedMimeType = _getMimeTypeFromExtension(
            picked.path.split('.').last,
          );
        });
      }
    } catch (e) {
      _showError('Ошибка выбора изображения: $e');
    }
  }

  /// Выбор файла через file_selector
  Future<void> _pickFile() async {
    try {
      // Открываем диалог выбора файла с поддержкой всех типов
      final XFile? file = await openFile(
        acceptedTypeGroups: FileTypes.all,
        initialDirectory: await _getInitialDirectory(),
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _selectedFileData = bytes;
          _selectedFileName = file.name;
          _selectedMimeType =
              file.mimeType ??
              _getMimeTypeFromExtension(file.path.split('.').last);
        });
      }
    } catch (e) {
      _showError('Ошибка выбора файла: $e');
    }
  }

  /// Получение начальной директории для file_selector
  Future<String?> _getInitialDirectory() async {
    try {
      // Пытаемся получить доступ к директории документов
      final documentsDir = await getApplicationDocumentsDirectory();
      return documentsDir.path;
    } catch (e) {
      return null;
    }
  }

  /// Определение MIME-типа по расширению
  String _getMimeTypeFromExtension(String extension) {
    const mimeTypes = {
      // Изображения
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'bmp': 'image/bmp',
      'webp': 'image/webp',
      'heic': 'image/heic',
      'heif': 'image/heif',
      // Видео
      'mp4': 'video/mp4',
      'avi': 'video/x-msvideo',
      'mov': 'video/quicktime',
      'wmv': 'video/x-ms-wmv',
      'flv': 'video/x-flv',
      'mkv': 'video/x-matroska',
      'webm': 'video/webm',
      // Аудио
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'aac': 'audio/aac',
      'flac': 'audio/flac',
      'm4a': 'audio/mp4',
      // Документы
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
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
    if (_selectedFileData == null) return;

    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      _showError('Пожалуйста, введите описание файла');
      return;
    }

    // Проверка размера файла (макс. 50 МБ)
    if (_selectedFileData!.length > 50 * 1024 * 1024) {
      _showError('Файл слишком большой (макс. 50 МБ)');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Проверяем, что указан personId или eventId
      if (widget.personId == null && widget.eventId == null) {
        _showError('Не указан получатель файла');
        return;
      }

      context.read<MediaBloc>().add(
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

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Ошибка добавления файла: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
