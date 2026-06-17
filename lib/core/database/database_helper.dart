import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('desp_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const realType = 'REAL NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const integerNullable = 'INTEGER';

    await db.execute('''
      CREATE TABLE transactions (
        id $textType PRIMARY KEY,
        title $textType,
        amount $realType,
        date $textType,
        type $textType,
        category $textType,
        paymentMethod $textType,
        isPending $integerType,
        isPaid $integerType,
        installmentNumber $integerNullable,
        totalInstallments $integerNullable,
        installmentParentId $textNullable,
        recurrenceParentId $textNullable,
        ownerId $textNullable,
        familyId $textNullable,
        isShared $integerNullable,
        description $textNullable,
        groupId $textNullable
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        uid TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        email TEXT NOT NULL,
        password TEXT NOT NULL,
        familyId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE current_session (
        uid TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        email TEXT NOT NULL,
        familyId TEXT
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE users (
          uid TEXT PRIMARY KEY,
          username TEXT NOT NULL,
          email TEXT NOT NULL,
          password TEXT NOT NULL,
          familyId TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE current_session (
          uid TEXT PRIMARY KEY,
          username TEXT NOT NULL,
          email TEXT NOT NULL,
          familyId TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE transactions ADD COLUMN ownerId TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN familyId TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN isShared INTEGER DEFAULT 0');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE transactions ADD COLUMN description TEXT');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE transactions ADD COLUMN groupId TEXT');
      await db.execute('UPDATE transactions SET groupId = recurrenceParentId WHERE recurrenceParentId IS NOT NULL');
      await db.execute('UPDATE transactions SET groupId = installmentParentId WHERE installmentParentId IS NOT NULL');
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
