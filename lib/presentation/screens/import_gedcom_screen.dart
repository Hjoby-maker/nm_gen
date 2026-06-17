import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_selector/file_selector.dart';
import 'package:nm_gen/domain/use_cases/gedcom/import_gedcom.dart';
import 'package:nm_gen/presentation/blocs/person/person_bloc.dart';
import 'package:nm_gen/presentation/blocs/person/person_event.dart';

class ImportGedcomScreen extends StatefulWidget {
  const ImportGedcomScreen({Key? key}) : super(key: key);

  @override
  State<ImportGedcomScreen> createState() => _ImportGedcomScreenState();
}

class _ImportGedcomScreenState extends State<ImportGedcomScreen> {
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Импорт GEDCOM'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSuccess ? Icons.check_circle : Icons.file_upload,
              size: 80,
              color: _isSuccess ? Colors.green.shade400 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _isSuccess
                  ? 'Импорт завершен!'
                  : 'Импорт генеалогических данных из GEDCOM файла',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: _isSuccess ? Colors.green.shade700 : null,
              ),
            ),
            if (!_isSuccess) ...[
              const SizedBox(height: 8),
              Text(
                'Поддерживаются файлы в формате .ged',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 32),
            if (_isLoading)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Импорт данных...'),
                ],
              )
            else if (_isSuccess)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      _message ?? 'Данные успешно импортированы!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.green.shade700),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check),
                    label: const Text('Готово'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                    ),
                  ),
                ],
              )
            else ...[
              ElevatedButton.icon(
                onPressed: _importGedcom,
                icon: const Icon(Icons.file_upload),
                label: const Text('Выбрать файл'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
              ),
              const SizedBox(height: 16),
              if (_message != null && !_isSuccess)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Назад'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _importGedcom() async {
    try {
      const gedcomTypeGroup = XTypeGroup(
        label: 'GEDCOM',
        extensions: ['ged'],
        mimeTypes: ['text/plain'],
      );

      final XFile? file = await openFile(acceptedTypeGroups: [gedcomTypeGroup]);

      if (file == null) return;

      setState(() {
        _isLoading = true;
        _message = null;
        _isSuccess = false;
      });

      final content = await file.readAsString();

      if (content.isEmpty) {
        setState(() {
          _isLoading = false;
          _message = 'Ошибка: файл пуст';
          _isSuccess = false;
        });
        return;
      }

      final importUseCase = context.read<ImportGedcomUseCase>();
      final importResult = await importUseCase.execute(content);

      importResult.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _message = 'Ошибка: ${failure.message}';
            _isSuccess = false;
          });
        },
        (count) {
          // Обновляем список людей через переданный PersonBloc
          context.read<PersonBloc>().add(const LoadPersonsEvent());

          setState(() {
            _isLoading = false;
            _message = '✅ Импортировано $count человек(а)';
            _isSuccess = true;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Ошибка: ${e.toString()}';
        _isSuccess = false;
      });
    }
  }
}
