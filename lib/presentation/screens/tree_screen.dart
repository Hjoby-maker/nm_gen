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
  const TreeScreen({
    Key? key,
    required this.rootPersonId,
    this.treeId, // <-- ДОБАВЛЯЕМ
  }) : super(key: key);
  final String rootPersonId;
  final String? treeId; // <-- ДОБАВЛЯЕМ

  @override
  State<TreeScreen> createState() => _TreeScreenState();
}

class _TreeScreenState extends State<TreeScreen> {
  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;
  static const double _minScale = 0.3;
  static const double _maxScale = 3.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TreeBloc>().add(
          LoadTreeEvent(
            widget.rootPersonId,
            treeId: widget.treeId, // <-- ПЕРЕДАЕМ treeId
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Генеалогическое древо'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () => _zoomIn(),
            tooltip: 'Увеличить',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () => _zoomOut(),
            tooltip: 'Уменьшить',
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen),
            onPressed: () => _resetZoom(),
            tooltip: 'Сбросить масштаб',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<TreeBloc>().add(
                LoadTreeEvent(widget.rootPersonId, treeId: widget.treeId),
              );
            },
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: BlocConsumer<TreeBloc, TreeState>(
        listener: (BuildContext context, TreeState state) {
          if (state is TreeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (BuildContext context, TreeState state) {
          if (state is TreeLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
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
                children: <Widget>[
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
                        LoadTreeEvent(
                          widget.rootPersonId,
                          treeId: widget.treeId,
                        ),
                      );
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          if (state is TreeLoaded) {
            final detailLevel = _getDetailLevel(_currentScale);

            return Stack(
              children: [
                InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: _minScale,
                  maxScale: _maxScale,
                  onInteractionUpdate: (details) {
                    setState(() {
                      _currentScale = details.scale;
                    });
                  },
                  child: TreeVisualizer(
                    rootNode: state.rootNode,
                    selectedPersonId: state.selectedPersonId,
                    centerPersonId: widget.rootPersonId,
                    onPersonTap: (personId) {
                      context.read<TreeBloc>().add(
                        SelectPersonEvent(personId, treeId: widget.treeId),
                      );
                      _showPersonInfo(context, personId, state);
                    },
                    detailLevel: detailLevel,
                  ),
                ),
                // Индикатор масштаба
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(_currentScale * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                // Легенда
                Positioned(
                  bottom: 70,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Выбранный человек',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Корень дерева',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  // =========================================================================
  // УПРАВЛЕНИЕ МАСШТАБОМ
  // =========================================================================

  void _zoomIn() {
    final double newScale = (_currentScale + 0.2).clamp(_minScale, _maxScale);
    _updateScale(newScale);
  }

  void _zoomOut() {
    final double newScale = (_currentScale - 0.2).clamp(_minScale, _maxScale);
    _updateScale(newScale);
  }

  void _resetZoom() {
    _updateScale(1.0);
  }

  void _updateScale(double scale) {
    setState(() {
      _currentScale = scale;
      _transformationController.value = Matrix4.identity()..scale(scale);
    });
  }

  DetailLevel _getDetailLevel(double scale) {
    if (scale >= 1.5) {
      return DetailLevel.full;
    } else if (scale >= 0.8) {
      return DetailLevel.medium;
    } else {
      return DetailLevel.minimal;
    }
  }

  // =========================================================================
  // ОТОБРАЖЕНИЕ ИНФОРМАЦИИ О ЧЕЛОВЕКЕ
  // =========================================================================

  void _showPersonInfo(
    BuildContext context,
    String personId,
    TreeLoaded state,
  ) {
    final Person? person = _findPerson(state.rootNode, personId);
    if (person == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) =>
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Заголовок
                  Row(
                    children: <Widget>[
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
                          children: <Widget>[
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
                        children: <Widget>[
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
                    children: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Закрыть'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Перейти на экран редактирования
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

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  Person? _findPerson(TreeNode node, String personId) {
    if (node.person.id == personId) return node.person;
    for (final TreeNode child in node.children) {
      final Person? found = _findPerson(child, personId);
      if (found != null) return found;
    }
    for (final TreeNode spouse in node.spouses) {
      final Person? found = _findPerson(spouse, personId);
      if (found != null) return found;
    }
    return null;
  }
}

/// Уровень детализации отображения узлов
enum DetailLevel { minimal, medium, full }
