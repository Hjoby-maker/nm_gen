import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/presentation/blocs/family/family_bloc.dart';
import 'package:nm_gen/presentation/blocs/person/person_bloc.dart';
import 'package:nm_gen/presentation/blocs/person/person_event.dart';
import 'package:nm_gen/presentation/blocs/person/person_state.dart';
import 'package:nm_gen/presentation/blocs/tree/tree_bloc.dart';
import 'package:nm_gen/presentation/screens/family_screen.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.family_restroom),
            onPressed: () => _navigateToTree(context),
            tooltip: 'Просмотр древа',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
            tooltip: 'Поиск',
          ),
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
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PersonError) {
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
                  children: [
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
                          context.read<PersonBloc>().add(ClearSearchEvent());
                        },
                        child: const Text('Очистить поиск'),
                      )
                    else
                      Column(
                        children: [
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
                            context.read<PersonBloc>().add(ClearSearchEvent());
                          },
                          child: const Text('Очистить'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.persons.length,
                    itemBuilder: (context, index) {
                      final person = state.persons[index];
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
                            children: [
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
                            _navigateToTreeWithPerson(context, person.id);
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
        children: [
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
        ],
      ),
    );
  }

  // =========================================================================
  // НАВИГАЦИЯ
  // =========================================================================

  /// Навигация к древу с корневым человеком (первый в списке)
  void _navigateToTree(BuildContext context) {
    final state = context.read<PersonBloc>().state;
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

  /// Навигация к древу с конкретным человеком
  void _navigateToTreeWithPerson(BuildContext context, String personId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => getIt<TreeBloc>(),
          child: TreeScreen(rootPersonId: personId),
        ),
      ),
    );
  }

  /// Навигация к экрану семьи
  void _navigateToFamily(
    BuildContext context,
    String personId,
    String personName,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider.value(
              value: context
                  .read<PersonBloc>(), // Передаем существующий PersonBloc
            ),
            BlocProvider(create: (context) => getIt<FamilyBloc>()),
          ],
          child: FamilyScreen(personId: personId, personName: personName),
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
              final bloc = context.read<PersonBloc>();
              bloc.add(SearchPersonsEvent(query));
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
    final personBloc = context.read<PersonBloc>();

    final nameController = TextEditingController();
    final surnameController = TextEditingController();
    Gender selectedGender = Gender.male;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Добавить человека'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              items: Gender.values.map((gender) {
                return DropdownMenuItem(
                  value: gender,
                  child: Text(gender.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) selectedGender = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  surnameController.text.isNotEmpty) {
                final person = Person.create(
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
    final personBloc = context.read<PersonBloc>();

    final nameController = TextEditingController(text: person.firstName);
    final surnameController = TextEditingController(text: person.lastName);
    Gender selectedGender = person.gender;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Редактировать человека'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              items: Gender.values.map((gender) {
                return DropdownMenuItem(
                  value: gender,
                  child: Text(gender.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) selectedGender = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  surnameController.text.isNotEmpty) {
                final updatedPerson = person.copyWith(
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
