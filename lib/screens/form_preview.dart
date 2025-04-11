import 'dart:io';
import 'package:pdf/pdf.dart';
import '../models/template.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Map<String, String> englishToHindiMapping = {
  "GOVERNMENT OF INDIA": "GOVERNMENT OF INDIA",
  "DEPARTMENT OF ATOMIC ENERGY": "DEPARTMENT OF ATOMIC ENERGY",
  "ATOMIC MINERALS DIRECTORATE FOR EXPLORATION & RESEARCH":
      "ATOMIC MINERALS DIRECTORATE FOR EXPLORATION & RESEARCH",
  "NORTHERN REGION": "NORTHERN REGION",
  "Casual Entry Permit": "Casual Entry Permit",
  "Valid Duration": "Valid Duration",
  "Printed On": "Printed On",
  "Reg No": "Reg No",
  "Registration Date": "Registration Date",
};

Map<String, String> getHindiImageFilenames() {
  return {
    "GOVERNMENT OF INDIA": "GOVERNMENT OF INDIA.png",
    "DEPARTMENT OF ATOMIC ENERGY": "DEPARTMENT OF ATOMIC ENERGY.png",
    "ATOMIC MINERALS DIRECTORATE FOR EXPLORATION & RESEARCH":
        "ATOMIC MINERALS DIRECTORATE FOR EXPLORATION & RESEARCH.png",
    "NORTHERN REGION": "NORTHERN REGION.png",
    "Casual Entry Permit": "Casual Entry Permit.png",
    "Valid Duration": "Valid Duration.png",
    "Printed On": "Printed On.png",
    "Reg No": "Reg No.png",
    "Registration Date": "Registration Date.png",
  };
}

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

  Future<Map<String, pw.MemoryImage>> loadHindiImages() async {
    Map<String, pw.MemoryImage> hindiImages = {};
    final filenameMapping = getHindiImageFilenames();

    for (var entry in englishToHindiMapping.entries) {
      try {
        final filename = filenameMapping[entry.key];
        if (filename != null) {
          final ByteData data =
              await rootBundle.load('assets/hindi_text/$filename');
          final Uint8List bytes = data.buffer.asUint8List();
          hindiImages[entry.key] = pw.MemoryImage(bytes);
        }
      } catch (e) {
        print('Error loading Hindi image for ${entry.key}: $e');
      }
    }

    return hindiImages;
  }

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load("assets/fonts/Mukta-Regular.ttf");
    final hindiFont = pw.Font.ttf(fontData);

    // Load amd logo if available
    pw.MemoryImage? amdLogo;
    try {
      final ByteData data =
          await rootBundle.load('assets/images/ministry_logo.png');
      final Uint8List bytes = data.buffer.asUint8List();
      amdLogo = pw.MemoryImage(bytes);
    } catch (e) {
      print('Error loading ministry logo: $e');
    }

    // Load anniversary logo if available
    pw.MemoryImage? anniversaryLogo;
    try {
      final ByteData data = await rootBundle.load('assets/images/75_logo.png');
      final Uint8List bytes = data.buffer.asUint8List();
      anniversaryLogo = pw.MemoryImage(bytes);
    } catch (e) {
      print('Error loading emblem logo: $e');
    }

    // Load instructions image
    pw.MemoryImage? instructionsImage;
    try {
      final ByteData data =
          await rootBundle.load('assets/images/instructions.png');
      final Uint8List bytes = data.buffer.asUint8List();
      instructionsImage = pw.MemoryImage(bytes);
    } catch (e) {
      print('Error loading instructions image: $e');
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

    final hindiImages = await loadHindiImages();

    // const double inch = 72.0;
    pdf.addPage(
      pw.Page(
        // pageFormat: PdfPageFormat(10 * inch, 6.0 * inch, marginAll: 0),
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Container(
            // decoration: pw.BoxDecoration(
            //   color: PdfColor.fromHex("#e8e8e8"),
            // ),
            width: PdfPageFormat.a4.width,
            height: PdfPageFormat.a4.height,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Main content wrapped in Expanded
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        // Header section
                        pw.Container(
                          color: PdfColor.fromHex("#d9d9d9"),
                          padding: const pw.EdgeInsets.symmetric(
                              vertical: 5, horizontal: 10),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              if (amdLogo != null) pw.Image(amdLogo, width: 70),
                              pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                children: [
                                  _buildHindiText(
                                    hindiImages["GOVERNMENT OF INDIA"],
                                    "GOVERNMENT OF INDIA",
                                    null,
                                    hindiFont,
                                    15,
                                    null,
                                  ),
                                  _buildHindiText(
                                    hindiImages[
                                        "ATOMIC MINERALS DIRECTORATE FOR EXPLORATION & RESEARCH"],
                                    null,
                                    null,
                                    hindiFont,
                                    15,
                                    null,
                                  ),
                                  _buildHindiText(
                                    null,
                                    "ATOMIC MINERALS DIRECTORATE FOR EXPLORATION & RESEARCH",
                                    null,
                                    hindiFont,
                                    15,
                                    null,
                                  ),
                                  _buildHindiText(
                                    hindiImages["DEPARTMENT OF ATOMIC ENERGY"],
                                    "DEPARTMENT OF ATOMIC ENERGY",
                                    null,
                                    hindiFont,
                                    15,
                                    null,
                                  ),
                                  _buildHindiText(
                                    hindiImages["NORTHERN REGION"],
                                    "NORTHERN REGION",
                                    null,
                                    hindiFont,
                                    15,
                                    null,
                                  ),
                                ],
                              ),
                              if (anniversaryLogo != null)
                                pw.Image(anniversaryLogo, width: 60),
                            ],
                          ),
                        ),

                        // Title
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 5),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Image(hindiImages["Casual Entry Permit"]!,
                                  height: 15),
                              pw.Text(
                                'Casual Entry Permit',
                                style: pw.TextStyle(
                                  font: hindiFont,
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  decoration: pw.TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Valid Duration
                        pw.Container(
                          padding: const pw.EdgeInsets.only(top: 5),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildHindiText(
                                hindiImages["Valid Duration"],
                                "Valid Duration",
                                validDuration,
                                hindiFont,
                                10,
                                200,
                              ),
                              _buildHindiText(
                                hindiImages["Printed On"],
                                "Printed On",
                                '${regDate.day}/${regDate.month}/${regDate.year} ${regDate.hour}:${regDate.minute}',
                                hindiFont,
                                10,
                                100,
                              ),
                            ],
                          ),
                        ),

                        // Reg Info
                        pw.Container(
                          padding: const pw.EdgeInsets.only(
                            top: 5,
                            bottom: 10,
                          ),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildHindiText(
                                hindiImages["Reg No"],
                                "Reg No",
                                regNoSubstring,
                                hindiFont,
                                10,
                                100,
                              ),
                              _buildHindiText(
                                hindiImages["Registration Date"],
                                "Registration Date",
                                '${regDate.day}/${regDate.month}/${regDate.year}',
                                hindiFont,
                                10,
                                100,
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
                                  _buildInfoRow(
                                    'नाम',
                                    'Name of visitor:',
                                    widget.formData['Name of visitor'] ?? '',
                                    hindiFont,
                                  ),
                                  _buildInfoRow(
                                    'मोबाइल',
                                    'Mobile No:',
                                    widget.formData['Mobile No.'] ?? '',
                                    hindiFont,
                                  ),
                                  _buildInfoRow(
                                    'सामग्री',
                                    'Material carried in:',
                                    widget.formData['Material carried in'] ??
                                        '',
                                    hindiFont,
                                  ),
                                  _buildInfoRow(
                                    'अधिकारी',
                                    'Officer (Name) to be visited:',
                                    widget.formData['Officer Name'] ?? '',
                                    hindiFont,
                                  ),
                                  _buildInfoRow(
                                    'पीवीसी विवरण',
                                    'Details of PVC:',
                                    widget.formData['PVC Details'] ?? '',
                                    hindiFont,
                                  ),
                                ],
                              ),
                            ),
                            // Address & ID details
                            pw.Expanded(
                              flex: 6,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(
                                    'पता',
                                    'Address:',
                                    widget.formData['Address'] ?? '',
                                    hindiFont,
                                  ),
                                  _buildInfoRow(
                                    'आईडी विवरण',
                                    'ID No. /Aadhar No:',
                                    widget.formData['ID Details'] ?? 'sss',
                                    hindiFont,
                                  ),
                                  _buildInfoRow(
                                    'उद्देश्य',
                                    'Purpose of visit:',
                                    widget.formData['Purpose'] ?? '',
                                    hindiFont,
                                  ),
                                  _buildInfoRow(
                                    'स्थान',
                                    'Place to be visited:',
                                    widget.formData['Place'] ?? '11',
                                    hindiFont,
                                  ),
                                  _buildInfoRow(
                                    'स्टाफ',
                                    'Escorting staff:',
                                    widget.formData['Escorting staff'] ?? '',
                                    hindiFont,
                                  ),
                                ],
                              ),
                            ),
                            // Photo column
                            pw.Expanded(
                              flex: 3,
                              child: pw.Container(
                                alignment: pw.Alignment.center,
                                child: visitorPhoto != null
                                    ? pw.Image(
                                        visitorPhoto,
                                        width: 70,
                                        height: 80,
                                        fit: pw.BoxFit.cover,
                                      )
                                    : pw.Container(
                                        width: 70,
                                        height: 80,
                                        decoration: pw.BoxDecoration(
                                          border: pw.Border.all(
                                            color: PdfColors.black,
                                          ),
                                        ),
                                        alignment: pw.Alignment.center,
                                        child: pw.Text(
                                          'Photo',
                                          style: pw.TextStyle(
                                            font: hindiFont,
                                            fontSize: 8,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),

                        // Signature section
                        pw.Container(
                          padding: const pw.EdgeInsets.only(
                            top: 10,
                            bottom: 0,
                            left: 10,
                            right: 10,
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            mainAxisAlignment: pw.MainAxisAlignment.start,
                            children: [
                              pw.SizedBox(height: 20),
                              pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.SizedBox(
                                    height: 50,
                                    child: _buildSignatureBox(
                                        'Signature of the visitor'),
                                  ),
                                  pw.SizedBox(
                                    height: 50,
                                    child: _buildSignatureBox(
                                        "Duty ASO at Security C/R."),
                                  )
                                ],
                              ),
                              pw.SizedBox(height: 10),
                              pw.Row(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.SizedBox(
                                      height: 50,
                                      child: _buildSignatureBox(
                                        'Signature of the officer visited with time',
                                      ),
                                    ),
                                    pw.Row(
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Text(
                                          'Out Time: ',
                                          style: pw.TextStyle(
                                            fontSize: 8,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                        pw.Text(
                                          '________ Hrs',
                                          style: pw.TextStyle(
                                            fontSize: 8,
                                          ),
                                        ),
                                      ],
                                    ),
                                    pw.Row(
                                      children: [
                                        pw.Text(
                                          'In time: ',
                                          style: pw.TextStyle(
                                            fontSize: 8,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                        pw.Text(
                                          '${regDate.hour}: ${regDate.minute} Hrs',
                                          style: pw.TextStyle(
                                            fontSize: 8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ])
                            ],
                          ),
                        ),

                        // Divider
                        pw.SizedBox(
                          width: PdfPageFormat.a4.width * 0.75,
                          child: pw.Divider(
                            color: PdfColors.black,
                            thickness: 0.5,
                            height: 20,
                          ),
                        ),

                        // Footer with instructions
                        pw.Container(
                          width: PdfPageFormat.a4.width,
                          height: 335,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey100,
                          ),
                          child: pw.Center(
                            child: pw.Image(
                              instructionsImage!,
                              width: 445,
                              fit: pw.BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
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

  pw.Widget _buildHindiText(dynamic hindiImage, String? englishLabel,
      String? value, pw.Font font, double? height, double? width) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 0),
      child: value == null
          ? pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                if (hindiImage != null)
                  pw.Image(hindiImage, height: height ?? 15),
                if (hindiImage != null) pw.SizedBox(width: 2),
                if (englishLabel != null)
                  pw.SizedBox(
                    child: pw.Text(
                      englishLabel,
                      style: pw.TextStyle(
                        font: font,
                        color: PdfColors.black,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                if (englishLabel != null) pw.SizedBox(width: 5),
                if (value != null)
                  pw.Expanded(
                    child: pw.Text(
                      value,
                      style: pw.TextStyle(font: font, fontSize: 9),
                    ),
                  ),
              ],
            )
          : pw.Container(
              width: width,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        margin: const pw.EdgeInsets.only(left: 0),
                        child: pw.Text(
                          '(',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                      ),
                      pw.Image(hindiImage, height: height ?? 10),
                      pw.Container(
                        margin: const pw.EdgeInsets.only(left: 0),
                        child: pw.Text(
                          ')',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.SizedBox(
                        child: pw.Text(
                          englishLabel!,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                      ),
                      pw.Container(
                        margin: const pw.EdgeInsets.only(left: 0, right: 2.5),
                        child: pw.Text(
                          ':',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          value,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  pw.Widget _buildInfoRow(
      String hindiLabel, String englishLabel, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 0),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.SizedBox(
                child: pw.Text(englishLabel,
                    style: pw.TextStyle(
                        fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 5),
              pw.Expanded(
                child: pw.Text(value,
                    style: pw.TextStyle(font: font, fontSize: 9)),
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
            fontSize: 8,
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
          // IconButton(
          //   icon: const Icon(Icons.print),
          //   onPressed: () async {
          //     final bytes = await _pdfFuture;
          //     await Printing.layoutPdf(
          //       onLayout: (_) => Future.value(bytes),
          //       name: 'Visitor Pass',
          //     );
          //   },
          // ),
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
