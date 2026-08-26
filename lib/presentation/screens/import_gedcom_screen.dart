// lib/presentation/screens/import_gedcom_screen.dart
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/di/injector.dart';
import 'package:nm_gen/domain/entities/project.dart';
import 'package:nm_gen/domain/use_cases/gedcom/import_gedcom.dart';
import 'package:nm_gen/presentation/blocs/family/family_bloc.dart';
import 'package:nm_gen/presentation/blocs/family/family_event.dart';
import 'package:nm_gen/presentation/blocs/person/person_bloc.dart';
import 'package:nm_gen/presentation/blocs/person/person_event.dart';
import 'package:nm_gen/presentation/blocs/project/project_bloc.dart';
import 'package:nm_gen/presentation/blocs/project/project_event.dart';
import 'package:nm_gen/presentation/blocs/project/project_state.dart';
import 'package:nm_gen/presentation/blocs/tree/tree_bloc.dart';
import 'package:nm_gen/presentation/blocs/tree/tree_event.dart';
import 'package:nm_gen/presentation/screens/main_screen.dart';

class ImportGedcomScreen extends StatefulWidget {
  const ImportGedcomScreen({Key? key}) : super(key: key);

  @override
  State<ImportGedcomScreen> createState() => _ImportGedcomScreenState();
}

class _ImportGedcomScreenState extends State<ImportGedcomScreen> {
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;
  String? _currentTreeId;

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
    debugPrint(
      '🔍 ImportGedcomScreen: build вызван, isSuccess=$_isSuccess, isLoading=$_isLoading',
    );

