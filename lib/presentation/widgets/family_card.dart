import 'package:flutter/material.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/core/enums/gender.dart';

/// Карточка семьи для отображения
class FamilyCard extends StatelessWidget {
  final Family family;
  final Person? husband;
  final Person? wife;
  final List<Person> children;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const FamilyCard({
    Key? key,
    required this.family,
    this.husband,
    this.wife,
    this.children = const [],
    this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Родители
              Row(
                children: [
                  Expanded(
                    child: _buildParentChip(
                      context,
                      husband,
                      '${husband?.displayName ?? 'Не указан'}',
                      Icons.male,
                      Colors.blue,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.favorite, color: Colors.red, size: 16),
                  ),
                  Expanded(
                    child: _buildParentChip(
                      context,
                      wife,
                      '${wife?.displayName ?? 'Не указан'}',
                      Icons.female,
                      Colors.pink,
                    ),
                  ),
                ],
              ),
              // Дети
              if (children.isNotEmpty) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.child_care, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Дети (${children.length})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: children.map((child) {
                    return Chip(
                      label: Text(child.displayName),
                      avatar: CircleAvatar(
                        radius: 12,
                        backgroundColor: child.gender == Gender.male
                            ? Colors.blue.shade100
                            : Colors.pink.shade100,
                        child: Icon(
                          child.gender == Gender.male
                              ? Icons.male
                              : Icons.female,
                          size: 14,
                          color: child.gender == Gender.male
                              ? Colors.blue
                              : Colors.pink,
                        ),
                      ),
                      onDeleted: () {
                        // TODO: Удалить ребенка из семьи
                      },
                    );
                  }).toList(),
                ),
              ],
              // Даты
              if (family.marriageDate != null || family.divorceDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      if (family.marriageDate != null)
                        Text(
                          'Брак: ${_formatDate(family.marriageDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      if (family.marriageDate != null &&
                          family.divorceDate != null)
                        const SizedBox(width: 16),
                      if (family.divorceDate != null)
                        Text(
                          'Развод: ${_formatDate(family.divorceDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              // Кнопки действий
              if (onEdit != null || onDelete != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: onEdit,
                          tooltip: 'Редактировать',
                        ),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 20,
                            color: Colors.red,
                          ),
                          onPressed: onDelete,
                          tooltip: 'Удалить',
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParentChip(
    BuildContext context,
    Person? person,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: person != null ? color.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: person != null ? color : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: person != null ? color : Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: person != null
                    ? FontWeight.w500
                    : FontWeight.normal,
                color: person != null ? Colors.black87 : Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
