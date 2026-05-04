import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseConnection {
  static final DatabaseConnection _instance =
      DatabaseConnection._internal();

  factory DatabaseConnection() => _instance;

  DatabaseConnection._internal();

  Database? _db;

  /// Return database instance
  Future<Database> get db async {
    _db ??= await openDb();
    return _db!;
  }

  Future<Database> openDb() async {

    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, 'smartbill.db');

    return _db = await openDatabase(
      path,
      version: 2, // IMPORTANT: increase version

      onCreate: (Database db, int version) async {

        await db.execute('''
          CREATE TABLE IF NOT EXISTS xml_files (
            _id INTEGER PRIMARY KEY AUTOINCREMENT,
            xml_text TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS pdfs (
            _id INTEGER PRIMARY KEY AUTOINCREMENT,
            cufe TEXT UNIQUE,
            nit TEXT,
            date TEXT,
            total_amount REAL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS colombian_bill (
            _id INTEGER PRIMARY KEY AUTOINCREMENT,
            bill_number TEXT NOT NULL,
            company_name TEXT, -- NEW COLUMN
            date TEXT,
            time TEXT,
            nit TEXT,
            customer_id TEXT,
            amount_before_iva TEXT,
            iva TEXT,
            other_tax TEXT,
            total_amount TEXT,
            cufe TEXT,
            dian_link TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS peruvian_bill (
            _id INTEGER PRIMARY KEY AUTOINCREMENT,
            ruc_company TEXT NOT NULL,
            receipt_id TEXT,
            code_start TEXT,
            code_end TEXT,
            igv TEXT,
            amount TEXT,
            date TEXT,
            percentage TEXT,
            ruc_customer TEXT,
            summery TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS transactions (
            _id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId TEXT NOT NULL,
            amount REAL,
            date TEXT,
            category TEXT,
            description TEXT,
            type TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS favorites (
            _id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId TEXT NOT NULL,
            cryptoId TEXT UNIQUE
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS ocr_receipts (
            _id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId TEXT NOT NULL,
            image TEXT,
            extracted_text TEXT NOT NULL,
            date TEXT NOT NULL,
            company TEXT,
            nit TEXT NOT NULL,
            user_document TEXT NOT NULL,
            amount REAL NOT NULL
          )
        ''');
      },

      /// MIGRATIONS
      onUpgrade: (Database db, int oldVersion, int newVersion) async {

        // Version 1 -> 2
        if (oldVersion < 2) {

          await db.execute('''
            ALTER TABLE colombian_bill
            ADD COLUMN company_name TEXT
          ''');

        }
      },

      onDowngrade: onDatabaseDowngradeDelete,
    );
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  Future deleteDb() async {

    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, 'smartbill.db');

    await deleteDatabase(path);

    print("Database deleted");
  }
}