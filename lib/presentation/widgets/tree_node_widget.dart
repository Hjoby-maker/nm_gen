import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/entities/tree_node.dart';
import 'package:nm_gen/presentation/screens/tree_screen.dart';

/// Виджет для отображения узла дерева.
///
/// Раскладка теперь горизонтальная (фото/аватар слева, текст справа) и
/// зависит от уровня детализации (который, в свою очередь, зависит от
/// масштаба InteractiveViewer в tree_screen.dart):
///   - minimal: аватар + "Фамилия И.О."
///   - medium:  аватар + полное ФИО
///   - full:    аватар + полное ФИО, дата рождения и смерти (если есть)
class TreeNodeWidget extends StatelessWidget {
  const TreeNodeWidget({
    Key? key,
    required this.node,
    this.onTap,
    this.isSelected = false,
    this.isRoot = false,
    this.isCenter = false,
    this.detailLevel = DetailLevel.medium,
    this.isCompact = false,
  }) : super(key: key);

  final TreeNode node;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isRoot;
  final bool isCenter;
  final DetailLevel detailLevel;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final Person person = node.person;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final bool isMinimal = detailLevel == DetailLevel.minimal || isCompact;
    final bool isFull = detailLevel == DetailLevel.full && !isCompact;

    final double avatarRadius = isMinimal ? 14 : (isFull ? 26 : 20);
    final double iconSize = isMinimal ? 14 : (isFull ? 26 : 20);
    final double nameFontSize = isMinimal ? 11 : (isFull ? 13 : 13);
    final double dateFontSize = 10;
    final double padding = isMinimal ? 6.0 : (isFull ? 10.0 : 8.0);
    final double gap = isMinimal ? 6.0 : (isFull ? 10.0 : 8.0);

    // Определяем цвет выделения
    Color borderColor = Colors.grey.shade300;
    Color backgroundColor = Colors.white;
    double borderWidth = 1.0;

    if (isCenter) {
      // Центральный человек - яркое выделение
      borderColor = Colors.green;
      backgroundColor = Colors.green.shade50;
      borderWidth = 3.0;
    } else if (isSelected) {
      borderColor = colorScheme.primary;
      backgroundColor = colorScheme.primary.withOpacity(0.2);
      borderWidth = 2.0;
    } else if (isRoot) {
      borderColor = colorScheme.primary;
      backgroundColor = colorScheme.primary.withOpacity(0.15);
      borderWidth = 2.0;
    } else if (node.isDuplicateReference) {
      // Этот человек уже полностью отображён в другой ветке дерева
      // (например, как чей-то ребёнок в родительской линии супруга/супруги).
      // Показываем облегчённую карточку-ссылку, а не дублируем всю ветку.
      borderColor = Colors.orange.shade400;
      backgroundColor = Colors.orange.shade50;
      borderWidth = 1.5;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(isMinimal ? 8 : 12),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: isCenter
                  ? Colors.green.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.15),
              spreadRadius: isCenter ? 2 : 1,
              blurRadius: isCenter ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(padding),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(context, avatarRadius, iconSize),
            SizedBox(width: gap),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildTextContent(
                  person: person,
                  isMinimal: isMinimal,
                  isFull: isFull,
                  nameFontSize: nameFontSize,
                  dateFontSize: dateFontSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Аватар: если у человека есть основной портрет (person.photoPath) —
  /// показываем его фото, иначе — цветную заглушку с иконкой пола. Поверх
  /// — значки-бейджи (звезда для центра, ссылка для карточки-дубликата).
  Widget _buildAvatar(BuildContext context, double avatarRadius, double iconSize) {
    final Person person = node.person;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (person.hasPrimaryPortrait)
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: _getGenderColor(context),
            // Фото полностью закрывает заглушку с иконкой, поэтому child
            // здесь не задаём.
            backgroundImage: FileImage(File(person.photoPath!)),
            onBackgroundImageError: (_, __) {
              // Файл фото мог быть удалён/перемещён на устройстве — молча
              // остаёмся с цветной подложкой без фото, приложение не падает.
            },
          )
        else
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: _getGenderColor(context),
            child: Icon(
              person.gender == Gender.male
                  ? Icons.male
                  : person.gender == Gender.female
                  ? Icons.female
                  : Icons.person,
              color: Colors.white,
              size: iconSize,
            ),
          ),
        if (isCenter)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 10),
            ),
          ),
        if (node.isDuplicateReference)
          Positioned(
            left: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.orange.shade400,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.link, color: Colors.white, size: 10),
            ),
          ),
      ],
    );
  }

  /// Текстовый блок справа от аватара — состав зависит от уровня
  /// детализации, как просил пользователь:
  ///  - minimal: только "Фамилия И.О."
  ///  - medium:  только полное ФИО
  ///  - full:    полное ФИО + дата рождения + дата смерти (если есть)
  List<Widget> _buildTextContent({
    required Person person,
    required bool isMinimal,
    required bool isFull,
    required double nameFontSize,
    required double dateFontSize,
  }) {
    final FontWeight nameWeight = isRoot || isCenter
        ? FontWeight.bold
        : FontWeight.w500;
    final Color? nameColor = isCenter ? Colors.green.shade700 : null;

    if (isMinimal) {
      return [
        Text(
          _surnameWithInitials(person),
          style: TextStyle(
            fontWeight: nameWeight,
            fontSize: nameFontSize,
            color: nameColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ];
    }

    final List<Widget> lines = [
      Text(
        person.fullName,
        style: TextStyle(
          fontWeight: nameWeight,
          fontSize: nameFontSize,
          color: nameColor,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ];

    if (isFull) {
      final String? birth = person.birthDate != null
          ? _formatDate(person.birthDate!)
          : null;
      final String? death = person.deathDate != null
          ? _formatDate(person.deathDate!)
          : null;

      if (birth != null || death != null) {
        lines.add(const SizedBox(height: 2));
      }
      if (birth != null) {
        lines.add(
          Text(
            'р. $birth',
            style: TextStyle(
              fontSize: dateFontSize,
              color: isCenter ? Colors.green.shade600 : Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }
      if (!person.isAlive && death != null) {
        lines.add(
          Text(
            'ум. $death',
            style: TextStyle(
              fontSize: dateFontSize,
              color: isCenter ? Colors.green.shade600 : Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }
      if (node.isDuplicateReference) {
        lines.add(const SizedBox(height: 2));
        lines.add(
          Text(
            'Семья показана в другой ветке',
            style: TextStyle(
              fontSize: 8,
              color: Colors.orange.shade900,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }
    }

    return lines;
  }

  /// "Фамилия И.О." — собирается напрямую из структурированных полей
  /// Person (firstName/lastName/middleName), без разбора строк.
  String _surnameWithInitials(Person person) {
    final String initials = <String?>[person.firstName, person.middleName]
        .where((p) => p != null && p.isNotEmpty)
        .map((p) => '${p![0].toUpperCase()}.')
        .join(' ');

    if (person.lastName.isEmpty) {
      return initials.isEmpty ? person.displayName : initials;
    }
    return initials.isEmpty ? person.lastName : '${person.lastName} $initials';
  }

  String _formatDate(DateTime date) {
    final String d = date.day.toString().padLeft(2, '0');
    final String m = date.month.toString().padLeft(2, '0');
    return '$d.$m.${date.year}';
  }

  Color _getGenderColor(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    switch (node.person.gender) {
      case Gender.male:
        return Colors.blue;
      case Gender.female:
        return Colors.pink;
      default:
        return colorScheme.secondary;
    }
  }
}