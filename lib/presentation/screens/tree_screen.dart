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
  const TreeScreen({Key? key, required this.rootPersonId, this.treeId})
    : super(key: key);
  final String rootPersonId;
  final String? treeId;

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
          LoadTreeEvent(widget.rootPersonId, treeId: widget.treeId),
        );
      }
    });
  }

  @override
  void didUpdateWidget(covariant TreeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.treeId != widget.treeId ||
        oldWidget.rootPersonId != widget.rootPersonId) {
      context.read<TreeBloc>().add(
        LoadTreeEvent(widget.rootPersonId, treeId: widget.treeId),
      );
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  /// Отладочный вывод структуры дерева
  void _debugPrintTree(
    TreeNode node, {
    String prefix = '',
    bool isLast = true,
  }) {
    final connector = isLast ? '└── ' : '├── ';
    final childPrefix = isLast ? '    ' : '│   ';

    final duplicateMark = node.isDuplicateReference ? ' [ссылка-дубль]' : '';
    print(
      '$prefix$connector${node.person.displayName} (id: ${node.person.id})$duplicateMark',
    );
    print(
      '$childPrefix   children: ${node.children.length}, spouses: ${node.spouses.length}',
    );

    // Выводим детей
    for (int i = 0; i < node.children.length; i++) {
      final child = node.children[i];
      final isChildLast = i == node.children.length - 1;
      _debugPrintTree(child, prefix: prefix + childPrefix, isLast: isChildLast);
    }

    // Выводим супругов
    for (int i = 0; i < node.spouses.length; i++) {
      final spouse = node.spouses[i];
      final isSpouseLast = i == node.spouses.length - 1;
      print('$prefix$childPrefix   ─── Супруг: ${spouse.person.displayName}');
      // Рекурсивно показываем детей супруга
      for (int j = 0; j < spouse.children.length; j++) {
        final child = spouse.children[j];
        final isChildLast = j == spouse.children.length - 1;
        _debugPrintTree(
          child,
          prefix: prefix + childPrefix + '    ',
          isLast: isChildLast,
        );
      }
    }
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
          if (state is TreeLoaded) {
            // 🔍 Отладочный вывод структуры дерева
            print('═══════════════════════════════════════════════════');
            print('🌳 СТРУКТУРА ДЕРЕВА');
            print('═══════════════════════════════════════════════════');
            _debugPrintTree(state.rootNode);
            print('═══════════════════════════════════════════════════');
            print('📊 СТАТИСТИКА:');
            print('  - Корень: ${state.rootNode.person.displayName}');
            print('  - Детей у корня: ${state.rootNode.children.length}');
            print('  - Супругов у корня: ${state.rootNode.spouses.length}');

            // Подсчет всех людей в дереве.
            // ⚠️ Раньше здесь просто инкрементировался счётчик на каждый
            // визит узла - но один и тот же человек может законно
            // встречаться в структуре несколько раз (например, он одному
            // родителю ребёнок, а другому - супруг), и get_full_tree.dart
            // в таких случаях возвращает "карточку-ссылку"
            // (isDuplicateReference), а не разворачивает его заново.
            // Считаем уникальные id, а не количество визитов узлов.
            final Set<String> uniqueIds = {};
            void countPeople(TreeNode node) {
              uniqueIds.add(node.person.id);
              for (final child in node.children) {
                countPeople(child);
              }
              for (final spouse in node.spouses) {
                uniqueIds.add(spouse.person.id);
                for (final child in spouse.children) {
                  countPeople(child);
                }
              }
            }

            countPeople(state.rootNode);
            uniqueIds.remove('virtual_root');
            print('  - Всего уникальных людей в дереве: ${uniqueIds.length}');
            print('═══════════════════════════════════════════════════');
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

            final hasChildren =
                state.rootNode.children.isNotEmpty ||
                state.rootNode.spouses.isNotEmpty;

            if (!hasChildren) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.account_tree,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Нет данных для отображения',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Добавьте людей и семьи в проект',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Stack(
              children: [
                InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: _minScale,
                  maxScale: _maxScale,
                  // constrained: false отдаёт ребёнку его естественный
                  // (потенциально огромный) размер, вместо того чтобы
                  // насильно ужимать его под вьюпорт - именно этого не
                  // хватало, чтобы дерево нормально панорамировалось и
                  // масштабировалось целиком, а не "плыло".
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(400),
                  onInteractionUpdate: (details) {
                    setState(() {
                      // details.scale - это дельта текущего жеста, а не
                      // абсолютный масштаб. Берём реальный масштаб из
                      // самой матрицы трансформации, иначе бейдж процентов
                      // и detailLevel постепенно расходятся с реальностью.
                      _currentScale = _transformationController.value
                          .getMaxScaleOnAxis();
                    });
                  },
                  child: TreeVisualizer(
                    rootNode: state.rootNode,
                    selectedPersonId: state.selectedPersonId,
                    centerPersonId: widget.rootPersonId.isNotEmpty
                        ? widget.rootPersonId
                        : null,
                    onPersonTap: (personId) {
                      context.read<TreeBloc>().add(
                        SelectPersonEvent(personId, treeId: widget.treeId),
                      );
                      _showPersonInfo(context, personId, state);
                    },
                    detailLevel: detailLevel,
                  ),
                ),
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
    final double clampedScale = scale.clamp(_minScale, _maxScale);

    // Раньше здесь стояло Matrix4.identity()..scale(scale) - это всегда
    // масштабирует от левого верхнего угла (0,0). При уменьшении масштаба
    // дерево визуально "уезжало" в угол и переставало заполнять экран.
    // Масштабируем вместо этого относительно центра видимой области, чтобы
    // дерево оставалось на месте и по центру после нажатия +/-.
    final Size viewportSize = MediaQuery.of(context).size;
    final Offset center = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );
    final Matrix4 matrix = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..scale(clampedScale)
      ..translate(-center.dx, -center.dy);

    setState(() {
      _currentScale = clampedScale;
      _transformationController.value = matrix;
    });
  }

  DetailLevel _getDetailLevel(double scale) {
    if (scale >= 1.5) return DetailLevel.full;
    if (scale >= 0.8) return DetailLevel.medium;
    return DetailLevel.minimal;
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
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
