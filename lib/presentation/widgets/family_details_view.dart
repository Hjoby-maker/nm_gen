import 'package:flutter/material.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/use_cases/family/get_family_with_details.dart'; // <-- ПРАВИЛЬНЫЙ ИМПОРТ

/// Виджет для отображения детальной информации о семье
class FamilyDetailsView extends StatelessWidget {
  const FamilyDetailsView({
    super.key,
    required this.details,
    required this.onEdit,
    required this.onDelete,
    required this.onAddChild,
    required this.onDeleteChild,
    required this.onBack,
    this.treeId,
  });

  final FamilyDetails details;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddChild;
  final Function(String) onDeleteChild;
  final VoidCallback onBack;
  final String? treeId;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Карточка с информацией о семье
          _buildFamilyInfoCard(),
          const SizedBox(height: 16),
          // Карточка с детьми
          _buildChildrenCard(context),
          const SizedBox(height: 16),
          // Кнопки действий
          _buildActionButtons(),
          const SizedBox(height: 16),
          // Кнопка возврата
          _buildBackButton(),
        ],
      ),
    );
  }

  // =========================================================================
  // ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
  // =========================================================================

  Widget _buildFamilyInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Информация о семье',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Муж', details.husband?.displayName ?? 'Не указан'),
            _buildInfoRow('Жена', details.wife?.displayName ?? 'Не указана'),
            if (details.family.marriageDate != null)
              _buildInfoRow(
                'Дата брака',
                _formatDate(details.family.marriageDate!),
              ),
            if (details.family.divorceDate != null)
              _buildInfoRow(
                'Дата развода',
                _formatDate(details.family.divorceDate!),
              ),
            if (details.family.marriagePlace != null)
              _buildInfoRow('Место брака', details.family.marriagePlace!),
            if (details.family.notes != null)
              _buildInfoRow('Заметки', details.family.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildChildrenCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Дети',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: onAddChild,
                  tooltip: 'Добавить ребенка',
                ),
              ],
            ),
            if (details.children.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Нет детей',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...details.children.map((child) {
                return _buildChildTile(child);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildChildTile(Person child) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: child.gender == Gender.male
            ? Colors.blue.shade100
            : Colors.pink.shade100,
        child: Text(
          child.displayName.substring(0, 1).toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: child.gender == Gender.male
                ? Colors.blue.shade700
                : Colors.pink.shade700,
          ),
        ),
      ),
      title: Text(child.displayName),
      subtitle: Text(child.formattedAge),
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
        onPressed: () => onDeleteChild(child.id),
        tooltip: 'Удалить из семьи',
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
            label: const Text('Редактировать'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('Удалить', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return Center(
      child: TextButton(
        onPressed: onBack,
        child: const Text('← Вернуться к списку'),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
