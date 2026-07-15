// lib/core/utils/image_picker_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Выбор изображения из галереи или камеры
  Future<File?> pickImage(
    BuildContext context, {
    ImageSource source = ImageSource.gallery,
    bool showDeleteOption = true,
  }) async {
    final List<Widget> actions = [];

    if (showDeleteOption) {
      actions.add(
        TextButton(
          onPressed: () => Navigator.pop(context, 'delete'),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Удалить фото'),
        ),
      );
    }

    actions.add(
      TextButton(
        onPressed: () => Navigator.pop(context, 'camera'),
        child: const Text('Камера'),
      ),
    );

    actions.add(
      TextButton(
        onPressed: () => Navigator.pop(context, 'gallery'),
        child: const Text('Галерея'),
      ),
    );

    actions.add(
      TextButton(
        onPressed: () => Navigator.pop(context, 'cancel'),
        child: const Text('Отмена'),
      ),
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите действие'),
        content: const Text('Что вы хотите сделать с фото?'),
        actions: actions,
      ),
    );

    if (result == 'delete') {
      return null; // Удалить фото
    }

    if (result == 'camera' || result == 'gallery') {
      final source = result == 'camera'
          ? ImageSource.camera
          : ImageSource.gallery;

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    }

    return null;
  }

  /// Быстрый выбор изображения (без диалога)
  Future<File?> pickImageQuick(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }
}
