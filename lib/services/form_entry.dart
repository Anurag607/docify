import 'package:uuid/uuid.dart';

class FormEntry {
  final String id;
  final String templateId;
  final Map<String, String> fieldValues;
  final DateTime createdAt;

  FormEntry({
    String? id,
    required this.templateId,
    required this.fieldValues,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'template_id': templateId,
      'field_values': fieldValues,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory FormEntry.fromMap(Map<String, dynamic> map) {
    return FormEntry(
      id: map['id'],
      templateId: map['template_id'],
      fieldValues: Map<String, String>.from(map['field_values']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }
}
