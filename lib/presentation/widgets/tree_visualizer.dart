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
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: _buildNode(context, rootNode, true),
        ),
      ),
    );
  }

  /// Рекурсивное построение дерева
  Widget _buildNode(BuildContext context, TreeNode node, bool isRoot) {
    final isSelected = selectedPersonId == node.person.id;
    final isCenter = centerPersonId == node.person.id;

    // Если есть супруги, показываем группу родителей с их детьми
    if (node.spouses.isNotEmpty) {
      return _buildNodeWithSpouses(context, node, isRoot, isSelected, isCenter);
    }

    // Если нет супругов, показываем одного человека и его детей (рекурсивно)
    return _buildSinglePersonNode(context, node, isRoot, isSelected, isCenter);
  }

  /// Узел с одним человеком (рекурсивно показывает детей)
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

  /// Узел с супругами (рекурсивно показывает детей)
  Widget _buildNodeWithSpouses(
    BuildContext context,
    TreeNode node,
    bool isRoot,
    bool isSelected,
    bool isCenter,
  ) {
    // Все родители: основной + супруги
    final List<TreeNode> allParents = [node, ...node.spouses];

    // Собираем всех уникальных детей от всех родителей
    final allChildren = _getAllUniqueChildren(allParents);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Горизонтальный ряд родителей
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 24,
          runSpacing: 16,
          children: allParents.map((parent) {
            final isParentCenter = parent.person.id == centerPersonId;
            final isParentSelected = parent.person.id == selectedPersonId;

            return TreeNodeWidget(
              node: parent,
              isRoot: false,
              isSelected: isParentSelected,
              isCenter: isParentCenter,
              onTap: () => onPersonTap(parent.person.id),
              detailLevel: detailLevel,
            );
          }).toList(),
        ),

        // Общие дети всех родителей (рекурсивно)
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

  /// Получить всех уникальных детей из списка родителей
  List<TreeNode> _getAllUniqueChildren(List<TreeNode> parents) {
    final childMap = <String, TreeNode>{};
    for (final parent in parents) {
      for (final child in parent.children) {
        childMap[child.person.id] = child;
      }
    }
    return childMap.values.toList();
  }

  /// Построение строки детей (рекурсивно)
  Widget _buildChildrenRow(
    BuildContext context,
    List<TreeNode> children,
    bool isNested,
  ) {
    if (children.isEmpty) return const SizedBox.shrink();

    // Если детей много, показываем их в несколько строк
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ряд детей
        Wrap(
          alignment: WrapAlignment.center,
          spacing: isNested ? 8 : 16,
          runSpacing: isNested ? 8 : 16,
          children: children.map((child) {
            return _buildChildNode(context, child);
          }).toList(),
        ),
        // 🔥 Рекурсивно показываем внуков для каждого ребенка
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
                // Рекурсивно показываем внуков
                _buildChildrenRow(context, child.children, true),
              ],
            );
          }).toList(),
      ],
    );
  }

  Widget _buildChildNode(BuildContext context, TreeNode child) {
    final isSelected = selectedPersonId == child.person.id;
    final isCenter = centerPersonId == child.person.id;

    // Если у ребенка есть супруги, показываем его в полном размере
    if (child.spouses.isNotEmpty) {
      return _buildNodeWithSpouses(context, child, false, isSelected, isCenter);
    }

    // Если у ребенка есть дети, показываем его в полном размере
    if (child.children.isNotEmpty) {
      return _buildNode(context, child, false);
    }

    // Иначе показываем компактный вид
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
