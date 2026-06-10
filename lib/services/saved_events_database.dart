import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite-backed store for "saved for later" events.
///
/// Kept separate from [StorageService] (which wraps shared_preferences):
/// saved events are a growing, queryable collection rather than a single
/// blob, so a small relational table is a better fit and demonstrates a
/// second persistence approach alongside shared_preferences.
class SavedEventsDatabase {
  static Database? _db;

  Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'anza_saved_events.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE saved_events (
            event_id TEXT PRIMARY KEY,
            saved_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> save(String eventId) async {
    final db = await _database;
    await db.insert(
      'saved_events',
      {'event_id': eventId, 'saved_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> unsave(String eventId) async {
    final db = await _database;
    await db.delete('saved_events', where: 'event_id = ?', whereArgs: [eventId]);
  }

  Future<Set<String>> loadSavedEventIds() async {
    final db = await _database;
    final rows = await db.query('saved_events');
    return rows.map((row) => row['event_id'] as String).toSet();
  }
}
