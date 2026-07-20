// lib/presentation/widgets/person_detail/person_avatar_picker.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/core/utils/file_helper.dart';
import 'package:nm_gen/core/utils/image_picker_service.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/presentation/blocs/media/media_bloc.dart';
import 'package:nm_gen/presentation/blocs/media/media_event.dart';
import 'package:nm_gen/presentation/widgets/person_avatar.dart';

/// Кликабельный аватар человека с возможностью выбрать новое фото
/// (камера/галерея) и сохранить его как основной портрет.
///
/// Берёт MediaBloc из контекста (он уже предоставлен на уровне экрана
/// через MultiBlocProvider) - явно прокидывать его сюда не нужно.
/// Сохранённое фото попадёт в состояние через MediaBloc (AddMediaFile с
/// setAsPrimary: true); синхронизация person.photoPath после этого -
/// ответственность экрана (PersonDetailScreen), а не этого виджета, т.к.
/// именно экран владеет состоянием Person.
class PersonAvatarPicker extends StatelessWidget {
  const PersonAvatarPicker({super.key, required this.person, this.radius = 50});

  final Person person;
  final double radius;

  static final ImagePickerService _imagePickerService = ImagePickerService();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickAndSetAvatar(context),
      child: Stack(
        children: [
          PersonAvatar(person: person, radius: radius),
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
              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Выбор фото (камера/галерея) и сохранение его как основного портрета
  /// человека. Реально сохраняется на диск через FileStorageService (внутри
  /// MediaRepository.addMedia -> FileStorageService.saveFile), путь и
  /// метаданные пишутся в MediaAttachment с setAsPrimary: true.
  Future<void> _pickAndSetAvatar(BuildContext context) async {
    if (person.id.isEmpty) return;

    // showDeleteOption: false - удаление текущего портрета уже доступно
    // на вкладке "Файлы" (кнопка удаления на карточке медиа с пометкой
    // "Основной"), так что здесь не нужно решать неоднозначность между
    // "отмена" и "удалить" (оба варианта ImagePickerService.pickImage
    // возвращают null).
    final File? picked = await _imagePickerService.pickImage(
      context,
      showDeleteOption: false,
    );

    if (picked == null || !context.mounted) return; // пользователь отменил выбор

    try {
      final Uint8List bytes = await picked.readAsBytes();
      final String fileName = picked.path.split(Platform.pathSeparator).last;
      final String mimeType = FileHelper.getMimeTypeFromExtension(fileName);

      context.read<MediaBloc>().add(
        AddMediaFile(
          fileData: bytes,
          fileName: fileName,
          mimeType: mimeType,
          description: 'Портрет',
          personId: person.id,
          setAsPrimary: true,
          generateThumbnail: true,
        ),
      );
      // MediaSection (вкладка "Файлы") уже подписан на этот же MediaBloc
      // через BlocConsumer и сам покажет SnackBar об успехе/ошибке и
      // обновит список - здесь дублировать не нужно.
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки фото: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}