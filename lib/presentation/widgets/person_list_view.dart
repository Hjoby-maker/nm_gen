import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/presentation/blocs/person/person_bloc.dart';
import 'package:nm_gen/presentation/blocs/person/person_state.dart';
import 'package:nm_gen/presentation/blocs/person/person_event.dart';

class PersonListView extends StatelessWidget {
  final String treeId;
  final Function(String) onPersonTap;
  final VoidCallback onAddPerson;

  const PersonListView({
    super.key,
    required this.treeId,
    required this.onPersonTap,
    required this.onAddPerson,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PersonBloc, PersonState>(
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
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<PersonBloc>().add(
                      LoadPersonsEvent(treeId: treeId),
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
                        ? 'Ничего не найдено'
                        : 'Нет людей в базе данных',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  if (!state.isSearching)
                    ElevatedButton(
                      onPressed: onAddPerson,
                      child: const Text('Добавить человека'),
                    ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.persons.length,
            itemBuilder: (context, index) {
              final person = state.persons[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                  subtitle: Text(person.formattedAge),
                  onTap: () => onPersonTap(person.id),
                ),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
