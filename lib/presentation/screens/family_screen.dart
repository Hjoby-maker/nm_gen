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
import 'package:nm_gen/presentation/widgets/family_form_dialog.dart';
import 'package:nm_gen/core/enums/gender.dart';

class FamilyScreen extends StatefulWidget {
  final String personId;
  final String personName;

  const FamilyScreen({
    Key? key,
    required this.personId,
    required this.personName,
  }) : super(key: key);

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FamilyBloc>().add(LoadFamiliesEvent(widget.personId));
      final personState = context.read<PersonBloc>().state;
      if (personState is! PersonsLoaded) {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddFamilyDialog(context),
            tooltip: 'Добавить семью',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<FamilyBloc>().add(
                LoadFamiliesEvent(widget.personId),
              );
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
            context.read<FamilyBloc>().add(LoadFamiliesEvent(widget.personId));
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
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<FamilyBloc>().add(
                        LoadFamiliesEvent(widget.personId),
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
              itemBuilder: (context, index) {
                final family = state.families[index];
                final husband = state.persons[family.husbandId];
                final wife = state.persons[family.wifeId];
                final children = family.childrenIds
                    .map((id) => state.persons[id])
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
                  // Добавляем кнопку "Добавить ребенка" в карточку
                  onAddChild: () => _showAddChildDialog(context, family.id),
                );
              },
            );
          }

          if (state is FamilyDetailsLoaded) {
            return _buildFamilyDetailsView(context, state.details);
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

  Widget _buildFamilyDetailsView(BuildContext context, FamilyDetails details) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Карточка с информацией о семье
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Информация о семье',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Муж',
                    details.husband?.displayName ?? 'Не указан',
                  ),
                  _buildInfoRow(
                    'Жена',
                    details.wife?.displayName ?? 'Не указана',
                  ),
                  if (details.family.marriageDate != null)
                    _buildInfoRow(
                      'Дата брака',
                      _formatDate(details.family.marriageDate!),
                    ),
                  if (details.family.divorceDate != null)
                    _buildInfoRow(
                      'Дата развода',
                      _formatDate(details.family.divorceDate!),
                    ),
                  if (details.family.marriagePlace != null)
                    _buildInfoRow('Место брака', details.family.marriagePlace!),
                  if (details.family.notes != null)
                    _buildInfoRow('Заметки', details.family.notes!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Карточка с детьми
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Дети',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.person_add),
                        onPressed: () =>
                            _showAddChildDialog(context, details.family.id),
                        tooltip: 'Добавить ребенка',
                      ),
                    ],
                  ),
                  if (details.children.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Нет детей',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...details.children.map((child) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: child.gender == Gender.male
                              ? Colors.blue.shade100
                              : Colors.pink.shade100,
                          child: Text(
                            child.displayName.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: child.gender == Gender.male
                                  ? Colors.blue.shade700
                                  : Colors.pink.shade700,
                            ),
                          ),
                        ),
                        title: Text(child.displayName),
                        subtitle: Text(child.formattedAge),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _confirmRemoveChild(
                            context,
                            details.family.id,
                            child.id,
                            child.displayName,
                          ),
                          tooltip: 'Удалить из семьи',
                        ),
                        onTap: () {
                          // TODO: Перейти к просмотру ребенка
                        },
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Кнопки действий
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _showEditFamilyDialog(context, details.family),
                  icon: const Icon(Icons.edit),
                  label: const Text('Редактировать'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _confirmDeleteFamily(context, details.family.id),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'Удалить',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Кнопка возврата к списку
          Center(
            child: TextButton(
              onPressed: () {
                context.read<FamilyBloc>().add(
                  LoadFamiliesEvent(widget.personId),
                );
              },
              child: const Text('← Вернуться к списку'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // =========================================================================
  // ДИАЛОГИ
  // =========================================================================

  /// Диалог добавления новой семьи
  void _showAddFamilyDialog(BuildContext context) {
    final personState = context.read<PersonBloc>().state;

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

    final familyBloc = context.read<FamilyBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => FamilyFormDialog(
        availablePersons: personState.persons,
        onSave: (family) {
          familyBloc.add(AddFamilyEvent(family));
        },
      ),
    );
  }

  /// Диалог редактирования семьи
  void _showEditFamilyDialog(BuildContext context, Family family) {
    final personState = context.read<PersonBloc>().state;

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

    final familyBloc = context.read<FamilyBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => FamilyFormDialog(
        existingFamily: family,
        availablePersons: personState.persons,
        onSave: (updatedFamily) {
          familyBloc.add(UpdateFamilyEvent(updatedFamily));
        },
      ),
    );
  }

  /// Показать детали семьи
  void _showFamilyDetails(BuildContext context, String familyId) {
    context.read<FamilyBloc>().add(LoadFamilyDetailsEvent(familyId));
  }

  /// Диалог добавления ребенка в семью
  void _showAddChildDialog(BuildContext context, String familyId) {
    final personState = context.read<PersonBloc>().state;

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

    final familyState = context.read<FamilyBloc>().state;
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

    final availableChildren = personState.persons
        .where((person) => person.id != widget.personId)
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

    final familyBloc = context.read<FamilyBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AddChildDialog(
        availableChildren: availableChildren,
        onAddChild: (childId) {
          familyBloc.add(AddChildToFamilyEvent(familyId, childId));
        },
      ),
    );
  }

  /// Подтверждение удаления семьи
  void _confirmDeleteFamily(BuildContext context, String familyId) {
    final familyBloc = context.read<FamilyBloc>();

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
              familyBloc.add(DeleteFamilyEvent(familyId));
              Navigator.pop(dialogContext);
              familyBloc.add(LoadFamiliesEvent(widget.personId));
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
    final familyBloc = context.read<FamilyBloc>();

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
              familyBloc.add(RemoveChildFromFamilyEvent(familyId, childId));
              Navigator.pop(dialogContext);
              // Обновляем список
              familyBloc.add(LoadFamiliesEvent(widget.personId));
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
