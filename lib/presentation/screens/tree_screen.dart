import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/entities/tree_node.dart';
import 'package:nm_gen/presentation/blocs/tree/tree_bloc.dart';
import 'package:nm_gen/presentation/blocs/tree/tree_event.dart';
import 'package:nm_gen/presentation/blocs/tree/tree_state.dart';
import 'package:nm_gen/presentation/widgets/tree_visualizer.dart';

class TreeScreen extends StatefulWidget {
  final String rootPersonId;

  const TreeScreen({Key? key, required this.rootPersonId}) : super(key: key);

  @override
  State<TreeScreen> createState() => _TreeScreenState();
}

class _TreeScreenState extends State<TreeScreen> {
  @override
  void initState() {
    super.initState();
    // Загружаем дерево при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TreeBloc>().add(LoadTreeEvent(widget.rootPersonId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Генеалогическое древо'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              // TODO: Увеличить масштаб
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              // TODO: Уменьшить масштаб
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<TreeBloc>().add(LoadTreeEvent(widget.rootPersonId));
            },
          ),
        ],
      ),
      body: BlocConsumer<TreeBloc, TreeState>(
        listener: (context, state) {
          if (state is TreeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TreeLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Загрузка генеалогического древа...'),
                ],
              ),
            );
          }

          if (state is TreeError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<TreeBloc>().add(
                        LoadTreeEvent(widget.rootPersonId),
                      );
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          if (state is TreeLoaded) {
            return TreeVisualizer(
              rootNode: state.rootNode,
              selectedPersonId: state.selectedPersonId,
              onPersonTap: (personId) {
                context.read<TreeBloc>().add(SelectPersonEvent(personId));
                _showPersonInfo(context, personId, state);
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Показать информацию о человеке в BottomSheet
  void _showPersonInfo(
    BuildContext context,
    String personId,
    TreeLoaded state,
  ) {
    // Находим человека в дереве
    final person = _findPerson(state.rootNode, personId);
    if (person == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: person.gender == Gender.male
                        ? Colors.blue
                        : person.gender == Gender.female
                        ? Colors.pink
                        : Colors.grey,
                    child: Icon(
                      person.gender == Gender.male
                          ? Icons.male
                          : person.gender == Gender.female
                          ? Icons.female
                          : Icons.person,
                      color: Colors.white,
                      size: 30,
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (person.occupation != null)
                          Text(
                            person.occupation!,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        Text(
                          person.formattedAge,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              // Информация
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (person.birthDate != null)
                        _buildInfoRow(
                          'Дата рождения',
                          _formatDate(person.birthDate!),
                        ),
                      if (person.deathDate != null)
                        _buildInfoRow(
                          'Дата смерти',
                          _formatDate(person.deathDate!),
                        ),
                      if (person.birthPlace != null)
                        _buildInfoRow('Место рождения', person.birthPlace!),
                      if (person.deathPlace != null)
                        _buildInfoRow('Место смерти', person.deathPlace!),
                      if (person.occupation != null)
                        _buildInfoRow('Профессия', person.occupation!),
                      if (person.biography != null)
                        _buildInfoRow('Биография', person.biography!),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              // Кнопки
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Закрыть'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Перейти на экран редактирования
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Редактировать'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Строка информации
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

  /// Форматирование даты
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  /// Рекурсивный поиск человека в дереве
  Person? _findPerson(TreeNode node, String personId) {
    if (node.person.id == personId) return node.person;
    for (final child in node.children) {
      final found = _findPerson(child, personId);
      if (found != null) return found;
    }
    for (final spouse in node.spouses) {
      final found = _findPerson(spouse, personId);
      if (found != null) return found;
    }
    return null;
  }
}
