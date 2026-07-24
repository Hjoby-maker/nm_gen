// lib/presentation/screens/persons_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/di/injector.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/presentation/blocs/family/family_bloc.dart';
import 'package:nm_gen/presentation/blocs/media/media_bloc.dart';
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
  const PersonsScreen({super.key, required this.treeId});
  final String treeId;

  @override
  State<PersonsScreen> createState() => _PersonsScreenState();
}

class _PersonsScreenState extends State<PersonsScreen> {
  late final PersonBloc _personBloc;
  late final MediaBloc _mediaBloc;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    try {
      _personBloc = getIt<PersonBloc>();
      _mediaBloc = getIt<MediaBloc>();
    } catch (e) {
      debugPrint('❌ PersonsScreen: Ошибка получения BLoC: $e');
      debugPrint('❌ StackTrace: ${StackTrace.current}');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isInitialized) {
        _isInitialized = true;
        try {
          _personBloc.add(LoadPersonsEvent(treeId: widget.treeId));
        } catch (e) {
          debugPrint('❌ PersonsScreen: Ошибка отправки LoadPersonsEvent: $e');
        }
      } else {
        debugPrint(
          '⚠️ PersonsScreen: Пропускаем загрузку (mounted=$mounted, _isInitialized=$_isInitialized)',
        );
      }
    });
  }

  @override
  void didUpdateWidget(covariant PersonsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.treeId != widget.treeId) {
      try {
        _personBloc.add(LoadPersonsEvent(treeId: widget.treeId));
      } catch (e) {
        debugPrint(
          '❌ PersonsScreen: Ошибка отправки LoadPersonsEvent при смене treeId: $e',
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _personBloc),
          BlocProvider.value(value: _mediaBloc),
        ],
        child: _buildScaffold(context),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ PersonsScreen: Критическая ошибка в build: $e');
      debugPrint('❌ StackTrace: $stackTrace');
      return Scaffold(
        appBar: AppBar(title: const Text('Ошибка')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  debugPrint(
                    '🔄 PersonsScreen: Перезагрузка после ошибки build',
                  );
                  setState(() {});
                },
                child: const Text('Попробовать снова'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
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
              debugPrint('🔄 PersonsScreen: Ручное обновление');
              try {
                _personBloc.add(LoadPersonsEvent(treeId: widget.treeId));
                debugPrint('✅ PersonsScreen: Ручное обновление отправлено');
              } catch (e) {
                debugPrint('❌ PersonsScreen: Ошибка ручного обновления: $e');
              }
            },
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => _showDebugInfo(context),
            tooltip: 'Отладка',
          ),
        ],
      ),
      body: _buildBody(context),
      floatingActionButton: FloatingActionButton(
        // heroTag: null отключает Hero-обёртку для этого FAB - иначе он
        // сталкивается тегами с FAB на других экранах, которые остаются
        // смонтированными (просто невидимыми) в стеке Navigator, когда
        // поверх открывается любой другой route (в т.ч. диалог).
        heroTag: null,
        onPressed: () => _showAddPersonDialog(context),
        child: const Icon(Icons.person_add),
        tooltip: 'Добавить человека',
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    debugPrint('🔍 PersonsScreen: _buildBody вызван');
    return BlocConsumer<PersonBloc, PersonState>(
      listener: (context, state) {
        debugPrint(
          '📊 PersonsScreen: Состояние изменилось: ${state.runtimeType}',
        );
        debugPrint('📊 PersonsScreen: Состояние детали: $state');

        if (state is PersonOperationSuccess) {
          debugPrint('✅ PersonsScreen: Операция успешна: ${state.message}');
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            debugPrint('❌ PersonsScreen: Ошибка показа SnackBar: $e');
          }
        } else if (state is PersonError) {
          debugPrint('❌❌❌ PersonsScreen: ОШИБКА: ${state.message}');
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message + 'QWERTY4'),
                backgroundColor: Colors.red,
              ),
            );
          } catch (e) {
            debugPrint('❌ PersonsScreen: Ошибка показа SnackBar ошибки: $e');
          }
        }
      },
      builder: (context, state) {
        debugPrint(
          '🎨 PersonsScreen: Builder вызван, состояние: ${state.runtimeType}',
        );

        try {
          if (state is PersonLoading) {
            debugPrint('⏳ PersonsScreen: Показываем загрузку');
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
            debugPrint('❌ PersonsScreen: Показываем ошибку: ${state.message}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    'TreeId: ${widget.treeId}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      debugPrint(
                        '🔄 PersonsScreen: Повторная загрузка после ошибки',
                      );
                      try {
                        _personBloc.add(
                          LoadPersonsEvent(treeId: widget.treeId),
                        );
                      } catch (e) {
                        debugPrint(
                          '❌ PersonsScreen: Ошибка повторной загрузки: $e',
                        );
                      }
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          if (state is PersonsLoaded) {
            if (state.persons.isEmpty) {
              debugPrint('📋 PersonsScreen: Список персон ПУСТ');
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
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'TreeId: ${widget.treeId}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    if (state.isSearching)
                      ElevatedButton(
                        onPressed: () {
                          debugPrint('🔄 PersonsScreen: Очистка поиска');
                          try {
                            _personBloc.add(const ClearSearchEvent());
                          } catch (e) {
                            debugPrint(
                              '❌ PersonsScreen: Ошибка очистки поиска: $e',
                            );
                          }
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
                            debugPrint(
                              '🔄 PersonsScreen: Очистка поиска через кнопку',
                            );
                            try {
                              _personBloc.add(const ClearSearchEvent());
                            } catch (e) {
                              debugPrint(
                                '❌ PersonsScreen: Ошибка очистки поиска: $e',
                              );
                            }
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
                      debugPrint(
                        '👤 PersonsScreen: Отображение персоны #$index: ${person.displayName}',
                      );
                      return Dismissible(
                        key: Key(person.id),
                        direction: DismissDirection.horizontal,
                        background: _buildSwipeRightBackground(context),
                        secondaryBackground: _buildSwipeLeftBackground(context),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            return await _confirmDeleteDialog(
                              context,
                              person.id,
                              person.displayName,
                            );
                          } else if (direction == DismissDirection.endToStart) {
                            _showSwipeLeftActions(context, person);
                            return false;
                          }
                          return false;
                        },
                        onDismissed: (direction) {
                          if (direction == DismissDirection.startToEnd) {
                            try {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Человек удален'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              debugPrint(
                                '❌ PersonsScreen: Ошибка показа SnackBar удаления: $e',
                              );
                            }
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
                            onTap: () async {
                              debugPrint(
                                '👤 PersonsScreen: Переход к персоне ${person.displayName} (${person.id})',
                              );
                              try {
                                // ⚠️ PersonDetailScreen создаёт свой собственный
                                // экземпляр PersonBloc через getIt<PersonBloc>(),
                                // отдельный от _personBloc этого экрана - поэтому
                                // изменения (аватар, редактирование полей) не
                                // прилетают сюда сами по себе через общий bloc.
                                // Простое и надёжное решение - перезагрузить
                                // список при возврате, вне зависимости от того,
                                // как именно зарегистрирован PersonBloc в DI.
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PersonDetailScreen(personId: person.id),
                                  ),
                                );
                                if (mounted) {
                                  debugPrint(
                                    '🔄 PersonsScreen: Обновление списка после возврата с экрана деталей',
                                  );
                                  _personBloc.add(
                                    LoadPersonsEvent(treeId: widget.treeId),
                                  );
                                }
                              } catch (e) {
                                debugPrint(
                                  '❌ PersonsScreen: Ошибка навигации: $e',
                                );
                              }
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

          debugPrint(
            '⚠️⚠️⚠️ PersonsScreen: НЕИЗВЕСТНОЕ СОСТОЯНИЕ: ${state.runtimeType}',
          );
          debugPrint('⚠️ PersonsScreen: Состояние: $state');
          return const SizedBox.shrink();
        } catch (e, stackTrace) {
          debugPrint('❌❌❌ PersonsScreen: КРИТИЧЕСКАЯ ОШИБКА В BUILDER: $e');
          debugPrint('❌ StackTrace: $stackTrace');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Ошибка: $e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    debugPrint(
                      '🔄 PersonsScreen: Перезагрузка после критической ошибки',
                    );
                    try {
                      _personBloc.add(LoadPersonsEvent(treeId: widget.treeId));
                    } catch (e) {
                      debugPrint('❌ PersonsScreen: Ошибка перезагрузки: $e');
                    }
                  },
                  child: const Text('Перезагрузить'),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  // =========================================================================
  // ОТЛАДОЧНАЯ ИНФОРМАЦИЯ
  // =========================================================================

  void _showDebugInfo(BuildContext context) {
    final state = _personBloc.state;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отладочная информация'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDebugRow('TreeId', widget.treeId),
              _buildDebugRow('Состояние', state.runtimeType.toString()),
              if (state is PersonsLoaded) ...[
                _buildDebugRow(
                  'Количество персон',
                  state.persons.length.toString(),
                ),
                _buildDebugRow('Поиск', state.isSearching ? 'Да' : 'Нет'),
                _buildDebugRow('Запрос', state.searchQuery ?? 'нет'),
                _buildDebugRow('TreeId из состояния', state.treeId ?? 'нет'),
              ],
              if (state is PersonError) ...[
                _buildDebugRow('Ошибка', state.message),
              ],
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
                'isInitialized: $_isInitialized',
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
              debugPrint(
                '🔄 PersonsScreen: Принудительная перезагрузка из отладки',
              );
              try {
                _personBloc.add(LoadPersonsEvent(treeId: widget.treeId));
              } catch (e) {
                debugPrint(
                  '❌ PersonsScreen: Ошибка принудительной перезагрузки: $e',
                );
              }
            },
            child: const Text('Перезагрузить'),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugRow(String label, String value) {
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

  // =========================================================================
  // ДЕЙСТВИЯ ПРИ СВАЙПЕ
  // =========================================================================

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

  void _showSwipeLeftActions(BuildContext context, Person person) {
    debugPrint(
      '🔍 PersonsScreen: _showSwipeLeftActions для ${person.displayName}',
    );
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

  Future<bool> _confirmDeleteDialog(
    BuildContext context,
    String personId,
    String name,
  ) async {
    debugPrint('🔍 PersonsScreen: _confirmDeleteDialog для $name');
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
              debugPrint('🗑️ PersonsScreen: Удаление человека $name');
              try {
                _personBloc.add(DeletePersonEvent(personId));
              } catch (e) {
                debugPrint('❌ PersonsScreen: Ошибка удаления: $e');
              }
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
    debugPrint('🔍 PersonsScreen: _navigateToFamily для $personName');
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
    debugPrint('🔍 PersonsScreen: _navigateToTreeWithPerson для $personId');
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
    debugPrint('🔍 PersonsScreen: _showSearchDialog вызван');
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
              debugPrint('🔍 PersonsScreen: Поиск по запросу "$query"');
              try {
                _personBloc.add(
                  SearchPersonsEvent(query, treeId: widget.treeId),
                );
              } catch (e) {
                debugPrint('❌ PersonsScreen: Ошибка поиска: $e');
              }
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
    debugPrint('➕ PersonsScreen: Открытие диалога добавления человека');
    showDialog(
      context: context,
      builder: (dialogContext) => PersonFormDialog(
        treeId: widget.treeId,
        onSave: (person) {
          debugPrint('✅ PersonsScreen: Добавлен человек ${person.displayName}');
          try {
            _personBloc.add(AddPersonEvent(person, treeId: widget.treeId));
          } catch (e) {
            debugPrint('❌ PersonsScreen: Ошибка добавления: $e');
          }
        },
      ),
    );
  }

  void _showEditPersonDialog(BuildContext context, Person person) {
    debugPrint(
      '✏️ PersonsScreen: Открытие диалога редактирования ${person.displayName}',
    );
    showDialog(
      context: context,
      builder: (dialogContext) => PersonFormDialog(
        existingPerson: person,
        treeId: widget.treeId,
        onSave: (updatedPerson) {
          debugPrint(
            '✅ PersonsScreen: Обновлен человек ${updatedPerson.displayName}',
          );
          try {
            _personBloc.add(UpdatePersonEvent(updatedPerson));
          } catch (e) {
            debugPrint('❌ PersonsScreen: Ошибка обновления: $e');
          }
        },
      ),
    );
  }
}
