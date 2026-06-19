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

  Widget _buildNode(BuildContext context, TreeNode node, bool isRoot) {
    final isSelected = selectedPersonId == node.person.id;
    final isCenter = centerPersonId == node.person.id;

    // Собираем всех супругов вместе с основным узлом
    final List<Widget> spouseAndMainRow = [];

    // Добавляем основного человека
    spouseAndMainRow.add(
      TreeNodeWidget(
        node: node,
        isRoot: isRoot,
        isSelected: isSelected,
        isCenter: isCenter,
        onTap: () => onPersonTap(node.person.id),
        detailLevel: detailLevel,
      ),
    );

    // Добавляем супругов горизонтально
    if (node.spouses.isNotEmpty) {
      for (int i = 0; i < node.spouses.length; i++) {
        final spouse = node.spouses[i];
        spouseAndMainRow.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildSpouseConnector(context, spouse),
          ),
        );
        spouseAndMainRow.add(_buildSpouseNode(context, spouse));
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

  Widget _buildSpouseConnector(BuildContext context, TreeNode spouse) {
    // Определяем тип связи
    String relationType = 'Супруг(а)';

    // Проверяем, является ли супруг родителем
    final childFamilies = <String>[];
    // Здесь можно добавить логику определения типа связи

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            relationType,
            style: TextStyle(
              fontSize: 8,
              color: Colors.red.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Icon(Icons.favorite, color: Colors.red, size: 12),
      ],
    );
  }

  Widget _buildSpouseNode(BuildContext context, TreeNode spouse) {
    final isSelected = selectedPersonId == spouse.person.id;
    final isCenter = centerPersonId == spouse.person.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCenter ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCenter ? Colors.green : Colors.grey.shade300,
          width: isCenter ? 2 : 1,
        ),
      ),
      child: TreeNodeWidget(
        node: spouse,
        onTap: () => onPersonTap(spouse.person.id),
        isSelected: isSelected,
        isCenter: isCenter,
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
    final isCenter = centerPersonId == child.person.id;

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
