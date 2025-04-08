import 'dart:io';

import 'package:docify/services/capture_image.dart';
import 'package:docify/screens/form_preview.dart';
import 'package:docify/services/suggestion_service.dart';
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
  // Map to store suggestions for each field
  final Map<String, List<String>> _fieldSuggestions = {};
  // Track the currently focused field for dropdown
  String? _currentFocusedField;
  // For filtering suggestions based on input
  final Map<String, List<String>> _filteredSuggestions = {};
  // Controllers for text fields
  final Map<String, TextEditingController> _controllers = {};
  // Track hovered suggestion index
  int _hoveredSuggestionIndex = -1;
  bool _isLoadingSuggestions = true;

  @override
  void initState() {
    super.initState();
    // Initialize controllers for all text fields
    for (var field in widget.template.fields) {
      if (['text', 'email', 'phone', 'number'].contains(field.type)) {
        _controllers[field.id] =
            TextEditingController(text: field.defaultValue);
        _filteredSuggestions[field.id] = [];
      }
    }
    _loadSuggestions();
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoadingSuggestions = true;
    });

    // Load suggestions for all text-based fields
    for (var field in widget.template.fields) {
      if (field.type == 'text' ||
          field.type == 'email' ||
          field.type == 'phone' ||
          field.type == 'number') {
        final suggestions = await SuggestionService.getSuggestions(
            widget.template.id, field.label);

        setState(() {
          _fieldSuggestions[field.label] = suggestions;
          _filteredSuggestions[field.id] = suggestions;
        });
      }
    }

    setState(() {
      _isLoadingSuggestions = false;
    });
  }

  // Filter suggestions based on user input
  void _filterSuggestions(String fieldId, String query) {
    // Find the field to get its label
    final field = widget.template.fields.firstWhere((f) => f.id == fieldId);

    if (_fieldSuggestions.containsKey(field.label)) {
      setState(() {
        if (query.isEmpty) {
          // Show all suggestions when query is empty
          _filteredSuggestions[fieldId] =
              List.from(_fieldSuggestions[field.label]!);
        } else {
          // Filter suggestions based on query
          _filteredSuggestions[fieldId] = _fieldSuggestions[field.label]!
              .where((suggestion) =>
                  suggestion.toLowerCase().contains(query.toLowerCase()))
              .toList();
        }
        // Reset hovered index when filtering
        _hoveredSuggestionIndex = -1;
      });
    }
  }

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

  // Build dropdown list for suggestions
  Widget _buildSuggestionsDropdown(String fieldId) {
    final suggestions = _filteredSuggestions[fieldId] ?? [];

    if (_currentFocusedField != fieldId || suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(4.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      constraints: const BoxConstraints(
        maxHeight: 200,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return MouseRegion(
            onEnter: (_) {
              setState(() {
                _hoveredSuggestionIndex = index;
              });
            },
            onExit: (_) {
              setState(() {
                _hoveredSuggestionIndex = -1;
              });
            },
            child: Container(
              color: _hoveredSuggestionIndex == index
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
              child: ListTile(
                dense: true,
                title: Text(
                  suggestions[index],
                  style: TextStyle(
                    color: _hoveredSuggestionIndex == index
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    fontWeight: _hoveredSuggestionIndex == index
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  // Update the text field with selected suggestion
                  _controllers[fieldId]!.text = suggestions[index];

                  // Update the form field value
                  _formKey.currentState?.fields[fieldId]
                      ?.didChange(suggestions[index]);

                  // Hide dropdown
                  setState(() {
                    _currentFocusedField = null;
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }

  FormFieldValidator? _getValidator(FormFieldModel field) {
    if (field.type == 'number') {
      return field.required
          ? FormBuilderValidators.compose([
              (value) => (value == null || (value as String).isEmpty)
                  ? '${field.label} is required'
                  : null,
              FormBuilderValidators.numeric(
                  errorText: '${field.label} must be a number'),
            ])
          : FormBuilderValidators.numeric(
              errorText: '${field.label} must be a number');
    } else if (field.required) {
      return (value) => (value == null || (value as String).isEmpty)
          ? '${field.label} is required'
          : null;
    }
    return null;
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

    // Fields that can have suggestions
    if (['text', 'number', 'email', 'phone'].contains(field.type)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Focus(
            onFocusChange: (hasFocus) {
              if (hasFocus) {
                setState(() {
                  _currentFocusedField = field.id;
                  // Initialize with all suggestions
                  _filterSuggestions(field.id, _controllers[field.id]!.text);
                  // Reset hover state
                  _hoveredSuggestionIndex = -1;
                });
              } else {
                // Delay hiding the dropdown to allow for selection
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (mounted) {
                    setState(() {
                      if (_currentFocusedField == field.id) {
                        _currentFocusedField = null;
                      }
                    });
                  }
                });
              }
            },
            child: FormBuilderTextField(
              name: field.id,
              controller: _controllers[field.id],
              decoration: decoration,
              keyboardType: _getKeyboardType(field.type),
              validator: _getValidator(field),
              onChanged: (value) {
                if (value != null) {
                  _filterSuggestions(field.id, value);
                }
              },
            ),
          ),
          if (!_isLoadingSuggestions) _buildSuggestionsDropdown(field.id),
        ],
      );
    }

    switch (field.type) {
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
      case 'date':
        return FormBuilderDateTimePicker(
          name: field.id,
          decoration: decoration,
          inputType: InputType.date,
          validator: field.required
              ? (value) => value == null ? '${field.label} is required' : null
              : null,
        );
      default:
        return FormBuilderTextField(
          name: field.id,
          decoration: decoration,
          keyboardType: _getKeyboardType(field.type),
          validator: _getValidator(field),
          initialValue: field.defaultValue,
        );
    }
  }

  void _saveFormData(Map<String, dynamic> formData) {
    // Convert formData to string map for storage
    final Map<String, String> stringFormData = {};
    for (var field in widget.template.fields) {
      if (field.type != 'image' && formData[field.id] != null) {
        stringFormData[field.label] = formData[field.id].toString();
      }
    }

    // Save form data for future suggestions
    SuggestionService.saveFormEntry(widget.template.id, stringFormData);
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
                      content: const Text('Please capture the required image'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                  return;
                }

                if (_formKey.currentState?.saveAndValidate() ?? false) {
                  final formData =
                      Map<String, dynamic>.from(_formKey.currentState!.value);

                  // Save form data for future suggestions
                  _saveFormData(formData);

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
      body: _isLoadingSuggestions
          ? Center(child: CircularProgressIndicator())
          : GestureDetector(
              // Dismiss the dropdown when tapping outside
              onTap: () {
                setState(() {
                  _currentFocusedField = null;
                });
                FocusScope.of(context).unfocus();
              },
              child: SingleChildScrollView(
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
            ),
    );
  }
}
