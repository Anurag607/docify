import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'form_field.g.dart';

@JsonSerializable()
class FormFieldModel {
  final String id;
  final String label;
  final String type;
  final bool required;
  final String? defaultValue;
  final int order;
  final Map<String, dynamic>? validationRules;

  FormFieldModel({
    String? id,
    required this.label,
    required this.type,
    this.required = false,
    this.defaultValue,
    required this.order,
    this.validationRules,
  }) : id = id ?? const Uuid().v4();

  factory FormFieldModel.fromJson(Map<String, dynamic> json) =>
      _$FormFieldModelFromJson(json);

  Map<String, dynamic> toJson() => _$FormFieldModelToJson(this);

  FormFieldModel copyWith({
    String? label,
    String? type,
    bool? required,
    String? defaultValue,
    int? order,
    Map<String, dynamic>? validationRules,
  }) {
    return FormFieldModel(
      id: id,
      label: label ?? this.label,
      type: type ?? this.type,
      required: required ?? this.required,
      defaultValue: defaultValue ?? this.defaultValue,
      order: order ?? this.order,
      validationRules: validationRules ?? this.validationRules,
    );
  }
}
