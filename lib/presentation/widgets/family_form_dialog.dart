import 'package:flutter/material.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/entities/person.dart';

class FamilyFormDialog extends StatefulWidget {
  const FamilyFormDialog({
    Key? key,
    this.existingFamily,
    required this.availablePersons,
    required this.onSave,
    this.treeId, // <-- ДОБАВЛЯЕМ
  }) : super(key: key);
  final Family? existingFamily;
  final List<Person> availablePersons;
  final Function(Family) onSave;
  final String? treeId; // <-- ДОБАВЛЯЕМ

  @override
  State<FamilyFormDialog> createState() => _FamilyFormDialogState();
}

class _FamilyFormDialogState extends State<FamilyFormDialog> {
  String? _selectedHusbandId;
  String? _selectedWifeId;
  DateTime? _marriageDate;
  DateTime? _divorceDate;
  final TextEditingController _marriagePlaceController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingFamily != null) {
      _selectedHusbandId = widget.existingFamily!.husbandId;
      _selectedWifeId = widget.existingFamily!.wifeId;
      _marriageDate = widget.existingFamily!.marriageDate;
      _divorceDate = widget.existingFamily!.divorceDate;
      _marriagePlaceController.text =
          widget.existingFamily!.marriagePlace ?? '';
      _notesController.text = widget.existingFamily!.notes ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Person> persons = widget.availablePersons;

    return AlertDialog(
      title: Text(
        widget.existingFamily == null ? 'Создать семью' : 'Редактировать семью',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Муж
            DropdownButtonFormField<String>(
              initialValue: _selectedHusbandId,
              decoration: const InputDecoration(
                labelText: 'Муж',
                border: OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Не выбран'),
                ),
                ...persons.map((Person person) {
                  return DropdownMenuItem<String>(
                    value: person.id,
                    child: Text(person.displayName),
                  );
                }),
              ],
              onChanged: (String? value) {
                setState(() {
                  _selectedHusbandId = value;
                });
              },
            ),
            const SizedBox(height: 8),
            // Жена
            DropdownButtonFormField<String>(
              initialValue: _selectedWifeId,
              decoration: const InputDecoration(
                labelText: 'Жена',
                border: OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Не выбрана'),
                ),
                ...persons.map((Person person) {
                  return DropdownMenuItem<String>(
                    value: person.id,
                    child: Text(person.displayName),
                  );
                }),
              ],
              onChanged: (String? value) {
                setState(() {
                  _selectedWifeId = value;
                });
              },
            ),
            const SizedBox(height: 8),
            // Дата брака
            ListTile(
              title: Text(
                _marriageDate != null
                    ? 'Дата брака: ${_formatDate(_marriageDate!)}'
                    : 'Дата брака не указана',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (_marriageDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        setState(() {
                          _marriageDate = null;
                        });
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context, true),
                  ),
                ],
              ),
            ),
            // Дата развода
            ListTile(
              title: Text(
                _divorceDate != null
                    ? 'Дата развода: ${_formatDate(_divorceDate!)}'
                    : 'Дата развода не указана',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (_divorceDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        setState(() {
                          _divorceDate = null;
                        });
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context, false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Место брака
            TextField(
              controller: _marriagePlaceController,
              decoration: const InputDecoration(
                labelText: 'Место брака',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            // Заметки
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Заметки',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(onPressed: _saveFamily, child: const Text('Сохранить')),
      ],
    );
  }

  void _saveFamily() {
    if (_selectedHusbandId == null && _selectedWifeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите хотя бы одного родителя'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Определяем treeId
    final String treeId =
        widget.treeId ?? widget.existingFamily?.treeId ?? 'default';

    final Family family = Family(
      id:
          widget.existingFamily?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      treeId: treeId, // <-- ДОБАВЛЯЕМ обязательный параметр
      husbandId: _selectedHusbandId,
      wifeId: _selectedWifeId,
      childrenIds: widget.existingFamily?.childrenIds ?? <String>[],
      marriageDate: _marriageDate,
      divorceDate: _divorceDate,
      marriagePlace: _marriagePlaceController.text.isNotEmpty
          ? _marriagePlaceController.text
          : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    widget.onSave(family);
    Navigator.pop(context);
  }

  Future<void> _selectDate(BuildContext context, bool isMarriage) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isMarriage) {
          _marriageDate = picked;
        } else {
          _divorceDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
