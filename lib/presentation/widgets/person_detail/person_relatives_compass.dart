// lib/presentation/widgets/person_detail/person_relatives_compass.dart
import 'package:flutter/material.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/entities/person_relatives.dart';
import 'package:nm_gen/presentation/widgets/person_avatar.dart';

/// HUD-компас родственного окружения на экране деталей человека: родители
/// сверху, дети снизу, супруг(и) слева, братья/сёстры справа. Тап по
/// любому - переход к деталям этого человека.
///
/// ⚠️ Это не буквальный оверлей поверх краёв физического экрана (Stack с
/// Positioned) - на узком мобильном экране внутри прокручиваемой вкладки
/// такой оверлей конфликтовал бы со скроллом, чёлкой и клавиатурой.
/// Вместо этого - три горизонтальные "полосы" (верх/середина/низ),
/// которые визуально читаются как компас, но остаются частью обычного
/// потока вёрстки и корректно скроллятся вместе со всем остальным.
class PersonRelativesCompass extends StatelessWidget {
  const PersonRelativesCompass({
    super.key,
    required this.relatives,
    required this.onSelectPerson,
  });

  final PersonRelatives relatives;
  final ValueChanged<String> onSelectPerson;

  @override
  Widget build(BuildContext context) {
    if (relatives.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            _buildZoneLabel('Родители'),
            const SizedBox(height: 6),
            _buildGroup(relatives.parents),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildZoneLabel('Супруг(и)'),
                        const SizedBox(height: 6),
                        _buildGroup(relatives.spouses),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 24, thickness: 1),
                  Expanded(
                    child: Column(
                      children: [
                        _buildZoneLabel('Братья/сёстры'),
                        const SizedBox(height: 6),
                        _buildGroup(relatives.siblings),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildZoneLabel('Дети'),
            const SizedBox(height: 6),
            _buildGroup(relatives.children),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildGroup(List<Person> people) {
    if (people.isEmpty) {
      return Text(
        '—',
        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: people.map(_buildChip).toList(),
    );
  }

  Widget _buildChip(Person person) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onSelectPerson(person.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PersonAvatar(person: person, radius: 22),
            const SizedBox(height: 4),
            SizedBox(
              width: 64,
              child: Text(
                person.displayName,
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}