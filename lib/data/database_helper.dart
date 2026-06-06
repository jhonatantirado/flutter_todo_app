import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/todo.dart';

class DatabaseHelper {
  static const _dbName = 'todos.db';
  static const _dbVersion = 2; // bumped from 1 → 2 for target_date migration
  static const _tableName = 'todos';

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Called once on a fresh install.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        title       TEXT    NOT NULL,
        description TEXT    NOT NULL DEFAULT '',
        status      TEXT    NOT NULL DEFAULT 'pending',
        target_date TEXT,
        created_at  TEXT    NOT NULL
      )
    ''');
  }

  // Called when an existing install upgrades from an older schema version.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Version 1 → 2: add the target_date column.
      // Existing rows get NULL automatically (no target date set).
      await db.execute(
        'ALTER TABLE $_tableName ADD COLUMN target_date TEXT',
      );
    }
  }

  Future<Todo> insertTodo(Todo todo) async {
    final db = await database;
    final id = await db.insert(
      _tableName,
      todo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return todo.copyWith(id: id);
  }

  Future<List<Todo>> getAllTodos() async {
    final db = await database;
    final rows = await db.query(_tableName, orderBy: 'created_at DESC');
    return rows.map(Todo.fromMap).toList();
  }

  Future<void> updateTodo(Todo todo) async {
    assert(todo.id != null, 'Cannot update a Todo without an id');
    final db = await database;
    await db.update(
      _tableName,
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  Future<void> deleteTodo(int id) async {
    final db = await database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}