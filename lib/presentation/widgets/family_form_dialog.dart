import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/entities/person.dart';

class FamilyFormDialog extends StatefulWidget {
  const FamilyFormDialog({
    Key? key,
    this.existingFamily,
    required this.availablePersons,
    required this.onSave,
    this.treeId,
  }) : super(key: key);
  final Family? existingFamily;
  final List<Person> availablePersons;
  final Function(Family) onSave;
  final String? treeId;

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
  final TextEditingController _marriageDateController = TextEditingController();
  final TextEditingController _divorceDateController = TextEditingController();

  // Состояние ошибок для полей дат
  bool _marriageDateHasError = false;
  bool _divorceDateHasError = false;
  String? _marriageDateErrorText;
  String? _divorceDateErrorText;

  @override
  void initState() {
    super.initState();
    if (widget.existingFamily != null) {
      // Проверяем, существует ли муж в списке доступных людей
      final husbandExists = widget.availablePersons.any(
        (p) => p.id == widget.existingFamily!.husbandId,
      );
      _selectedHusbandId = husbandExists
          ? widget.existingFamily!.husbandId
          : null;

      // Проверяем, существует ли жена в списке доступных людей
      final wifeExists = widget.availablePersons.any(
        (p) => p.id == widget.existingFamily!.wifeId,
      );
      _selectedWifeId = wifeExists ? widget.existingFamily!.wifeId : null;

      _marriageDate = widget.existingFamily!.marriageDate;
      _divorceDate = widget.existingFamily!.divorceDate;
      _marriagePlaceController.text =
          widget.existingFamily!.marriagePlace ?? '';
      _notesController.text = widget.existingFamily!.notes ?? '';

      _marriageDateController.text = _marriageDate != null
          ? _formatDate(_marriageDate!)
          : '';
      _divorceDateController.text = _divorceDate != null
          ? _formatDate(_divorceDate!)
          : '';
    }
  }

  @override
  void dispose() {
    _marriagePlaceController.dispose();
    _notesController.dispose();
    _marriageDateController.dispose();
    _divorceDateController.dispose();
    super.dispose();
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
              value: _selectedHusbandId,
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
              value: _selectedWifeId,
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
            // Дата брака - с ручным вводом и маской
            _buildDateTextField(
              controller: _marriageDateController,
              label: 'Дата брака',
              hasError: _marriageDateHasError,
              errorText: _marriageDateErrorText,
              onDateChanged: (date) {
                setState(() {
                  _marriageDate = date;
                  _validateMarriageDate();
                });
              },
              onCalendarTap: () => _selectDate(context, true),
            ),
            const SizedBox(height: 4),
            // Дата развода - с ручным вводом и маской
            _buildDateTextField(
              controller: _divorceDateController,
              label: 'Дата развода',
              hasError: _divorceDateHasError,
              errorText: _divorceDateErrorText,
              onDateChanged: (date) {
                setState(() {
                  _divorceDate = date;
                  _validateDivorceDate();
                });
              },
              onCalendarTap: () => _selectDate(context, false),
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

  /// Поле ввода даты с маской и валидацией
  Widget _buildDateTextField({
    required TextEditingController controller,
    required String label,
    required bool hasError,
    required String? errorText,
    required Function(DateTime?) onDateChanged,
    required VoidCallback onCalendarTap,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'ДД.ММ.ГГГГ',
        border: const OutlineInputBorder(),
        errorText: errorText,
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: onCalendarTap,
          tooltip: 'Выбрать из календаря',
        ),
      ),
      onChanged: (value) {
        // Применяем маску ввода
        final filtered = _applyDateMask(value);
        if (filtered != value) {
          controller.value = TextEditingValue(
            text: filtered,
            selection: TextSelection.collapsed(offset: filtered.length),
          );
        }

        final parsedDate = _parseDate(filtered);
        onDateChanged(parsedDate);
      },
      keyboardType: TextInputType.datetime,
      inputFormatters: [
        LengthLimitingTextInputFormatter(10), // ДД.ММ.ГГГГ
      ],
    );
  }

  /// Применяет маску для ввода даты
  String _applyDateMask(String value) {
    // Удаляем все нецифровые символы
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) return '';

    final buffer = StringBuffer();
    int digitIndex = 0;

