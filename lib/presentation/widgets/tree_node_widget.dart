import 'package:flutter/material.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/domain/entities/tree_node.dart';
import 'package:nm_gen/presentation/screens/tree_screen.dart';

/// Виджет для отображения узла дерева
class TreeNodeWidget extends StatelessWidget {
  final TreeNode node;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isRoot;
  final bool isCenter; // <-- Добавляем флаг
  final DetailLevel detailLevel;
  final bool isCompact;

  const TreeNodeWidget({
    Key? key,
    required this.node,
    this.onTap,
    this.isSelected = false,
    this.isRoot = false,
    this.isCenter = false, // <-- По умолчанию false
    this.detailLevel = DetailLevel.medium,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final person = node.person;
    final colorScheme = Theme.of(context).colorScheme;

    final isMinimal = detailLevel == DetailLevel.minimal || isCompact;
    final isFull = detailLevel == DetailLevel.full && !isCompact;

    final avatarRadius = isMinimal ? 16 : (isFull ? 28 : 22);
    final iconSize = isMinimal ? 18 : (isFull ? 28 : 22);
    final fontSize = isMinimal ? 10 : (isFull ? 14 : 12);
    final padding = isMinimal ? 4.0 : (isFull ? 12.0 : 8.0);

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Аватар с обводкой для центрального человека
            Stack(
              children: [
                CircleAvatar(
                  radius: avatarRadius.toDouble(),
                  backgroundColor: _getGenderColor(context),
                  child: Icon(
                    person.gender == Gender.male
                        ? Icons.male
                        : person.gender == Gender.female
                        ? Icons.female
                        : Icons.person,
                    color: Colors.white,
                    size: iconSize.toDouble(),
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
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            // Имя
            if (!isMinimal || isRoot) ...[
              const SizedBox(height: 4),
              Text(
                person.displayName,
                style: TextStyle(
                  fontWeight: isRoot || isCenter
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: fontSize.toDouble(),
                  color: isCenter ? Colors.green.shade700 : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
            // Дополнительная информация
            if (!isMinimal) ...[
              if (person.formattedAge != 'Возраст неизвестен' && !isCompact)
                Text(
                  person.formattedAge,
                  style: TextStyle(
                    fontSize: (fontSize - 2).toDouble(),
                    color: isCenter
                        ? Colors.green.shade600
                        : Colors.grey.shade600,
                  ),
                ),
              if (!person.isAlive && isFull)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('†', style: TextStyle(fontSize: 10)),
                ),
              if (isFull && person.occupation != null)
                Text(
                  person.occupation!,
                  style: TextStyle(
                    fontSize: (fontSize - 2).toDouble(),
                    color: Colors.grey.shade500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              // Подпись "Центр" для выделенного человека
              if (isCenter)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ЦЕНТР',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getGenderColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
