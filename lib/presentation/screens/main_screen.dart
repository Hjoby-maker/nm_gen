import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/di/injector.dart';
import 'package:nm_gen/domain/entities/project.dart';
import 'package:nm_gen/presentation/blocs/project/project_bloc.dart';
import 'package:nm_gen/presentation/blocs/project/project_event.dart';
import 'package:nm_gen/presentation/blocs/project/project_state.dart';
import 'package:nm_gen/presentation/blocs/person/person_bloc.dart';
import 'package:nm_gen/presentation/blocs/person/person_event.dart';
import 'package:nm_gen/presentation/screens/all_families_screen.dart';
import 'package:nm_gen/presentation/screens/export_gedcom_screen.dart';
import 'package:nm_gen/presentation/screens/import_gedcom_screen.dart';
import 'package:nm_gen/presentation/screens/persons_screen.dart';
import 'package:nm_gen/presentation/screens/settings_screen.dart';
import 'package:nm_gen/presentation/screens/tree_screen.dart';
import 'package:nm_gen/presentation/widgets/tree_selector_drawer.dart';

/// Основной экран приложения с нижней навигацией
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String _selectedTreeId = 'default';
  String _selectedTreeName = 'Мое древо';

  late final ProjectBloc _projectBloc;
  late final PersonBloc _personBloc;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _projectBloc = getIt<ProjectBloc>();
    _personBloc = getIt<PersonBloc>();

    _projectBloc.add(LoadProjectsEvent());

    _buildScreens();
  }

  /// Создает экраны с текущим treeId
  void _buildScreens() {
    _screens = [
      PersonsScreen(
        key: ValueKey('persons_$_selectedTreeId'), // <-- Ключ для пересоздания
        treeId: _selectedTreeId,
      ),
      AllFamiliesScreen(
        key: ValueKey('families_$_selectedTreeId'),
        treeId: _selectedTreeId,
      ),
      TreeScreenWrapper(
        key: ValueKey('tree_$_selectedTreeId'),
        treeId: _selectedTreeId,
      ),
      const ImportExportScreen(key: ValueKey('import_export')),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onTreeSelected(String treeId, String treeName) {
    // Обновляем состояние
    _selectedTreeId = treeId;
    _selectedTreeName = treeName;

    // Пересоздаем экраны с новым treeId
    _buildScreens();

    // Обновляем PersonBloc с новым treeId
    _personBloc.add(LoadPersonsEvent(treeId: treeId));

    // Обновляем состояние UI
    setState(() {});

    // Закрываем drawer
    Navigator.pop(context);

    // Обновляем выбранный проект в ProjectBloc
    _projectBloc.add(SelectProjectEvent(treeId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _projectBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.family_restroom, size: 28),
              const SizedBox(width: 8),
              Text(_selectedTreeName),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'v1.0',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            // Кнопка системных настроек
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
              tooltip: 'Настройки',
            ),
            // Кнопка авторизации (заглушка)
            IconButton(
              icon: const Icon(Icons.account_circle),
              onPressed: () {
                _showAuthDialog(context);
              },
              tooltip: 'Войти',
            ),
          ],
        ),
        // Drawer для выбора древа
        drawer: BlocBuilder<ProjectBloc, ProjectState>(
          builder: (context, state) {
            if (state is ProjectsLoaded) {
              return TreeSelectorDrawer(
                currentTreeId: _selectedTreeId,
                projects: state.projects,
                onTreeSelected: _onTreeSelected,
                onAddTree: () => _showAddTreeDialog(context),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        body: IndexedStack(index: _selectedIndex, children: _screens),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Персоны'),
            BottomNavigationBarItem(
              icon: Icon(Icons.family_restroom),
              label: 'Семьи',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_tree),
              label: 'Древо',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.file_copy),
              label: 'Импорт/Экспорт',
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // ДИАЛОГИ
  // =========================================================================

  void _showAuthDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Авторизация'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Функция авторизации в разработке',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showAddTreeDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Создать новое древо'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Название древа *',
                hintText: 'Например: Ивановы',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                hintText: 'Краткое описание проекта',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final project = Project.create(
                  name: nameController.text,
                  description: descriptionController.text.isNotEmpty
                      ? descriptionController.text
                      : null,
                );
                _projectBloc.add(AddProjectEvent(project));
                Navigator.pop(context);

                // Выбираем новый проект автоматически
                _projectBloc.stream.listen((state) {
                  if (state is ProjectsLoaded) {
                    final newProject = state.projects.firstWhere(
                      (p) => p.name == project.name,
                      orElse: () => state.projects.first,
                    );
                    _onTreeSelected(newProject.id, newProject.name);
                  }
                }).cancel();
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// ВСПОМОГАТЕЛЬНЫЕ КЛАССЫ И ОБЕРТКИ
// =========================================================================

/// Обертка для TreeScreen с передачей treeId
class TreeScreenWrapper extends StatelessWidget {
  final String treeId;

  const TreeScreenWrapper({super.key, required this.treeId});

  @override
  Widget build(BuildContext context) {
    return TreeScreen(rootPersonId: 'default_root', treeId: treeId);
  }
}

/// Экран импорта/экспорта
class ImportExportScreen extends StatelessWidget {
  const ImportExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Импорт / Экспорт'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.upload_file), text: 'Импорт'),
              Tab(icon: Icon(Icons.download), text: 'Экспорт'),
            ],
          ),
        ),
        body: TabBarView(
          children: [const ImportGedcomScreen(), const ExportGedcomScreen()],
        ),
      ),
    );
  }
}