    try {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Импорт GEDCOM'),
          //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                  color: _isSuccess
                      ? Colors.green.shade400
                      : Colors.grey.shade400,
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
                        onPressed: _onDonePressed,
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
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Быстрая загрузка тестового дерева (4 поколения, 13 человек)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
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
                      debugPrint(
                        '🔍 ImportGedcomScreen: Нажата кнопка "Назад"',
                      );
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
          //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
  // ОБРАБОТЧИК КНОПКИ "ГОТОВО"
  // =========================================================================

  void _onDonePressed() {
    debugPrint('🔍 ImportGedcomScreen: _onDonePressed вызван');
    _navigateToMainScreenWithRefresh();
  }

  /// Переход на MainScreen с полным обновлением данных
  void _navigateToMainScreenWithRefresh() {
    debugPrint('🔄 ImportGedcomScreen: Переход на MainScreen с обновлением...');

    // 1. Определяем текущий treeId
    String treeId = _currentTreeId ?? 'default';
    try {
      final projectState = context.read<ProjectBloc>().state;
      if (projectState is ProjectsLoaded) {
        final defaultProject = projectState.projects.firstWhere(
          (p) => p.isDefault,
          orElse: () => projectState.projects.isNotEmpty
              ? projectState.projects.first
              : Project.empty(),
        );
        if (defaultProject.id.isNotEmpty) {
          treeId = defaultProject.id;
          debugPrint('🔍 ImportGedcomScreen: Текущий treeId = $treeId');
        }
      }
    } catch (e) {
      debugPrint('⚠️ ImportGedcomScreen: Не удалось получить treeId: $e');
    }

    // 2. Обновляем все BLoC с правильным treeId
    try {
      // PersonBloc - загружаем людей
      final personBloc = getIt<PersonBloc>();
      personBloc.add(LoadPersonsEvent(treeId: treeId));
      debugPrint('✅ PersonBloc обновлен (treeId: $treeId)');
    } catch (e) {
      debugPrint('❌ Ошибка обновления PersonBloc: $e');
    }

    try {
      // FamilyBloc - загружаем семьи
      final familyBloc = getIt<FamilyBloc>();
      familyBloc.add(LoadAllFamiliesEvent(treeId: treeId));
      debugPrint('✅ FamilyBloc обновлен (treeId: $treeId)');
    } catch (e) {
      debugPrint('❌ Ошибка обновления FamilyBloc: $e');
    }

    try {
      // TreeBloc - загружаем дерево
      final treeBloc = getIt<TreeBloc>();
      // Загружаем дерево с пустым корнем (покажет всех)
      treeBloc.add(LoadTreeEvent('', treeId: treeId));
      debugPrint('✅ TreeBloc обновлен (treeId: $treeId)');
    } catch (e) {
      debugPrint('❌ Ошибка обновления TreeBloc: $e');
    }

    try {
      // ProjectBloc - перезагружаем проекты
      final projectBloc = getIt<ProjectBloc>();
      projectBloc.add(LoadProjectsEvent());
      debugPrint('✅ ProjectBloc обновлен');
    } catch (e) {
      debugPrint('❌ Ошибка обновления ProjectBloc: $e');
    }

    debugPrint('✅ Все BLoC обновлены');

    // 3. Выполняем навигацию с пересозданием MainScreen
    // Используем pushReplacement для полной замены текущего экрана
    // и удаления всех предыдущих экранов из стека
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        try {
          // Сначала пробуем popUntil чтобы очистить стек
          Navigator.popUntil(context, (route) => route.isFirst);

          // Затем заменяем корневой экран на новый MainScreen
          // с передачей параметра для принудительного обновления
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
          debugPrint('✅ ImportGedcomScreen: Переход на MainScreen выполнен');
        } catch (e) {
          debugPrint('❌ ImportGedcomScreen: Ошибка навигации: $e');
          // Запасной вариант - прямой pushReplacement
          try {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
            debugPrint(
              '✅ ImportGedcomScreen: Переход на MainScreen (запасной)',
            );
          } catch (e2) {
            debugPrint(
              '❌ ImportGedcomScreen: Альтернативная навигация не удалась: $e2',
            );
            // Последний вариант - просто pop
            try {
              Navigator.pop(context);
            } catch (e3) {
              debugPrint(
                '❌ ImportGedcomScreen: Все варианты навигации не удались: $e3',
              );
            }
          }
        }
      }
    });
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
      debugPrint(
        '🔍 ImportGedcomScreen: Файл загружен, размер: ${content.length} символов',
      );

      if (content.isEmpty) {
        debugPrint('⚠️ ImportGedcomScreen: Файл пуст');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _message = '❌ Файл пуст';
            _isSuccess = false;
          });
        }
        return;
      }

      // Получаем treeId для импорта
      String treeId = 'default';
      try {
        final projectState = context.read<ProjectBloc>().state;
        if (projectState is ProjectsLoaded) {
          final defaultProject = projectState.projects.firstWhere(
            (p) => p.isDefault,
            orElse: () => projectState.projects.isNotEmpty
                ? projectState.projects.first
                : Project.empty(),
          );
          if (defaultProject.id.isNotEmpty) {
            treeId = defaultProject.id;
            _currentTreeId = treeId;
          }
        }
      } catch (e) {
        debugPrint('⚠️ ImportGedcomScreen: Не удалось получить treeId: $e');
      }

      debugPrint('🔍 ImportGedcomScreen: Начинаем импорт с treeId=$treeId...');
      final importResult = await _importUseCase.execute(
        content,
        treeId: treeId,
      );
      debugPrint('🔍 ImportGedcomScreen: Импорт завершен');

      importResult.fold(
        (failure) {
          debugPrint(
            '❌ ImportGedcomScreen: Ошибка импорта: ${failure.message}',
          );
          if (mounted) {
            setState(() {
              _isLoading = false;
              _message = '❌ Ошибка: ${failure.message}';
              _isSuccess = false;
            });
          }
        },
        (count) {
          debugPrint(
            '✅ ImportGedcomScreen: Успешно импортировано $count человек',
          );

          if (mounted) {
            setState(() {
              _isLoading = false;
              _message = '✅ Импортировано $count человек(а)';
              _isSuccess = true;
            });
            debugPrint(
              '🔍 ImportGedcomScreen: Состояние обновлено, _isSuccess = true',
            );
          }
        },
      );
    } catch (e, stackTrace) {
      debugPrint('❌ ImportGedcomScreen: Критическая ошибка: $e');
      debugPrint('❌ StackTrace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _message = '❌ Ошибка загрузки: ${e.toString()}';
          _isSuccess = false;
        });
      }
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
        if (mounted) {
          setState(() {
            _isLoading = false;
            _message = '❌ Выбор файла отменен';
            _isSuccess = false;
          });
        }
        return;
      }

      if (!file.path.toLowerCase().endsWith('.ged')) {
        debugPrint('⚠️ ImportGedcomScreen: Неверное расширение файла');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _message = '❌ Пожалуйста, выберите файл с расширением .ged';
            _isSuccess = false;
          });
        }
        return;
      }

      debugPrint('🔍 ImportGedcomScreen: Читаем содержимое файла...');
      final content = await file.readAsString();
      debugPrint(
        '🔍 ImportGedcomScreen: Файл прочитан, размер: ${content.length} символов',
      );

      if (content.isEmpty) {
        debugPrint('⚠️ ImportGedcomScreen: Файл пуст');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _message = '❌ Файл пуст';
            _isSuccess = false;
          });
        }
        return;
      }

      // Получаем treeId для импорта
      String treeId = 'default';
      try {
        final projectState = context.read<ProjectBloc>().state;
        if (projectState is ProjectsLoaded) {
          final defaultProject = projectState.projects.firstWhere(
            (p) => p.isDefault,
            orElse: () => projectState.projects.isNotEmpty
                ? projectState.projects.first
                : Project.empty(),
          );
          if (defaultProject.id.isNotEmpty) {
            treeId = defaultProject.id;
            _currentTreeId = treeId;
          }
        }
      } catch (e) {
        debugPrint('⚠️ ImportGedcomScreen: Не удалось получить treeId: $e');
      }

      debugPrint('🔍 ImportGedcomScreen: Начинаем импорт с treeId=$treeId...');
      final importResult = await _importUseCase.execute(
        content,
        treeId: treeId,
      );
      debugPrint('🔍 ImportGedcomScreen: Импорт завершен');

      importResult.fold(
        (failure) {
          debugPrint(
            '❌ ImportGedcomScreen: Ошибка импорта: ${failure.message}',
          );
          if (mounted) {
            setState(() {
              _isLoading = false;
              _message = '❌ Ошибка: ${failure.message}';
              _isSuccess = false;
            });
          }
        },
        (count) {
          debugPrint(
            '✅ ImportGedcomScreen: Успешно импортировано $count человек',
          );

          if (mounted) {
            setState(() {
              _isLoading = false;
              _message = '✅ Импортировано $count человек(а)';
              _isSuccess = true;
            });
          }
        },
      );
    } catch (e, stackTrace) {
      debugPrint('❌ ImportGedcomScreen: Критическая ошибка: $e');
      debugPrint('❌ StackTrace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _message = '❌ Ошибка: ${e.toString()}';
          _isSuccess = false;
        });
      }
    }
  }
}
