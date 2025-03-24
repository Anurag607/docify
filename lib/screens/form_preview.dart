import 'dart:io';
import 'package:pdf/pdf.dart';
import '../models/template.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FormPreviewScreen extends StatefulWidget {
  final Template template;
  final Map<String, dynamic> formData;

  const FormPreviewScreen({
    super.key,
    required this.template,
    required this.formData,
  });

  @override
  State<FormPreviewScreen> createState() => _FormPreviewScreenState();
}

class _FormPreviewScreenState extends State<FormPreviewScreen> {
  late Future<Uint8List> _pdfFuture;

  @override
  void initState() {
    super.initState();
    _pdfFuture = _generatePdf();
  }

  Future<Uint8List> _generatePdf() async {
    final fontData =
        await rootBundle.load("assets/fonts/NotoSansDevanagari-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    final pdf = pw.Document(theme: pw.ThemeData.withFont(base: ttf));

    // Load ministry logo if available
    pw.MemoryImage? amdLogo;
    try {
      final ByteData data =
          await rootBundle.load('assets/images/ministry_logo.png');
      final Uint8List bytes = data.buffer.asUint8List();
      amdLogo = pw.MemoryImage(bytes);
    } catch (e) {
      print('Error loading ministry logo: $e');
    }

    // Load emblem logo if available
    pw.MemoryImage? anniversaryLogo;
    try {
      final ByteData data = await rootBundle.load('assets/images/75_logo.png');
      final Uint8List bytes = data.buffer.asUint8List();
      anniversaryLogo = pw.MemoryImage(bytes);
    } catch (e) {
      print('Error loading emblem logo: $e');
    }

    // Create visitor photo placeholder or use actual image if available
    print('Visitor Photo: ${widget.formData['Visitor Photo']}');
    pw.MemoryImage? visitorPhoto =
        await safeLoadImage(widget.formData['Visitor Photo']);
    if (visitorPhoto == null) {
      print('No visitor photo found, using default placeholder.');
    } else {
      print('Visitor photo loaded and compressed successfully.');
    }

    final regDate = DateTime.now();
    final endHour = (regDate.hour + 3) % 24; // Ensure hour does not exceed 23
    final validDuration =
        "${regDate.hour}:${regDate.minute} to $endHour:${regDate.minute}";

    // Ensure the substring operation is within the valid range
    final regNo = widget.formData['Reg No'] ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final regNoSubstring = regNo.length > 15 ? regNo.substring(5, 15) : regNo;

    const double inch = 72.0;
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(10 * inch, 6.0 * inch, marginAll: 0),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 1, color: PdfColors.black),
            ),
            padding: const pw.EdgeInsets.only(left: 8, right: 8, top: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header section
                pw.Container(
                  color: PdfColors.grey300,
                  padding: const pw.EdgeInsets.symmetric(
                      vertical: 5, horizontal: 10),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      if (amdLogo != null) pw.Image(amdLogo, width: 40),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text('भारत सरकार GOVERNMENT OF INDIA',
                              style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text(
                              'परमाणु ऊर्जा विभाग DEPARTMENT OF ATOMIC ENERGY',
                              style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text('परमाणु खनिज अन्वेषण एवं अनुसंधान निदेशालय',
                              style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text(
                              'ATOMIC MINERALS DIRECTORATE FOR EXPLORATION & RESEARCH',
                              style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text('उत्तरी क्षेत्र NORTHERN REGION',
                              style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      if (anniversaryLogo != null)
                        pw.Image(anniversaryLogo, width: 40),
                    ],
                  ),
                ),

                // Title
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 5),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('आकस्मिक प्रवेश पत्र',
                          style: pw.TextStyle(
                              font: ttf,
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text('Casual Entry Permit',
                          style: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              decoration: pw.TextDecoration.underline)),
                    ],
                  ),
                ),

                // Valid Duration
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 5),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('(वैध अवधि)',
                                style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Text('Valid Duration: $validDuration',
                                style: pw.TextStyle(font: ttf, fontSize: 8)),
                          ],
                        ),
                      ),
                      pw.Container(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('(मुद्रित)',
                                style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Text(
                                'Printed On: ${regDate.day}/${regDate.month}/${regDate.year} ${regDate.hour}:${regDate.minute}',
                                style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Reg Info
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 5),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('(पंजीकरण संख्या)',
                                style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Text('Reg No: $regNoSubstring',
                                style: pw.TextStyle(font: ttf, fontSize: 8)),
                          ],
                        ),
                      ),
                      pw.Container(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('(पंजीकरण तिथि)',
                                style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Text(
                                'Registration Date: ${regDate.day}/${regDate.month}/${regDate.year}',
                                style: pw.TextStyle(font: ttf, fontSize: 8)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Main information section
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Visitor info
                    pw.Expanded(
                      flex: 6,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('नाम', 'Name of visitor:',
                              widget.formData['Name of Visitor'] ?? '', ttf),
                          _buildInfoRow('मोबाइल', 'Mobile No:',
                              widget.formData['Mobile No.'] ?? '', ttf),
                          _buildInfoRow(
                              'सामग्री',
                              'Material carried in:',
                              widget.formData['Material carried in'] ?? '',
                              ttf),
                          _buildInfoRow(
                              'अधिकारी',
                              'Officer (Name) to be visited:',
                              widget.formData['Officer Name'] ?? '',
                              ttf),
                          _buildInfoRow('पीवीसी विवरण', 'Details of PVC:',
                              widget.formData['PVC Details'] ?? '', ttf),
                        ],
                      ),
                    ),
                    // Address & ID details
                    pw.Expanded(
                      flex: 6,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('पता', 'Address:',
                              widget.formData['Address'] ?? '', ttf),
                          _buildInfoRow('आईडी विवरण', 'ID No./Aadhar No:',
                              widget.formData['ID Details'] ?? '', ttf),
                          _buildInfoRow('उद्देश्य', 'Purpose of visit:',
                              widget.formData['Purpose'] ?? '', ttf),
                          _buildInfoRow('स्थान', 'Place to be visited:',
                              widget.formData['Place'] ?? '', ttf),
                          _buildInfoRow('स्टाफ', 'Escorting staff:',
                              widget.formData['Escorting staff'] ?? '', ttf),
                        ],
                      ),
                    ),
                    // Photo column
                    pw.Expanded(
                      flex: 3,
                      child: pw.Container(
                        alignment: pw.Alignment.center,
                        child: visitorPhoto != null
                            ? pw.Image(visitorPhoto,
                                width: 70, height: 90, fit: pw.BoxFit.cover)
                            : pw.Container(
                                width: 70,
                                height: 90,
                                decoration: pw.BoxDecoration(
                                    border:
                                        pw.Border.all(color: PdfColors.black)),
                                alignment: pw.Alignment.center,
                                child: pw.Text('Photo',
                                    style:
                                        pw.TextStyle(font: ttf, fontSize: 8)),
                              ),
                      ),
                    ),
                  ],
                ),

                // Signature section
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 20),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.SizedBox(
                            height: 50,
                            child:
                                _buildSignatureBox('Signature of the visitor'),
                          ),
                          pw.SizedBox(
                            height: 50,
                            child:
                                _buildSignatureBox("Duty ASO at Security C/R."),
                          )
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.SizedBox(
                        height: 50,
                        child: _buildSignatureBox(
                            'Signature of the officer visited with time'),
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildInfoRow(
      String hindiLabel, String englishLabel, String value, pw.Font ttf) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                child: pw.Text(englishLabel,
                    style: pw.TextStyle(
                        fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 5),
              pw.Expanded(
                child:
                    pw.Text(value, style: pw.TextStyle(font: ttf, fontSize: 9)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSignatureBox(String text) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _sharePdf() async {
    try {
      final bytes = await _pdfFuture;
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/visitor_pass.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Visitor Pass');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing PDF: $e')),
      );
    }
  }

  Future<void> _savePdf() async {
    try {
      final bytes = await _pdfFuture;
      final result = await Printing.sharePdf(
        bytes: bytes,
        filename: 'visitor_pass.pdf',
      );
      if (!result) {
        throw Exception('Failed to save PDF');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Pass Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePdf,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _savePdf,
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              final bytes = await _pdfFuture;
              await Printing.layoutPdf(
                onLayout: (_) => Future.value(bytes),
                name: 'Visitor Pass',
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Uint8List>(
        future: _pdfFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data'));
          }

          return PdfPreview(
            build: (_) => Future.value(snapshot.data!),
            allowPrinting: false,
            allowSharing: false,
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
          );
        },
      ),
    );
  }
}

Future<pw.MemoryImage?> safeLoadImage(String? path,
    {int maxSizeBytes = 100000}) async {
  if (path == null) return null;

  try {
    final imageFile = File(path);
    if (await imageFile.exists()) {
      final bytes = await imageFile.readAsBytes();
      print('Image size: ${bytes.length} bytes');

      if (bytes.length <= maxSizeBytes) {
        return pw.MemoryImage(bytes);
      }

      print('Compression failed, using placeholder image');
      final placeholder =
          await rootBundle.load('assets/images/photo_placeholder.jpg');
      return pw.MemoryImage(placeholder.buffer.asUint8List());
    } else {
      print('Image file does not exist: $path');
    }
  } catch (e) {
    print('Error loading image: $e');
  }

  return null;
}
