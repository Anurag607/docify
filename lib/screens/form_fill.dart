import 'dart:io';

import 'package:camera/camera.dart';
import 'package:docify/services/capture_image.dart';
import 'package:docify/screens/form_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
  XFile? _pickedImage;

  Future captureVisitorPhoto() async {
    final File? imageFile = await ImagePickerService.pickImage(context);

    if (imageFile != null) {
      final imagePath = imageFile.path;
      setState(() {
        _pickedImage = XFile(imagePath);
      });
      print('Image captured: $imagePath');
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

  Future<pw.Document> _generatePdf() async {
    final formData = _formKey.currentState!.value;
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context pwContext) {
          // Changed from context to pwContext
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40.0),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        widget.template.name,
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueAccent,
                        ),
                      ),
                      if (widget.template.description.isNotEmpty) ...[
                        pw.SizedBox(height: 8),
                        pw.Text(
                          widget.template.description,
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                      pw.SizedBox(height: 4),
                      pw.Divider(color: PdfColors.blueAccent),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),
                ...widget.template.fields.map((field) {
                  final value = formData[field.id]?.toString() ?? '';
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          field.label,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey800,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey100,
                            borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(4),
                            ),
                          ),
                          child: pw.Text(
                            value,
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  Future<void> _handlePdfAction(
      BuildContext context, Future<void> Function(pw.Document) action) async {
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please capture the required image1'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final pdf = await _generatePdf();
      if (!mounted) return;
      await action(pdf);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all required fields'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.name),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.camera_alt),
          //   tooltip: 'Capture Photo',
          //   onPressed: captureVisitorPhoto,
          // ),
          IconButton(
            icon: const Icon(Icons.preview_outlined),
            tooltip: 'Preview document',
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
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Download as PDF',
            onPressed: () => _handlePdfAction(context, (pdf) async {
              await Printing.sharePdf(
                bytes: await pdf.save(),
                filename:
                    '${widget.template.name.toLowerCase().replaceAll(' ', '_')}.pdf',
              );
            }),
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print document',
            onPressed: () => _handlePdfAction(context, (pdf) async {
              final printer = await Printing.pickPrinter(context: context);
              if (printer != null) {
                await Printing.directPrintPdf(
                  printer: printer,
                  onLayout: (format) => pdf.save(),
                );
              }
            }),
          ),
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
