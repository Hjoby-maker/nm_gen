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
import 'package:nm_gen/presentation/widgets/family_form_dialog.dart';
import 'package:nm_gen/presentation/widgets/person_avatar.dart';
import 'package:nm_gen/presentation/widgets/person_form_dialog.dart';
import 'package:nm_gen/di/injector.dart';

class PersonDetailScreen extends StatefulWidget {
  const PersonDetailScreen({Key? key, required this.personId})
    : super(key: key);
  final String personId;

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  Person? _person;
  bool _isLoading = true;
  String? _treeId;

  // Получаем BLoC через getIt
  late final PersonBloc _personBloc;
  late final FamilyBloc _familyBloc;

  @override
  void initState() {
    super.initState();
    _personBloc = getIt<PersonBloc>();
    _familyBloc = getIt<FamilyBloc>();

    // Отложенная загрузка
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Получаем текущее состояние
    final personState = _personBloc.state;

    // Если данные еще не загружены или treeId не совпадает, загружаем
    if (personState is! PersonsLoaded || personState.treeId != _treeId) {
      _personBloc.add(LoadPersonsEvent(treeId: _treeId));
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Получаем обновленное состояние
    final updatedState = _personBloc.state;
    if (updatedState is PersonsLoaded) {
      setState(() {
        _person = updatedState.persons.firstWhere(
          (p) => p.id == widget.personId,
          orElse: () => Person.empty(),
        );
        _treeId = updatedState.treeId ?? 'default';
        _isLoading = false;
      });

      // Загружаем семьи
      _familyBloc.add(LoadFamiliesEvent(widget.personId, treeId: _treeId));
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_person?.displayName ?? 'Загрузка...'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: <Widget>[
          if (_person != null && _person!.id.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditPersonDialog(context),
              tooltip: 'Редактировать',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Загрузка данных...'),
                ],
              ),
            )
          : _person == null || _person!.id.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Человек не найден',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Назад'),
                  ),
                ],
              ),
            )
          : BlocProvider.value(
              value: _familyBloc,
              child: BlocConsumer<FamilyBloc, FamilyState>(
                listener: (BuildContext context, FamilyState state) {
                  if (state is FamilyOperationSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _familyBloc.add(
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
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _buildPersonInfo(),
                        const SizedBox(height: 24),
                        _buildFamiliesSection(
                          'Семьи (как ребенок)',
                          _getFamiliesAsChild(state),
                          isChild: true,
                        ),
                        const SizedBox(height: 16),
                        _buildFamiliesSection(
                          'Семьи (как родитель)',
                          _getFamiliesAsParent(state),
                          isChild: false,
                        ),
                        const SizedBox(height: 16),
                        _buildActionButtons(context),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildPersonInfo() {
    final Person person = _person!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                PersonAvatar(person: person, radius: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
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
        children: <Widget>[
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
            children: <Widget>[
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
          children: <Widget>[
            Row(
              children: <Widget>[
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
            ...families.map((Family family) {
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
                      builder: (BuildContext context) => FamilyScreen(
                        personId: widget.personId,
                        personName: _person?.displayName ?? '',
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        ElevatedButton.icon(
          onPressed: () => _showAddSiblingDialog(context),
          icon: const Icon(Icons.group_add),
          label: const Text('Добавить брата/сестру'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddSpouseDialog(context),
          icon: const Icon(Icons.favorite),
          label: const Text('Добавить супруга'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
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
    if (state is! FamiliesLoaded) return <Family>[];
    return state.families
        .where((Family family) => family.childrenIds.contains(widget.personId))
        .toList();
  }

  List<Family> _getFamiliesAsParent(FamilyState state) {
    if (state is! FamiliesLoaded) return <Family>[];
    return state.families
        .where(
          (Family family) =>
              family.husbandId == widget.personId ||
              family.wifeId == widget.personId,
        )
        .toList();
  }

  String _getFamilyLabel(Family family, bool isChild) {
    if (isChild) {
      final List<String> parents = <String>[];
      if (family.husbandId != null) parents.add('отец: ${family.husbandId}');
      if (family.wifeId != null) parents.add('мать: ${family.wifeId}');
      return parents.isNotEmpty ? parents.join(', ') : 'Семья';
    } else {
      final String? spouseId = family.husbandId == widget.personId
          ? family.wifeId
          : family.husbandId;
      return spouseId != null ? 'Супруг: $spouseId' : 'Семья';
    }
  }

  // =========================================================================
  // ДИАЛОГИ
  // =========================================================================

  /// Получить список персон текущего проекта
  List<Person> _getProjectPersons(PersonsLoaded state) {
    // Если treeId не задан, используем 'default'
    final treeId = _treeId ?? 'default';

    // Фильтруем персоны по treeId
    return state.persons.where((p) => p.treeId == treeId).toList();
  }

  void _showAddSiblingDialog(BuildContext context) {
    final PersonState personState = _personBloc.state;
    final FamilyState familyState = _familyBloc.state;

    if (personState is! PersonsLoaded || familyState is! FamiliesLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Данные еще загружаются...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Получаем персоны текущего проекта
    final projectPersons = _getProjectPersons(personState);

    if (projectPersons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('В этом проекте нет других людей'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Находим семьи, где человек является ребенком
    final List<Family> parentFamilies = familyState.families
        .where((Family family) => family.childrenIds.contains(widget.personId))
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

    if (parentFamilies.length > 1) {
      _showSelectFamilyForSiblingDialog(
        context,
        parentFamilies,
        projectPersons,
      );
    } else {
      _showAddSiblingToFamilyDialog(
        context,
        parentFamilies.first,
        projectPersons,
      );
    }
  }

  void _showSelectFamilyForSiblingDialog(
    BuildContext context,
    List<Family> families,
    List<Person> availablePersons,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Выберите семью'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: families.map((Family family) {
            return ListTile(
              title: Text('Семья #${family.id.substring(0, 8)}'),
              subtitle: Text(
                'Родители: ${family.husbandId ?? '?'} и ${family.wifeId ?? '?'}',
              ),
              onTap: () {
                Navigator.pop(context);
                _showAddSiblingToFamilyDialog(
                  context,
                  family,
                  availablePersons,
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAddSiblingToFamilyDialog(
    BuildContext context,
    Family family,
    List<Person> availablePersons,
  ) {
    final availableSiblings = availablePersons
        .where((Person p) => p.id != widget.personId)
        .where((Person p) => p.id != family.husbandId)
        .where((Person p) => p.id != family.wifeId)
        .where((Person p) => !family.childrenIds.contains(p.id))
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
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Добавить брата/сестру'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableSiblings.map((Person person) {
            return ListTile(
              leading: CircleAvatar(
                child: Text(person.displayName.substring(0, 1).toUpperCase()),
              ),
              title: Text(person.displayName),
              subtitle: Text(person.formattedAge),
              onTap: () {
                _familyBloc.add(
                  AddChildToFamilyEvent(family.id, person.id, treeId: _treeId),
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
    final PersonState personState = _personBloc.state;
    if (personState is! PersonsLoaded) return;

    // Получаем персоны текущего проекта
    final projectPersons = _getProjectPersons(personState);

    // Исключаем текущего человека
    final availablePersons = projectPersons
        .where((p) => p.id != widget.personId)
        .toList();

    if (availablePersons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет доступных людей для создания семьи'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Добавить супруга'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Выберите супруга для создания семьи:'),
            const SizedBox(height: 8),
            ...availablePersons.map((Person person) {
              return ListTile(
                leading: CircleAvatar(
                  child: Text(person.displayName.substring(0, 1).toUpperCase()),
                ),
                title: Text(person.displayName),
                subtitle: Text(person.formattedAge),
                onTap: () {
                  final String treeId = _treeId ?? 'default';
                  final Family family = Family(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    treeId: treeId,
                    husbandId: _person?.gender == Gender.male
                        ? widget.personId
                        : person.id,
                    wifeId: _person?.gender == Gender.female
                        ? widget.personId
                        : person.id,
                    childrenIds: const <String>[],
                  );
                  _familyBloc.add(AddFamilyEvent(family, treeId: treeId));
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
    _showAddFamilyDialog(context);
  }

  void _showAddFamilyDialog(BuildContext context) {
    final PersonState personState = _personBloc.state;
    if (personState is! PersonsLoaded) return;

    // Получаем персоны текущего проекта
    final projectPersons = _getProjectPersons(personState);

    if (projectPersons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('В этом проекте нет других людей'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final String treeId = _treeId ?? 'default';

    showDialog(
      context: context,
      builder: (BuildContext context) => FamilyFormDialog(
        availablePersons: projectPersons,
        treeId: treeId,
        onSave: (Family family) {
          _familyBloc.add(AddFamilyEvent(family, treeId: treeId));
        },
      ),
    );
  }

  void _showEditPersonDialog(BuildContext context) {
    if (_person == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => PersonFormDialog(
        existingPerson: _person!,
        treeId: _treeId ?? 'default',
        onSave: (updatedPerson) {
          _personBloc.add(UpdatePersonEvent(updatedPerson));
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
