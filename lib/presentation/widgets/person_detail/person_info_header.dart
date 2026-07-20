// lib/presentation/widgets/person_detail/person_info_header.dart
import 'package:flutter/material.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/core/utils/date_formatters.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/presentation/widgets/person_detail/person_avatar_picker.dart';

/// Карточка с основной информацией о человеке: аватар (кликабельный,
/// PersonAvatarPicker), ФИО, пол, возраст, профессия, даты и места
/// рождения/смерти, биография.
///
/// Чисто отображение - ничего не пишет в blocs напрямую (кроме самого
/// PersonAvatarPicker, у которого своя узкая ответственность).
class PersonInfoHeader extends StatelessWidget {
  const PersonInfoHeader({super.key, required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    final String age = person.age != null
        ? '${person.age} лет'
        : 'Возраст неизвестен';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PersonAvatarPicker(person: person, radius: 50),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            person.gender == Gender.male
                                ? Icons.male
                                : person.gender == Gender.female
                                ? Icons.female
                                : Icons.person,
                            size: 16,
                            color: person.gender == Gender.male
                                ? Colors.blue
                                : Colors.pink,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            person.gender.displayName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        age,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (person.occupation != null)
                        Text(
                          person.occupation!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  if (person.birthDate != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      children: [
                        const Icon(Icons.cake, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Дата рождения: ${formatDate(person.birthDate!)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (person.deathDate != null) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      children: [
                        const Icon(Icons.warning, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Дата смерти: ${formatDate(person.deathDate!)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (person.birthPlace != null) ...[
                    const SizedBox(height: 4),
                    // Expanded требует прямого предка Row/Column/Flex - Wrap
                    // для этого не подходит ("Incorrect use of
                    // ParentDataWidget"). По смыслу это одна строка "иконка
                    // + текст", а не переносимый поток элементов - Row.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            person.birthPlace!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (person.biography != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        person.biography!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}