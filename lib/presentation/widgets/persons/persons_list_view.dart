// lib/presentation/widgets/persons/persons_list_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/di/injector.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/presentation/blocs/family/family_bloc.dart';
import 'package:nm_gen/presentation/blocs/person/person_bloc.dart';
import 'package:nm_gen/presentation/blocs/person/person_event.dart';
import 'package:nm_gen/presentation/blocs/person/person_state.dart';
import 'package:nm_gen/presentation/blocs/tree/tree_bloc.dart';
import 'package:nm_gen/presentation/screens/family_screen.dart';
import 'package:nm_gen/presentation/screens/person_detail_screen.dart';
import 'package:nm_gen/presentation/screens/tree_screen.dart';
import 'package:nm_gen/presentation/widgets/persons/confirm_delete_person_dialog.dart';
import 'package:nm_gen/presentation/widgets/persons/person_actions_sheet.dart';
import 'package:nm_gen/presentation/widgets/persons/person_form_launcher.dart';
import 'package:nm_gen/presentation/widgets/persons/person_list_tile.dart';

/// Тело экрана списка персон: подписывается на PersonBloc (уже
/// предоставлен выше по дереву через MultiBlocProvider в
/// persons_screen.dart, здесь достаточно context.read/BlocConsumer) и
/// рисует загрузку/ошибку/пустой список/сам список - плюс вся логика по
/// строке списка (переход к деталям, удаление, шторка действий, переходы
/// на экраны семьи/древа). persons_screen.dart отвечает только за
/// Scaffold (AppBar/FAB) и владение блоками - см. person_detail_screen.dart
/// для того же принципа разделения.
class PersonsListView extends StatelessWidget {
  const PersonsListView({super.key, required this.treeId});

  final String treeId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PersonBloc, PersonState>(
      listener: (context, state) {
        if (state is PersonOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is PersonError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is PersonLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Загрузка данных...'),
              ],
            ),
          );
        }

        if (state is PersonError) {
          return _buildErrorState(context, state.message);
        }

        if (state is PersonsLoaded) {
          return state.persons.isEmpty
              ? _buildEmptyState(context, state)
              : _buildList(context, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'TreeId: $treeId',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _reload(context),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, PersonsLoaded state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            state.isSearching
                ? 'Ничего не найдено по запросу "${state.searchQuery}"'
                : 'Нет людей в базе данных',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'TreeId: $treeId',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          if (state.isSearching)
            ElevatedButton(
              onPressed: () =>
                  context.read<PersonBloc>().add(const ClearSearchEvent()),
              child: const Text('Очистить поиск'),
            )
          else
            ElevatedButton(
              onPressed: () => showAddPersonDialog(
                context,
                personBloc: context.read<PersonBloc>(),
                treeId: treeId,
              ),
              child: const Text('Добавить человека'),
            ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, PersonsLoaded state) {
    return Column(
      children: [
        if (state.isSearching)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Результаты поиска: "${state.searchQuery}" (${state.persons.length})',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      context.read<PersonBloc>().add(const ClearSearchEvent()),
                  child: const Text('Очистить'),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.persons.length,
            itemBuilder: (context, index) {
              final Person person = state.persons[index];
              return PersonListTile(
                person: person,
                onTap: () => _openPersonDetail(context, person),
                onConfirmDelete: () async {
                  final bool confirmed = await confirmDeletePersonDialog(
                    context,
                    person.displayName,
                  );
                  if (confirmed) {
                    context.read<PersonBloc>().add(
                      DeletePersonEvent(person.id),
                    );
                  }
                  return confirmed;
                },
                onDeleted: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Человек удален'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                onSwipeLeftActions: () => showPersonActionsSheet(
                  context,
                  person: person,
                  onEdit: () => showEditPersonDialog(
                    context,
                    personBloc: context.read<PersonBloc>(),
                    person: person,
                    treeId: treeId,
                  ),
                  onManageFamily: () => _navigateToFamily(context, person),
                  onShowInTree: () =>
                      _navigateToTreeWithPerson(context, person.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _reload(BuildContext context) {
    context.read<PersonBloc>().add(LoadPersonsEvent(treeId: treeId));
  }

  Future<void> _openPersonDetail(BuildContext context, Person person) async {
    final PersonBloc personBloc = context.read<PersonBloc>();
    // ⚠️ PersonDetailScreen создаёт свой собственный экземпляр PersonBloc
    // через getIt<PersonBloc>(), отдельный от блока этого экрана - поэтому
    // изменения (аватар, редактирование полей) не прилетают сюда сами по
    // себе через общий bloc. Простое и надёжное решение - перезагрузить
    // список при возврате, вне зависимости от того, как именно
    // зарегистрирован PersonBloc в DI.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonDetailScreen(personId: person.id),
      ),
    );
    personBloc.add(LoadPersonsEvent(treeId: treeId));
  }

  void _navigateToFamily(BuildContext context, Person person) {
    final PersonBloc personBloc = context.read<PersonBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: personBloc),
            BlocProvider<FamilyBloc>(create: (context) => getIt<FamilyBloc>()),
          ],
          child: FamilyScreen(
            personId: person.id,
            personName: person.displayName,
          ),
        ),
      ),
    );
  }

  void _navigateToTreeWithPerson(BuildContext context, String personId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => getIt<TreeBloc>(),
          child: TreeScreen(rootPersonId: personId, treeId: treeId),
        ),
      ),
    );
  }
}