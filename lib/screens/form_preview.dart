import 'dart:io';
import 'package:docify/services/compress_img.dart';
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
    pw.MemoryImage? ministryLogo;
    try {
      final ByteData data =
          await rootBundle.load('assets/images/ministry_logo.png');
      final Uint8List bytes = data.buffer.asUint8List();
      ministryLogo = pw.MemoryImage(bytes);
    } catch (e) {
      print('Error loading ministry logo: $e');
    }

    // Load emblem logo if available
    pw.MemoryImage? emblemLogo;
    try {
      final ByteData data =
          await rootBundle.load('assets/images/emblem_logo.png');
      final Uint8List bytes = data.buffer.asUint8List();
      emblemLogo = pw.MemoryImage(bytes);
    } catch (e) {
      print('Error loading emblem logo: $e');
    }

    // Create visitor photo placeholder or use actual image if available
    print('Visitor Photo: ${widget.formData['Visitor Photo']}');
    pw.MemoryImage? visitorPhoto = await compressImageForPdf(
        widget.formData['Visitor Photo'],
        maxSizeBytes: 500000 // 500KB limit
        );
    print('Visitor photo loaded and compressed successfully.');

    final regDate = DateTime.now();
    final endHour = (regDate.hour + 3) % 24; // Ensure hour does not exceed 23
    final validDuration =
        "${regDate.hour}:${regDate.minute} to $endHour:${regDate.minute}";

    // Ensure the substring operation is within the valid range
    final regNo = widget.formData['Reg No'] ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final regNoSubstring = regNo.length > 15 ? regNo.substring(5, 15) : regNo;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 1, color: PdfColors.black),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header
                pw.Container(
                  color: PdfColors.lightBlue,
                  padding: const pw.EdgeInsets.symmetric(
                      vertical: 10, horizontal: 20),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      if (ministryLogo != null)
                        pw.Image(ministryLogo, width: 50),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text('गृह मंत्रालय • स्वागत संगठन',
                              style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 12,
                                  color: PdfColors.white)),
                          pw.Text(
                              'MINISTRY OF HOME AFFAIRS • RECEPTION ORGANISATION',
                              style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 10,
                                  color: PdfColors.white)),
                        ],
                      ),
                      if (emblemLogo != null) pw.Image(emblemLogo, width: 30),
                    ],
                  ),
                ),

                // Title & Block info
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      vertical: 10, horizontal: 20),
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text('( Block No. 12 CGO )',
                              style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 7,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text('Daily Visitor Pass',
                              style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Valid Duration
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 20, vertical: 5),
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
                                style: pw.TextStyle(font: ttf, fontSize: 10)),
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
                                style: pw.TextStyle(font: ttf, fontSize: 8)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Reg Info
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 20, vertical: 5),
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
                                style: pw.TextStyle(font: ttf, fontSize: 10)),
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
                                'Reg Date: ${regDate.day}/${regDate.month}/${regDate.year}',
                                style: pw.TextStyle(font: ttf, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Title for visitor details
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 20, vertical: 5),
                  decoration: pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.grey))),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('(आगंतुक विवरण)',
                          style: pw.TextStyle(
                              font: ttf,
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text('Visitor Details',
                          style: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),

                // Main information
                pw.Container(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Left column with visitor info
                      pw.Expanded(
                        flex: 7,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('नाम', 'Name: ',
                                  widget.formData['Name'] ?? '', ttf),
                              pw.SizedBox(height: 3),
                              _buildInfoRow('पिता/पति का नाम', 'F/S Name: ',
                                  widget.formData['F/S Name'] ?? '', ttf),
                              pw.SizedBox(height: 3),
                              _buildInfoRow('लिंग', 'Gender: ',
                                  widget.formData['Gender'] ?? '', ttf),
                              pw.SizedBox(height: 3),
                              _buildInfoRow('मिलने को', 'To Meet: ',
                                  widget.formData['To Meet'] ?? '', ttf),
                              pw.SizedBox(height: 3),
                              _buildInfoRow('अधिकारी का नाम', 'Officer Name: ',
                                  widget.formData['Officer Name'] ?? '', ttf),
                              pw.SizedBox(height: 3),
                              _buildInfoRow(
                                  'अनुमोदन अधिकारी',
                                  'Approving Officer: ',
                                  widget.formData['Approving Officer'] ?? '',
                                  ttf),
                            ],
                          ),
                        ),
                      ),
                      // Right column with address and other info
                      pw.Expanded(
                        flex: 7,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('पता', 'Address: ',
                                  widget.formData['Address'] ?? '', ttf),
                              pw.SizedBox(height: 3),
                              _buildInfoRow('मोबाइल नंबर', 'Mobile No.: ',
                                  widget.formData['Mobile No.'] ?? '', ttf),
                              pw.SizedBox(height: 3),
                              _buildInfoRow('पहचान विवरण', 'ID Details: ',
                                  widget.formData['ID Details'] ?? '', ttf),
                            ],
                          ),
                        ),
                      ),
                      // Photo column
                      pw.Expanded(
                        flex: 3,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          child: pw.Column(
                            children: [
                              pw.Container(
                                width: 80,
                                height: 100,
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(color: PdfColors.black),
                                ),
                                child: visitorPhoto != null
                                    ? pw.Image(visitorPhoto,
                                        fit: pw.BoxFit.cover)
                                    : pw.Center(
                                        child: pw.Text('Photo',
                                            style: pw.TextStyle(
                                                font: ttf, fontSize: 8))),
                              ),
                              pw.SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Additional info section
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        children: [
                          pw.Expanded(
                              child: _buildInfoRow('गैजेट', 'Gadgets: ',
                                  widget.formData['Gadgets'] ?? '', ttf)),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        children: [
                          pw.Expanded(
                              child: _buildInfoRow('उद्देश्य', 'Purpose: ',
                                  widget.formData['Purpose'] ?? '', ttf)),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        children: [
                          pw.Expanded(
                              child: _buildInfoRow('टिप्पणी', 'Remark: ',
                                  widget.formData['Remark'] ?? '', ttf)),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                pw.Container(
                                  width: double.infinity,
                                  height: 1,
                                  color: PdfColors.black,
                                ),
                                pw.SizedBox(height: 5),
                                pw.Text('Signature, Officer Visited',
                                    style:
                                        pw.TextStyle(font: ttf, fontSize: 8)),
                                pw.Text('अधिकारी के हस्ताक्षर',
                                    style:
                                        pw.TextStyle(font: ttf, fontSize: 8)),
                              ],
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                pw.Container(
                                  width: double.infinity,
                                  height: 40,
                                  child: pw.Center(
                                    child: widget.formData['Valid Date'] != null
                                        ? pw.Text(
                                            '${widget.formData['Valid Date']}',
                                            style: pw.TextStyle(
                                                font: ttf,
                                                fontSize: 14,
                                                fontWeight: pw.FontWeight.bold))
                                        : pw.Text(
                                            '${regDate.day}/${regDate.month}/${regDate.year}',
                                            style: pw.TextStyle(
                                                font: ttf,
                                                fontSize: 14,
                                                fontWeight:
                                                    pw.FontWeight.bold)),
                                  ),
                                ),
                                pw.Text('Valid Date',
                                    style:
                                        pw.TextStyle(font: ttf, fontSize: 8)),
                                pw.Text('वैध तिथि',
                                    style:
                                        pw.TextStyle(font: ttf, fontSize: 8)),
                              ],
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                pw.Container(
                                  width: double.infinity,
                                  height: 40,
                                  decoration: pw.BoxDecoration(
                                    border:
                                        pw.Border.all(color: PdfColors.white),
                                  ),
                                  child: pw.Transform.rotate(
                                    angle: 0.2,
                                    child: pw.Center(
                                      child: pw.Container(
                                        height: 1,
                                        width: 100,
                                        color: PdfColors.blue,
                                      ),
                                    ),
                                  ),
                                ),
                                pw.Text('Sr. Reception/ Reception Officer',
                                    style:
                                        pw.TextStyle(font: ttf, fontSize: 8)),
                                pw.Text('वरिष्ठ स्वागत/ स्वागत अधिकारी',
                                    style:
                                        pw.TextStyle(font: ttf, fontSize: 8)),
                                pw.Text('(Arvind Kumar)',
                                    style:
                                        pw.TextStyle(font: ttf, fontSize: 8)),
                                pw.Text('Reception, Block No. 12 CGO',
                                    style:
                                        pw.TextStyle(font: ttf, fontSize: 6)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.Expanded(child: pw.Container()), // Fill remaining space

                // Instructions
                pw.Container(
                  color: PdfColors.lightBlue,
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Column(
                    children: [
                      pw.Text('INSTRUCTIONS/निशा निर्देश',
                          style: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'VISITOR SHOULD NOT ROAM AROUND THE OFFICES IN THE GOVERNMENT BUILDING EXCEPT THE OFFICE TO BE VISITED AND HE/SHE MUST RETURN THE PASS TO SECURITY PERSONNEL AFTER THE VISIT.',
                        style: pw.TextStyle(
                            font: ttf, fontSize: 8, color: PdfColors.white),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Footer
                pw.Container(
                  color: PdfColors.lightBlue,
                  padding: const pw.EdgeInsets.symmetric(
                      vertical: 5, horizontal: 20),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('MINISTRY OF HOME AFFAIRS',
                          style: pw.TextStyle(
                              font: ttf, fontSize: 10, color: PdfColors.white)),
                      pw.Text('•',
                          style: pw.TextStyle(
                              font: ttf, fontSize: 10, color: PdfColors.white)),
                      pw.Text('RECEPTION ORGANISATION',
                          style: pw.TextStyle(
                              font: ttf, fontSize: 10, color: PdfColors.white)),
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
          pw.Text('($hindiLabel)',
              style: pw.TextStyle(
                  font: ttf, fontSize: 6, fontWeight: pw.FontWeight.bold)),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 100,
                child: pw.Text(englishLabel,
                    style: pw.TextStyle(
                        font: ttf,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.normal)),
              ),
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
            // The key change is here:
            build: (_) => Future.value(snapshot.data!),
            allowPrinting: true,
            allowSharing: true,
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
    {int maxSizeBytes = 500000}) async {
  if (path == null) return null;

  try {
    final imageFile = File(path);
    if (await imageFile.exists()) {
      final bytes = await imageFile.readAsBytes();
      print('Image size: ${bytes.length} bytes');

      // If the image is within the size limit, use it directly
      if (bytes.length <= maxSizeBytes) {
        return pw.MemoryImage(bytes);
      }

      // Try to compress the image
      // final compressedBytes =
      //     await compressImageToBytes(path, maxSizeBytes: maxSizeBytes);

      // if (compressedBytes != null) {
      //   print('Compressed image size: ${compressedBytes.length} bytes');
      //   print(
      //       'Compression ratio: ${(bytes.length / compressedBytes.length).toStringAsFixed(2)}x');
      //   return pw.MemoryImage(compressedBytes);
      // }

      // If compression fails, use a placeholder
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

  // If all else fails, return null
  return null;
}
