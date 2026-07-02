import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/di/injector.dart';
import 'package:nm_gen/domain/entities/tree_project.dart';
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
  final List<TreeProject> _treeProjects = [
    TreeProject(id: 'default', name: 'Мое древо'),
    TreeProject(id: 'kuznetsov', name: 'Кузнецовы'),
    TreeProject(id: 'petrov', name: 'Петровы'),
    // Здесь будут загружаться проекты из БД
  ];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      PersonsScreen(treeId: _selectedTreeId),
      AllFamiliesScreen(treeId: _selectedTreeId),
      TreeScreenWrapper(treeId: _selectedTreeId),
      const ImportExportScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onTreeSelected(String treeId, String treeName) {
    setState(() {
      _selectedTreeId = treeId;
      _selectedTreeName = treeName;
      // Обновляем экраны с новым treeId
      _screens = [
        PersonsScreen(treeId: _selectedTreeId),
        AllFamiliesScreen(treeId: _selectedTreeId),
        TreeScreenWrapper(treeId: _selectedTreeId),
        const ImportExportScreen(),
      ];
    });
    // Закрываем drawer
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
      drawer: TreeSelectorDrawer(
        currentTreeId: _selectedTreeId,
        projects: _treeProjects,
        onTreeSelected: _onTreeSelected,
        onAddTree: () => _showAddTreeDialog(context),
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

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Создать новое древо'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Название древа',
            hintText: 'Например: Ивановы',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final newProject = TreeProject(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                );
                setState(() {
                  _treeProjects.add(newProject);
                });
                Navigator.pop(context);
                _onTreeSelected(newProject.id, newProject.name);
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
