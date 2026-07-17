// lib/presentation/screens/import_gedcom_screen.dart
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/di/injector.dart';
import 'package:nm_gen/domain/use_cases/gedcom/import_gedcom.dart';
import 'package:nm_gen/presentation/blocs/person/person_bloc.dart';
import 'package:nm_gen/presentation/blocs/person/person_event.dart';
import 'package:nm_gen/presentation/blocs/project/project_bloc.dart';
import 'package:nm_gen/presentation/blocs/project/project_event.dart';

class ImportGedcomScreen extends StatefulWidget {
  const ImportGedcomScreen({Key? key}) : super(key: key);

  @override
  State<ImportGedcomScreen> createState() => _ImportGedcomScreenState();
}

class _ImportGedcomScreenState extends State<ImportGedcomScreen> {
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  ImportGedcomUseCase get _importUseCase => getIt<ImportGedcomUseCase>();

  @override
  void initState() {
    super.initState();
    debugPrint('🔍 ImportGedcomScreen: initState вызван');
    try {
      context.read<ProjectBloc>().add(LoadProjectsEvent());
      debugPrint('✅ ImportGedcomScreen: ProjectBloc загружен');
    } catch (e) {
      debugPrint('❌ ImportGedcomScreen: Ошибка загрузки ProjectBloc: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 ImportGedcomScreen: build вызван, isSuccess=$_isSuccess, isLoading=$_isLoading');
    
    try {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Импорт GEDCOM'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SingleChildScrollView(
          child: Padding(
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
                        onPressed: () {
                          debugPrint('🔍 ImportGedcomScreen: Нажата кнопка "Готово"');
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Готово'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(200, 50),
                        ),
                      ),
                    ],
                  )
                else ...[
                  // ============================================================
                  // КНОПКА ЗАГРУЗКИ ИЗ АССЕТОВ (ТЕСТОВЫЕ ДАННЫЕ)
                  // ============================================================
                  ElevatedButton.icon(
                    onPressed: _loadSampleGedcom,
                    icon: const Icon(Icons.file_present),
                    label: const Text('📁 Загрузить демо-файл'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(250, 50),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Быстрая загрузка тестового дерева (4 поколения, 13 человек)',
                            style: TextStyle(fontSize: 12, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Обычный выбор файла
                  ElevatedButton.icon(
                    onPressed: _importWithFileSelector,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Выбрать .ged файл'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(250, 50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _importWithFileSelector,
                    icon: const Icon(Icons.file_present, size: 16),
                    label: const Text('Или через системный диалог'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
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
                    onPressed: () {
                      debugPrint('🔍 ImportGedcomScreen: Нажата кнопка "Назад"');
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Назад'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ ImportGedcomScreen: Ошибка в build: $e');
      debugPrint('❌ StackTrace: $stackTrace');
      return Scaffold(
        appBar: AppBar(
          title: const Text('Импорт GEDCOM'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Ошибка отображения: ${e.toString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Назад'),
              ),
            ],
          ),
        ),
      );
    }
  }

  // =========================================================================
  // ЗАГРУЗКА ИЗ АССЕТОВ (ТЕСТОВЫЕ ДАННЫЕ)
  // =========================================================================

  Future<void> _loadSampleGedcom() async {
    debugPrint('🔍 ImportGedcomScreen: _loadSampleGedcom вызван');
    try {
      setState(() {
        _isLoading = true;
        _message = null;
        _isSuccess = false;
      });

      debugPrint('🔍 ImportGedcomScreen: Загрузка файла из ассетов...');
      final String content = await rootBundle.loadString(
        'assets/gedcom/kuznetsov_tree.ged',
      );
      debugPrint('🔍 ImportGedcomScreen: Файл загружен, размер: ${content.length} символов');

      if (content.isEmpty) {
        debugPrint('⚠️ ImportGedcomScreen: Файл пуст');
        setState(() {
          _isLoading = false;
          _message = '❌ Файл пуст';
          _isSuccess = false;
        });
        return;
      }

      debugPrint('🔍 ImportGedcomScreen: Начинаем импорт...');
      final importResult = await _importUseCase.execute(content);
      debugPrint('🔍 ImportGedcomScreen: Импорт завершен');

      importResult.fold(
        (failure) {
          debugPrint('❌ ImportGedcomScreen: Ошибка импорта: ${failure.message}');
          setState(() {
            _isLoading = false;
            _message = '❌ Ошибка: ${failure.message}';
            _isSuccess = false;
          });
        },
        (count) {
          debugPrint('✅ ImportGedcomScreen: Успешно импортировано $count человек');
          try {
            debugPrint('🔍 ImportGedcomScreen: Обновляем список людей...');
            context.read<PersonBloc>().add(LoadPersonsEvent());
            debugPrint('✅ ImportGedcomScreen: Список людей обновлен');
          } catch (e) {
            debugPrint('❌ ImportGedcomScreen: Ошибка обновления списка людей: $e');
          }

          setState(() {
            _isLoading = false;
            _message = '✅ Импортировано $count человек(а)';
            _isSuccess = true;
          });
          debugPrint('🔍 ImportGedcomScreen: Состояние обновлено, _isSuccess = true');

          // Автоматически возвращаемся через 2 секунды
          debugPrint('🔍 ImportGedcomScreen: Запускаем таймер на 2 секунды');
          Future.delayed(const Duration(seconds: 2), () {
            debugPrint('🔍 ImportGedcomScreen: Таймер сработал, возвращаемся на предыдущий экран');
            if (mounted) {
              try {
                Navigator.pop(context);
                debugPrint('✅ ImportGedcomScreen: Навигация назад выполнена');
              } catch (e) {
                debugPrint('❌ ImportGedcomScreen: Ошибка навигации: $e');
              }
            } else {
              debugPrint('⚠️ ImportGedcomScreen: Widget не в дереве, навигация отменена');
            }
          });
        },
      );
    } catch (e, stackTrace) {
      debugPrint('❌ ImportGedcomScreen: Критическая ошибка: $e');
      debugPrint('❌ StackTrace: $stackTrace');
      setState(() {
        _isLoading = false;
        _message = '❌ Ошибка загрузки: ${e.toString()}';
        _isSuccess = false;
      });
    }
  }

  // =========================================================================
  // ВЫБОР ФАЙЛА ЧЕРЕЗ file_selector
  // =========================================================================

  Future<void> _importWithFileSelector() async {
    debugPrint('🔍 ImportGedcomScreen: _importWithFileSelector вызван');
    try {
      setState(() {
        _isLoading = true;
        _message = null;
        _isSuccess = false;
      });

      const gedcomTypeGroup = XTypeGroup(
        label: 'GEDCOM',
        extensions: <String>['ged'],
        mimeTypes: <String>['text/plain', 'application/gedcom'],
      );

      debugPrint('🔍 ImportGedcomScreen: Открываем диалог выбора файла');
      final XFile? file = await openFile(acceptedTypeGroups: [gedcomTypeGroup]);
      debugPrint('🔍 ImportGedcomScreen: Файл выбран: ${file?.path ?? "null"}');

      if (file == null) {
        debugPrint('⚠️ ImportGedcomScreen: Выбор файла отменен');
        setState(() {
          _isLoading = false;
          _message = '❌ Выбор файла отменен';
          _isSuccess = false;
        });
        return;
      }

      if (!file.path.toLowerCase().endsWith('.ged')) {
        debugPrint('⚠️ ImportGedcomScreen: Неверное расширение файла');
        setState(() {
          _isLoading = false;
          _message = '❌ Пожалуйста, выберите файл с расширением .ged';
          _isSuccess = false;
        });
        return;
      }

      debugPrint('🔍 ImportGedcomScreen: Читаем содержимое файла...');
      final content = await file.readAsString();
      debugPrint('🔍 ImportGedcomScreen: Файл прочитан, размер: ${content.length} символов');

      if (content.isEmpty) {
        debugPrint('⚠️ ImportGedcomScreen: Файл пуст');
        setState(() {
          _isLoading = false;
          _message = '❌ Файл пуст';
          _isSuccess = false;
        });
        return;
      }

      debugPrint('🔍 ImportGedcomScreen: Начинаем импорт...');
      final importResult = await _importUseCase.execute(content);
      debugPrint('🔍 ImportGedcomScreen: Импорт завершен');

      importResult.fold(
        (failure) {
          debugPrint('❌ ImportGedcomScreen: Ошибка импорта: ${failure.message}');
          setState(() {
            _isLoading = false;
            _message = '❌ Ошибка: ${failure.message}';
            _isSuccess = false;
          });
        },
        (count) {
          debugPrint('✅ ImportGedcomScreen: Успешно импортировано $count человек');
          try {
            context.read<PersonBloc>().add(LoadPersonsEvent());
            debugPrint('✅ ImportGedcomScreen: Список людей обновлен');
          } catch (e) {
            debugPrint('❌ ImportGedcomScreen: Ошибка обновления списка людей: $e');
          }

          setState(() {
            _isLoading = false;
            _message = '✅ Импортировано $count человек(а)';
            _isSuccess = true;
          });

          Future.delayed(const Duration(seconds: 2), () {
            debugPrint('🔍 ImportGedcomScreen: Таймер сработал, возвращаемся');
            if (mounted) {
              try {
                Navigator.pop(context);
              } catch (e) {
                debugPrint('❌ ImportGedcomScreen: Ошибка навигации: $e');
              }
            }
          });
        },
      );
    } catch (e, stackTrace) {
      debugPrint('❌ ImportGedcomScreen: Критическая ошибка: $e');
      debugPrint('❌ StackTrace: $stackTrace');
      setState(() {
        _isLoading = false;
        _message = '❌ Ошибка: ${e.toString()}';
        _isSuccess = false;
      });
    }
  }
}