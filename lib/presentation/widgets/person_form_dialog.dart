// lib/presentation/widgets/person_form_dialog.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/core/utils/image_picker_service.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class PersonFormDialog extends StatefulWidget {
  const PersonFormDialog({
    super.key,
    this.existingPerson,
    required this.treeId,
    required this.onSave,
  });

  final Person? existingPerson;
  final String treeId;
  final Function(Person) onSave;

  @override
  State<PersonFormDialog> createState() => _PersonFormDialogState();
}

class _PersonFormDialogState extends State<PersonFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _middleNameController;
  late final TextEditingController _birthPlaceController;
  late final TextEditingController _occupationController;
  late final TextEditingController _biographyController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _deathDateController;
  late Gender _selectedGender;
  DateTime? _birthDate;
  DateTime? _deathDate;
  String? _photoPath;
  final ImagePickerService _imagePickerService = ImagePickerService();

  // Состояние ошибок для полей дат
  bool _birthDateHasError = false;
  bool _deathDateHasError = false;
  String? _birthDateErrorText;
  String? _deathDateErrorText;

  bool get isEditing => widget.existingPerson != null;

  @override
  void initState() {
    super.initState();
    final person = widget.existingPerson;
    _nameController = TextEditingController(text: person?.firstName ?? '');
    _surnameController = TextEditingController(text: person?.lastName ?? '');
    _middleNameController = TextEditingController(
      text: person?.middleName ?? '',
    );
    _birthPlaceController = TextEditingController(
      text: person?.birthPlace ?? '',
    );
    _occupationController = TextEditingController(
      text: person?.occupation ?? '',
    );
    _biographyController = TextEditingController(text: person?.biography ?? '');
    _selectedGender = person?.gender ?? Gender.male;
    _birthDate = person?.birthDate;
    _deathDate = person?.deathDate;
    _photoPath = person?.photoPath;

    _birthDateController = TextEditingController(
      text: _birthDate != null ? _formatDate(_birthDate!) : '',
    );
    _deathDateController = TextEditingController(
      text: _deathDate != null ? _formatDate(_deathDate!) : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _middleNameController.dispose();
    _birthPlaceController.dispose();
    _occupationController.dispose();
    _biographyController.dispose();
    _birthDateController.dispose();
    _deathDateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _imagePickerService.pickImage(context);
    if (file != null) {
      final String savedPath = await _saveImageToAppDirectory(file);
      setState(() {
        _photoPath = savedPath;
      });
    } else {
      setState(() {
        _photoPath = null;
      });
    }
  }

  Future<String> _saveImageToAppDirectory(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final File savedFile = File('${appDir.path}/photos/$fileName');

      await savedFile.parent.create(recursive: true);
      await imageFile.copy(savedFile.path);
      return savedFile.path;
    } catch (e) {
      return imageFile.path;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Редактировать человека' : 'Добавить человека'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPhotoPicker(),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Имя *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _surnameController,
              decoration: const InputDecoration(
                labelText: 'Фамилия *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _middleNameController,
              decoration: const InputDecoration(
                labelText: 'Отчество',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Gender>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Пол',
                border: OutlineInputBorder(),
              ),
              items: Gender.values.map((gender) {
                return DropdownMenuItem<Gender>(
                  value: gender,
                  child: Text(gender.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedGender = value);
              },
            ),
            const SizedBox(height: 8),
            _buildDateTextField(
              controller: _birthDateController,
              label: 'Дата рождения',
              hasError: _birthDateHasError,
              errorText: _birthDateErrorText,
              onDateChanged: (date) {
                setState(() {
                  _birthDate = date;
                  _validateBirthDate();
                });
              },
              onCalendarTap: () => _selectDate(context, (date) {
                setState(() {
                  _birthDate = date;
                  _birthDateController.text = date != null
                      ? _formatDate(date)
                      : '';
                  _validateBirthDate();
                });
              }, initialDate: _birthDate ?? DateTime.now()),
            ),
            const SizedBox(height: 4),
            _buildDateTextField(
              controller: _deathDateController,
              label: 'Дата смерти',
              hasError: _deathDateHasError,
              errorText: _deathDateErrorText,
              onDateChanged: (date) {
                setState(() {
                  _deathDate = date;
                  _validateDeathDate();
                });
              },
              onCalendarTap: () => _selectDate(context, (date) {
                setState(() {
                  _deathDate = date;
                  _deathDateController.text = date != null
                      ? _formatDate(date)
                      : '';
                  _validateDeathDate();
                });
              }, initialDate: _deathDate ?? DateTime.now()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _birthPlaceController,
              decoration: const InputDecoration(
                labelText: 'Место рождения',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _occupationController,
              decoration: const InputDecoration(
                labelText: 'Профессия',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _biographyController,
              decoration: const InputDecoration(
                labelText: 'Биография',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _savePerson,
          child: Text(isEditing ? 'Сохранить' : 'Добавить'),
        ),
      ],
    );
  }

  Widget _buildPhotoPicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade200,
          border: Border.all(color: Colors.grey.shade400, width: 2),
        ),
        child: _photoPath != null && File(_photoPath!).existsSync()
            ? ClipOval(
                child: Image.file(
                  File(_photoPath!),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholder(),
                ),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt, size: 30, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          'Фото',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

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
        // Применяем маску ввода: разрешаем только цифры и разделители
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
        // Ограничиваем длину 10 символов (ДД.ММ.ГГГГ)
        LengthLimitingTextInputFormatter(10),
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

  /// Валидация даты рождения
  void _validateBirthDate() {
    setState(() {
      if (_birthDateController.text.isNotEmpty && _birthDate == null) {
        _birthDateHasError = true;
        _birthDateErrorText = 'Неверный формат даты';
      } else if (_birthDate != null && _birthDate!.isAfter(DateTime.now())) {
        _birthDateHasError = true;
        _birthDateErrorText = 'Дата рождения не может быть в будущем';
      } else if (_birthDate != null && _birthDate!.isBefore(DateTime(1800))) {
        _birthDateHasError = true;
        _birthDateErrorText = 'Год должен быть не раньше 1800';
      } else if (_birthDate != null &&
          _deathDate != null &&
          _deathDate!.isBefore(_birthDate!)) {
        _birthDateHasError = true;
        _birthDateErrorText = 'Дата смерти не может быть раньше даты рождения';
      } else {
        _birthDateHasError = false;
        _birthDateErrorText = null;
      }
    });
  }

  /// Валидация даты смерти
  void _validateDeathDate() {
    setState(() {
      if (_deathDateController.text.isNotEmpty && _deathDate == null) {
        _deathDateHasError = true;
        _deathDateErrorText = 'Неверный формат даты';
      } else if (_deathDate != null && _deathDate!.isAfter(DateTime.now())) {
        _deathDateHasError = true;
        _deathDateErrorText = 'Дата смерти не может быть в будущем';
      } else if (_deathDate != null && _deathDate!.isBefore(DateTime(1800))) {
        _deathDateHasError = true;
        _deathDateErrorText = 'Год должен быть не раньше 1800';
      } else if (_deathDate != null &&
          _birthDate != null &&
          _deathDate!.isBefore(_birthDate!)) {
        _deathDateHasError = true;
        _deathDateErrorText = 'Дата смерти не может быть раньше даты рождения';
      } else {
        _deathDateHasError = false;
        _deathDateErrorText = null;
      }
    });
  }

  Future<void> _selectDate(
    BuildContext context,
    Function(DateTime?) onChanged, {
    required DateTime initialDate,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1800),
      lastDate: DateTime.now(),
    );
    if (picked != null) onChanged(picked);
  }

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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _savePerson() {
    final firstName = _nameController.text.trim();
    final lastName = _surnameController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Имя и фамилия обязательны для заполнения'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Валидация дат перед сохранением
    if (_birthDateController.text.isNotEmpty && _birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Неверный формат даты рождения'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_deathDateController.text.isNotEmpty && _deathDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Неверный формат даты смерти'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_birthDate != null && _deathDate != null) {
      if (_deathDate!.isBefore(_birthDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Дата смерти не может быть раньше даты рождения'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    final person = Person(
      id:
          widget.existingPerson?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      treeId: widget.treeId,
      firstName: firstName,
      lastName: lastName,
      middleName: _middleNameController.text.trim().isNotEmpty
          ? _middleNameController.text.trim()
          : null,
      gender: _selectedGender,
      birthDate: _birthDate,
      deathDate: _deathDate,
      birthPlace: _birthPlaceController.text.trim().isNotEmpty
          ? _birthPlaceController.text.trim()
          : null,
      deathPlace: null,
      occupation: _occupationController.text.trim().isNotEmpty
          ? _occupationController.text.trim()
          : null,
      biography: _biographyController.text.trim().isNotEmpty
          ? _biographyController.text.trim()
          : null,
      photoUrls: const [],
      photoPath: _photoPath,
      createdAt: widget.existingPerson?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSave(person);
    Navigator.pop(context);
  }
}
