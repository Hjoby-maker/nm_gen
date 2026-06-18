import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:nm_gen/di/injector.dart'; // <-- Добавляем
import 'package:nm_gen/domain/use_cases/gedcom/export_gedcom.dart';

class ExportGedcomScreen extends StatefulWidget {
  const ExportGedcomScreen({Key? key}) : super(key: key);

  @override
  State<ExportGedcomScreen> createState() => _ExportGedcomScreenState();
}

class _ExportGedcomScreenState extends State<ExportGedcomScreen> {
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  // Получаем Use Case из DI
  ExportGedcomUseCase get _exportUseCase => getIt<ExportGedcomUseCase>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Экспорт GEDCOM'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSuccess ? Icons.check_circle : Icons.file_download,
              size: 80,
              color: _isSuccess ? Colors.green.shade400 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _isSuccess
                  ? 'Экспорт завершен!'
                  : 'Экспорт генеалогических данных в GEDCOM файл',
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
                'Файл будет сохранен в формате .ged',
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
                  Text('Генерация файла...'),
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
                      _message ?? 'Файл успешно сохранен!',
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
                onPressed: _exportGedcom,
                icon: const Icon(Icons.file_download),
                label: const Text('Экспортировать'),
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

  Future<void> _exportGedcom() async {
    setState(() {
      _isLoading = true;
      _message = null;
      _isSuccess = false;
    });

    try {
      final result = await _exportUseCase.execute();

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _message = 'Ошибка: ${failure.message}';
            _isSuccess = false;
          });
        },
        (gedcom) async {
          try {
            const gedcomTypeGroup = XTypeGroup(
              label: 'GEDCOM',
              extensions: ['ged'],
              mimeTypes: ['text/plain'],
            );

            final fileName =
                'family_tree_${DateTime.now().millisecondsSinceEpoch}.ged';

            final FileSaveLocation? saveLocation = await getSaveLocation(
              acceptedTypeGroups: [gedcomTypeGroup],
              suggestedName: fileName,
            );

            if (saveLocation == null) {
              setState(() {
                _isLoading = false;
                _message = '❌ Экспорт отменен';
                _isSuccess = false;
              });
              return;
            }

            final String path = saveLocation.path;
            final file = File(path);
            await file.writeAsString(gedcom);

            setState(() {
              _isLoading = false;
              _message = '✅ Файл сохранен: ${file.path.split('/').last}';
              _isSuccess = true;
            });

            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) Navigator.pop(context);
            });
          } catch (e) {
            setState(() {
              _isLoading = false;
              _message = 'Ошибка сохранения: ${e.toString()}';
              _isSuccess = false;
            });
          }
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
