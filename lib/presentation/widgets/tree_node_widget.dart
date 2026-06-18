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
  final DetailLevel detailLevel;
  final bool isCompact;

  const TreeNodeWidget({
    Key? key,
    required this.node,
    this.onTap,
    this.isSelected = false,
    this.isRoot = false,
    this.detailLevel = DetailLevel.medium,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final person = node.person;
    final colorScheme = Theme.of(context).colorScheme;

    // Определяем размеры в зависимости от уровня детализации
    final isMinimal = detailLevel == DetailLevel.minimal || isCompact;
    final isFull = detailLevel == DetailLevel.full && !isCompact;

    final avatarRadius = isMinimal ? 16 : (isFull ? 28 : 22);
    final iconSize = isMinimal ? 18 : (isFull ? 28 : 22);
    final fontSize = isMinimal ? 10 : (isFull ? 14 : 12);
    final padding = isMinimal ? 4.0 : (isFull ? 12.0 : 8.0);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.2)
              : isRoot
              ? colorScheme.primary.withOpacity(0.15)
              : Colors.white,
          borderRadius: BorderRadius.circular(isMinimal ? 8 : 12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : isRoot
                ? colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : (isRoot ? 2 : 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Аватар
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
            // Имя (всегда показываем)
            if (!isMinimal || isRoot) ...[
              const SizedBox(height: 4),
              Text(
                person.displayName,
                style: TextStyle(
                  fontWeight: isRoot ? FontWeight.bold : FontWeight.normal,
                  fontSize: fontSize.toDouble(),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
            // Дополнительная информация для среднего и полного режимов
            if (!isMinimal) ...[
              // Возраст
              if (person.formattedAge != 'Возраст неизвестен' && !isCompact)
                Text(
                  person.formattedAge,
                  style: TextStyle(
                    fontSize: (fontSize - 2).toDouble(),
                    color: Colors.grey.shade600,
                  ),
                ),
              // Статус (жив/умер)
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
              // Профессия (только в полном режиме)
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
