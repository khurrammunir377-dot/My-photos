import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/folder_model.dart';
import '../utils/constants.dart';

/// Handles folder persistence (SQLite) and Pro/Free tier gating.
class FolderService {
  static final FolderService _instance = FolderService._internal();
  factory FolderService() => _instance;
  FolderService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'my_photo_organizer.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE folders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            albumName TEXT NOT NULL UNIQUE,
            createdAt TEXT NOT NULL,
            photoCount INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  // ---------- Pro / Free tier ----------

  Future<bool> isProUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefIsPro) ?? false;
  }

  Future<void> setProUser(bool isPro) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefIsPro, isPro);
  }

  /// Returns true if the user is allowed to create another folder.
  Future<bool> canCreateFolder() async {
    final isPro = await isProUser();
    if (isPro) return true;
    final folders = await getAllFolders();
    return folders.length < AppConstants.freeTierFolderLimit;
  }

  // ---------- Folder CRUD ----------

  Future<List<FolderModel>> getAllFolders() async {
    final db = await database;
    final rows = await db.query('folders', orderBy: 'createdAt DESC');
    return rows.map((r) => FolderModel.fromMap(r)).toList();
  }

  /// Sanitizes a user-entered folder name into a safe album name for the device gallery.
  String buildAlbumName(String folderName) {
    final sanitized = folderName.trim().replaceAll(RegExp(r'[^a-zA-Z0-9 _-]'), '');
    return '${AppConstants.albumPrefix}_$sanitized';
  }

  Future<FolderModel> createFolder(String name) async {
    final allowed = await canCreateFolder();
    if (!allowed) {
      throw Exception(
          'Free plan allows only ${AppConstants.freeTierFolderLimit} folder. Upgrade to Pro for unlimited folders.');
    }
    final db = await database;
    final folder = FolderModel(
      name: name,
      albumName: buildAlbumName(name),
      createdAt: DateTime.now(),
    );
    final id = await db.insert('folders', folder.toMap());
    return FolderModel(
      id: id,
      name: folder.name,
      albumName: folder.albumName,
      createdAt: folder.createdAt,
    );
  }

  Future<void> incrementPhotoCount(int folderId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE folders SET photoCount = photoCount + 1 WHERE id = ?',
      [folderId],
    );
  }

  Future<void> deleteFolder(int folderId) async {
    final db = await database;
    await db.delete('folders', where: 'id = ?', whereArgs: [folderId]);
  }
}
