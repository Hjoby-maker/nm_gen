import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/presentation/blocs/family/family_bloc.dart';
import 'package:nm_gen/presentation/blocs/family/family_event.dart';
import 'package:nm_gen/presentation/blocs/family/family_state.dart';
import 'package:nm_gen/presentation/blocs/person/person_bloc.dart';
import 'package:nm_gen/presentation/blocs/person/person_event.dart';
import 'package:nm_gen/presentation/blocs/person/person_state.dart';
import 'package:nm_gen/presentation/screens/family_screen.dart';
import 'package:nm_gen/presentation/widgets/add_child_dialog.dart';
import 'package:nm_gen/presentation/widgets/family_form_dialog.dart';

class PersonDetailScreen extends StatefulWidget {
  final String personId;

  const PersonDetailScreen({Key? key, required this.personId})
    : super(key: key);

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  Person? _person;
  List<Family> _familiesAsChild = [];
  List<Family> _familiesAsParent = [];
  Map<String, Person> _familyMembers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final personBloc = context.read<PersonBloc>();
    final familyBloc = context.read<FamilyBloc>();

    // Загружаем человека
    final personState = personBloc.state;
    if (personState is PersonsLoaded) {
      setState(() {
        _person = personState.persons.firstWhere(
          (p) => p.id == widget.personId,
          orElse: () => Person.empty(),
        );
      });
    } else {
      personBloc.add(const LoadPersonsEvent());
    }

