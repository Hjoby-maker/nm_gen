// lib/presentation/widgets/persons/confirm_delete_person_dialog.dart
import 'package:flutter/material.dart';

/// Диалог подтверждения удаления человека.
///
/// Возвращает true, если пользователь подтвердил удаление - сама отправка
/// DeletePersonEvent в PersonBloc остаётся на стороне вызывающего кода
/// (PersonsListView), этот диалог отвечает только за подтверждение в UI.
Future<bool> confirmDeletePersonDialog(
  BuildContext context,
  String name,
) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Удаление человека'),
      content: Text('Вы уверены, что хотите удалить "$name"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Удалить'),
        ),
      ],
    ),
  );
  return result ?? false;
}