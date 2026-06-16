/// Пол человека
enum Gender {
  male('Мужской'),
  female('Женский'),
  other('Другой'),
  unknown('Не указан');

  final String displayName;
  const Gender(this.displayName);

  /// Получить Gender из строки (для импорта GEDCOM)
  static Gender fromString(String value) {
    switch (value.toLowerCase()) {
      case 'male':
      case 'm':
        return Gender.male;
      case 'female':
      case 'f':
        return Gender.female;
      case 'other':
      case 'o':
        return Gender.other;
      default:
        return Gender.unknown;
    }
  }
}
