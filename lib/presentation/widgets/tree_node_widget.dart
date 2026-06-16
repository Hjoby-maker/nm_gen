import 'package:flutter/material.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/domain/entities/tree_node.dart';

/// Виджет для отображения узла дерева
class TreeNodeWidget extends StatelessWidget {
  final TreeNode node;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isRoot;

  const TreeNodeWidget({
    Key? key,
    required this.node,
    this.onTap,
    this.isSelected = false,
    this.isRoot = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final person = node.person;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.2)
              : isRoot
              ? colorScheme.primary.withOpacity(0.15)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
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
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Аватар
            CircleAvatar(
              radius: 24,
              backgroundColor: _getGenderColor(context),
              child: Icon(
                person.gender == Gender.male
                    ? Icons.male
                    : person.gender == Gender.female
                    ? Icons.female
                    : Icons.person,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 4),
            // Имя
            Text(
              person.displayName,
              style: TextStyle(
                fontWeight: isRoot ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            // Возраст
            if (person.formattedAge != 'Возраст неизвестен')
              Text(
                person.formattedAge,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            // Статус (жив/умер)
            if (!person.isAlive)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('†', style: TextStyle(fontSize: 10)),
              ),
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
