// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'form_field.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FormFieldModel _$FormFieldModelFromJson(Map<String, dynamic> json) =>
    FormFieldModel(
      id: json['id'] as String?,
      label: json['label'] as String,
      type: json['type'] as String,
      required: json['required'] as bool? ?? false,
      defaultValue: json['defaultValue'] as String?,
      order: (json['order'] as num).toInt(),
      validationRules: json['validationRules'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$FormFieldModelToJson(FormFieldModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'type': instance.type,
      'required': instance.required,
      'defaultValue': instance.defaultValue,
      'order': instance.order,
      'validationRules': instance.validationRules,
    };
