/// Тип отношения между людьми в семье
enum RelationshipType {
  spouse('Супруг(а)'),
  parent('Родитель'),
  child('Ребенок'),
  sibling('Брат/Сестра'),
  other('Другое');

  final String displayName;
  const RelationshipType(this.displayName);
}
