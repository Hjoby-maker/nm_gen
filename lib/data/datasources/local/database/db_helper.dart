import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:injectable/injectable.dart';

@injectable
class DatabaseHelper {
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String path = join(directory.path, 'family_tree.db');

    return openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Создание таблиц
  Future<void> _onCreate(Database db, int version) async {
    // Таблица проектов
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        created_at INTEGER,
        updated_at INTEGER
      )
    ''');

    // Создаем проект по умолчанию
    await db.insert('projects', {
      'id': 'default',
      'name': 'Мое древо',
      'description': 'Основное генеалогическое древо',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });

    // Таблица Person
    await db.execute('''
      CREATE TABLE persons (
        id TEXT PRIMARY KEY,
        tree_id TEXT NOT NULL DEFAULT 'default',
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        middle_name TEXT,
        gender TEXT NOT NULL,
        birth_date INTEGER,
        death_date INTEGER,
        birth_place TEXT,
        death_place TEXT,
        occupation TEXT,
        biography TEXT,
        photo_urls TEXT,
        photo_path TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Индексы для persons
    await db.execute('''
      CREATE INDEX idx_persons_tree_id ON persons (tree_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_persons_name ON persons (first_name, last_name)
    ''');
    await db.execute('''
      CREATE INDEX idx_persons_created_at ON persons (created_at)
    ''');

    // Таблица Family
    await db.execute('''
      CREATE TABLE families (
        id TEXT PRIMARY KEY,
        tree_id TEXT NOT NULL DEFAULT 'default',
        husband_id TEXT,
        wife_id TEXT,
        children_ids TEXT,
        marriage_date INTEGER,
        divorce_date INTEGER,
        marriage_place TEXT,
        notes TEXT,
        FOREIGN KEY (husband_id) REFERENCES persons (id) ON DELETE SET NULL,
        FOREIGN KEY (wife_id) REFERENCES persons (id) ON DELETE SET NULL
      )
    ''');

    // Индексы для families
    await db.execute('''
      CREATE INDEX idx_families_tree_id ON families (tree_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_families_husband ON families (husband_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_families_wife ON families (wife_id)
    ''');
  }

  /// Обновление базы данных (миграции)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      // Создаем таблицу проектов
      await db.execute('''
        CREATE TABLE projects (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          created_at INTEGER,
          updated_at INTEGER
        )
      ''');

      // Проверяем, существует ли проект по умолчанию
      final existing = await db.query(
        'projects',
        where: 'id = ?',
        whereArgs: ['default'],
      );
      if (existing.isEmpty) {
        await db.insert('projects', {
          'id': 'default',
          'name': 'Мое древо',
          'description': 'Основное генеалогическое древо',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
      }
    }
  }

  /// Вспомогательный метод для работы с транзакциями
  Future<T> transaction<T>(Future<T> Function(Transaction db) action) async {
    final Database db = await database;
    return db.transaction(action);
  }

  /// Закрыть базу данных
  Future<void> close() async {
    final Database? db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
