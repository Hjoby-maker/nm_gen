// lib/presentation/widgets/media/media_card.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nm_gen/core/utils/file_helper.dart';
import 'package:nm_gen/domain/entities/media_attachment.dart';

/// Карточка медиа-файла для отображения в сетке
class MediaCard extends StatelessWidget {
  const MediaCard({
    super.key,
    required this.media,
    this.isPrimary = false,
    this.onTap,
    this.onDelete,
    this.onSetPrimary,
    this.onEditDescription,
  });
  final MediaAttachment media;
  final bool isPrimary;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onSetPrimary;
  final VoidCallback? onEditDescription;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            // Миниатюра или иконка
            _buildThumbnail(),

            // Значок "Основной портрет"
            if (isPrimary) _buildPrimaryBadge(),

            // ✅ Значок "файл на устройстве" (не скопирован приложением)
            if (media.isDeviceReference) _buildSourceBadge(),

            // Кнопка удаления (только если есть onDelete)
            if (onDelete != null) _buildDeleteButton(context),

            // Кнопка "Сделать основным" (только если есть onSetPrimary и не isPrimary)
            if (onSetPrimary != null && !isPrimary)
              _buildSetPrimaryButton(context),

            // Нижняя панель с информацией
            _buildInfoPanel(context),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    // ✅ Внешняя ссылка: локального файла нет вообще, показываем иконку
    // ссылки и хост, вместо попытки прочитать несуществующий File(null).
    if (media.isExternalLink) {
      return _buildLinkThumbnail();
    }

    final bool hasThumbnail =
        media.thumbnailPath != null && File(media.thumbnailPath!).existsSync();
    // ⚠️ localPath теперь может быть null в принципе (по модели), но для
    // appStorage/deviceReference он всегда есть - на всякий случай
    // проверяем и это, а не только физическое существование файла на
    // диске (best-effort: файл-ссылка с телефона мог быть удалён/перемещён
    // пользователем или недоступен после перезапуска на Android - тогда
    // просто покажем заглушку вместо падения).
    final bool hasFile =
        media.localPath != null && File(media.localPath!).existsSync();

    // Если есть миниатюра
    if (hasThumbnail) {
      return Image.file(
        File(media.thumbnailPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildFallbackIcon(),
      );
    }

    // Если есть файл и это изображение
    if (hasFile && media.isImage) {
      return Image.file(
        File(media.localPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildFallbackIcon(),
      );
    }

    // Для видео с миниатюрой
    if (media.isVideo && hasThumbnail) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(media.thumbnailPath!),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackIcon(),
          ),
          const Center(
            child: Icon(
              Icons.play_circle_filled,
              color: Colors.white,
              size: 48,
            ),
          ),
        ],
      );
    }

    // Для видео без миниатюры
    if (media.isVideo) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.grey[900],
            child: const Center(
              child: Icon(Icons.videocam, size: 48, color: Colors.grey),
            ),
          ),
          const Center(
            child: Icon(
              Icons.play_circle_filled,
              color: Colors.white,
              size: 48,
            ),
          ),
        ],
      );
    }

    // Для аудио
    if (media.isAudio) {
      return Container(
        color: Colors.grey[800],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.audiotrack, size: 48, color: Colors.white70),
              const SizedBox(height: 8),
              Text(
                media.fileName,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    // ✅ Файл-ссылка с устройства, который больше не найден на диске
    // (перемещён/удалён пользователем, либо на Android слетело
    // разрешение после перезапуска). Показываем это явно, а не как
    // обычный документ - иначе непонятно, почему нет превью.
    if (media.isDeviceReference && !hasFile) {
      return _buildMissingFileState();
    }

    // Для документов и других файлов
    return _buildFallbackIcon();
  }

  /// Иконка внешней ссылки + домен, вместо попытки показать несуществующий
  /// локальный файл.
  Widget _buildLinkThumbnail() {
    String host = media.remoteUrl ?? '';
    final Uri? uri = Uri.tryParse(media.remoteUrl ?? '');
    if (uri != null && uri.host.isNotEmpty) host = uri.host;

    return Container(
      color: Colors.blue.shade50,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link, size: 44, color: Colors.blue.shade400),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                host,
                style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Состояние для файла-ссылки с устройства, который сейчас недоступен.
  Widget _buildMissingFileState() {
    return Container(
      color: Colors.orange.shade50,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.link_off,
              size: 40,
              color: Colors.orange.shade400,
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Файл недоступен',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getIconForType(), size: 48, color: Colors.grey[600]),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                media.mediaType.displayName,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType() {
    switch (media.mediaType) {
      case MediaType.image:
        return Icons.image;
      case MediaType.video:
        return Icons.videocam;
      case MediaType.audio:
        return Icons.audiotrack;
      case MediaType.document:
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildPrimaryBadge() {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text(
              'Основной',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Небольшой значок в углу карточки, показывающий, что это ссылка на
  /// файл на устройстве, а не копия, которой владеет приложение.
  Widget _buildSourceBadge() {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.smartphone, color: Colors.white, size: 14),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 16),
          onPressed: () => _showDeleteDialog(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          splashRadius: 20,
        ),
      ),
    );
  }

  Widget _buildSetPrimaryButton(BuildContext context) {
    return Positioned(
      bottom: 50,
      right: 8,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.star_border, color: Colors.white, size: 16),
          onPressed: onSetPrimary,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          splashRadius: 20,
          tooltip: 'Сделать основным портретом',
        ),
      ),
    );
  }

  Widget _buildInfoPanel(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (media.description.isNotEmpty)
              Text(
                media.description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  media.formattedSize,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
                const Spacer(),
                Text(
                  _formatDate(media.createdAt),
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inDays < 30) {
      final int weeks = difference.inDays ~/ 7;
      return '$weeks нед. назад';
    } else if (difference.inDays < 365) {
      final int months = difference.inDays ~/ 30;
      return '$months мес. назад';
    } else {
      final int years = difference.inDays ~/ 365;
      return '$years г. назад';
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить файл?'),
        content: Text(
          'Вы уверены, что хотите удалить файл "${media.fileName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}