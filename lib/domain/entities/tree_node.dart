import 'package:equatable/equatable.dart';
import 'person.dart';

/// Узел дерева для визуализации
class TreeNode extends Equatable {
  final Person person;
  final List<TreeNode> children;
  final List<TreeNode> spouses;
  final bool isRoot;
  final bool isCenter; // <-- Добавляем флаг для выделения центрального человека
  final int generation;

  /// true, если этот человек уже был полностью развёрнут (со своими детьми)
  /// в другой ветке дерева - например, он одновременно чей-то ребёнок в
  /// одной родительской линии и супруг/родитель в другой. Чтобы не строить
  /// один и тот же семейный кусок дважды, здесь показывается "ссылочная"
  /// карточка без собственных детей - полная версия уже отрисована в другом
  /// месте.
  final bool isDuplicateReference;

  const TreeNode({
    required this.person,
    this.children = const [],
    this.spouses = const [],
    this.isRoot = false,
    this.isCenter = false, // <-- По умолчанию false
    this.generation = 0,
    this.isDuplicateReference = false,
  });

  bool get isLeaf => children.isEmpty;

  int get descendantsCount {
    int count = children.length;
    for (final child in children) {
      count += child.descendantsCount;
    }
    return count;
  }

  String get treeId => person.treeId;

  TreeNode copyWith({
    Person? person,
    List<TreeNode>? children,
    List<TreeNode>? spouses,
    bool? isRoot,
    bool? isCenter,
    int? generation,
    bool? isDuplicateReference,
  }) {
    return TreeNode(
      person: person ?? this.person,
      children: children ?? this.children,
      spouses: spouses ?? this.spouses,
      isRoot: isRoot ?? this.isRoot,
      isCenter: isCenter ?? this.isCenter,
      generation: generation ?? this.generation,
      isDuplicateReference: isDuplicateReference ?? this.isDuplicateReference,
    );
  }

  @override
  List<Object?> get props => [
    person,
    children,
    spouses,
    isRoot,
    isCenter,
    generation,
    isDuplicateReference,
  ];
}
