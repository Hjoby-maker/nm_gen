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

  Widget _buildNode(BuildContext context, TreeNode node, bool isRoot) {
    final isSelected = selectedPersonId == node.person.id;
    final isCenter = centerPersonId == node.person.id;

    // Если есть супруги, показываем всех родителей
    if (node.spouses.isNotEmpty) {
      return _buildNodeWithAllParents(
        context,
        node,
        isRoot,
        isSelected,
        isCenter,
      );
    }

    // Если нет супругов, показываем только одного человека и его детей
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
          _buildChildrenRow(context, node.children),
        ],
      ],
    );
  }

  /// Узел со всеми родителями (основной + супруги)
  Widget _buildNodeWithAllParents(
    BuildContext context,
    TreeNode node,
    bool isRoot,
    bool isSelected,
    bool isCenter,
  ) {
    // Все родители: основной + супруги
    final List<TreeNode> allParents = [node, ...node.spouses];

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

            /*return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Карточка родителя
                TreeNodeWidget(
                  node: parent,
                  isRoot: false,
                  isSelected: isParentSelected,
                  isCenter: isParentCenter,
                  onTap: () => onPersonTap(parent.person.id),
                  detailLevel: detailLevel,
                ),
                // Дети этого родителя
                if (parent.children.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  // Показываем детей этого родителя под его карточкой
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: parent.children.map((child) {
                      final isChildCenter = child.person.id == centerPersonId;
                      final isChildSelected =
                          child.person.id == selectedPersonId;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isChildCenter
                              ? Colors.green.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isChildCenter
                                ? Colors.green
                                : Colors.grey.shade300,
                            width: isChildCenter ? 2 : 0.5,
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () => onPersonTap(child.person.id),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor:
                                    child.person.gender == Gender.male
                                    ? Colors.blue.shade100
                                    : Colors.pink.shade100,
                                child: Icon(
                                  child.person.gender == Gender.male
                                      ? Icons.male
                                      : Icons.female,
                                  size: 12,
                                  color: child.person.gender == Gender.male
                                      ? Colors.blue
                                      : Colors.pink,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                child.person.displayName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isChildCenter
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isChildCenter
                                      ? Colors.green.shade700
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            );*/

            // ОТРИСОВКА СУПРУГА (КРУПНАЯ КАРТОЧКА)
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

        // Общие дети (если есть)
        if (_getAllUniqueChildren(allParents).isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildVerticalLine(),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Все дети (${_getAllUniqueChildren(allParents).length})',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildChildrenRow(context, _getAllUniqueChildren(allParents)),
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
