import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:image_picker/image_picker.dart';
import '../models/template.dart';
import '../models/form_field.dart';
import '../services/database_service.dart';
import '../widgets/custom_app_bar.dart';

class TemplateBuilder extends StatefulWidget {
  final Template? template;

  const TemplateBuilder({super.key, this.template});

  @override
  State<TemplateBuilder> createState() => _TemplateBuilderState();
}

class _TemplateBuilderState extends State<TemplateBuilder> {
  final _formKey = GlobalKey<FormBuilderState>();
  final List<FormFieldModel> _fields = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _imageData;

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _nameController.text = widget.template!.name;
      _descriptionController.text = widget.template!.description;
      _fields.addAll(widget.template!.fields);
      _imageData = widget.template!.imageData;
    }
  }

  void _editField(FormFieldModel field) {
    final labelController = TextEditingController(text: field.label);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Field'),
        content: FormBuilder(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FormBuilderTextField(
                name: 'label',
                controller: labelController,
                decoration: const InputDecoration(labelText: 'Field Label'),
                validator: FormBuilderValidators.required(),
              ),
              FormBuilderDropdown<String>(
                name: 'type',
                decoration: const InputDecoration(labelText: 'Field Type'),
                initialValue: field.type,
                items: const [
                  DropdownMenuItem(value: 'text', child: Text('Text')),
                  DropdownMenuItem(value: 'number', child: Text('Number')),
                  DropdownMenuItem(value: 'date', child: Text('Date')),
                  DropdownMenuItem(value: 'email', child: Text('Email')),
                  DropdownMenuItem(value: 'phone', child: Text('Phone')),
                ],
                validator: FormBuilderValidators.required(),
              ),
              FormBuilderSwitch(
                name: 'required',
                title: const Text('Required'),
                initialValue: field.required,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final formContext = FormBuilder.of(context);
              if (formContext != null && formContext.saveAndValidate()) {
                final formData = formContext.value;
                setState(() {
                  final index = _fields.indexOf(field);
                  _fields[index] = FormFieldModel(
                    label: formData['label'] as String,
                    type: formData['type'] as String,
                    required: formData['required'] as bool,
                    order: field.order,
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addField() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Field'),
        content: FormBuilder(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FormBuilderTextField(
                name: 'label',
                decoration: const InputDecoration(labelText: 'Field Label'),
                validator: FormBuilderValidators.required(),
              ),
              FormBuilderDropdown<String>(
                name: 'type',
                decoration: const InputDecoration(labelText: 'Field Type'),
                items: const [
                  DropdownMenuItem(value: 'text', child: Text('Text')),
                  DropdownMenuItem(value: 'number', child: Text('Number')),
                  DropdownMenuItem(value: 'date', child: Text('Date')),
                  DropdownMenuItem(value: 'email', child: Text('Email')),
                  DropdownMenuItem(value: 'phone', child: Text('Phone')),
                ],
                validator: FormBuilderValidators.required(),
              ),
              FormBuilderSwitch(
                name: 'required',
                title: const Text('Required'),
                initialValue: false,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final formContext = FormBuilder.of(context);
              if (formContext != null && formContext.saveAndValidate()) {
                final formData = formContext.value;
                setState(() {
                  _fields.add(FormFieldModel(
                    label: formData['label'] as String,
                    type: formData['type'] as String,
                    required: formData['required'] as bool,
                    order: _fields.length,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _saveTemplate() async {
    if (_formKey.currentState!.saveAndValidate()) {
      final template = Template(
        id: widget.template?.id,
        name: _nameController.text,
        description: _descriptionController.text,
        fields: _fields,
        imageData: _imageData,
      );

      await DatabaseService().saveTemplate(template);
      if (mounted) {
        Navigator.pop(context, template);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.template == null ? 'Create Template' : 'Edit Template',
        actions: [
          ElevatedButton.icon(
            onPressed: _saveTemplate,
            icon: const Icon(Icons.save_outlined, color: Colors.white),
            label: const Text("Save", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6750A4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          )
        ],
      ),
      body: FormBuilder(
        key: _formKey,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Template Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: 'name',
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Template Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: FormBuilderValidators.required(),
                    ),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: 'description',
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Template Image',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (_imageData != null)
                      Stack(
                        children: [
                          Image.memory(
                            base64Decode(_imageData!),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              onPressed: () {
                                setState(() {
                                  _imageData = null;
                                });
                              },
                              icon: const Icon(Icons.delete_outline),
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.surface,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      InkWell(
                        onTap: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(
                              source: ImageSource.gallery);
                          if (image != null) {
                            final bytes = await image.readAsBytes();
                            setState(() {
                              _imageData = base64Encode(bytes);
                            });
                          }
                        },
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Upload Image',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.format_list_bulleted,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Form Fields',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const Spacer(),
                        if (_fields.isNotEmpty)
                          Text(
                            '${_fields.length} ${_fields.length == 1 ? 'field' : 'fields'}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                ),
                          ),
                        const SizedBox(width: 16),
                        FilledButton.icon(
                          onPressed: _addField,
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                          ),
                          label: const Text('Add Field'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_fields.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.drag_indicator,
                              size: 48,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Drag and drop form fields here',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add fields using the button above',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                            ),
                          ],
                        ),
                      )
                    else
                      Expanded(
                        child: ReorderableListView.builder(
                          itemCount: _fields.length,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (oldIndex < newIndex) {
                                newIndex -= 1;
                              }
                              final item = _fields.removeAt(oldIndex);
                              _fields.insert(newIndex, item);

                              // Update order of all fields
                              for (var i = 0; i < _fields.length; i++) {
                                _fields[i] = _fields[i].copyWith(order: i);
                              }
                            });
                          },
                          itemBuilder: (context, index) {
                            final field = _fields[index];
                            return Card(
                              key: ValueKey(field.order),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: ReorderableDragStartListener(
                                  index: index,
                                  child: Icon(
                                    Icons.drag_indicator,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                title: Text(field.label),
                                subtitle: Text(
                                  '${field.type.toUpperCase()}${field.required ? ' (Required)' : ''}',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => _editField(field),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () {
                                        setState(() {
                                          _fields.remove(field);
                                          // Update order of remaining fields
                                          for (var i = 0;
                                              i < _fields.length;
                                              i++) {
                                            _fields[i] =
                                                _fields[i].copyWith(order: i);
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
