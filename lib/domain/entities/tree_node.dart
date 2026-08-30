import 'package:equatable/equatable.dart';
import 'person.dart';

/// Узел дерева для визуализации
class TreeNode extends Equatable {
  const TreeNode({
    required this.person,
    this.children = const <TreeNode>[],
    this.spouses = const <TreeNode>[],
    this.isRoot = false,
    this.isCenter = false, // <-- По умолчанию false
    this.generation = 0,
    this.isDuplicateReference = false,
    this.isDivorced = false,
    this.isSiblingGroup = false,
  });
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

  /// true, если брак между основным человеком и ЭТИМ супругом расторгнут
  /// (Family.divorceDate != null). Имеет смысл только когда узел находится
  /// внутри чужого списка spouses - у "основного" узла в каждой конкретной
  /// семье это поле не используется.
  final bool isDivorced;

  /// true, если это синтетический (не отображаемый как карточка) узел-
  /// обёртка, чьи children - это несколько РАЗНЫХ корневых деревьев,
  /// объединённых только тем, что их "главы" - братья/сёстры без
  /// известных общих родителей (см. GetFullTreeUseCase - такая связь
  /// приходит из Family с husbandId == null && wifeId == null). У такого
  /// узла нет своего person-а для отображения, TreeVisualizer рисует его
  /// children рядом друг с другом с горизонтальной линией родства вместо
  /// разрыва на несколько независимых деревьев.
  final bool isSiblingGroup;

  bool get isLeaf => children.isEmpty;

  int get descendantsCount {
    int count = children.length;
    for (final TreeNode child in children) {
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
    bool? isDivorced,
    bool? isSiblingGroup,
  }) {
    return TreeNode(
      person: person ?? this.person,
      children: children ?? this.children,
      spouses: spouses ?? this.spouses,
      isRoot: isRoot ?? this.isRoot,
      isCenter: isCenter ?? this.isCenter,
      generation: generation ?? this.generation,
      isDuplicateReference: isDuplicateReference ?? this.isDuplicateReference,
      isDivorced: isDivorced ?? this.isDivorced,
      isSiblingGroup: isSiblingGroup ?? this.isSiblingGroup,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    person,
    children,
    spouses,
    isRoot,
    isCenter,
    generation,
    isDuplicateReference,
    isDivorced,
    isSiblingGroup,
  ];
}