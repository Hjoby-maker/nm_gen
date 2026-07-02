import 'package:flutter/material.dart';
import 'package:nm_gen/domain/entities/project.dart';

class TreeSelectorDrawer extends StatelessWidget {
  final String currentTreeId;
  final List<Project> projects;
  final Function(String, String) onTreeSelected;
  final VoidCallback onAddTree;
  final Function(String)? onDeleteProject;
  final Function(String)? onSetDefaultProject;
  final Function(String, String)? onRenameProject; // <-- ДОБАВЛЯЕМ

  const TreeSelectorDrawer({
    super.key,
    required this.currentTreeId,
    required this.projects,
    required this.onTreeSelected,
    required this.onAddTree,
    this.onDeleteProject,
    this.onSetDefaultProject,
    this.onRenameProject,
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
                  '${projects.length} проектов',
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
                final canDelete =
                    project.personCount == 0 &&
                    project.familyCount == 0 &&
                    !project.isDefault;

                return Dismissible(
                  key: Key(project.id),
                  direction: canDelete
                      ? DismissDirection.endToStart
                      : DismissDirection.none,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    if (onDeleteProject != null && canDelete) {
                      final result = await _showDeleteConfirmationDialog(
                        context,
                        project,
                      );
                      if (result == true) {
                        onDeleteProject!(project.id);
                      }
                      return false;
                    }
                    return false;
                  },
                  child: ListTile(
                    leading: Icon(
                      Icons.account_tree,
                      color: isSelected ? Colors.green : Colors.grey,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            project.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? Colors.green : null,
                            ),
                          ),
                        ),
                        if (project.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '⭐ По умолчанию',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Row(
                      children: [
                        if (project.personCount > 0)
                          Text(
                            '👤 ${project.personCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (project.familyCount > 0)
                          Text(
                            '👨‍👩‍👧‍👦 ${project.familyCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        if (project.description != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              project.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
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
                    onLongPress: () {
                      _showProjectActions(context, project);
                    },
                  ),
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

  void _showProjectActions(BuildContext context, Project project) {
    final canDelete =
        project.personCount == 0 &&
        project.familyCount == 0 &&
        !project.isDefault;

    showModalBottomSheet(
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
            // Переименовать проект
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.edit, color: Colors.white),
              ),
              title: const Text('Переименовать проект'),
              subtitle: Text('Изменить название "${project.name}"'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, project);
              },
            ),
            // Сделать проектом по умолчанию
            if (!project.isDefault)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.star, color: Colors.white),
                ),
                title: const Text('Сделать проектом по умолчанию'),
                subtitle: Text(
                  'Проект "${project.name}" будет выбран по умолчанию',
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (onSetDefaultProject != null) {
                    onSetDefaultProject!(project.id);
                  }
                },
              ),
            // Удалить проект
            if (canDelete)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                title: const Text('Удалить проект'),
                subtitle: Text(
                  'Удалить проект "${project.name}" без возможности восстановления',
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (onDeleteProject != null) {
                    _showDeleteConfirmationDialog(context, project);
                  }
                },
              ),
            if (project.isDefault)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Этот проект является проектом по умолчанию',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!canDelete && !project.isDefault)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Проект нельзя удалить, так как в нем есть персоны или семьи',
                          style: TextStyle(color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, Project project) {
    final TextEditingController controller = TextEditingController(
      text: project.name,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Переименовать проект'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Текущее название: "${project.name}"',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Новое название',
                hintText: 'Введите новое название проекта',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty && onRenameProject != null) {
                  onRenameProject!(project.id, value.trim());
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && onRenameProject != null) {
                onRenameProject!(project.id, newName);
                Navigator.pop(context);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(
    BuildContext context,
    Project project,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление проекта'),
        content: Text(
          'Вы уверены, что хотите удалить проект "${project.name}"?\n\n'
          'Все данные проекта будут удалены без возможности восстановления.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
