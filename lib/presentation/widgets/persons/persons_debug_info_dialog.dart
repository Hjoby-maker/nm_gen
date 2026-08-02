// lib/presentation/widgets/persons/persons_debug_info_dialog.dart
import 'package:flutter/material.dart';
import 'package:nm_gen/presentation/blocs/person/person_state.dart';

/// Диалог с отладочной информацией о текущем состоянии PersonBloc -
/// открывается по кнопке "жук" в AppBar экрана списка персон.
void showPersonsDebugInfoDialog(
  BuildContext context, {
  required String treeId,
  required PersonState state,
  required bool mounted,
  required bool isInitialized,
  required VoidCallback onReload,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Отладочная информация'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _debugRow('TreeId', treeId),
            _debugRow('Состояние', state.runtimeType.toString()),
            if (state is PersonsLoaded) ...[
              _debugRow('Количество персон', state.persons.length.toString()),
              _debugRow('Поиск', state.isSearching ? 'Да' : 'Нет'),
              _debugRow('Запрос', state.searchQuery ?? 'нет'),
              _debugRow('TreeId из состояния', state.treeId ?? 'нет'),
            ],
            if (state is PersonError) _debugRow('Ошибка', state.message),
            const Divider(),
            const Text(
              'Проверьте логи в консоли',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'В консоли есть отладочные сообщения с 🔍',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'mounted: $mounted',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              'isInitialized: $isInitialized',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Закрыть'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onReload();
          },
          child: const Text('Перезагрузить'),
        ),
      ],
    ),
  );
}

Widget _debugRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontFamily: 'monospace')),
        ),
      ],
    ),
  );
}