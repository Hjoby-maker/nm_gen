import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/core/enums/gender.dart';
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
import 'package:nm_gen/presentation/widgets/person_form_dialog.dart'; // <-- ДОБАВЛЯЕМ

class PersonsScreen extends StatefulWidget {
  final String treeId;

  const PersonsScreen({super.key, required this.treeId});

  @override
  State<PersonsScreen> createState() => _PersonsScreenState();
}

class _PersonsScreenState extends State<PersonsScreen> {
  late final PersonBloc _personBloc;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _personBloc = getIt<PersonBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isInitialized) {
        _isInitialized = true;
        _personBloc.add(LoadPersonsEvent(treeId: widget.treeId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _personBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Персоны'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _showSearchDialog(context),
              tooltip: 'Поиск',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _personBloc.add(LoadPersonsEvent(treeId: widget.treeId));
              },
              tooltip: 'Обновить',
            ),
          ],
        ),
        body: BlocConsumer<PersonBloc, PersonState>(
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
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
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
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _personBloc.add(
                          LoadPersonsEvent(treeId: widget.treeId),
                        );
                      },
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              );
            }

            if (state is PersonsLoaded) {
              if (state.persons.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.isSearching
                            ? 'Ничего не найдено по запросу "${state.searchQuery}"'
                            : 'Нет людей в базе данных',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (state.isSearching)
                        ElevatedButton(
                          onPressed: () {
                            _personBloc.add(const ClearSearchEvent());
                          },
                          child: const Text('Очистить поиск'),
                        )
                      else
                        ElevatedButton(
                          onPressed: () => _showAddPersonDialog(context),
                          child: const Text('Добавить человека'),
                        ),
                    ],
                  ),
                );
              }

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
                            onPressed: () {
                              _personBloc.add(const ClearSearchEvent());
                            },
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
                        final person = state.persons[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: person.gender == Gender.male
                                  ? Colors.blue.shade100
                                  : person.gender == Gender.female
                                  ? Colors.pink.shade100
                                  : Colors.grey.shade200,
                              child: Icon(
                                person.gender == Gender.male
                                    ? Icons.male
                                    : person.gender == Gender.female
                                    ? Icons.female
                                    : Icons.person,
                                color: person.gender == Gender.male
                                    ? Colors.blue
                                    : person.gender == Gender.female
                                    ? Colors.pink
                                    : Colors.grey,
                              ),
                            ),
                            title: Text(person.displayName),
                            subtitle: Text(
                              '${person.formattedAge} · ${person.occupation ?? 'Без профессии'}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.family_restroom,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () {
                                    _navigateToFamily(
                                      context,
                                      person.id,
                                      person.displayName,
                                    );
                                  },
                                  tooltip: 'Управление семьей',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.account_tree,
                                    color: Colors.green,
                                  ),
                                  onPressed: () {
                                    _navigateToTreeWithPerson(
                                      context,
                                      person.id,
                                    );
                                  },
                                  tooltip: 'Показать в древе',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () =>
                                      _showEditPersonDialog(context, person),
                                  tooltip: 'Редактировать',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _confirmDelete(
                                    context,
                                    person.id,
                                    person.displayName,
                                  ),
                                  tooltip: 'Удалить',
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PersonDetailScreen(personId: person.id),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddPersonDialog(context),
          child: const Icon(Icons.person_add),
        ),
      ),
    );
  }

  // =========================================================================
  // НАВИГАЦИЯ
  // =========================================================================

  void _navigateToFamily(
    BuildContext context,
    String personId,
    String personName,
  ) {
    final personBloc = context.read<PersonBloc>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: personBloc),
            BlocProvider<FamilyBloc>(create: (context) => getIt<FamilyBloc>()),
          ],
          child: FamilyScreen(personId: personId, personName: personName),
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
          child: TreeScreen(rootPersonId: personId, treeId: widget.treeId),
        ),
      ),
    );
  }

  // =========================================================================
  // ДИАЛОГИ
  // =========================================================================

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Поиск людей'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Введите имя или фамилию...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (query) {
            if (query.isNotEmpty) {
              _personBloc.add(SearchPersonsEvent(query, treeId: widget.treeId));
              Navigator.pop(dialogContext);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  void _showAddPersonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => PersonFormDialog(
        treeId: widget.treeId,
        onSave: (person) {
          _personBloc.add(AddPersonEvent(person, treeId: widget.treeId));
        },
      ),
    );
  }

  void _showEditPersonDialog(BuildContext context, Person person) {
    showDialog(
      context: context,
      builder: (dialogContext) => PersonFormDialog(
        existingPerson: person,
        treeId: widget.treeId,
        onSave: (updatedPerson) {
          _personBloc.add(UpdatePersonEvent(updatedPerson));
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String personId, String name) {
    final personBloc = context.read<PersonBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удаление человека'),
        content: Text('Вы уверены, что хотите удалить "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              personBloc.add(DeletePersonEvent(personId));
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
