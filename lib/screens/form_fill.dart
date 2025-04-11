import 'dart:io';

import 'package:docify/services/capture_image.dart';
import 'package:docify/screens/form_preview.dart';
import 'package:docify/services/suggestion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../models/template.dart';
import '../models/form_field.dart';
import '../models/form_entry.dart';
import '../services/database_service.dart';

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
  int hoveredSuggestionIndex = -1;
  bool _isLoadingSuggestions = true;

  // Add these new fields
  final DatabaseService _dbService = DatabaseService();
  FormEntry? selectedEntry;
  OverlayEntry? _overlayEntry;
  // Replace existing LayerLink with a map of LayerLinks for each field
  final Map<String, LayerLink> _layerLinks = {};

  @override
  void initState() {
    super.initState();
    // Initialize controllers and layer links for all text fields
    for (var field in widget.template.fields) {
      if (['text', 'email', 'phone', 'number'].contains(field.type)) {
        _controllers[field.id] =
            TextEditingController(text: field.defaultValue);
        _filteredSuggestions[field.id] = [];
        _layerLinks[field.id] = LayerLink();
      }
    }
    _loadSuggestions();
  }

  @override
  void dispose() {
    _removeOverlay();
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
          // Remove duplicates when storing suggestions
          _fieldSuggestions[field.label] = suggestions.toSet().toList();
          _filteredSuggestions[field.id] = suggestions.toSet().toList();
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
          // Show no suggestions and close overlay when query is empty
          _filteredSuggestions[fieldId] = [];
          _removeOverlay();
        } else {
          // Filter suggestions based on query and remove duplicates
          _filteredSuggestions[fieldId] = _fieldSuggestions[field.label]!
              .where((suggestion) =>
                  suggestion.toLowerCase().contains(query.toLowerCase()))
              .toSet() // Convert to Set to remove duplicates
              .toList();
        }
        // Reset hovered index when filtering
        hoveredSuggestionIndex = -1;
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
    final field = widget.template.fields.firstWhere((f) => f.id == fieldId);

    if (_currentFocusedField != fieldId || suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return CompositedTransformFollower(
      link: _layerLinks[fieldId]!,
      offset: const Offset(0, 48), // Offset to show below the text field
      child: Container(
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
        constraints: const BoxConstraints(maxHeight: 200),
        child: ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            return MouseRegion(
              onEnter: (_) {
                setState(() {
                  hoveredSuggestionIndex = index;
                });
                _showAssociatedEntriesOverlay(
                    context, fieldId, field.label, suggestions[index]);
              },
              onExit: (_) {
                setState(() {
                  hoveredSuggestionIndex = -1;
                });
              },
              child: ListTile(
                dense: true,
                title: Text(suggestions[index]),
                onTap: () {
                  // Only fill the current field
                  _controllers[fieldId]?.text = suggestions[index];
                  _formKey.currentState?.fields[fieldId]
                      ?.didChange(suggestions[index]);
                  setState(() {
                    _currentFocusedField = null;
                  });
                },
              ),
            );
          },
        ),
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
          CompositedTransformTarget(
            link: _layerLinks[field.id]!,
            child: Focus(
              onFocusChange: (hasFocus) {
                if (hasFocus) {
                  setState(() {
                    _currentFocusedField = field.id;
                    // Initialize with all suggestions
                    _filterSuggestions(field.id, _controllers[field.id]!.text);
                    // Reset hover state
                    hoveredSuggestionIndex = -1;
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
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _showClearCacheDialog(),
            tooltip: 'Clear Template Cache',
          ),
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

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Template Cache'),
        content: const Text(
            'This will delete all saved entries for this template. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _dbService.clearTemplateEntries(widget.template.id);
              Navigator.of(context).pop();
              setState(() {
                _fieldSuggestions.clear();
                _filteredSuggestions.clear();
              });
              _loadSuggestions();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildAssociatedEntriesPopup(String fieldLabel, String value) {
    return FutureBuilder<List<FormEntry>>(
      future: _dbService.getAssociatedEntries(
          widget.template.id, fieldLabel, value),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            width: 300,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          );
        }

        // Remove entries that have exactly the same values for all fields
        final entries = snapshot.data!;
        final uniqueEntries = entries
            .fold<Map<String, FormEntry>>({}, (map, entry) {
              // Create a key by sorting field keys and concatenating all values
              final values = Map.of(entry.fieldValues);
              final sortedKeys = values.keys.toList()..sort();
              final key = sortedKeys.map((k) => '$k:${values[k]}').join('|');

              if (!map.containsKey(key)) {
                map[key] = entry;
              } else if (entry.createdAt.isAfter(map[key]!.createdAt)) {
                // Keep the most recent entry if duplicates exist
                map[key] = entry;
              }
              return map;
            })
            .values
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Container(
          width: 300,
          margin: const EdgeInsets.only(top: 8),
          constraints: const BoxConstraints(maxHeight: 500),
          child: Card(
            elevation: 8,
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 20,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Previous Entries',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        entries.length != uniqueEntries.length
                            ? '${uniqueEntries.length} found'
                            : '${entries.length} found',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                      ),
                    ],
                  ),
                ),
                if (uniqueEntries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('No matching entries found')),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: uniqueEntries.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entry = uniqueEntries[index];
                        final formattedDate = _formatDate(entry.createdAt);
                        return ListTile(
                          selected: selectedEntry?.id == entry.id,
                          selectedTileColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withOpacity(0.1),
                          dense: true,
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Entry from $formattedDate',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: entry.fieldValues.entries.map((e) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: RichText(
                                  text: TextSpan(
                                    style: DefaultTextStyle.of(context).style,
                                    children: [
                                      TextSpan(
                                        text: '${e.key}: ',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(text: e.value),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          onTap: () {
                            setState(() {
                              // Toggle selection if same entry is tapped
                              if (selectedEntry?.id == entry.id) {
                                selectedEntry = null;
                              } else {
                                _fillFormWithEntry(entry);
                              }
                            });
                          },
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                        );
                      },
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _removeOverlay,
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAssociatedEntriesOverlay(
      BuildContext context, String fieldId, String fieldLabel, String value) {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        right: 16, // Gap from right edge of screen
        bottom: 0,
        width: 300,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Container(
              alignment: Alignment.topCenter,
              child: _buildAssociatedEntriesPopup(fieldLabel, value),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _fillFormWithEntry(FormEntry entry) {
    setState(() {
      selectedEntry = entry;
      for (var field in widget.template.fields) {
        if (field.type != 'image') {
          final value = entry.fieldValues[field.label];
          if (value != null) {
            _controllers[field.id]?.text = value;
            _formKey.currentState?.fields[field.id]?.didChange(value);
          }
        }
      }
    });
  }
}
