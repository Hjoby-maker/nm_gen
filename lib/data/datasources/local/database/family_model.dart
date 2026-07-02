import 'package:nm_gen/domain/entities/family.dart';

/// Модель Family для SQLite
class FamilyModel {
  FamilyModel({
    required this.id,
    required this.treeId,
    this.husbandId,
    this.wifeId,
    required this.childrenIds,
    this.marriageDate,
    this.divorceDate,
    this.marriagePlace,
    this.notes,
  });

  /// Конвертация из Domain Entity
  factory FamilyModel.fromDomain(Family family) {
    return FamilyModel(
      id: family.id,
      treeId: family.treeId,
      husbandId: family.husbandId,
      wifeId: family.wifeId,
      childrenIds: family.childrenIds.join(','),
      marriageDate: family.marriageDate?.millisecondsSinceEpoch,
      divorceDate: family.divorceDate?.millisecondsSinceEpoch,
      marriagePlace: family.marriagePlace,
      notes: family.notes,
    );
  }

  /// Создание из Map (для SQLite)
  factory FamilyModel.fromMap(Map<String, dynamic> map) {
    return FamilyModel(
      id: map['id'] as String,
      treeId: map['tree_id'] as String? ?? 'default',
      husbandId: map['husband_id'] as String?,
      wifeId: map['wife_id'] as String?,
      childrenIds: map['children_ids'] as String? ?? '',
      marriageDate: map['marriage_date'] as int?,
      divorceDate: map['divorce_date'] as int?,
      marriagePlace: map['marriage_place'] as String?,
      notes: map['notes'] as String?,
    );
  }
  final String id;
  final String treeId;
  final String? husbandId;
  final String? wifeId;
  final String childrenIds; // JSON строка
  final int? marriageDate;
  final int? divorceDate;
  final String? marriagePlace;
  final String? notes;

  /// Конвертация в Domain Entity
  Family toDomain() {
    return Family(
      id: id,
      treeId: treeId,
      husbandId: husbandId,
      wifeId: wifeId,
      childrenIds: childrenIds.isEmpty ? <String>[] : childrenIds.split(','),
      marriageDate: marriageDate != null
          ? DateTime.fromMillisecondsSinceEpoch(marriageDate!)
          : null,
      divorceDate: divorceDate != null
          ? DateTime.fromMillisecondsSinceEpoch(divorceDate!)
          : null,
      marriagePlace: marriagePlace,
      notes: notes,
    );
  }

  /// Конвертация в Map (для SQLite)
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'tree_id': treeId,
      'husband_id': husbandId,
      'wife_id': wifeId,
      'children_ids': childrenIds,
      'marriage_date': marriageDate,
      'divorce_date': divorceDate,
      'marriage_place': marriagePlace,
      'notes': notes,
    };
  }
}
