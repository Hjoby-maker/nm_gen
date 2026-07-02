import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/core/utils/image_picker_service.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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
  late Gender _selectedGender;
  DateTime? _birthDate;
  DateTime? _deathDate;
  String? _photoPath; // <-- ДОБАВЛЯЕМ
  final ImagePickerService _imagePickerService = ImagePickerService();

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
    _photoPath = person?.photoPath; // <-- ДОБАВЛЯЕМ
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _middleNameController.dispose();
    _birthPlaceController.dispose();
    _occupationController.dispose();
    _biographyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _imagePickerService.pickImage(context);
    if (file != null) {
      // Сохраняем фото в локальное хранилище приложения
      final savedPath = await _saveImageToAppDirectory(file);
      setState(() {
        _photoPath = savedPath;
      });
    } else {
      // Пользователь выбрал "Удалить фото"
      setState(() {
        _photoPath = null;
      });
    }
  }

  Future<String> _saveImageToAppDirectory(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final savedFile = File('${appDir.path}/photos/$fileName');

      // Создаем директорию если её нет
      await savedFile.parent.create(recursive: true);

      // Копируем файл
      await imageFile.copy(savedFile.path);
      return savedFile.path;
    } catch (e) {
      // Если не удалось сохранить, возвращаем исходный путь
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
            // Фото
            _buildPhotoPicker(),
            const SizedBox(height: 8),
            // Имя
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Имя *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            // Фамилия
            TextField(
              controller: _surnameController,
              decoration: const InputDecoration(
                labelText: 'Фамилия *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            // Отчество
            TextField(
              controller: _middleNameController,
              decoration: const InputDecoration(
                labelText: 'Отчество',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            // Пол
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
            // Дата рождения
            _buildDatePicker(
              label: 'Дата рождения',
              date: _birthDate,
              onChanged: (date) => setState(() => _birthDate = date),
              onClear: () => setState(() => _birthDate = null),
            ),
            const SizedBox(height: 4),
            // Дата смерти
            _buildDatePicker(
              label: 'Дата смерти',
              date: _deathDate,
              onChanged: (date) => setState(() => _deathDate = date),
              onClear: () => setState(() => _deathDate = null),
            ),
            const SizedBox(height: 8),
            // Место рождения
            TextField(
              controller: _birthPlaceController,
              decoration: const InputDecoration(
                labelText: 'Место рождения',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            // Профессия
            TextField(
              controller: _occupationController,
              decoration: const InputDecoration(
                labelText: 'Профессия',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            // Биография
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

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required Function(DateTime?) onChanged,
    required VoidCallback onClear,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        date != null ? '$label: ${_formatDate(date)}' : '$label не указана',
        style: TextStyle(
          color: date != null ? Colors.black : Colors.grey.shade600,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (date != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: onClear,
            ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context, onChanged),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    Function(DateTime?) onChanged,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1800),
      lastDate: DateTime.now(),
    );
    if (picked != null) onChanged(picked);
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
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
      photoPath: _photoPath, // <-- ДОБАВЛЯЕМ
      createdAt: widget.existingPerson?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSave(person);
    Navigator.pop(context);
  }
}
