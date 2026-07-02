import 'package:flutter/material.dart';
import 'package:nm_gen/domain/entities/tree_project.dart';

class TreeSelectorDrawer extends StatelessWidget {
  final String currentTreeId;
  final List<TreeProject> projects;
  final Function(String, String) onTreeSelected;
  final VoidCallback onAddTree;

  const TreeSelectorDrawer({
    super.key,
    required this.currentTreeId,
    required this.projects,
    required this.onTreeSelected,
    required this.onAddTree,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Заголовок
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: Colors.green.shade700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.family_restroom,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  'Генеалогическое древо',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Выберите проект',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          // Список проектов
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                final isSelected = project.id == currentTreeId;

                return ListTile(
                  leading: Icon(
                    Icons.account_tree,
                    color: isSelected ? Colors.green : Colors.grey,
                  ),
                  title: Text(
                    project.name,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? Colors.green : null,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  selected: isSelected,
                  selectedTileColor: Colors.green.shade50,
                  onTap: () {
                    if (!isSelected) {
                      onTreeSelected(project.id, project.name);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                );
              },
            ),
          ),
          // Кнопка добавления нового древа
          Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton.icon(
              onPressed: onAddTree,
              icon: const Icon(Icons.add),
              label: const Text('Создать новое древо'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
