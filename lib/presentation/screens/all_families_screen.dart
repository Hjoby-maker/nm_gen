import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/di/injector.dart';
import 'package:nm_gen/presentation/blocs/family/family_bloc.dart';
import 'package:nm_gen/presentation/blocs/family/family_event.dart';
import 'package:nm_gen/presentation/blocs/family/family_state.dart';
import 'package:nm_gen/presentation/blocs/person/person_bloc.dart';
import 'package:nm_gen/presentation/widgets/family_card.dart';
import 'package:nm_gen/presentation/widgets/family_details_view.dart';
import 'package:nm_gen/presentation/widgets/family_form_dialog.dart';
import 'package:nm_gen/domain/use_cases/family/get_family_with_details.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/presentation/blocs/person/person_state.dart';
import 'package:nm_gen/presentation/blocs/person/person_event.dart';
import 'package:nm_gen/presentation/widgets/add_child_dialog.dart';

class AllFamiliesScreen extends StatefulWidget {
  final String treeId;

  const AllFamiliesScreen({super.key, required this.treeId});

  @override
  State<AllFamiliesScreen> createState() => _AllFamiliesScreenState();
}

class _AllFamiliesScreenState extends State<AllFamiliesScreen> {
  late final FamilyBloc _familyBloc;
  late final PersonBloc _personBloc;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _familyBloc = getIt<FamilyBloc>();
    _personBloc = getIt<PersonBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isInitialized) {
        _isInitialized = true;
        _familyBloc.add(LoadAllFamiliesEvent(treeId: widget.treeId));
        _personBloc.add(LoadPersonsEvent(treeId: widget.treeId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _familyBloc),
        BlocProvider.value(value: _personBloc),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Семьи'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddFamilyDialog(context),
              tooltip: 'Добавить семью',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _familyBloc.add(LoadAllFamiliesEvent(treeId: widget.treeId));
                _personBloc.add(LoadPersonsEvent(treeId: widget.treeId));
              },
              tooltip: 'Обновить',
            ),
          ],
        ),
        body: BlocConsumer<FamilyBloc, FamilyState>(
          listener: (context, state) {
            if (state is FamilyOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
              _familyBloc.add(LoadAllFamiliesEvent(treeId: widget.treeId));
              _personBloc.add(LoadPersonsEvent(treeId: widget.treeId));
            } else if (state is FamilyError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is FamilyLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Загрузка семей...'),
                  ],
                ),
              );
            }

            if (state is FamilyError) {
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
                        _familyBloc.add(
                          LoadAllFamiliesEvent(treeId: widget.treeId),
                        );
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

            if (state is FamiliesLoaded) {
              if (state.families.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.family_restroom,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Нет семей',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Создайте первую семью',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showAddFamilyDialog(context),
                        child: const Text('Создать семью'),
                      ),
                    ],
                  ),
                );
              }

              // Сортируем семьи по дате брака (новые сверху)
              final sortedFamilies = List<Family>.from(state.families)
                ..sort((a, b) {
                  if (a.marriageDate == null && b.marriageDate == null)
                    return 0;
                  if (a.marriageDate == null) return 1;
                  if (b.marriageDate == null) return -1;
                  return b.marriageDate!.compareTo(a.marriageDate!);
                });

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: sortedFamilies.length,
                itemBuilder: (context, index) {
                  final Family family = sortedFamilies[index];
                  final Person? husband = state.persons[family.husbandId];
                  final Person? wife = state.persons[family.wifeId];
                  final List<Person> children = family.childrenIds
                      .map((id) => state.persons[id])
                      .whereType<Person>()
                      .toList();

                  return Dismissible(
                    key: Key(family.id),
                    direction: DismissDirection.horizontal,
                    // Свайп ВПРАВО → Удаление (красный фон)
                    background: _buildSwipeRightBackground(context),
                    // Свайп ВЛЕВО → Редактирование (синий фон)
                    secondaryBackground: _buildSwipeLeftBackground(context),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        // Свайп ВПРАВО → Удаление
                        return await _confirmDeleteFamilyDialog(
                          context,
                          family.id,
                        );
                      } else if (direction == DismissDirection.endToStart) {
                        // Свайп ВЛЕВО → Показать действия (не удаляем)
                        _showSwipeLeftActions(context, family);
                        return false;
                      }
                      return false;
                    },
                    onDismissed: (direction) {
                      if (direction == DismissDirection.startToEnd) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Семья удалена'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    child: FamilyCard(
                      family: family,
                      husband: husband,
                      wife: wife,
                      children: children,
                      onTap: () => _showFamilyDetails(context, family.id),
                      // Убираем кнопки, так как теперь есть свайпы
                      onEdit: null,
                      onDelete: null,
                      onDeleteChild: (childId) {
                        final child = children.firstWhere(
                          (c) => c.id == childId,
                          orElse: () => Person.empty(),
                        );
                        if (child.id.isNotEmpty) {
                          _confirmRemoveChild(
                            context,
                            family.id,
                            childId,
                            child.displayName,
                          );
                        }
                      },
                      onAddChild: () => _showAddChildDialog(context, family.id),
                    ),
                  );
                },
              );
            }

            if (state is FamilyDetailsLoaded) {
              return FamilyDetailsView(
                details: state.details,
                onEdit: () =>
                    _showEditFamilyDialog(context, state.details.family),
                onDelete: () =>
                    _confirmDeleteFamily(context, state.details.family.id),
                onAddChild: () =>
                    _showAddChildDialog(context, state.details.family.id),
                onDeleteChild: (childId) {
                  final child = state.details.children.firstWhere(
                    (c) => c.id == childId,
                    orElse: () => Person.empty(),
                  );
                  if (child.id.isNotEmpty) {
                    _confirmRemoveChild(
                      context,
                      state.details.family.id,
                      childId,
                      child.displayName,
                    );
                  }
                },
                onBack: () {
                  _familyBloc.add(LoadAllFamiliesEvent(treeId: widget.treeId));
                },
                treeId: widget.treeId,
              );
            }

            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddFamilyDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // =========================================================================
  // ДЕЙСТВИЯ ПРИ СВАЙПЕ
  // =========================================================================

  /// Фон при свайпе ВЛЕВО (endToStart) — показывается справа
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
            'Редактировать / Дети',
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
  void _showSwipeLeftActions(BuildContext context, Family family) {
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
              title: const Text('Редактировать семью'),
              subtitle: Text('Изменить данные семьи'),
              onTap: () {
                Navigator.pop(context);
                _showEditFamilyDialog(context, family);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.person_add, color: Colors.white),
              ),
              title: const Text('Добавить ребенка'),
              subtitle: Text('Добавить ребенка в семью'),
              onTap: () {
                Navigator.pop(context);
                _showAddChildDialog(context, family.id);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.purple,
                child: Icon(Icons.visibility, color: Colors.white),
              ),
              title: const Text('Показать детали'),
              subtitle: Text('Полная информация о семье'),
              onTap: () {
                Navigator.pop(context);
                _showFamilyDetails(context, family.id);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Диалог подтверждения удаления семьи
  Future<bool> _confirmDeleteFamilyDialog(
    BuildContext context,
    String familyId,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удаление семьи'),
        content: const Text('Вы уверены, что хотите удалить эту семью?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              _familyBloc.add(
                DeleteFamilyEvent(familyId, treeId: widget.treeId),
              );
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
  // ДИАЛОГИ
  // =========================================================================

  Future<void> _ensurePersonsLoaded(BuildContext context) async {
    final state = _personBloc.state;
    if (state is! PersonsLoaded) {
      final completer = Completer<void>();

      final subscription = _personBloc.stream.listen((newState) {
        if (newState is PersonsLoaded) {
          if (!completer.isCompleted) {
            completer.complete();
          }
        } else if (newState is PersonError) {
          if (!completer.isCompleted) {
            completer.completeError(newState.message);
          }
        }
      });

      _personBloc.add(LoadPersonsEvent(treeId: widget.treeId));

      try {
        await completer.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            if (!completer.isCompleted) {
              completer.completeError('Timeout загрузки данных');
            }
          },
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки списка людей: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      } finally {
        await subscription.cancel();
      }
    }
  }

  void _showAddFamilyDialog(BuildContext context) {
    final state = _personBloc.state;

    if (state is! PersonsLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Загрузка списка людей...'),
          backgroundColor: Colors.orange,
        ),
      );
      _ensurePersonsLoaded(context).then((_) {
        if (mounted) {
          final newState = _personBloc.state;
          if (newState is PersonsLoaded) {
            _showAddFamilyDialogWithData(context, newState.persons);
          }
        }
      });
      return;
    }

    _showAddFamilyDialogWithData(context, state.persons);
  }

  void _showAddFamilyDialogWithData(
    BuildContext context,
    List<Person> persons,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => FamilyFormDialog(
        availablePersons: persons,
        treeId: widget.treeId,
        onSave: (family) {
          _familyBloc.add(AddFamilyEvent(family, treeId: widget.treeId));
        },
      ),
    );
  }

  void _showEditFamilyDialog(BuildContext context, Family family) {
    final state = _personBloc.state;

    if (state is! PersonsLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Загрузка списка людей...'),
          backgroundColor: Colors.orange,
        ),
      );
      _ensurePersonsLoaded(context).then((_) {
        if (mounted) {
          final newState = _personBloc.state;
          if (newState is PersonsLoaded) {
            _showEditFamilyDialogWithData(context, family, newState.persons);
          }
        }
      });
      return;
    }

    _showEditFamilyDialogWithData(context, family, state.persons);
  }

  void _showEditFamilyDialogWithData(
    BuildContext context,
    Family family,
    List<Person> persons,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => FamilyFormDialog(
        existingFamily: family,
        availablePersons: persons,
        treeId: widget.treeId,
        onSave: (updatedFamily) {
          _familyBloc.add(
            UpdateFamilyEvent(updatedFamily, treeId: widget.treeId),
          );
        },
      ),
    );
  }

  void _showFamilyDetails(BuildContext context, String familyId) {
    _familyBloc.add(LoadFamilyDetailsEvent(familyId, treeId: widget.treeId));
  }

  void _showAddChildDialog(BuildContext context, String familyId) {
    final personState = _personBloc.state;

    if (personState is! PersonsLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Загрузка списка людей...'),
          backgroundColor: Colors.orange,
        ),
      );
      _ensurePersonsLoaded(context).then((_) {
        if (mounted) {
          final newState = _personBloc.state;
          if (newState is PersonsLoaded) {
            _showAddChildDialogWithData(context, familyId, newState.persons);
          }
        }
      });
      return;
    }

    _showAddChildDialogWithData(context, familyId, personState.persons);
  }

  void _showAddChildDialogWithData(
    BuildContext context,
    String familyId,
    List<Person> persons,
  ) {
    final familyState = _familyBloc.state;
    List<String> existingChildIds = [];
    List<String> parentIds = [];

    if (familyState is FamiliesLoaded) {
      final family = familyState.families.firstWhere(
        (f) => f.id == familyId,
        orElse: () => Family.empty(),
      );
      existingChildIds = family.childrenIds;
      parentIds = [
        if (family.husbandId != null) family.husbandId!,
        if (family.wifeId != null) family.wifeId!,
      ];
    }

    final availableChildren = persons
        .where((person) => !parentIds.contains(person.id))
        .where((person) => !existingChildIds.contains(person.id))
        .toList();

    if (availableChildren.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет доступных людей для добавления в семью'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AddChildDialog(
        availableChildren: availableChildren,
        onAddChild: (childId) {
          _familyBloc.add(
            AddChildToFamilyEvent(familyId, childId, treeId: widget.treeId),
          );
        },
      ),
    );
  }

  void _confirmDeleteFamily(BuildContext context, String familyId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удаление семьи'),
        content: const Text('Вы уверены, что хотите удалить эту семью?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              _familyBloc.add(
                DeleteFamilyEvent(familyId, treeId: widget.treeId),
              );
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveChild(
    BuildContext context,
    String familyId,
    String childId,
    String childName,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удаление ребенка'),
        content: Text('Вы уверены, что хотите удалить "$childName" из семьи?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              _familyBloc.add(
                RemoveChildFromFamilyEvent(
                  familyId,
                  childId,
                  treeId: widget.treeId,
                ),
              );
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
