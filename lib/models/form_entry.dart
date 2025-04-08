import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'form_entry.g.dart';

@JsonSerializable()
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

  factory FormEntry.fromJson(Map<String, dynamic> json) =>
      _$FormEntryFromJson(json);

  Map<String, dynamic> toJson() => _$FormEntryToJson(this);

  FormEntry copyWith({
    String? templateId,
    Map<String, String>? fieldValues,
    DateTime? createdAt,
  }) {
    return FormEntry(
      id: id,
      templateId: templateId ?? this.templateId,
      fieldValues: fieldValues ?? this.fieldValues,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
