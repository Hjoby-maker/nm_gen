import 'package:flutter/material.dart';
import 'package:nm_gen/domain/entities/person.dart';

class AddChildDialog extends StatefulWidget {
  const AddChildDialog({
    Key? key,
    required this.availableChildren,
    required this.onAddChild,
  }) : super(key: key);
  final List<Person> availableChildren;
  final Function(String) onAddChild;

  @override
  State<AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends State<AddChildDialog> {
  String? _selectedChildId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить ребенка'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DropdownButtonFormField<String>(
            initialValue: _selectedChildId,
            decoration: const InputDecoration(
              labelText: 'Выберите ребенка',
              border: OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<String>>[
              const DropdownMenuItem(
                value: null,
                child: Text('Выберите человека'),
              ),
              ...widget.availableChildren.map((Person person) {
                return DropdownMenuItem(
                  value: person.id,
                  child: Text(person.displayName),
                );
              }),
            ],
            onChanged: (String? value) {
              setState(() {
                _selectedChildId = value;
              });
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedChildId != null) {
              widget.onAddChild(_selectedChildId!);
              Navigator.pop(context);
            }
          },
          child: const Text('Добавить'),
        ),
      ],
    );
  }
}
