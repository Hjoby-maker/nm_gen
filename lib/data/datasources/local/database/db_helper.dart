import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Получаем путь к директории приложения
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'family_tree.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Создание таблиц
  Future<void> _onCreate(Database db, int version) async {
    // Таблица Person
    await db.execute('''
      CREATE TABLE persons (
        id TEXT PRIMARY KEY,
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
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Создаем индексы для ускорения поиска
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

    // Создаем индексы для семей
    await db.execute('''
      CREATE INDEX idx_families_husband ON families (husband_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_families_wife ON families (wife_id)
    ''');
  }

  /// Обновление базы данных (миграции)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Пример миграции для версии 2
      // await db.execute('ALTER TABLE persons ADD COLUMN new_field TEXT');
    }
  }

  /// Вспомогательный метод для работы с транзакциями
  Future<T> transaction<T>(Future<T> Function(Transaction db) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  /// Закрыть базу данных
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
