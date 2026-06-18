import 'package:flutter/material.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/entities/tree_node.dart';
import 'package:nm_gen/presentation/widgets/tree_node_widget.dart';
import 'package:nm_gen/presentation/screens/tree_screen.dart';

/// Виджет для визуализации генеалогического древа
class TreeVisualizer extends StatelessWidget {
  final TreeNode rootNode;
  final Function(String) onPersonTap;
  final String? selectedPersonId;
  final DetailLevel detailLevel;

  const TreeVisualizer({
    Key? key,
    required this.rootNode,
    required this.onPersonTap,
    this.selectedPersonId,
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

  Widget _buildNode(BuildContext context, TreeNode node, bool isRoot) {
    final isSelected = selectedPersonId == node.person.id;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Узел
        TreeNodeWidget(
          node: node,
          isRoot: isRoot,
          isSelected: isSelected,
          onTap: () => onPersonTap(node.person.id),
          detailLevel: detailLevel,
        ),

        // Супруги - располагаем горизонтально в Row
        if (node.spouses.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              Text(
                'Супруг(и)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Горизонтальное расположение супругов в Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...node.spouses.map((spouse) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: _buildSpouseNode(context, spouse),
                );
              }),
            ],
          ),
        ],

        // Дети
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
          _buildChildrenRow(context, node.children),
        ],
      ],
    );
  }

  Widget _buildSpouseNode(BuildContext context, TreeNode spouse) {
    final isSelected = selectedPersonId == spouse.person.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TreeNodeWidget(
        node: spouse,
        onTap: () => onPersonTap(spouse.person.id),
        isSelected: isSelected,
        detailLevel: detailLevel,
        isCompact: true,
      ),
    );
  }

  Widget _buildChildrenRow(BuildContext context, List<TreeNode> children) {
    // Если детей мало, показываем в ряд
    if (children.length <= 4) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: children.map((child) {
          return _buildChildNode(context, child);
        }).toList(),
      );
    } else {
      // Если детей много, показываем в несколько рядов
      return Column(
        children: [
          for (int i = 0; i < children.length; i += 4)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                children: children
                    .skip(i)
                    .take(4)
                    .map((child) => _buildChildNode(context, child))
                    .toList(),
              ),
            ),
        ],
      );
    }
  }

  Widget _buildChildNode(BuildContext context, TreeNode child) {
    final isSelected = selectedPersonId == child.person.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: TreeNodeWidget(
        node: child,
        onTap: () => onPersonTap(child.person.id),
        isSelected: isSelected,
        detailLevel: detailLevel,
        isCompact: detailLevel == DetailLevel.minimal,
      ),
    );
  }

  Widget _buildVerticalLine() {
    return Container(width: 2, height: 20, color: Colors.grey.shade400);
  }
}
