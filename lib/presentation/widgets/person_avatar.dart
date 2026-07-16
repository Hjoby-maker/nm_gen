// lib/presentation/widgets/person_avatar.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/domain/entities/person.dart';

class PersonAvatar extends StatelessWidget {
  // ← Меняем на StatelessWidget
  const PersonAvatar({
    super.key,
    required this.person,
    this.radius = 30,
    this.onTap,
    this.onLongPress,
  });

  final Person person;
  final double radius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: _getBackgroundColor(),
        child: _buildChild(),
      ),
    );
  }

  Widget _buildChild() {
    // Если есть фото — показываем его
    if (person.photoPath != null && person.photoPath!.isNotEmpty) {
      final File file = File(person.photoPath!);
      if (file.existsSync()) {
        return ClipOval(
          child: Image.file(
            file,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildIcon(),
          ),
        );
      }
    }

    // Если фото нет — показываем иконку
    return _buildIcon();
  }

  Widget _buildIcon() {
    final iconData = _getIconData();
    final color = _getIconColor();
    return Icon(iconData, size: radius * 0.8, color: color);
  }

  IconData _getIconData() {
    switch (person.gender) {
      case Gender.male:
        return Icons.male;
      case Gender.female:
        return Icons.female;
      default:
        return Icons.person;
    }
  }

  Color _getBackgroundColor() {
    switch (person.gender) {
      case Gender.male:
        return Colors.blue.shade100;
      case Gender.female:
        return Colors.pink.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getIconColor() {
    switch (person.gender) {
      case Gender.male:
        return Colors.blue;
      case Gender.female:
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}
