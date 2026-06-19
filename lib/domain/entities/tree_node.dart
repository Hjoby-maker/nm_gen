import 'package:equatable/equatable.dart';
import 'person.dart';

/// Узел дерева для визуализации
class TreeNode extends Equatable {
  final Person person;
  final List<TreeNode> children;
  final List<TreeNode> spouses;
  final bool isRoot;
  final bool isCenter; // <-- Добавляем флаг для выделения центрального человека

  const TreeNode({
    required this.person,
    this.children = const [],
    this.spouses = const [],
    this.isRoot = false,
    this.isCenter = false, // <-- По умолчанию false
  });

  bool get isLeaf => children.isEmpty;

  int get descendantsCount {
    int count = children.length;
    for (final child in children) {
      count += child.descendantsCount;
    }
    return count;
  }

  TreeNode copyWith({
    Person? person,
    List<TreeNode>? children,
    List<TreeNode>? spouses,
    bool? isRoot,
    bool? isCenter,
  }) {
    return TreeNode(
      person: person ?? this.person,
      children: children ?? this.children,
      spouses: spouses ?? this.spouses,
      isRoot: isRoot ?? this.isRoot,
      isCenter: isCenter ?? this.isCenter,
    );
  }

  @override
  List<Object?> get props => [person, children, spouses, isRoot, isCenter];
}
