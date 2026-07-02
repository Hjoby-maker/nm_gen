import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/use_cases/family/get_family_with_details.dart';
import 'package:nm_gen/presentation/blocs/family/family_bloc.dart';
import 'package:nm_gen/presentation/blocs/family/family_event.dart';
import 'package:nm_gen/presentation/blocs/family/family_state.dart';
import 'package:nm_gen/presentation/blocs/person/person_bloc.dart';
import 'package:nm_gen/presentation/blocs/person/person_event.dart';
import 'package:nm_gen/presentation/blocs/person/person_state.dart';
import 'package:nm_gen/presentation/widgets/add_child_dialog.dart';
import 'package:nm_gen/presentation/widgets/family_card.dart';
import 'package:nm_gen/presentation/widgets/family_details_view.dart';
import 'package:nm_gen/presentation/widgets/family_form_dialog.dart';
import 'package:nm_gen/core/enums/gender.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({
    Key? key,
    required this.personId,
    required this.personName,
  }) : super(key: key);
  final String personId;
  final String personName;

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  String? _treeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Получаем treeId из состояния PersonBloc
      final personState = context.read<PersonBloc>().state;
      if (personState is PersonsLoaded) {
        _treeId = personState.treeId;
      }

      context.read<FamilyBloc>().add(
        LoadFamiliesEvent(widget.personId, treeId: _treeId),
      );
      final PersonState personState2 = context.read<PersonBloc>().state;
      if (personState2 is! PersonsLoaded) {
        context.read<PersonBloc>().add(const LoadPersonsEvent());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Семья ${widget.personName}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddFamilyDialog(context),
            tooltip: 'Добавить семью',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<FamilyBloc>().add(
                LoadFamiliesEvent(widget.personId, treeId: _treeId),
              );
            },
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: BlocConsumer<FamilyBloc, FamilyState>(
        listener: (BuildContext context, FamilyState state) {
          if (state is FamilyOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            context.read<FamilyBloc>().add(
              LoadFamiliesEvent(widget.personId, treeId: _treeId),
            );
          } else if (state is FamilyError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (BuildContext context, FamilyState state) {
          if (state is FamilyLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
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
                children: <Widget>[
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<FamilyBloc>().add(
                        LoadFamiliesEvent(widget.personId, treeId: _treeId),
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
                  children: <Widget>[
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
                    Text(
                      '${widget.personName} не состоит в семьях',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
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

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.families.length,
              itemBuilder: (BuildContext context, int index) {
                final Family family = state.families[index];
                final Person? husband = state.persons[family.husbandId];
                final Person? wife = state.persons[family.wifeId];
                final List<Person> children = family.childrenIds
                    .map((String id) => state.persons[id])
                    .whereType<Person>()
                    .toList();

                return FamilyCard(
                  family: family,
                  husband: husband,
                  wife: wife,
                  children: children,
                  onTap: () => _showFamilyDetails(context, family.id),
                  onEdit: () => _showEditFamilyDialog(context, family),
                  onDelete: () => _confirmDeleteFamily(context, family.id),
                  onDeleteChild: (String childId) {
                    final Person child = children.firstWhere(
                      (Person c) => c.id == childId,
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
                context.read<FamilyBloc>().add(
                  LoadFamiliesEvent(widget.personId, treeId: _treeId),
                );
              },
              treeId: _treeId,
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFamilyDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // =========================================================================
  // ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
  // =========================================================================

  // =========================================================================
  // ДИАЛОГИ
  // =========================================================================

  /// Диалог добавления новой семьи
  void _showAddFamilyDialog(BuildContext context) {
    final PersonState personState = context.read<PersonBloc>().state;

    if (personState is! PersonsLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Загрузка списка людей...'),
          backgroundColor: Colors.orange,
        ),
      );
      context.read<PersonBloc>().add(const LoadPersonsEvent());
      return;
    }

    final FamilyBloc familyBloc = context.read<FamilyBloc>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => FamilyFormDialog(
        availablePersons: personState.persons,
        treeId: _treeId,
        onSave: (Family family) {
          familyBloc.add(AddFamilyEvent(family, treeId: _treeId));
        },
      ),
    );
  }

  /// Диалог редактирования семьи
  void _showEditFamilyDialog(BuildContext context, Family family) {
    final PersonState personState = context.read<PersonBloc>().state;

    if (personState is! PersonsLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Загрузка списка людей...'),
          backgroundColor: Colors.orange,
        ),
      );
      context.read<PersonBloc>().add(const LoadPersonsEvent());
      return;
    }

    final FamilyBloc familyBloc = context.read<FamilyBloc>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => FamilyFormDialog(
        existingFamily: family,
        availablePersons: personState.persons,
        treeId: _treeId,
        onSave: (Family updatedFamily) {
          familyBloc.add(UpdateFamilyEvent(updatedFamily, treeId: _treeId));
        },
      ),
    );
  }

  /// Показать детали семьи
  void _showFamilyDetails(BuildContext context, String familyId) {
    context.read<FamilyBloc>().add(
      LoadFamilyDetailsEvent(familyId, treeId: _treeId),
    );
  }

  /// Диалог добавления ребенка в семью
  void _showAddChildDialog(BuildContext context, String familyId) {
    final PersonState personState = context.read<PersonBloc>().state;

    if (personState is! PersonsLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Загрузка списка людей...'),
          backgroundColor: Colors.orange,
        ),
      );
      context.read<PersonBloc>().add(const LoadPersonsEvent());
      return;
    }

    final FamilyState familyState = context.read<FamilyBloc>().state;
    List<String> existingChildIds = <String>[];
    List<String> parentIds = <String>[];

    if (familyState is FamiliesLoaded) {
      final Family family = familyState.families.firstWhere(
        (Family f) => f.id == familyId,
        orElse: () => Family.empty(),
      );
      existingChildIds = family.childrenIds;
      parentIds = <String>[
        if (family.husbandId != null) family.husbandId!,
        if (family.wifeId != null) family.wifeId!,
      ];
    }

    final List<Person> availableChildren = personState.persons
        .where((Person person) => person.id != widget.personId)
        .where((Person person) => !parentIds.contains(person.id))
        .where((Person person) => !existingChildIds.contains(person.id))
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

    final FamilyBloc familyBloc = context.read<FamilyBloc>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AddChildDialog(
        availableChildren: availableChildren,
        onAddChild: (String childId) {
          familyBloc.add(
            AddChildToFamilyEvent(familyId, childId, treeId: _treeId),
          );
        },
      ),
    );
  }

  /// Подтверждение удаления семьи
  void _confirmDeleteFamily(BuildContext context, String familyId) {
    final FamilyBloc familyBloc = context.read<FamilyBloc>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Удаление семьи'),
        content: const Text('Вы уверены, что хотите удалить эту семью?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              familyBloc.add(DeleteFamilyEvent(familyId, treeId: _treeId));
              Navigator.pop(dialogContext);
              familyBloc.add(
                LoadFamiliesEvent(widget.personId, treeId: _treeId),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  /// Подтверждение удаления ребенка из семьи
  void _confirmRemoveChild(
    BuildContext context,
    String familyId,
    String childId,
    String childName,
  ) {
    final FamilyBloc familyBloc = context.read<FamilyBloc>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Удаление ребенка'),
        content: Text('Вы уверены, что хотите удалить "$childName" из семьи?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              familyBloc.add(
                RemoveChildFromFamilyEvent(familyId, childId, treeId: _treeId),
              );
              Navigator.pop(dialogContext);
              // Обновляем список
              familyBloc.add(
                LoadFamiliesEvent(widget.personId, treeId: _treeId),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // УТИЛИТЫ
  // =========================================================================

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
