import 'package:equatable/equatable.dart';
import 'package:nm_gen/core/enums/event_type.dart';

/// Событие в жизни человека (рождение, смерть, брак и т.д.)
class Event extends Equatable {
  const Event({
    required this.id,
    required this.personId,
    required this.type,
    this.date,
    this.place,
    this.description,
    this.mediaUrls = const [],
  });
  final String id;
  final String personId;
  final EventType type;
  final DateTime? date;
  final String? place;
  final String? description;
  final List<String> mediaUrls;

  Event copyWith({
    String? id,
    String? personId,
    EventType? type,
    DateTime? date,
    String? place,
    String? description,
    List<String>? mediaUrls,
  }) {
    return Event(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      type: type ?? this.type,
      date: date ?? this.date,
      place: place ?? this.place,
      description: description ?? this.description,
      mediaUrls: mediaUrls ?? this.mediaUrls,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    personId,
    type,
    date,
    place,
    description,
    mediaUrls,
  ];
}