    // День (2 цифры)
    for (int i = 0; i < 2 && digitIndex < digitsOnly.length; i++) {
      buffer.write(digitsOnly[digitIndex]);
      digitIndex++;
    }
    if (buffer.length == 2 && digitIndex < digitsOnly.length) {
      buffer.write('.');
    }

    // Месяц (2 цифры)
    for (int i = 0; i < 2 && digitIndex < digitsOnly.length; i++) {
      buffer.write(digitsOnly[digitIndex]);
      digitIndex++;
    }
    if (buffer.length >= 5 && digitIndex < digitsOnly.length) {
      buffer.write('.');
    }

    // Год (4 цифры)
    for (int i = 0; i < 4 && digitIndex < digitsOnly.length; i++) {
      buffer.write(digitsOnly[digitIndex]);
      digitIndex++;
    }

    return buffer.toString();
  }

  /// Парсит дату из строки
  DateTime? _parseDate(String text) {
    try {
      final cleaned = text.replaceAll(RegExp(r'[./-]'), '.');
      final parts = cleaned.split('.');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final date = DateTime(year, month, day);
        if (date.year == year && date.month == month && date.day == day) {
          return date;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Валидация даты брака
  void _validateMarriageDate() {
    setState(() {
      if (_marriageDateController.text.isNotEmpty && _marriageDate == null) {
        _marriageDateHasError = true;
        _marriageDateErrorText = 'Неверный формат даты';
      } else if (_marriageDate != null &&
          _marriageDate!.isAfter(DateTime.now())) {
        _marriageDateHasError = true;
        _marriageDateErrorText = 'Дата не может быть в будущем';
      } else if (_marriageDate != null &&
          _marriageDate!.isBefore(DateTime(1800))) {
        _marriageDateHasError = true;
        _marriageDateErrorText = 'Год должен быть не раньше 1800';
      } else if (_marriageDate != null &&
          _divorceDate != null &&
          _divorceDate!.isBefore(_marriageDate!)) {
        _marriageDateHasError = true;
        _marriageDateErrorText = 'Дата развода не может быть раньше даты брака';
      } else {
        _marriageDateHasError = false;
        _marriageDateErrorText = null;
      }
    });
  }

  /// Валидация даты развода
  void _validateDivorceDate() {
    setState(() {
      if (_divorceDateController.text.isNotEmpty && _divorceDate == null) {
        _divorceDateHasError = true;
        _divorceDateErrorText = 'Неверный формат даты';
      } else if (_divorceDate != null &&
          _divorceDate!.isAfter(DateTime.now())) {
        _divorceDateHasError = true;
        _divorceDateErrorText = 'Дата не может быть в будущем';
      } else if (_divorceDate != null &&
          _divorceDate!.isBefore(DateTime(1800))) {
        _divorceDateHasError = true;
        _divorceDateErrorText = 'Год должен быть не раньше 1800';
      } else if (_divorceDate != null &&
          _marriageDate != null &&
          _divorceDate!.isBefore(_marriageDate!)) {
        _divorceDateHasError = true;
        _divorceDateErrorText = 'Дата развода не может быть раньше даты брака';
      } else {
        _divorceDateHasError = false;
        _divorceDateErrorText = null;
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isMarriage) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isMarriage
          ? (_marriageDate ?? DateTime.now())
          : (_divorceDate ?? DateTime.now()),
      firstDate: DateTime(1800),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isMarriage) {
          _marriageDate = picked;
          _marriageDateController.text = _formatDate(picked);
          _validateMarriageDate();
        } else {
          _divorceDate = picked;
          _divorceDateController.text = _formatDate(picked);
          _validateDivorceDate();
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _saveFamily() {
    // Валидация дат перед сохранением
    if (_marriageDateController.text.isNotEmpty && _marriageDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Неверный формат даты брака'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_divorceDateController.text.isNotEmpty && _divorceDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Неверный формат даты развода'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_marriageDate != null && _divorceDate != null) {
      if (_divorceDate!.isBefore(_marriageDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Дата развода не может быть раньше даты брака'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    if (_selectedHusbandId == null && _selectedWifeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите хотя бы одного родителя'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final String treeId =
        widget.treeId ?? widget.existingFamily?.treeId ?? 'default';

    final Family family = Family(
      id:
          widget.existingFamily?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      treeId: treeId,
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
}
