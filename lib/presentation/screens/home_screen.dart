import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/presentation/blocs/family/family_bloc.dart';
import 'package:nm_gen/presentation/blocs/person/person_bloc.dart';
import 'package:nm_gen/presentation/blocs/person/person_event.dart';
import 'package:nm_gen/presentation/blocs/person/person_state.dart';
import 'package:nm_gen/presentation/blocs/tree/tree_bloc.dart';
import 'package:nm_gen/presentation/screens/export_gedcom_screen.dart';
import 'package:nm_gen/presentation/screens/family_screen.dart';
import 'package:nm_gen/presentation/screens/import_gedcom_screen.dart';
import 'package:nm_gen/presentation/screens/person_detail_screen.dart';
import 'package:nm_gen/presentation/screens/tree_screen.dart';
import 'package:nm_gen/di/injector.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Генеалогическое древо'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: <Widget>[
          // Импорт GEDCOM
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              final PersonBloc personBloc = context.read<PersonBloc>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => BlocProvider.value(
                    value: personBloc,
                    child: const ImportGedcomScreen(),
                  ),
                ),
              );
            },
            tooltip: 'Импорт GEDCOM',
          ),
          // Экспорт GEDCOM
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              final PersonBloc personBloc = context.read<PersonBloc>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => BlocProvider.value(
                    value: personBloc,
                    child: const ExportGedcomScreen(),
                  ),
                ),
              );
            },
            tooltip: 'Экспорт GEDCOM',
          ),
          // Древо
          IconButton(
            icon: const Icon(Icons.family_restroom),
            onPressed: () => _navigateToTree(context),
            tooltip: 'Просмотр древа',
          ),
          // Поиск
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
            tooltip: 'Поиск',
          ),
          // Обновить
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PersonBloc>().add(const LoadPersonsEvent());
            },
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: BlocConsumer<PersonBloc, PersonState>(
        listener: (BuildContext context, PersonState state) {
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
        builder: (BuildContext context, PersonState state) {
          if (state is PersonLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PersonError) {
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
                      context.read<PersonBloc>().add(const LoadPersonsEvent());
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
                  children: <Widget>[
                    const Icon(
                      Icons.family_restroom,
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
                    const SizedBox(height: 16),
                    if (state.isSearching)
                      ElevatedButton(
                        onPressed: () {
                          context.read<PersonBloc>().add(
                            const ClearSearchEvent(),
                          );
                        },
                        child: const Text('Очистить поиск'),
                      )
                    else
                      Column(
                        children: <Widget>[
                          ElevatedButton(
                            onPressed: () => _showAddPersonDialog(context),
                            child: const Text('Добавить человека'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => _navigateToTree(context),
                            icon: const Icon(Icons.family_restroom),
                            label: const Text('Перейти к древу'),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            }

            return Column(
              children: <Widget>[
                if (state.isSearching)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Результаты поиска: "${state.searchQuery}" (${state.persons.length})',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.read<PersonBloc>().add(
                              const ClearSearchEvent(),
                            );
                          },
                          child: const Text('Очистить'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.persons.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Person person = state.persons[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
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
                            children: <Widget>[
                              // Кнопка "Семья"
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
                              // Кнопка "Древо"
                              IconButton(
                                icon: const Icon(
                                  Icons.account_tree,
                                  color: Colors.green,
                                ),
                                onPressed: () {
                                  _navigateToTreeWithPerson(context, person.id);
                                },
                                tooltip: 'Показать в древе',
                              ),
                              // Кнопка "Редактировать"
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () =>
                                    _showEditPersonDialog(context, person),
                                tooltip: 'Редактировать',
                              ),
                              // Кнопка "Удалить"
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
                            _navigateToPersonDetail(context, person.id);
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Кнопка "Древо"
          FloatingActionButton(
            heroTag: 'tree',
            onPressed: () => _navigateToTree(context),
            backgroundColor: Colors.green,
            child: const Icon(Icons.account_tree),
          ),
          const SizedBox(height: 16),
          // Кнопка "Добавить"
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _showAddPersonDialog(context),
            child: const Icon(Icons.person_add),
          ),
          const SizedBox(height: 16),
          // Кнопка "Удалить всё" (красная)
          FloatingActionButton(
            heroTag: 'delete_all',
            onPressed: () => _confirmDeleteAll(context),
            backgroundColor: Colors.red,
            child: const Icon(Icons.delete_sweep),
            tooltip: 'Удалить все данные',
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // НАВИГАЦИЯ
  // =========================================================================

  void _navigateToTree(BuildContext context) {
    final PersonState state = context.read<PersonBloc>().state;
    if (state is PersonsLoaded && state.persons.isNotEmpty) {
      _navigateToTreeWithPerson(context, state.persons.first.id);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Добавьте хотя бы одного человека для просмотра древа'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _navigateToTreeWithPerson(BuildContext context, String personId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => BlocProvider(
          create: (BuildContext context) => getIt<TreeBloc>(),
          child: TreeScreen(rootPersonId: personId),
        ),
      ),
    );
  }

  void _navigateToFamily(
    BuildContext context,
    String personId,
    String personName,
  ) {
    final PersonBloc personBloc = context.read<PersonBloc>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => MultiBlocProvider(
          providers: <BlocProvider>[
            BlocProvider.value(value: personBloc),
            BlocProvider<FamilyBloc>(
              create: (BuildContext context) => getIt<FamilyBloc>(),
            ),
          ],
          child: FamilyScreen(personId: personId, personName: personName),
        ),
      ),
    );
  }

  void _navigateToPersonDetail(BuildContext context, String personId) {
    final PersonBloc personBloc = context.read<PersonBloc>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => MultiBlocProvider(
          providers: <BlocProvider>[
            BlocProvider.value(value: personBloc),
            BlocProvider<FamilyBloc>(
              create: (BuildContext context) => getIt<FamilyBloc>(),
            ),
          ],
          child: PersonDetailScreen(personId: personId),
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
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Поиск людей'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Введите имя или фамилию...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (String query) {
            if (query.isNotEmpty) {
              final PersonBloc bloc = context.read<PersonBloc>();
              bloc.add(SearchPersonsEvent(query));
              Navigator.pop(dialogContext);
            }
          },
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  void _showAddPersonDialog(BuildContext context) {
    final PersonBloc personBloc = context.read<PersonBloc>();

    final TextEditingController nameController = TextEditingController();
    final TextEditingController surnameController = TextEditingController();
    Gender selectedGender = Gender.male;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Добавить человека'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Имя',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: surnameController,
              decoration: const InputDecoration(
                labelText: 'Фамилия',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Gender>(
              value: selectedGender,
              decoration: const InputDecoration(
                labelText: 'Пол',
                border: OutlineInputBorder(),
              ),
              items: Gender.values.map((Gender gender) {
                return DropdownMenuItem<Gender>(
                  value: gender,
                  child: Text(gender.displayName),
                );
              }).toList(),
              onChanged: (Gender? value) {
                if (value != null) selectedGender = value;
              },
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  surnameController.text.isNotEmpty) {
                final Person person = Person.create(
                  firstName: nameController.text,
                  lastName: surnameController.text,
                  gender: selectedGender,
                );
                personBloc.add(AddPersonEvent(person));
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _showEditPersonDialog(BuildContext context, Person person) {
    final PersonBloc personBloc = context.read<PersonBloc>();

    final TextEditingController nameController = TextEditingController(
      text: person.firstName,
    );
    final TextEditingController surnameController = TextEditingController(
      text: person.lastName,
    );
    Gender selectedGender = person.gender;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Редактировать человека'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Имя',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: surnameController,
              decoration: const InputDecoration(
                labelText: 'Фамилия',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Gender>(
              value: selectedGender,
              decoration: const InputDecoration(
                labelText: 'Пол',
                border: OutlineInputBorder(),
              ),
              items: Gender.values.map((Gender gender) {
                return DropdownMenuItem<Gender>(
                  value: gender,
                  child: Text(gender.displayName),
                );
              }).toList(),
              onChanged: (Gender? value) {
                if (value != null) selectedGender = value;
              },
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  surnameController.text.isNotEmpty) {
                final Person updatedPerson = person.copyWith(
                  firstName: nameController.text,
                  lastName: surnameController.text,
                  gender: selectedGender,
                );
                personBloc.add(UpdatePersonEvent(updatedPerson));
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String personId, String name) {
    final PersonBloc personBloc = context.read<PersonBloc>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Удаление человека'),
        content: Text('Вы уверены, что хотите удалить "$name"?'),
        actions: <Widget>[
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

  // =========================================================================
  // УДАЛЕНИЕ ВСЕХ ДАННЫХ
  // =========================================================================

  void _confirmDeleteAll(BuildContext context) {
    final PersonBloc personBloc = context.read<PersonBloc>();
    final PersonState state = personBloc.state;

    if (state is! PersonsLoaded || state.persons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет данных для удаления'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final int count = state.persons.length;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('⚠️ Удаление всех данных'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Вы уверены, что хотите удалить ВСЕХ людей ($count человек) и все связанные семьи?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Row(
                children: <Widget>[
                  Icon(Icons.warning, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Это действие НЕЛЬЗЯ будет отменить!',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              // Вызываем событие удаления всех людей
              personBloc.add(const DeleteAllPersonsEvent());
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить всё'),
          ),
        ],
      ),
    );
  }
}
