import 'dart:io';

import 'package:docify/services/capture_image.dart';
import 'package:docify/screens/form_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../models/template.dart';
import '../models/form_field.dart';

class FormFillScreen extends StatefulWidget {
  final Template template;

  const FormFillScreen({super.key, required this.template});

  @override
  State<FormFillScreen> createState() => _FormFillScreenState();
}

class _FormFillScreenState extends State<FormFillScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  File? _pickedImage;

  Future captureVisitorPhoto() async {
    final File? imageFile = await ImagePickerService.pickImage(context);

    if (imageFile != null) {
      setState(() {
        _pickedImage = imageFile;
      });
      print('Image captured: ${imageFile.path}');
    } else {
      print('No image captured.');
    }
  }

  IconData _getFieldIcon(String fieldType) {
    switch (fieldType) {
      case 'text':
        return Icons.text_fields;
      case 'number':
        return Icons.numbers;
      case 'email':
        return Icons.email_outlined;
      case 'phone':
        return Icons.phone_outlined;
      case 'date':
        return Icons.calendar_today_outlined;
      default:
        return Icons.text_fields;
    }
  }

  TextInputType _getKeyboardType(String fieldType) {
    switch (fieldType) {
      case 'number':
        return TextInputType.number;
      case 'email':
        return TextInputType.emailAddress;
      case 'phone':
        return TextInputType.phone;
      default:
        return TextInputType.text;
    }
  }

  Widget _buildFormField(BuildContext context, FormFieldModel field) {
    final decoration = InputDecoration(
      labelText: field.label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      prefixIcon: Icon(
        _getFieldIcon(field.type),
        color: Theme.of(context).colorScheme.primary,
      ),
      border: OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2.0,
        ),
      ),
    );

    switch (field.type) {
      case 'text':
        return FormBuilderTextField(
          name: field.id,
          decoration: decoration,
          keyboardType: TextInputType.text,
          validator: field.required
              ? (value) =>
                  value?.isEmpty == true ? '${field.label} is required' : null
              : null,
          initialValue: field.defaultValue,
        );
      case 'number':
        return FormBuilderTextField(
          name: field.id,
          decoration: decoration,
          keyboardType: TextInputType.number,
          validator: field.required
              ? FormBuilderValidators.compose([
                  (value) => value?.isEmpty == true
                      ? '${field.label} is required'
                      : null,
                  FormBuilderValidators.numeric(
                      errorText: '${field.label} must be a number'),
                ])
              : FormBuilderValidators.numeric(
                  errorText: '${field.label} must be a number'),
          initialValue: field.defaultValue,
        );
      case 'image':
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade800),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Row(
            children: [
              Icon(
                Icons.camera_alt,
                color: const Color(0xFFCDBBFC),
              ),
              const SizedBox(width: 10),
              Text(
                'Visitor Photo',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16.0,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: captureVisitorPhoto,
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: const Text(
                  'Capture Image',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
        );
      // Other cases remain the same with the updated decoration
      default:
        return FormBuilderTextField(
          name: field.id,
          decoration: decoration,
          keyboardType: _getKeyboardType(field.type),
          validator: field.required
              ? (value) =>
                  value?.isEmpty == true ? '${field.label} is required' : null
              : null,
          initialValue: field.defaultValue,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.name),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.preview_outlined, color: Colors.white),
              label: const Text(
                'Preview Document',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade800,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onPressed: () {
                if (_pickedImage == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please capture the required image2'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                  return;
                }

                if (_formKey.currentState?.saveAndValidate() ?? false) {
                  final formData =
                      Map<String, dynamic>.from(_formKey.currentState!.value);
                  formData['Visitor Photo'] = _pickedImage!.path;

                  final mappedFormData = <String, dynamic>{};
                  for (var field in widget.template.fields) {
                    mappedFormData[field.label] = formData[field.id];
                  }

                  mappedFormData['Visitor Photo'] = _pickedImage!.path;

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => FormPreviewScreen(
                        template: widget.template,
                        formData: mappedFormData,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please fill in all required fields'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              children: widget.template.fields.map((field) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildFormField(context, field),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
