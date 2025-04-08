// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'form_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FormEntry _$FormEntryFromJson(Map<String, dynamic> json) => FormEntry(
      id: json['id'] as String?,
      templateId: json['templateId'] as String,
      fieldValues: Map<String, String>.from(json['fieldValues'] as Map),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$FormEntryToJson(FormEntry instance) => <String, dynamic>{
      'id': instance.id,
      'templateId': instance.templateId,
      'fieldValues': instance.fieldValues,
      'createdAt': instance.createdAt.toIso8601String(),
    };
