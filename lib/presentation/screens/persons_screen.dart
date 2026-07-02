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
import 'package:nm_gen/presentation/widgets/person_avatar.dart';
import 'package:nm_gen/presentation/widgets/person_form_dialog.dart';

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
  void didUpdateWidget(covariant PersonsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ Если treeId изменился, перезагружаем данные
    if (oldWidget.treeId != widget.treeId) {
      _personBloc.add(LoadPersonsEvent(treeId: widget.treeId));
    }
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
                        return Dismissible(
                          key: Key(person.id),
                          direction: DismissDirection.horizontal,
                          // ✅ background — показывается при свайпе ВПРАВО (startToEnd)
                          background: _buildSwipeRightBackground(context),
                          // ✅ secondaryBackground — показывается при свайпе ВЛЕВО (endToStart)
                          secondaryBackground: _buildSwipeLeftBackground(
                            context,
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              // Свайп ВПРАВО → Удаление
                              return await _confirmDeleteDialog(
                                context,
                                person.id,
                                person.displayName,
                              );
                            } else if (direction ==
                                DismissDirection.endToStart) {
                              // Свайп ВЛЕВО → Показать действия (не удаляем)
                              _showSwipeLeftActions(context, person);
                              return false;
                            }
                            return false;
                          },
                          onDismissed: (direction) {
                            if (direction == DismissDirection.startToEnd) {
                              // Удаление уже обработано в confirmDismiss
                              // Показываем SnackBar
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Человек удален'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: PersonAvatar(person: person, radius: 25),
                              title: Text(person.displayName),
                              subtitle: Text(
                                '${person.formattedAge} · ${person.occupation ?? 'Без профессии'}',
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
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
  // ДЕЙСТВИЯ ПРИ СВАЙПЕ
  // =========================================================================

  /// Фон при свайпе ВЛЕВО (endToStart) — показывается справа
  /// ✅ Исправлено: теперь это secondaryBackground
  Widget _buildSwipeLeftBackground(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerRight,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.edit, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Icon(Icons.family_restroom, color: Colors.white, size: 28),
          SizedBox(width: 16),
          Text(
            'Редактировать / Семья',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Фон при свайпе ВПРАВО (startToEnd) — показывается слева
  /// ✅ Исправлено: теперь это background
  Widget _buildSwipeRightBackground(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      child: const Row(
        children: [
          Icon(Icons.delete_forever, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Text(
            'Удалить',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Показать диалог с выбором действия при свайпе влево
  void _showSwipeLeftActions(BuildContext context, Person person) {
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
                _showEditPersonDialog(context, person);
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
                _navigateToFamily(context, person.id, person.displayName);
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
                _navigateToTreeWithPerson(context, person.id);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Диалог подтверждения удаления
  Future<bool> _confirmDeleteDialog(
    BuildContext context,
    String personId,
    String name,
  ) async {
    final result = await showDialog<bool>(
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
            onPressed: () {
              _personBloc.add(DeletePersonEvent(personId));
              Navigator.pop(dialogContext, true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    return result ?? false;
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
