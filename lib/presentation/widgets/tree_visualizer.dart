import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nm_gen/domain/entities/tree_node.dart';
import 'package:nm_gen/presentation/widgets/tree_node_widget.dart';
import 'package:nm_gen/presentation/screens/tree_screen.dart';

/// Виджет для визуализации генеалогического древа.
///
/// ⚠️ Раньше дерево строилось вложенными Row/Column ("виджет-композицией").
/// У этого подхода два системных недостатка, из-за которых дерево иногда
/// выглядело сломанным:
///   1. Между родителем и рядом детей рисовалась одна вертикальная палочка
///      без разветвления к каждому ребёнку — при 3+ детях связь читалась
///      плохо или пропадала визуально.
///   2. Row выравнивает карточки по центру строки. Если у одного ребёнка
///      нет потомков, а у другого — большое поддерево, их "строки"
///      получали разную высоту, и карточки одного поколения съезжали по
///      вертикали друг относительно друга.
///
/// Теперь дерево сначала полностью раскладывается в абсолютные координаты
/// (_TreeLayoutEngine): для каждого узла заранее вычисляется (x, y), где
/// y = уровень поколения * фиксированная высота строки — поэтому все узлы
/// одного поколения гарантированно оказываются на одной линии. Связи между
/// родителями и детьми рисуются одним CustomPaint по этим же точным
/// координатам, поэтому связь никогда не "теряется".
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
    final _CardMetrics metrics = _CardMetrics.forDetailLevel(detailLevel);
    final _TreeLayoutEngine engine = _TreeLayoutEngine(metrics: metrics);
    final _TreeLayout layout = engine.layoutRoot(rootNode);

    // InteractiveViewer (в tree_screen.dart) сам панорамирует и
    // масштабирует весь холст целиком — здесь просто отдаём ему контент
    // его естественного (заранее посчитанного) размера, без собственных
    // скроллов и без Row/Column, "плывущих" от содержимого.
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: SizedBox(
        width: layout.size.width,
        height: layout.size.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Все связи (родитель-ребёнок и брачные) рисуются одним слоем
            // под карточками, по точным координатам из layout-движка.
            Positioned.fill(
              child: CustomPaint(
                painter: _TreeConnectorPainter(
                  edges: layout.edges,
                  marriageEdges: layout.marriageEdges,
                ),
              ),
            ),
            // Подписи "Дети (N)" над шиной коннектора.
            for (final _ChildCountLabel label in layout.childCountLabels)
              Positioned(
                left: label.center.dx - 60,
                top: label.top,
                width: 120,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label.text,
                      style: TextStyle(
                        fontSize: 11,
                        color: label.merged
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
                        fontWeight: label.merged
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            // Иконки брака поверх линии коннектора между супругами:
            // разбитое сердце для расторгнутых браков (Family.divorceDate
            // != null), обычное - для действующих.
            for (final _MarriageMarker marker in layout.marriageMarkers)
              Positioned(
                left: marker.center.dx - 8,
                top: marker.center.dy - 8,
                child: Icon(
                  marker.isDivorced ? Icons.heart_broken : Icons.favorite,
                  size: 16,
                  color: marker.isDivorced
                      ? Colors.grey.shade500
                      : Colors.pink.shade300,
                ),
              ),
            // Сами карточки людей — позиционированы абсолютно, поэтому все
            // карточки одного поколения гарантированно на одной высоте.
            for (final _PositionedCard card in layout.cards)
              Positioned(
                left: card.offset.dx,
                top: card.offset.dy,
                width: metrics.cardWidth,
                child: TreeNodeWidget(
                  node: card.node,
                  isRoot: card.isRoot,
                  isSelected: card.node.person.id == selectedPersonId,
                  isCenter: card.node.person.id == centerPersonId,
                  onTap: () => onPersonTap(card.node.person.id),
                  detailLevel: detailLevel,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// РАЗМЕРЫ КАРТОЧЕК ПО УРОВНЮ ДЕТАЛИЗАЦИИ
// =============================================================================

/// Ориентировочные размеры карточки для текущего DetailLevel. Точная
/// фактическая высота TreeNodeWidget может слегка отличаться (например,
/// из-за отображения профессии или пометки "†"), поэтому вертикальный
/// зазор между поколениями (generationGap) взят с запасом.
class _CardMetrics {
  final double cardWidth;
  final double cardHeight;
  final double generationGap;
  final double spouseGap;
  final double siblingGap;

  const _CardMetrics({
    required this.cardWidth,
    required this.cardHeight,
    required this.generationGap,
    required this.spouseGap,
    required this.siblingGap,
  });

  double get rowHeight => cardHeight + generationGap;

  // Карточка теперь горизонтальная (фото слева, текст справа), поэтому она
  // заметно шире и заметно ниже, чем в прежней вертикальной раскладке.
  factory _CardMetrics.forDetailLevel(DetailLevel level) {
    switch (level) {
      case DetailLevel.minimal:
        // Аватар 28px + паддинги + "Фамилия И.О." в одну строку.
        return const _CardMetrics(
          cardWidth: 112,
          cardHeight: 46,
          generationGap: 40,
          spouseGap: 20,
          siblingGap: 14,
        );
      case DetailLevel.full:
        // Аватар 52px + ФИО (до 2 строк) + дата рождения + дата смерти.
        return const _CardMetrics(
          cardWidth: 200,
          cardHeight: 90,
          generationGap: 56,
          spouseGap: 28,
          siblingGap: 22,
        );
      case DetailLevel.medium:
        // Аватар 40px + полное ФИО (до 2 строк).
        return const _CardMetrics(
          cardWidth: 164,
          cardHeight: 62,
          generationGap: 48,
          spouseGap: 24,
          siblingGap: 18,
        );
    }
  }
}

// =============================================================================
// LAYOUT-ДВИЖОК
// =============================================================================

class _PositionedCard {
  final TreeNode node;
  final Offset offset; // top-left в глобальных координатах холста
  final bool isRoot;

  _PositionedCard(this.node, this.offset, this.isRoot);
}

class _Edge {
  final Offset from;
  final Offset to;

  const _Edge(this.from, this.to);
}

class _ChildCountLabel {
  final Offset center;
  final double top;
  final String text;
  final bool merged;

  _ChildCountLabel({
    required this.center,
    required this.top,
    required this.text,
    required this.merged,
  });
}

/// Иконка брака между двумя соседними карточками супругов. [isDivorced]
/// решает, рисовать целое сердце (действующий брак) или разбитое
/// (Family.divorceDate != null - брак расторгнут), см. TreeNode.isDivorced.
class _MarriageMarker {
  final Offset center;
  final bool isDivorced;

  const _MarriageMarker({required this.center, required this.isDivorced});
}

/// Результат раскладки одного поддерева в локальных координатах, где
/// x всегда начинается с 0.
class _SubtreeLayout {
  final double width;
  final List<_PositionedCard> cards;
  final List<_Edge> edges;
  final List<_MarriageMarker> marriageMarkers;
  final List<_ChildCountLabel> childCountLabels;

  /// x-координата (локальная) точки, к которой должен подключаться
  /// коннектор родительского поколения сверху — это горизонтальный центр
  /// родительского юнита (человек + супруги), а не центр всего поддерева.
  final double parentUnitCenterX;
  final double parentUnitBottomY;

  _SubtreeLayout({
    required this.width,
    required this.cards,
    required this.edges,
    required this.marriageMarkers,
    required this.childCountLabels,
    required this.parentUnitCenterX,
    required this.parentUnitBottomY,
  });

  _SubtreeLayout shiftedBy(double dx) {
    Offset shift(Offset o) => Offset(o.dx + dx, o.dy);
    return _SubtreeLayout(
      width: width,
      cards: cards
          .map((c) => _PositionedCard(c.node, shift(c.offset), c.isRoot))
          .toList(),
      edges: edges.map((e) => _Edge(shift(e.from), shift(e.to))).toList(),
      marriageMarkers: marriageMarkers
          .map(
            (m) => _MarriageMarker(
              center: shift(m.center),
              isDivorced: m.isDivorced,
            ),
          )
          .toList(),
      childCountLabels: childCountLabels
          .map(
            (l) => _ChildCountLabel(
              center: shift(l.center),
              top: l.top,
              text: l.text,
              merged: l.merged,
            ),
          )
          .toList(),
      parentUnitCenterX: parentUnitCenterX + dx,
      parentUnitBottomY: parentUnitBottomY,
    );
  }
}

class _TreeLayout {
  final Size size;
  final List<_PositionedCard> cards;
  final List<_Edge> edges;
  final List<_MarriageMarker> marriageMarkers;
  final List<_ChildCountLabel> childCountLabels;

  _TreeLayout({
    required this.size,
    required this.cards,
    required this.edges,
    required this.marriageMarkers,
    required this.childCountLabels,
  });

  List<_Edge> get marriageEdges => const [];
}

class _TreeLayoutEngine {
  final _CardMetrics metrics;

  _TreeLayoutEngine({required this.metrics});

  /// Точка входа: раскладывает всё дерево, включая случай служебного
  /// "виртуального корня" с несколькими независимыми ветвями.
  _TreeLayout layoutRoot(TreeNode rootNode) {
    late final _SubtreeLayout layout;

    if (rootNode.person.id == 'virtual_root') {
      if (rootNode.children.length == 1) {
        layout = _layoutFamily(rootNode.children.first, 0);
      } else {
        layout = _layoutForest(rootNode.children);
      }
    } else {
      layout = _layoutFamily(rootNode, 0);
    }

    final double maxBottom = layout.cards.isEmpty
        ? 0
        : layout.cards
              .map((c) => c.offset.dy + metrics.cardHeight)
              .reduce(math.max);

    return _TreeLayout(
      size: Size(layout.width, maxBottom + 24),
      cards: layout.cards,
      edges: layout.edges,
      marriageMarkers: layout.marriageMarkers,
      childCountLabels: layout.childCountLabels,
    );
  }

  /// Раскладывает несколько независимых деревьев (нет общего предка) рядом
  /// друг с другом с увеличенным зазором между ними.
  _SubtreeLayout _layoutForest(List<TreeNode> roots) {
    final double gap = metrics.siblingGap * 3;
    final List<_SubtreeLayout> layouts = roots
        .map((r) => _layoutFamily(r, 0))
        .toList();

    double cursor = 0;
    final List<_PositionedCard> cards = [];
    final List<_Edge> edges = [];
    final List<_MarriageMarker> markers = [];
    final List<_ChildCountLabel> labels = [];

    for (final layout in layouts) {
      final shifted = layout.shiftedBy(cursor);
      cards.addAll(shifted.cards);
      edges.addAll(shifted.edges);
      markers.addAll(shifted.marriageMarkers);
      labels.addAll(shifted.childCountLabels);
      cursor += layout.width + gap;
    }

    final double totalWidth = layouts.isEmpty ? 0 : cursor - gap;
    return _SubtreeLayout(
      width: totalWidth,
      cards: cards,
      edges: edges,
      marriageMarkers: markers,
      childCountLabels: labels,
      parentUnitCenterX: totalWidth / 2,
      parentUnitBottomY: 0,
    );
  }

  /// Раскладывает семейный юнит: primary + его супруги на уровне [level],
  /// и рекурсивно — их общих детей на уровне [level] + 1.
  _SubtreeLayout _layoutFamily(TreeNode primary, int level) {
    final List<TreeNode> parents = [primary, ...primary.spouses];
    final double unitWidth =
        parents.length * metrics.cardWidth +
        (parents.length - 1) * metrics.spouseGap;
    final double y = level * metrics.rowHeight;

    final List<TreeNode> children = _uniqueChildren(parents);

    // Карточки-ссылки (isDuplicateReference) намеренно не разворачиваются
    // повторно — их дети уже показаны в другой ветке дерева, поэтому здесь
    // они всегда обрабатываются как листья, даже если данные на узле
    // почему-то содержат children/spouses.
    final bool treatAsLeaf = children.isEmpty || primary.isDuplicateReference;

    if (treatAsLeaf) {
      return _layoutParentsRow(parents, y, level == 0);
    }

    // 1. Раскладываем детей рекурсивно и ставим их в ряд.
    final List<_SubtreeLayout> childLayouts = children
        .map((c) => _layoutFamily(c, level + 1))
        .toList();

    final double childrenTotalWidth =
        childLayouts.fold(0.0, (sum, l) => sum + l.width) +
        metrics.siblingGap * (childLayouts.length - 1);

    final double subtreeWidth = math.max(unitWidth, childrenTotalWidth);

    double cursor = (subtreeWidth - childrenTotalWidth) / 2;
    final List<_PositionedCard> cards = [];
    final List<_Edge> edges = [];
    final List<_MarriageMarker> markers = [];
    final List<_ChildCountLabel> labels = [];
    final List<Offset> childConnectPoints = [];

    for (final childLayout in childLayouts) {
      final shifted = childLayout.shiftedBy(cursor);
      cards.addAll(shifted.cards);
      edges.addAll(shifted.edges);
      markers.addAll(shifted.marriageMarkers);
      labels.addAll(shifted.childCountLabels);
      childConnectPoints.add(
        Offset(shifted.parentUnitCenterX, y + metrics.rowHeight),
      );
      cursor += childLayout.width + metrics.siblingGap;
    }

    // 2. Родительский юнит центрируем над своим поддеревом детей.
    final _SubtreeLayout parentsRow = _layoutParentsRow(
      parents,
      y,
      level == 0,
    );
    final double unitStartX = (subtreeWidth - unitWidth) / 2;
    final shiftedParents = parentsRow.shiftedBy(unitStartX);
    cards.addAll(shiftedParents.cards);
    edges.addAll(shiftedParents.edges);
    markers.addAll(shiftedParents.marriageMarkers);

    // 3. Коннектор: ствол вниз от родителя -> общая шина -> ветка к
    // каждому ребёнку. Рисуется явными линиями по точным координатам, так
    // что связь видна всегда, независимо от количества детей.
    final double parentCenterX = unitStartX + unitWidth / 2;
    final double parentBottomY = y + metrics.cardHeight;
    final double busY = parentBottomY + metrics.generationGap / 2;

    edges.add(_Edge(Offset(parentCenterX, parentBottomY), Offset(parentCenterX, busY)));

    if (childConnectPoints.length == 1) {
      final Offset p = childConnectPoints.first;
      edges.add(_Edge(Offset(parentCenterX, busY), Offset(p.dx, busY)));
      edges.add(_Edge(Offset(p.dx, busY), Offset(p.dx, p.dy)));
    } else {
      final double minX = childConnectPoints
          .map((p) => p.dx)
          .reduce(math.min);
      final double maxX = childConnectPoints
          .map((p) => p.dx)
          .reduce(math.max);
      // Шина обязательно проходит через x родителя, даже если он лежит
      // чуть за пределами крайних детей (редкий случай очень узкой семьи).
      edges.add(
        _Edge(
          Offset(math.min(minX, parentCenterX), busY),
          Offset(math.max(maxX, parentCenterX), busY),
        ),
      );
      for (final p in childConnectPoints) {
        edges.add(_Edge(Offset(p.dx, busY), Offset(p.dx, p.dy)));
      }
    }

    final bool merged = parents.length > 1;
    labels.add(
      _ChildCountLabel(
        center: Offset(parentCenterX, busY),
        top: busY - 9,
        text: merged
            ? 'Все дети (${children.length})'
            : 'Дети (${children.length})',
        merged: merged,
      ),
    );

    return _SubtreeLayout(
      width: subtreeWidth,
      cards: cards,
      edges: edges,
      marriageMarkers: markers,
      childCountLabels: labels,
      parentUnitCenterX: subtreeWidth / 2,
      parentUnitBottomY: parentBottomY,
    );
  }

  /// Раскладывает только строку "человек + супруги" без детей, с брачными
  /// коннекторами между соседними карточками.
  _SubtreeLayout _layoutParentsRow(
    List<TreeNode> parents,
    double y,
    bool isRoot,
  ) {
    final List<_PositionedCard> cards = [];
    final List<_MarriageMarker> markers = [];
    final double unitWidth =
        parents.length * metrics.cardWidth +
        (parents.length - 1) * metrics.spouseGap;

    for (int i = 0; i < parents.length; i++) {
      final double x = i * (metrics.cardWidth + metrics.spouseGap);
      cards.add(_PositionedCard(parents[i], Offset(x, y), isRoot));
    }
    for (int i = 0; i < parents.length - 1; i++) {
      final double xA =
          i * (metrics.cardWidth + metrics.spouseGap) + metrics.cardWidth;
      final double xB = (i + 1) * (metrics.cardWidth + metrics.spouseGap);
      // parents = [primary, ...primary.spouses], поэтому parents[i + 1]
      // всегда сам супруг - именно на нём (а не на primary) хранится
      // isDivorced для брака между ним и primary, см. TreeNode.isDivorced.
      markers.add(
        _MarriageMarker(
          center: Offset((xA + xB) / 2, y + metrics.cardHeight / 2),
          isDivorced: parents[i + 1].isDivorced,
        ),
      );
    }

    return _SubtreeLayout(
      width: unitWidth,
      cards: cards,
      edges: const [],
      marriageMarkers: markers,
      childCountLabels: const [],
      parentUnitCenterX: unitWidth / 2,
      parentUnitBottomY: y + metrics.cardHeight,
    );
  }

  /// Собирает уникальных детей по всем родителям юнита (человек + супруги),
  /// т.к. общие дети могут числиться в children и у мужа, и у жены.
  List<TreeNode> _uniqueChildren(List<TreeNode> parents) {
    final Map<String, TreeNode> childMap = {};
    for (final parent in parents) {
      for (final child in parent.children) {
        childMap[child.person.id] = child;
      }
    }
    return childMap.values.toList();
  }
}

// =============================================================================
// ОТРИСОВКА СВЯЗЕЙ
// =============================================================================

class _TreeConnectorPainter extends CustomPainter {
  final List<_Edge> edges;
  final List<_Edge> marriageEdges;

  _TreeConnectorPainter({required this.edges, required this.marriageEdges});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final edge in edges) {
      canvas.drawLine(edge.from, edge.to, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TreeConnectorPainter oldDelegate) {
    return oldDelegate.edges != edges;
  }
}