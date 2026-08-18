// lib/presentation/widgets/persons/person_list_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/presentation/blocs/person/person_bloc.dart';
import 'package:nm_gen/presentation/blocs/person/person_event.dart';
import 'package:nm_gen/presentation/widgets/favorite_icon.dart';
import 'package:nm_gen/presentation/widgets/person_avatar.dart';

/// Одна строка человека в списке (persons_screen.dart): свайп вправо -
/// удалить (с подтверждением), свайп влево - открыть шторку действий
/// (редактировать / семья / древо). Тап - переход к деталям.
class PersonListTile extends StatelessWidget {
  const PersonListTile({
    super.key,
    required this.person,
    required this.onTap,
    required this.onConfirmDelete,
    required this.onDeleted,
    required this.onSwipeLeftActions,
  });

  final Person person;
  final VoidCallback onTap;

  /// Показывает диалог подтверждения удаления и, если пользователь
  /// подтвердил, сам отправляет DeletePersonEvent - возвращает true/false
  /// для Dismissible.confirmDismiss.
  final Future<bool> Function() onConfirmDelete;

  /// Вызывается, когда Dismissible завершил анимацию удаления вправо
  /// (например, чтобы показать SnackBar).
  final VoidCallback onDeleted;

  /// Открывает шторку действий (свайп влево).
  final VoidCallback onSwipeLeftActions;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(person.id),
      direction: DismissDirection.horizontal,
      background: _buildSwipeRightBackground(),
      secondaryBackground: _buildSwipeLeftBackground(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          return onConfirmDelete();
        } else if (direction == DismissDirection.endToStart) {
          onSwipeLeftActions();
          return false;
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          onDeleted();
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: PersonAvatar(person: person, radius: 25),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  person.displayName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Звездочка избранного
              FavoriteIcon(
                isFavorite: person.isFavorite,
                size: 18,
                onTap: () {
                  // Переключаем избранное при клике на звездочку
                  context.read<PersonBloc>().add(ToggleFavoriteEvent(person));
                },
              ),
            ],
          ),
          subtitle: Text(
            '${person.formattedAge} · ${person.occupation ?? 'Без профессии'}',
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildSwipeLeftBackground() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerRight,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.edit, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Icon(Icons.family_restroom, color: Colors.white, size: 28),
          SizedBox(width: 16),
          Text(
            'Редактировать / Семья',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeRightBackground() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      child: const Row(
        children: [
          Icon(Icons.delete_forever, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Text(
            'Удалить',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