    // Загружаем семьи
    familyBloc.add(LoadFamiliesEvent(widget.personId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_person?.displayName ?? 'Загрузка...'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditPersonDialog(context),
            tooltip: 'Редактировать',
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
            // Перезагружаем данные
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
          if (_person == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Информация о человеке
                _buildPersonInfo(),
                const SizedBox(height: 24),

                // Семьи где человек - ребенок
                _buildFamiliesSection(
                  'Семьи (как ребенок)',
                  _getFamiliesAsChild(state),
                  isChild: true,
                ),
                const SizedBox(height: 16),

                // Семьи где человек - родитель
                _buildFamiliesSection(
                  'Семьи (как родитель)',
                  _getFamiliesAsParent(state),
                  isChild: false,
                ),
                const SizedBox(height: 16),

                // Кнопки действий
                _buildActionButtons(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPersonInfo() {
    final person = _person!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: person.gender == Gender.male
                      ? Colors.blue.shade100
                      : Colors.pink.shade100,
                  child: Icon(
                    person.gender == Gender.male ? Icons.male : Icons.female,
                    size: 40,
                    color: person.gender == Gender.male
                        ? Colors.blue
                        : Colors.pink,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        person.formattedAge,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      if (person.occupation != null)
                        Text(
                          person.occupation!,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (person.birthDate != null)
              _buildInfoRow('Дата рождения', _formatDate(person.birthDate!)),
            if (person.deathDate != null)
              _buildInfoRow('Дата смерти', _formatDate(person.deathDate!)),
            if (person.birthPlace != null)
              _buildInfoRow('Место рождения', person.birthPlace!),
            if (person.biography != null)
              _buildInfoRow('Биография', person.biography!),
          ],
        ),
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
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildFamiliesSection(
    String title,
    List<Family> families, {
    required bool isChild,
  }) {
    if (families.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isChild ? 'Не состоит в семьях как ребенок' : 'Нет семей',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              if (!isChild)
                TextButton.icon(
                  onPressed: () => _showAddFamilyDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Создать семью'),
                ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${families.length}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...families.map((family) {
              return ListTile(
                title: Text(_getFamilyLabel(family, isChild)),
                subtitle: Text(
                  family.marriageDate != null
                      ? 'Брак: ${_formatDate(family.marriageDate!)}'
                      : 'Дата брака не указана',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FamilyScreen(
                        personId: widget.personId,
                        personName: _person?.displayName ?? '',
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Добавить брата/сестру
        ElevatedButton.icon(
          onPressed: () => _showAddSiblingDialog(context),
          icon: const Icon(Icons.group_add),
          label: const Text('Добавить брата/сестру'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
        ),
        // Добавить супруга
        ElevatedButton.icon(
          onPressed: () => _showAddSpouseDialog(context),
          icon: const Icon(Icons.favorite),
          label: const Text('Добавить супруга'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
        // Добавить ребенка
        ElevatedButton.icon(
          onPressed: () => _showAddChildAsParentDialog(context),
          icon: const Icon(Icons.child_care),
          label: const Text('Добавить ребенка'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // ЛОГИКА ПОЛУЧЕНИЯ СЕМЕЙ
  // =========================================================================

  List<Family> _getFamiliesAsChild(FamilyState state) {
    if (state is! FamiliesLoaded) return [];
    return state.families
        .where((family) => family.childrenIds.contains(widget.personId))
        .toList();
  }

  List<Family> _getFamiliesAsParent(FamilyState state) {
    if (state is! FamiliesLoaded) return [];
    return state.families
        .where(
          (family) =>
              family.husbandId == widget.personId ||
              family.wifeId == widget.personId,
        )
        .toList();
  }

  String _getFamilyLabel(Family family, bool isChild) {
    if (isChild) {
      final parents = <String>[];
      if (family.husbandId != null) parents.add('отец: ${family.husbandId}');
      if (family.wifeId != null) parents.add('мать: ${family.wifeId}');
      return parents.isNotEmpty ? parents.join(', ') : 'Семья';
    } else {
      final spouseId = family.husbandId == widget.personId
          ? family.wifeId
          : family.husbandId;
      return spouseId != null ? 'Супруг: $spouseId' : 'Семья';
    }
  }

  // =========================================================================
  // ДИАЛОГИ
  // =========================================================================

  void _showAddSiblingDialog(BuildContext context) {
    final personState = context.read<PersonBloc>().state;
    final familyState = context.read<FamilyBloc>().state;

    if (personState is! PersonsLoaded || familyState is! FamiliesLoaded) return;

    // Находим семьи, где человек является ребенком
    final parentFamilies = familyState.families
        .where((family) => family.childrenIds.contains(widget.personId))
        .toList();

    if (parentFamilies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сначала добавьте родителей в семью'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Если несколько семей - показываем выбор
    if (parentFamilies.length > 1) {
      _showSelectFamilyForSiblingDialog(context, parentFamilies);
    } else {
      _showAddSiblingToFamilyDialog(context, parentFamilies.first);
    }
  }

  void _showSelectFamilyForSiblingDialog(
    BuildContext context,
    List<Family> families,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите семью'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: families.map((family) {
            return ListTile(
              title: Text('Семья #${family.id.substring(0, 8)}'),
              subtitle: Text(
                'Родители: ${family.husbandId ?? '?'} и ${family.wifeId ?? '?'}',
              ),
              onTap: () {
                Navigator.pop(context);
                _showAddSiblingToFamilyDialog(context, family);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAddSiblingToFamilyDialog(BuildContext context, Family family) {
    final personState = context.read<PersonBloc>().state;
    if (personState is! PersonsLoaded) return;

    final availableSiblings = personState.persons
        .where((p) => p.id != widget.personId)
        .where((p) => p.id != family.husbandId)
        .where((p) => p.id != family.wifeId)
        .where((p) => !family.childrenIds.contains(p.id))
        .toList();

    if (availableSiblings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет доступных людей для добавления как брата/сестры'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить брата/сестру'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableSiblings.map((person) {
            return ListTile(
              leading: CircleAvatar(
                child: Text(person.displayName.substring(0, 1).toUpperCase()),
              ),
              title: Text(person.displayName),
              subtitle: Text(person.formattedAge),
              onTap: () {
                context.read<FamilyBloc>().add(
                  AddChildToFamilyEvent(family.id, person.id),
                );
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAddSpouseDialog(BuildContext context) {
    // Создаем новую семью с текущим человеком и выбранным супругом
    final personState = context.read<PersonBloc>().state;
    if (personState is! PersonsLoaded) return;

    // Показываем диалог выбора супруга
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить супруга'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Выберите супруга для создания семьи:'),
            const SizedBox(height: 8),
            ...personState.persons.where((p) => p.id != widget.personId).map((
              person,
            ) {
              return ListTile(
                leading: CircleAvatar(
                  child: Text(person.displayName.substring(0, 1).toUpperCase()),
                ),
                title: Text(person.displayName),
                subtitle: Text(person.formattedAge),
                onTap: () {
                  // Создаем семью
                  final family = Family(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    husbandId: _person?.gender == Gender.male
                        ? widget.personId
                        : person.id,
                    wifeId: _person?.gender == Gender.female
                        ? widget.personId
                        : person.id,
                    childrenIds: [],
                  );
                  context.read<FamilyBloc>().add(AddFamilyEvent(family));
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showAddChildAsParentDialog(BuildContext context) {
    // Создаем новую семью с текущим человеком как родителем
    final personState = context.read<PersonBloc>().state;
    if (personState is! PersonsLoaded) return;

    // Показываем диалог выбора второго родителя и ребенка
    // Для простоты сначала создаем семью, потом добавляем ребенка
    _showAddFamilyDialog(context);
  }

  void _showAddFamilyDialog(BuildContext context) {
    final personState = context.read<PersonBloc>().state;
    if (personState is! PersonsLoaded) return;

    final familyBloc = context.read<FamilyBloc>();

    showDialog(
      context: context,
      builder: (context) => FamilyFormDialog(
        availablePersons: personState.persons,
        onSave: (family) {
          familyBloc.add(AddFamilyEvent(family));
        },
      ),
    );
  }

  void _showEditPersonDialog(BuildContext context) {
    // TODO: Реализовать редактирование человека
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
