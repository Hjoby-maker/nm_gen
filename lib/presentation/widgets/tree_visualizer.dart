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

    // Собираем всех супругов вместе с основным узлом в один горизонтальный ряд
    final List<Widget> spouseAndMainRow = [];

    // Добавляем основного человека
    spouseAndMainRow.add(
      TreeNodeWidget(
        node: node,
        isRoot: isRoot,
        isSelected: isSelected,
        onTap: () => onPersonTap(node.person.id),
        detailLevel: detailLevel,
      ),
    );

    // Добавляем супругов горизонтально
    if (node.spouses.isNotEmpty) {
      spouseAndMainRow.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _buildSpouseConnector(),
        ),
      );

      for (int i = 0; i < node.spouses.length; i++) {
        final spouse = node.spouses[i];
        spouseAndMainRow.add(_buildSpouseNode(context, spouse));
        if (i < node.spouses.length - 1) {
          spouseAndMainRow.add(const SizedBox(width: 8));
        }
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Горизонтальный ряд: основной человек + супруги
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: spouseAndMainRow,
        ),

        // Дети (под всей этой горизонтальной группой)
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

  Widget _buildSpouseConnector() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.favorite, color: Colors.red, size: 16),
        Text(
          'Супруг(а)',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
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
