// lib/presentation/widgets/person_avatar.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/presentation/blocs/media/media_bloc.dart';
import 'package:nm_gen/presentation/blocs/media/media_event.dart';
import 'package:nm_gen/presentation/blocs/media/media_state.dart';

class PersonAvatar extends StatefulWidget {
  const PersonAvatar({
    super.key,
    required this.person,
    this.radius = 30,
    this.onTap,
    this.onLongPress,
    this.loadFromMedia =
        true, // Флаг: загружать из медиа-модуля или использовать photoPath
  });

  final Person person;
  final double radius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool loadFromMedia;

  @override
  State<PersonAvatar> createState() => _PersonAvatarState();
}

class _PersonAvatarState extends State<PersonAvatar> {
  String? _portraitPath;

  @override
  void initState() {
    super.initState();
    if (widget.loadFromMedia && widget.person.id.isNotEmpty) {
      _loadPortrait();
    }
  }

  void _loadPortrait() {
    final mediaBloc = context.read<MediaBloc>();
    mediaBloc.add(LoadPrimaryPortrait(widget.person.id));
  }

  @override
  Widget build(BuildContext context) {
    // Если используем старый photoPath
    if (!widget.loadFromMedia) {
      return _buildAvatar(widget.person.photoPath);
    }

    // Используем медиа-модуль
    return BlocBuilder<MediaBloc, MediaState>(
      builder: (context, state) {
        String? path;

        if (state is PrimaryPortraitLoaded &&
            state.personId == widget.person.id) {
          path = state.portrait?.localPath;
        }

        // Если портрет не загружен, используем photoPath как fallback
        if (path == null || path.isEmpty) {
          path = widget.person.photoPath;
        }

        return _buildAvatar(path);
      },
    );
  }

  Widget _buildAvatar(String? photoPath) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: CircleAvatar(
        radius: widget.radius,
        backgroundColor: _getBackgroundColor(),
        child: _buildChild(photoPath),
      ),
    );
  }

  Widget _buildChild(String? photoPath) {
    // Если есть фото — показываем его
    if (photoPath != null && photoPath.isNotEmpty) {
      final file = File(photoPath);
      if (file.existsSync()) {
        return ClipOval(
          child: Image.file(
            file,
            width: widget.radius * 2,
            height: widget.radius * 2,
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
    return Icon(iconData, size: widget.radius * 0.8, color: color);
  }

  IconData _getIconData() {
    switch (widget.person.gender) {
      case Gender.male:
        return Icons.male;
      case Gender.female:
        return Icons.female;
      default:
        return Icons.person;
    }
  }

  Color _getBackgroundColor() {
    switch (widget.person.gender) {
      case Gender.male:
        return Colors.blue.shade100;
      case Gender.female:
        return Colors.pink.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getIconColor() {
    switch (widget.person.gender) {
      case Gender.male:
        return Colors.blue;
      case Gender.female:
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}
