import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Выбор изображения из галереи
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      return null;
    }
  }

  /// Выбор изображения с камеры
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      return null;
    }
  }

  /// Выбор изображения с возможностью выбора источника
  Future<File?> pickImage(BuildContext context) async {
    // Сначала показываем меню и получаем выбранное действие (строку)
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Выбрать из галереи'),
              onTap: () => Navigator.pop(
                context,
                'gallery',
              ), // Закрываем меню и возвращаем 'gallery'
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Сделать фото'),
              onTap: () => Navigator.pop(
                context,
                'camera',
              ), // Закрываем меню и возвращаем 'camera'
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Удалить фото',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    // После закрытия меню выполняем нужное действие
    if (action == 'gallery') {
      return await pickImageFromGallery();
    } else if (action == 'camera') {
      return await pickImageFromCamera();
    }

    // Если пользователь закрыл меню свайпом или нажал "Удалить", возвращаем null
    return null;
  }
}
