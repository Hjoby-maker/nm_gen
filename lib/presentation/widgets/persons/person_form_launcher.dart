// lib/presentation/widgets/persons/person_form_launcher.dart
import 'package:flutter/material.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/presentation/blocs/person/person_bloc.dart';
import 'package:nm_gen/presentation/blocs/person/person_event.dart';
import 'package:nm_gen/presentation/widgets/person_form_dialog.dart';

/// Открывает форму добавления нового человека и отправляет результат в
/// PersonBloc.
///
/// Используется в трёх местах: FAB на persons_screen.dart, кнопка
/// "Добавить человека" в пустом состоянии PersonsListView - оба места
/// должны делать ровно одно и то же, поэтому логика вынесена сюда, а не
/// продублирована.
void showAddPersonDialog(
  BuildContext context, {
  required PersonBloc personBloc,
  required String treeId,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) => PersonFormDialog(
      treeId: treeId,
      onSave: (person) {
        personBloc.add(AddPersonEvent(person, treeId: treeId));
      },
    ),
  );
}

/// Открывает форму редактирования человека и отправляет результат в
/// PersonBloc. Используется из шторки действий (свайп влево по строке
/// списка) - см. person_actions_sheet.dart.
void showEditPersonDialog(
  BuildContext context, {
  required PersonBloc personBloc,
  required Person person,
  required String treeId,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) => PersonFormDialog(
      existingPerson: person,
      treeId: treeId,
      onSave: (updatedPerson) {
        personBloc.add(UpdatePersonEvent(updatedPerson));
      },
    ),
  );
}