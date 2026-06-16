import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Person> _persons = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPersons();
  }

  Future<void> _loadPersons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repository = GetIt.instance<PersonRepository>();
      _persons = await repository.getAllPersons();
    } catch (e) {
      // Обработка ошибки
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addTestPerson() async {
    final repository = GetIt.instance<PersonRepository>();

    final person = Person.create(
      firstName: 'Иван',
      lastName: 'Петров',
      middleName: 'Иванович',
      gender: Gender.male,
      birthDate: DateTime(1980, 1, 15),
      occupation: 'Инженер',
    );

    await repository.addPerson(person);
    await _loadPersons();
  }

  Future<void> _deletePerson(String id) async {
    final repository = GetIt.instance<PersonRepository>();
    await repository.deletePerson(id);
    await _loadPersons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Генеалогическое древо'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPersons),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _persons.isEmpty
          ? Center(
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
                    'Нет людей в базе данных',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addTestPerson,
                    child: const Text('Добавить тестового человека'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _persons.length,
              itemBuilder: (context, index) {
                final person = _persons[index];
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
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deletePerson(person.id),
                    ),
                    onTap: () {
                      // TODO: Перейти на экран деталей
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Выбран: ${person.fullName}')),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTestPerson,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
