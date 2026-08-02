// lib/presentation/widgets/persons/person_actions_sheet.dart
import 'package:flutter/material.dart';
import 'package:nm_gen/domain/entities/person.dart';

/// Нижняя шторка с действиями над человеком, открываемая свайпом влево по
/// строке в списке (PersonListTile): редактировать / управление семьёй /
/// показать в древе.
void showPersonActionsSheet(
  BuildContext context, {
  required Person person,
  required VoidCallback onEdit,
  required VoidCallback onManageFamily,
  required VoidCallback onShowInTree,
}) {
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
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.edit, color: Colors.white),
            ),
            title: const Text('Редактировать'),
            subtitle: Text('Изменить данные "${person.displayName}"'),
            onTap: () {
              Navigator.pop(context);
              onEdit();
            },
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(Icons.family_restroom, color: Colors.white),
            ),
            title: const Text('Управление семьей'),
            subtitle: Text('Семьи ${person.displayName}'),
            onTap: () {
              Navigator.pop(context);
              onManageFamily();
            },
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.account_tree, color: Colors.white),
            ),
            title: const Text('Показать в древе'),
            subtitle: Text('Древо ${person.displayName}'),
            onTap: () {
              Navigator.pop(context);
              onShowInTree();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}