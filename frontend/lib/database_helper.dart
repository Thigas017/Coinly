import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  //Singleton instance to ensure a single database connection
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  //Returns existing database instance or initializes a new one
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('coins_vault.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, filePath);

    //Opens the database file
    //If it does not exist, a new clean database file will be created
    return await openDatabase(
      path,
      version: 2, // Incremented version to apply schema changes
      onCreate: _createDB,
      onUpgrade: _upgradeDB, // Handles migration for existing databases
    );
  }

  Future _createDB(Database db, int version) async {
    //Primary key uses TEXT to support UUID identifiers
    await db.execute('''
      CREATE TABLE coins (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        country TEXT NOT NULL,
        year INTEGER NOT NULL,
        faceValue REAL NOT NULL,
        imagePath TEXT,
        anomalies TEXT,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    //Safely adds the new column to existing local databases
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE coins ADD COLUMN anomalies TEXT;');
    }
  }

  //Inserts a coin into local storage
  Future<int> insertCoin(Map<String, dynamic> coin) async {
    final db = await instance.database;
    //ConflictAlgorithm.replace prevents duplicate primary keys
    return await db.insert(
      'coins',
      coin,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  //Retrieves all stored coins ordered alphabetically
  Future<List<Map<String, dynamic>>> getAllLocalCoins() async {
    final db = await instance.database;
    return await db.query('coins', orderBy: 'name ASC');
  }

  //Retrieves coins not yet synchronized with backend
  Future<List<Map<String, dynamic>>> getUnsyncedCoins() async {
    final db = await instance.database;
    return await db.query('coins', where: 'isSynced = ?', whereArgs: [0]);
  }

  //Marks a coin as synchronized
  Future<void> markAsSynced(String id) async {
    final db = await instance.database;
    await db.update('coins', {'isSynced': 1}, where: 'id = ?', whereArgs: [id]);
  }
}