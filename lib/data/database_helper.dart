import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/todo.dart';

class DatabaseHelper {
  static const _dbName = 'todos.db';
  static const _dbVersion = 1;
  static const _tableName = 'todos';

  // Singleton
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
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        title      TEXT    NOT NULL,
        description TEXT   NOT NULL DEFAULT '',
        status     TEXT    NOT NULL DEFAULT 'pending',
        created_at TEXT    NOT NULL
      )
    ''');
  }

  // ── CRUD ────────────────────────────────────────────────────────────────────

  /// Insert a new Todo and return it with the DB-assigned id.
  Future<Todo> insertTodo(Todo todo) async {
    final db = await database;
    final id = await db.insert(
      _tableName,
      todo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return todo.copyWith(id: id);
  }

  /// Fetch all todos ordered by most-recently created first.
  Future<List<Todo>> getAllTodos() async {
    final db = await database;
    final rows = await db.query(
      _tableName,
      orderBy: 'created_at DESC',
    );
    return rows.map(Todo.fromMap).toList();
  }

  /// Fetch todos filtered by status.
  Future<List<Todo>> getTodosByStatus(TodoStatus status) async {
    final db = await database;
    final rows = await db.query(
      _tableName,
      where: 'status = ?',
      whereArgs: [status.value],
      orderBy: 'created_at DESC',
    );
    return rows.map(Todo.fromMap).toList();
  }

  /// Update title, description and status of an existing todo.
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

  /// Delete a todo by id.
  Future<void> deleteTodo(int id) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Close the database (call on app teardown if needed).
  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}
