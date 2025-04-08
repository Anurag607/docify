import 'package:docify/services/form_entry.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../models/template.dart';
import '../models/form_field.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'docify.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createDatabase(db, version);
        await _insertDefaultTemplate(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add form_entries table if upgrading from version 1
          await db.execute('''
            CREATE TABLE form_entries(
              id TEXT PRIMARY KEY,
              template_id TEXT NOT NULL,
              field_values TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              FOREIGN KEY (template_id) REFERENCES templates (id) ON DELETE CASCADE
            )
          ''');
        }
      },
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE templates(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE form_fields(
        id TEXT PRIMARY KEY,
        template_id TEXT NOT NULL,
        label TEXT NOT NULL,
        type TEXT NOT NULL,
        required INTEGER NOT NULL,
        default_value TEXT,
        order_index INTEGER NOT NULL,
        validation_rules TEXT,
        FOREIGN KEY (template_id) REFERENCES templates (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE form_entries(
        id TEXT PRIMARY KEY,
        template_id TEXT NOT NULL,
        field_values TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (template_id) REFERENCES templates (id) ON DELETE CASCADE
      )
    ''');
  }

  // Existing methods...

  Future<void> _insertDefaultTemplate(Database db) async {
    final templateId = const Uuid().v4();
    final now = DateTime.now();

    // Insert template
    await db.insert(
      'templates',
      {
        'id': templateId,
        'name': 'Casual Entry Permit',
        'description': 'Template for Casual Entry Permit',
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      },
    );

    // Field definitions based on the official pass
    final fieldDefinitions = [
      {'label': 'Name of visitor', 'type': 'text', 'required': true},
      {'label': 'Mobile No.', 'type': 'phone', 'required': true},
      {'label': 'Material carried in', 'type': 'text', 'required': false},
      {'label': 'Officer Name', 'type': 'text', 'required': true},
      {'label': 'PVC Details', 'type': 'text', 'required': false},
      {'label': 'Address', 'type': 'text', 'required': true},
      {'label': 'ID Details', 'type': 'text', 'required': true},
      {'label': 'Purpose', 'type': 'text', 'required': true},
      {'label': 'Place', 'type': 'text', 'required': true},
      {'label': 'Escorting staff', 'type': 'text', 'required': false},
      {'label': 'Visitor Photo', 'type': 'image', 'required': true},
    ];

    // Insert each field
    for (int i = 0; i < fieldDefinitions.length; i++) {
      final field = fieldDefinitions[i];
      await db.insert(
        'form_fields',
        {
          'id': const Uuid().v4(),
          'template_id': templateId,
          'label': field['label'],
          'type': field['type'],
          'required': field['required'] == true ? 1 : 0,
          'default_value': '',
          'order_index': i,
          'validation_rules': null,
        },
      );
    }

    print('Default template inserted with ID: $templateId');
  }

  Future<void> ensureDefaultTemplate() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM templates'));

    if (count == 0) {
      await _insertDefaultTemplate(db);
      print('Inserted default template because no templates existed');
    }
  }

  Future<List<Template>> getAllTemplates() async {
    final db = await database;
    final List<Map<String, dynamic>> templateMaps = await db.query('templates');

    return Future.wait(templateMaps.map((templateMap) async {
      final List<Map<String, dynamic>> fieldMaps = await db.query(
        'form_fields',
        where: 'template_id = ?',
        whereArgs: [templateMap['id']],
        orderBy: 'order_index',
      );

      final fields = fieldMaps
          .map((fieldMap) => FormFieldModel(
                id: fieldMap['id'],
                label: fieldMap['label'],
                type: fieldMap['type'],
                required: fieldMap['required'] == 1,
                defaultValue: fieldMap['default_value'],
                order: fieldMap['order_index'],
                validationRules: fieldMap['validation_rules'] != null
                    ? Map<String, dynamic>.from(
                        fieldMap['validation_rules'] as Map<String, dynamic>)
                    : null,
              ))
          .toList();

      return Template(
        id: templateMap['id'],
        name: templateMap['name'],
        description: templateMap['description'],
        fields: fields,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(templateMap['created_at']),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(templateMap['updated_at']),
      );
    }));
  }

  Future<String> saveTemplate(Template template) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'templates',
        {
          'id': template.id,
          'name': template.name,
          'description': template.description,
          'created_at': template.createdAt.millisecondsSinceEpoch,
          'updated_at': template.updatedAt.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (var field in template.fields) {
        await txn.insert(
          'form_fields',
          {
            'id': field.id,
            'template_id': template.id,
            'label': field.label,
            'type': field.type,
            'required': field.required ? 1 : 0,
            'default_value': field.defaultValue,
            'order_index': field.order,
            'validation_rules': field.validationRules?.toString(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    return template.id;
  }

  Future<Template?> getTemplate(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> templateMaps = await db.query(
      'templates',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (templateMaps.isEmpty) return null;

    final templateMap = templateMaps.first;
    final List<Map<String, dynamic>> fieldMaps = await db.query(
      'form_fields',
      where: 'template_id = ?',
      whereArgs: [id],
      orderBy: 'order_index',
    );

    final fields = fieldMaps
        .map((fieldMap) => FormFieldModel(
              id: fieldMap['id'],
              label: fieldMap['label'],
              type: fieldMap['type'],
              required: fieldMap['required'] == 1,
              defaultValue: fieldMap['default_value'],
              order: fieldMap['order_index'],
              validationRules: fieldMap['validation_rules'] != null
                  ? Map<String, dynamic>.from(
                      fieldMap['validation_rules'] as Map<String, dynamic>)
                  : null,
            ))
        .toList();

    return Template(
      id: templateMap['id'],
      name: templateMap['name'],
      description: templateMap['description'],
      fields: fields,
      createdAt: DateTime.fromMillisecondsSinceEpoch(templateMap['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(templateMap['updated_at']),
    );
  }

  Future<void> deleteTemplate(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'form_fields',
        where: 'template_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'templates',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // Form entry methods for DatabaseService class
  Future<String> saveFormEntry(FormEntry entry) async {
    final db = await database;

    // First, check if we need to prune old entries (keeping only the most recent 20)
    await _pruneOldEntries(db, entry.templateId);

    await db.insert(
      'form_entries',
      {
        'id': entry.id,
        'template_id': entry.templateId,
        'field_values': jsonEncode(entry.fieldValues),
        'created_at': entry.createdAt.millisecondsSinceEpoch,
      },
    );
    return entry.id;
  }

  Future<void> _pruneOldEntries(Database db, String templateId) async {
    // Get the count of entries for this template
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM form_entries WHERE template_id = ?',
      [templateId],
    ));

    if (count != null && count >= 20) {
      // Find IDs of entries to keep (the 19 most recent ones)
      final entriesToKeep = await db.query(
        'form_entries',
        columns: ['id'],
        where: 'template_id = ?',
        whereArgs: [templateId],
        orderBy: 'created_at DESC',
        limit: 19,
      );

      final keepIds = entriesToKeep.map((e) => e['id'] as String).toList();

      // Delete all entries except the ones we want to keep
      if (keepIds.isNotEmpty) {
        final placeholders = List.filled(keepIds.length, '?').join(',');
        await db.rawDelete(
          'DELETE FROM form_entries WHERE template_id = ? AND id NOT IN ($placeholders)',
          [templateId, ...keepIds],
        );
      }
    }
  }

  Future<List<FormEntry>> getRecentEntries(String templateId,
      {int limit = 20}) async {
    final db = await database;
    final List<Map<String, dynamic>> entryMaps = await db.query(
      'form_entries',
      where: 'template_id = ?',
      whereArgs: [templateId],
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return entryMaps.map((map) {
      return FormEntry(
        id: map['id'],
        templateId: map['template_id'],
        fieldValues: Map<String, String>.from(jsonDecode(map['field_values'])),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      );
    }).toList();
  }

  Future<List<String>> getSuggestions(String templateId, String fieldLabel,
      {int limit = 5}) async {
    // Just call getRecentEntries and process the results
    final entries = await getRecentEntries(templateId);

    // Extract unique values for the specific field
    final suggestions = <String>{};
    for (var entry in entries) {
      final value = entry.fieldValues[fieldLabel];
      if (value != null && value.isNotEmpty) {
        suggestions.add(value);
      }

      if (suggestions.length >= limit) {
        break;
      }
    }

    return suggestions.toList();
  }
}
// This code is a Dart class that provides methods to interact with a SQLite database.
// It includes methods to initialize the database, create tables, insert default data,
// and perform CRUD operations on templates and form entries.
// The class uses the sqflite package for database operations and uuid package for generating unique IDs.
// The database schema includes tables for templates, form fields, and form entries.
// The class also includes methods to ensure a default template exists, save templates and form entries,
// retrieve templates and form entries, delete templates, and get suggestions for form fields based on recent entries.
// The code is structured to be reusable and maintainable, with clear separation of concerns.
