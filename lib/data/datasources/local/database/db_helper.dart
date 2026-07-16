import 'dart:async';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

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
      version: 7,
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
        updated_at INTEGER,
        is_default INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Создаем проект по умолчанию
    await db.insert('projects', <String, Object>{
      'id': 'default',
      'name': 'Мое древо',
      'description': 'Основное генеалогическое древо',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
      'is_default': 1,
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

    // Таблица событий
    await db.execute('''
      CREATE TABLE events (
        id TEXT PRIMARY KEY,
        person_id TEXT NOT NULL,
        tree_id TEXT NOT NULL DEFAULT 'default',
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        start_date INTEGER,
        end_date INTEGER,
        place TEXT,
        notes TEXT,
        created_at INTEGER,
        updated_at INTEGER,
        FOREIGN KEY (person_id) REFERENCES persons (id) ON DELETE CASCADE
      )
    ''');

    // Индексы для событий
    await db.execute('''
      CREATE INDEX idx_events_person_id ON events (person_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_events_tree_id ON events (tree_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_events_type ON events (type)
    ''');

    // Таблица медиа-вложений (фото/файлы, привязанные к Person или Event)
    await _createMediaAttachmentsTable(db);
  }

  /// Создаёт таблицу media_attachments и её индексы.
  /// Вынесено в отдельный метод, т.к. используется и в _onCreate
  /// (новые установки), и в _onUpgrade (существующие базы без этой таблицы).
  Future<void> _createMediaAttachmentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE media_attachments (
        id TEXT PRIMARY KEY,
        person_id TEXT,
        event_id TEXT,
        file_name TEXT NOT NULL,
        local_path TEXT NOT NULL,
        remote_url TEXT,
        mime_type TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        is_primary INTEGER NOT NULL DEFAULT 0,
        thumbnail_path TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER,
        FOREIGN KEY (person_id) REFERENCES persons (id) ON DELETE CASCADE,
        FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_media_person_id ON media_attachments (person_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_media_event_id ON media_attachments (event_id)
    ''');
    // Отдельный индекс под самый частый запрос из лога:
    // "WHERE person_id = ? AND is_primary = 1"
    await db.execute('''
      CREATE INDEX idx_media_person_primary ON media_attachments (person_id, is_primary)
    ''');
  }

  /// Обновление базы данных (миграции)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Миграция для версии 4 — добавляем колонку is_default
    if (oldVersion < 4) {
      try {
        // Проверяем существование таблицы projects
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='projects'",
        );

        if (tables.isNotEmpty) {
          final columns = await db.rawQuery('PRAGMA table_info(projects)');
          final hasIsDefault = columns.any(
            (col) => col['name'] == 'is_default',
          );

          if (!hasIsDefault) {
            await db.execute(
              'ALTER TABLE projects ADD COLUMN is_default INTEGER NOT NULL DEFAULT 0',
            );
            await db.update(
              'projects',
              <String, int>{'is_default': 1},
              where: 'id = ?',
              whereArgs: <String>['default'],
            );
          }
        }
      } catch (e) {
        print('⚠️ Ошибка миграции is_default: $e');
      }
    }

    // Миграция для версии 6 — создаем таблицу events
    if (oldVersion < 6) {
      try {
        // Проверяем, существует ли таблица events
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='events'",
        );

        if (tables.isEmpty) {
          // Создаем таблицу событий
          await db.execute('''
            CREATE TABLE events (
              id TEXT PRIMARY KEY,
              person_id TEXT NOT NULL,
              tree_id TEXT NOT NULL DEFAULT 'default',
              type TEXT NOT NULL,
              title TEXT NOT NULL,
              description TEXT,
              start_date INTEGER,
              end_date INTEGER,
              place TEXT,
              notes TEXT,
              created_at INTEGER,
              updated_at INTEGER,
              FOREIGN KEY (person_id) REFERENCES persons (id) ON DELETE CASCADE
            )
          ''');

          // Создаем индексы для событий
          await db.execute('''
            CREATE INDEX idx_events_person_id ON events (person_id)
          ''');
          await db.execute('''
            CREATE INDEX idx_events_tree_id ON events (tree_id)
          ''');
          await db.execute('''
            CREATE INDEX idx_events_type ON events (type)
          ''');
        }
      } catch (e) {
        print('⚠️ Ошибка миграции events: $e');
      }
    }

    // Миграция для версии 7 — создаём таблицу media_attachments.
    // Без неё у всех, кто уже открывал приложение раньше (база создана
    // на version < 7), таблицы физически нет, и любой запрос к ней падает
    // с "no such table: media_attachments" - именно это было в логах.
    if (oldVersion < 7) {
      try {
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='media_attachments'",
        );

        if (tables.isEmpty) {
          await _createMediaAttachmentsTable(db);
        }
      } catch (e) {
        print('⚠️ Ошибка миграции media_attachments: $e');
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
