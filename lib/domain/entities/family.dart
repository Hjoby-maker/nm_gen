import 'package:equatable/equatable.dart';

/// Сущность семьи (брака/союза) между двумя людьми
class Family extends Equatable {
  final String id;
  final String? husbandId; // ID мужа/партнера 1
  final String? wifeId; // ID жены/партнера 2
  final List<String> childrenIds;
  final DateTime? marriageDate;
  final DateTime? divorceDate;
  final String? marriagePlace;
  final String? notes;

  const Family({
    required this.id,
    this.husbandId,
    this.wifeId,
    this.childrenIds = const [],
    this.marriageDate,
    this.divorceDate,
    this.marriagePlace,
    this.notes,
  });

  /// Активен ли брак
  bool get isActive => divorceDate == null && marriageDate != null;

  /// Есть ли у семьи дети
  bool get hasChildren => childrenIds.isNotEmpty;

  /// Количество детей
  int get childrenCount => childrenIds.length;

  /// Получить ID родителя для проверки
  List<String> get parentIds => [
    if (husbandId != null) husbandId!,
    if (wifeId != null) wifeId!,
  ];

  Family copyWith({
    String? id,
    String? husbandId,
    String? wifeId,
    List<String>? childrenIds,
    DateTime? marriageDate,
    DateTime? divorceDate,
    String? marriagePlace,
    String? notes,
  }) {
    return Family(
      id: id ?? this.id,
      husbandId: husbandId ?? this.husbandId,
      wifeId: wifeId ?? this.wifeId,
      childrenIds: childrenIds ?? this.childrenIds,
      marriageDate: marriageDate ?? this.marriageDate,
      divorceDate: divorceDate ?? this.divorceDate,
      marriagePlace: marriagePlace ?? this.marriagePlace,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    husbandId,
    wifeId,
    childrenIds,
    marriageDate,
    divorceDate,
    marriagePlace,
    notes,
  ];

  /// Пустая семья
  static Family empty() =>
      Family(id: '', husbandId: null, wifeId: null, childrenIds: const []);
}
