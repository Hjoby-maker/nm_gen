import 'package:nm_gen/domain/entities/event.dart';

/// Модель Event для SQLite
class EventModel {
  EventModel({
    required this.id,
    required this.personId,
    required this.treeId,
    required this.type,
    required this.title,
    this.description,
    this.startDate,
    this.endDate,
    this.place,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  /// Конвертация из Domain Entity
  factory EventModel.fromDomain(Event event) {
    return EventModel(
      id: event.id,
      personId: event.personId,
      treeId: event.treeId,
      type: event.type.name,
      title: event.title,
      description: event.description,
      startDate: event.startDate?.millisecondsSinceEpoch,
      endDate: event.endDate?.millisecondsSinceEpoch,
      place: event.place,
      notes: event.notes,
      createdAt: event.createdAt?.millisecondsSinceEpoch,
      updatedAt: event.updatedAt?.millisecondsSinceEpoch,
    );
  }

  /// Создание из Map (для SQLite)
  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] as String,
      personId: map['person_id'] as String,
      treeId: map['tree_id'] as String? ?? 'default',
      type: map['type'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      startDate: map['start_date'] as int?,
      endDate: map['end_date'] as int?,
      place: map['place'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as int?,
      updatedAt: map['updated_at'] as int?,
    );
  }

  final String id;
  final String personId;
  final String treeId;
  final String type;
  final String title;
  final String? description;
  final int? startDate;
  final int? endDate;
  final String? place;
  final String? notes;
  final int? createdAt;
  final int? updatedAt;

  /// Конвертация в Domain Entity
  Event toDomain() {
    return Event(
      id: id,
      personId: personId,
      treeId: treeId,
      type: EventType.fromString(type),
      title: title,
      description: description,
      startDate: startDate != null
          ? DateTime.fromMillisecondsSinceEpoch(startDate!)
          : null,
      endDate: endDate != null
          ? DateTime.fromMillisecondsSinceEpoch(endDate!)
          : null,
      place: place,
      notes: notes,
      createdAt: createdAt != null
          ? DateTime.fromMillisecondsSinceEpoch(createdAt!)
          : null,
      updatedAt: updatedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(updatedAt!)
          : null,
    );
  }

  /// Конвертация в Map (для SQLite)
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'person_id': personId,
      'tree_id': treeId,
      'type': type,
      'title': title,
      'description': description,
      'start_date': startDate,
      'end_date': endDate,
      'place': place,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
