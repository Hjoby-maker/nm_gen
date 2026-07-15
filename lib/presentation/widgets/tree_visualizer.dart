import 'package:flutter/material.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/entities/tree_node.dart';
import 'package:nm_gen/presentation/widgets/tree_node_widget.dart';
import 'package:nm_gen/presentation/screens/tree_screen.dart';

/// Виджет для визуализации генеалогического древа
class TreeVisualizer extends StatelessWidget {
  final TreeNode rootNode;
  final Function(String) onPersonTap;
  final String? selectedPersonId;
  final String? centerPersonId;
  final DetailLevel detailLevel;

  const TreeVisualizer({
    Key? key,
    required this.rootNode,
    required this.onPersonTap,
    this.selectedPersonId,
    this.centerPersonId,
    this.detailLevel = DetailLevel.medium,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // rootNode может быть служебным "виртуальным корнем"
    final Widget content;
    if (rootNode.person.id == 'virtual_root') {
      if (rootNode.children.length == 1) {
        content = _buildNode(context, rootNode.children.first, true);
      } else {
        // Используем SingleChildScrollView для горизонтальной прокрутки корневых узлов
        content = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rootNode.children
                .map(
                  (node) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildNode(context, node, true),
                  ),
                )
                .toList(),
          ),
        );
      }
    } else {
      content = _buildNode(context, rootNode, true);
    }

    return SingleChildScrollView(
      child: Center(
        child: Padding(padding: const EdgeInsets.all(32.0), child: content),
      ),
    );
  }

  /// Рекурсивное построение дерева
  Widget _buildNode(BuildContext context, TreeNode node, bool isRoot) {
    final isSelected = selectedPersonId == node.person.id;
    final isCenter = centerPersonId == node.person.id;

    if (node.spouses.isNotEmpty) {
      return _buildNodeWithSpouses(context, node, isRoot, isSelected, isCenter);
    }

    return _buildSinglePersonNode(context, node, isRoot, isSelected, isCenter);
  }

  /// Узел с одним человеком
  Widget _buildSinglePersonNode(
    BuildContext context,
    TreeNode node,
    bool isRoot,
    bool isSelected,
    bool isCenter,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TreeNodeWidget(
          node: node,
          isRoot: isRoot,
          isSelected: isSelected,
          isCenter: isCenter,
          onTap: () => onPersonTap(node.person.id),
          detailLevel: detailLevel,
        ),
        if (node.children.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildVerticalLine(),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Дети (${node.children.length})',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 8),
          _buildChildrenRow(context, node.children, false),
        ],
      ],
    );
  }

  /// Узел с супругами
  Widget _buildNodeWithSpouses(
    BuildContext context,
    TreeNode node,
    bool isRoot,
    bool isSelected,
    bool isCenter,
  ) {
    final List<TreeNode> allParents = [node, ...node.spouses];
    final allChildren = _getAllUniqueChildren(allParents);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Горизонтальный ряд родителей с явным коннектором брака между ними
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: _buildParentsWithConnectors(allParents),
          ),
        ),

        // Общие дети
        if (allChildren.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildVerticalLine(),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Все дети (${allChildren.length})',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildChildrenRow(context, allChildren, false),
        ],
      ],
    );
  }

  /// Строит ряд карточек супругов, вставляя между каждой парой заметный
  /// коннектор брака (⚭), чтобы горизонтальная семейная связь читалась
  /// с первого взгляда, а не терялась в обычных отступах Row.
  List<Widget> _buildParentsWithConnectors(List<TreeNode> parents) {
    final List<Widget> widgets = [];
    for (int i = 0; i < parents.length; i++) {
      final parent = parents[i];
      final isParentCenter = parent.person.id == centerPersonId;
      final isParentSelected = parent.person.id == selectedPersonId;

      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: TreeNodeWidget(
            node: parent,
            isRoot: false,
            isSelected: isParentSelected,
            isCenter: isParentCenter,
            onTap: () => onPersonTap(parent.person.id),
            detailLevel: detailLevel,
          ),
        ),
      );

      if (i < parents.length - 1) {
        widgets.add(_buildMarriageConnector());
      }
    }
    return widgets;
  }

  /// Небольшая горизонтальная линия с иконкой брака между карточками
  /// супругов.
  Widget _buildMarriageConnector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 12, height: 2, color: Colors.pink.shade200),
              Icon(Icons.favorite, size: 12, color: Colors.pink.shade300),
              Container(width: 12, height: 2, color: Colors.pink.shade200),
            ],
          ),
        ],
      ),
    );
  }

  /// Получить всех уникальных детей
  List<TreeNode> _getAllUniqueChildren(List<TreeNode> parents) {
    final childMap = <String, TreeNode>{};
    for (final parent in parents) {
      for (final child in parent.children) {
        childMap[child.person.id] = child;
      }
    }
    return childMap.values.toList();
  }

  /// Построение строки детей (без переноса на новые строки внутри поколения)
  Widget _buildChildrenRow(
    BuildContext context,
    List<TreeNode> children,
    bool isNested,
  ) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ Горизонтальная прокрутка для детей одного поколения
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: children.map((child) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: isNested ? 4 : 8),
                child: _buildChildNode(context, child),
              );
            }).toList(),
          ),
        ),
        // ✅ Рекурсивно показываем внуков (без горизонтальных ограничений)
        if (children.any((c) => c.children.isNotEmpty))
          ...children.where((c) => c.children.isNotEmpty).map((child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                _buildVerticalLine(),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Дети ${child.person.displayName} (${child.children.length})',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ),
                const SizedBox(height: 4),
                // ✅ Рекурсивный вызов с горизонтальной прокруткой
                _buildChildrenRow(context, child.children, true),
              ],
            );
          }).toList(),
      ],
    );
  }

  /// Построение узла ребенка
  Widget _buildChildNode(BuildContext context, TreeNode child) {
    final isSelected = selectedPersonId == child.person.id;
    final isCenter = centerPersonId == child.person.id;

    if (child.spouses.isNotEmpty) {
      return _buildNodeWithSpouses(context, child, false, isSelected, isCenter);
    }

    if (child.children.isNotEmpty) {
      return _buildNode(context, child, false);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: TreeNodeWidget(
        node: child,
        onTap: () => onPersonTap(child.person.id),
        isSelected: isSelected,
        isCenter: isCenter,
        detailLevel: detailLevel,
        isCompact: detailLevel == DetailLevel.minimal,
      ),
    );
  }

  Widget _buildVerticalLine() {
    return Container(width: 2, height: 20, color: Colors.grey.shade400);
  }
}
