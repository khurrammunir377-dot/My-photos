import 'package:sqflite/sqflite.dart';
import '../models/person_model.dart';
import 'folder_service.dart';

/// Stores named "Person" groups - each one a user-curated set of photo IDs.
/// Reuses the same SQLite database as FolderService (via its shared connection).
class PeopleService {
  static final PeopleService _instance = PeopleService._internal();
  factory PeopleService() => _instance;
  PeopleService._internal();

  Future<Database> get _db async {
    final db = await FolderService().database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS people (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        coverPhotoId TEXT NOT NULL,
        photoIds TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
    return db;
  }

  Future<List<PersonModel>> getAllPeople() async {
    final db = await _db;
    final rows = await db.query('people', orderBy: 'createdAt DESC');
    return rows.map((r) => PersonModel.fromMap(r)).toList();
  }

  Future<PersonModel> createPerson(String name, String coverPhotoId, List<String> photoIds) async {
    final db = await _db;
    final person = PersonModel(
      name: name,
      coverPhotoId: coverPhotoId,
      photoIds: photoIds,
      createdAt: DateTime.now(),
    );
    final id = await db.insert('people', person.toMap());
    return PersonModel(
      id: id,
      name: person.name,
      coverPhotoId: person.coverPhotoId,
      photoIds: person.photoIds,
      createdAt: person.createdAt,
    );
  }

  Future<void> addPhotosToPerson(int personId, List<String> newPhotoIds) async {
    final db = await _db;
    final rows = await db.query('people', where: 'id = ?', whereArgs: [personId]);
    if (rows.isEmpty) return;
    final existing = PersonModel.fromMap(rows.first);
    final merged = {...existing.photoIds, ...newPhotoIds}.toList();
    await db.update(
      'people',
      {'photoIds': merged.join(',')},
      where: 'id = ?',
      whereArgs: [personId],
    );
  }

  Future<void> renamePerson(int personId, String newName) async {
    final db = await _db;
    await db.update('people', {'name': newName}, where: 'id = ?', whereArgs: [personId]);
  }

  Future<void> deletePerson(int personId) async {
    final db = await _db;
    await db.delete('people', where: 'id = ?', whereArgs: [personId]);
  }

  /// Returns the set of photo IDs already assigned to *any* person, so the
  /// scan screen can skip faces the user has already grouped.
  Future<Set<String>> getAllAssignedPhotoIds() async {
    final people = await getAllPeople();
    final all = <String>{};
    for (final p in people) {
      all.addAll(p.photoIds);
    }
    return all;
  }
}
