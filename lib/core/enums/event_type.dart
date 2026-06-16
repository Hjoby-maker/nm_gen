/// Тип события в жизни человека
enum EventType {
  birth('Рождение'),
  death('Смерть'),
  marriage('Брак'),
  divorce('Развод'),
  baptism('Крещение'),
  graduation('Окончание'),
  employment('Работа'),
  retirement('Выход на пенсию'),
  other('Другое');

  final String displayName;
  const EventType(this.displayName);

  static EventType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'birth':
        return EventType.birth;
      case 'death':
        return EventType.death;
      case 'marriage':
        return EventType.marriage;
      case 'divorce':
        return EventType.divorce;
      case 'baptism':
        return EventType.baptism;
      case 'graduation':
        return EventType.graduation;
      case 'employment':
        return EventType.employment;
      case 'retirement':
        return EventType.retirement;
      default:
        return EventType.other;
    }
  }
}
