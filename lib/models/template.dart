import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'form_field.dart';

part 'template.g.dart';

@JsonSerializable()
class Template {
  final String id;
  final String name;
  final String description;
  final List<FormFieldModel> fields;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageData; // Base64 encoded image data

  Template({
    String? id,
    required this.name,
    required this.description,
    required this.fields,
    this.imageData,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Template.fromJson(Map<String, dynamic> json) =>
      _$TemplateFromJson(json);

  Map<String, dynamic> toJson() => _$TemplateToJson(this);

  Template copyWith({
    String? name,
    String? description,
    List<FormFieldModel>? fields,
    String? imageData,
  }) {
    return Template(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      fields: fields ?? this.fields,
      imageData: imageData ?? this.imageData,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
