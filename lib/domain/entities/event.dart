// lib/domain/entities/event.dart
import 'package:equatable/equatable.dart';

/// Тип события
enum EventType {
  birth('Рождение'),
  death('Смерть'),
  baptism('Крещение'),
  burial('Похороны'),
  education('Образование'),
  occupation('Работа'),
  relocation('Переезд'),
  other('Другое');

  final String displayName;
  const EventType(this.displayName);

  static EventType fromString(String value) {
    return EventType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EventType.other,
    );
  }

  /// Список типов событий, которые доступны для выбора (без брака и развода)
  static List<EventType> get availableTypes {
    return [
      EventType.birth,
      EventType.death,
      EventType.baptism,
      EventType.burial,
      EventType.education,
      EventType.occupation,
      EventType.relocation,
      EventType.other,
    ];
  }
}

/// Сущность события в жизни человека
class Event extends Equatable {
  const Event({
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

  final String id;
  final String personId;
  final String treeId;
  final EventType type;
  final String title;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? place;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Создать новое событие
  factory Event.create({
    required String personId,
    required String treeId,
    required EventType type,
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? place,
    String? notes,
  }) {
    final now = DateTime.now();
    return Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      personId: personId,
      treeId: treeId,
      type: type,
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      place: place,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// ============================================
  /// МЕТОДЫ ДЛЯ РАБОТЫ С МЕДИА-ФАЙЛАМИ
  /// ============================================

  /// Получить имя директории для файлов этого события
  String get mediaDirectoryName => 'event_$id';

  /// Проверить, есть ли у события какие-либо вложения
  bool get hasAttachments =>
      false; // Будет обновляться при загрузке из репозитория

  /// Проверить, можно ли добавить медиа к этому событию
  bool get canAddMedia => id.isNotEmpty;

  /// Получить отображаемое название события для UI
  String get displayTitle {
    final dateStr = startDate != null ? ' (${_formatDate(startDate!)})' : '';
    return '$type: $title$dateStr';
  }

  /// Форматирование даты для отображения
  String _formatDate(DateTime date) {
    final months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'май',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Краткое описание события для списка
  String get shortDescription {
    final parts = <String>[];
    if (place != null && place!.isNotEmpty) parts.add(place!);
    if (startDate != null) parts.add(_formatDate(startDate!));
    return parts.isNotEmpty
        ? parts.join(', ')
        : 'Нет дополнительной информации';
  }

  /// Получить цвет для типа события (для UI)
  String get colorHex {
    switch (type) {
      case EventType.birth:
        return '#4CAF50'; // Зеленый
      case EventType.death:
        return '#F44336'; // Красный
      case EventType.baptism:
        return '#2196F3'; // Синий
      case EventType.burial:
        return '#9E9E9E'; // Серый
      case EventType.education:
        return '#FF9800'; // Оранжевый
      case EventType.occupation:
        return '#795548'; // Коричневый
      case EventType.relocation:
        return '#9C27B0'; // Фиолетовый
      case EventType.other:
        return '#607D8B'; // Сине-серый
    }
  }

  Event copyWith({
    String? id,
    String? personId,
    String? treeId,
    EventType? type,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? place,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      treeId: treeId ?? this.treeId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      place: place ?? this.place,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    personId,
    treeId,
    type,
    title,
    description,
    startDate,
    endDate,
    place,
    notes,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() => '$type: $title';
}
