import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart'; // For rootBundle.load()
import 'package:path_provider/path_provider.dart'; // For saving PDF
import 'package:permission_handler/permission_handler.dart'; // For storage permission

import 'package:pdf/pdf.dart'; // ⬅ PDF color & metadata
import 'package:pdf/widgets.dart'
as pw;

import 'Edit_Reception_Data/edit_reception_data.dart'; // ⬅ PDF widgets (Document, MultiPage, etc.)

class Showreceptiondata extends StatefulWidget {
  @override
  _ShowreceptiondataState createState() => _ShowreceptiondataState();
}

class _ShowreceptiondataState extends State<Showreceptiondata> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();

  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _requestStoragePermission();
  }

  Future<void> _selectDate({required bool isStart}) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate =
    isStart ? (_startDate ?? now) : (_endDate ?? now);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _deleteRecord(String docId) async {
    try {
      await _firestore.collection('ReceptionPage').doc(docId).delete();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Reception Record deleted successfully',
            style:
            TextStyle(fontFamily: "Times New Roman", color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Error deleting record: $e',
            style:
            TextStyle(fontFamily: "Times New Roman", color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        // Android 13+
        final photos = await Permission.photos.request();
        final videos = await Permission.videos.request();
        final audio = await Permission.audio.request();
        final manage = await Permission.manageExternalStorage.request(); // optional, risky for Play Store

        return photos.isGranted || videos.isGranted || audio.isGranted || manage.isGranted;
      } else {
        // Android 12 અને નીચે
        final storage = await Permission.storage.request();
        return storage.isGranted;
      }
    }
    return true; // iOS → no problem
  }





  void showCustomSnackBar(BuildContext context, String message, String filePath) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 30,
        left: 16,
        right: 16,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF4B5563),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message, // 👈 Dynamic message (PDF / Excel)
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        filePath,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final file = File(filePath);
                    if (await file.exists()) {
                      final result = await OpenFile.open(filePath);
                      if (result.type != ResultType.done) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not open file: ${result.message}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('File not found at: $filePath'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    overlayEntry.remove();
                  },
                  child: Text(
                    'OPEN',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay!.insert(overlayEntry);

    Future.delayed(Duration(seconds: 5), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }


  Future<void> exportReceptionDataAsExcel({
    required List<QueryDocumentSnapshot> docs,
    required BuildContext context,
  }) async {
    final excel = xls.Excel.createExcel();
    final xls.Sheet sheet = excel['Reception Reports'];

    // Define headers
    final headers = [
      'Client Name',
      'Phone Number',
      'Whatsapp Number'
          'Email',
      'Assigned Staff',
      'Appointment Date',
      'Appointment Time',
      'Location',
      'Meeting Purpose',
      'Task Due Date',
      'Task Priority',
      'Task Status',
      'Meeting Status',
    ];

    // Header style
    final xls.CellStyle headerStyle = xls.CellStyle(
      bold: true,
      fontColorHex: xls.ExcelColor.fromHexString("#FFFFFF"),
      backgroundColorHex: xls.ExcelColor.fromHexString("#0F172A"),
      horizontalAlign: xls.HorizontalAlign.Center,
      verticalAlign: xls.VerticalAlign.Center,
      fontFamily: 'Calibri',
    );
    // Write headers
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet
          .cell(xls.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = xls.TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Write data rows
    for (int row = 0; row < docs.length; row++) {
      final data = docs[row].data() as Map<String, dynamic>;
      final values = [
        data['client_name'] ?? 'N/A',
        data['phone_number'] ?? 'N/A',
        data['whatsaapp_number'] ?? 'N/A',
        data['email'] ?? 'N/A',
        data['assigned_staff'] ?? 'N/A',
        data['appointment_date'] ?? 'N/A',
        data['appointment_time'] ?? 'N/A',
        data['location'] ?? 'N/A',
        data['meeting_purpose'] ?? 'N/A',
        data['task_due_date'] ?? 'N/A',
        data['task_priority'] ?? 'N/A',
        data['task_status'] ?? 'N/A',
        data['client_meeting_status'] ?? 'N/A',
      ];

      for (int col = 0; col < values.length; col++) {
        final cell = sheet.cell(xls.CellIndex.indexByColumnRow(
            columnIndex: col, rowIndex: row + 1));
        cell.value = values[col];
      }
    }

    // Request storage permission
    // Request permission
    final granted = await _requestStoragePermission();
    if (!granted) {
      showCustomSnackBar(context, 'Storage permission denied.','');
      return;
    }


    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        showCustomSnackBar(context, 'Failed to access storage.','');
        return;
      }


      final filePath =
          '${directory.path}/ReceptionReport_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final fileBytes = excel.encode();
      final file = File(filePath);
      await file.writeAsBytes(fileBytes!);

      showCustomSnackBar(context, 'Excel saved successfully!', filePath);
    } catch (e) {
      showCustomSnackBar(context, 'Error saving Excel file: $e','');
    }
  }




  Future<void> exportReceptionDataAsPDF(
      List<QueryDocumentSnapshot> docs, BuildContext context) async {
    final pdf = pw.Document();

    // Load logo
    final ByteData logoData = await rootBundle.load('assets/images/ppo.jpg');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    final pw.ImageProvider logoImage = pw.MemoryImage(logoBytes);

    // Load icons
    Future<pw.MemoryImage> loadIcon(String path) async {
      final data = await rootBundle.load(path);
      return pw.MemoryImage(data.buffer.asUint8List());
    }

    final phoneIcon = await loadIcon('assets/images/call.png');
    final emailIcon = await loadIcon('assets/images/mes.png');
    final personIcon = await loadIcon('assets/images/prof.png');
    final calendarIcon = await loadIcon('assets/images/cal.png');

    final icons = {
      'phone': phoneIcon,
      'email': emailIcon,
      'person': personIcon,
      'calendar': calendarIcon,
    };

    // Build the PDF content
    pdf.addPage(
      pw.MultiPage(
        margin: pw.EdgeInsets.all(24),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Center(
              child: pw.Container(
                width: 80,
                height: 80,
                child: pw.Image(logoImage),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Reception Report',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo800,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              DateFormat('dd MMM yyyy').format(DateTime.now()),
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            ),
            pw.Divider(),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ),
        build: (context) => docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return buildReceptionRecord(data, icons);
        }).toList(),
      ),
    );

    // Request permission
    final granted = await _requestStoragePermission();
    if (!granted) {
      showCustomSnackBar(context, 'Storage permission denied.','');
      return;
    }


    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        showCustomSnackBar(context, 'Failed to access storage.','');
        return;
      }

      final filePath =
          '${directory.path}/ReceptionReport_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);

      await file.writeAsBytes(await pdf.save());

      showCustomSnackBar(context, 'PDF saved successfully!', filePath);
    } catch (e) {
      showCustomSnackBar(context, 'Error saving PDF: $e','');
    }
  }

  pw.Widget buildReceptionRecord(
      Map<String, dynamic> data, Map<String, pw.ImageProvider> icons) {
    return pw.Container(
      padding: pw.EdgeInsets.all(12),
      margin: pw.EdgeInsets.only(bottom: 16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Client Information',
            style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo900),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            columnWidths: {
              0: pw.FixedColumnWidth(20),
              1: pw.FlexColumnWidth(),
              2: pw.FlexColumnWidth(),
            },
            children: [
              _buildTableRow(
                  icons['person']!, 'Client Name', data['client_name'],
                  'Phone', data['phone_number']),
              _buildTableRow(
                  icons['email']!, 'Email', data['email'],
                  'Assigned Staff', data['assigned_staff']),
              _buildTableRow(
                  icons['phone']!, 'Whatsapp', data['whatsaapp_number'],
                  '', ''),
            ],
          ),

          pw.SizedBox(height: 12),
          pw.Text(
            'Appointment Information',
            style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo900),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            columnWidths: {
              0: pw.FixedColumnWidth(20),
              1: pw.FlexColumnWidth(),
              2: pw.FlexColumnWidth(),
            },
            children: [
              _buildTableRow(icons['calendar']!, 'Date',
                  data['appointment_date'], 'Time', data['appointment_time']),
              _buildTableRow(icons['person']!, 'Location', data['location'],
                  'Purpose', data['meeting_purpose']),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Task Information',
            style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo900),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            columnWidths: {
              0: pw.FixedColumnWidth(20),
              1: pw.FlexColumnWidth(),
              2: pw.FlexColumnWidth(),
            },
            children: [
              _buildTableRow(icons['calendar']!, 'Due Date',
                  data['task_due_date'], 'Priority', data['task_priority']),
              _buildTableRow(
                  icons['person']!,
                  'Task Status',
                  data['task_status'],
                  'Meeting Status',
                  data['client_meeting_status']),
            ],
          ),
        ],
      ),
    );
  }

  pw.TableRow _buildTableRow(
      pw.ImageProvider icon,
      String label1,
      dynamic value1,
      String label2,
      dynamic value2,
      ) {
    return pw.TableRow(
      children: [
        pw.Container(
          width: 20,
          height: 20,
          margin: pw.EdgeInsets.only(top: 4),
          child: pw.Image(icon),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label1,
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.Text(value1?.toString() ?? 'N/A',
                style:
                pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label2,
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.Text(value2?.toString() ?? 'N/A',
                style:
                pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.blue.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.info,
                color: Colors.white,
              ),
              SizedBox(width: 10),
              Text(
                "Meeting Summary",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 1.5,
                  color: Colors.white,
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0A2A5A), // Deep navy blue
                      Color(0xFF15489C), // Strong steel blue
                      Color(0xFF1E64D8), // Vivid rich blue
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade900.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Search by Clientname...',
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    hintText: 'Enter Client full name',
                    hintStyle: TextStyle(
                      color: Colors.cyan.shade300,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Icon(Icons.search, color: Colors.white),
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(10),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _selectDate(isStart: true),
                  icon: Icon(
                    Icons.date_range,
                    color: Colors.white,
                  ),
                  label: Text(
                    _startDate != null
                        ? 'From: ${DateFormat('dd MMM yyyy').format(_startDate!)}'
                        : 'Start Date',
                    style: TextStyle(
                        fontFamily: "Times New Roman", color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5))),
                ),
                ElevatedButton.icon(
                  onPressed: () => _selectDate(isStart: false),
                  icon: Icon(
                    Icons.date_range,
                    color: Colors.white,
                  ),
                  label: Text(
                    _endDate != null
                        ? 'To: ${DateFormat('dd MMM yyyy').format(_endDate!)}'
                        : 'End Date',
                    style: TextStyle(
                        fontFamily: "Times New Roman", color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5))),
                ),
              ],
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('ReceptionPage').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No Reception info available!',
                          style: TextStyle(
                            fontFamily: 'Times New Roman',
                          ),
                        ),
                      );
                    }
                    final filteredDocs = snapshot.data!.docs.where((doc) {
                      final clientName =
                      (doc['client_name'] ?? '').toString().toLowerCase();
                      final dateString = doc['appointment_date'] ?? '';
                      DateTime? appointmentDate;

                      try {
                        appointmentDate = DateTime.parse(dateString);
                      } catch (e) {
                        return false;
                      }

                      final matchesSearch =
                      clientName.contains(_searchQuery.toLowerCase());
                      final matchesStartDate = _startDate == null ||
                          appointmentDate
                              .isAfter(_startDate!.subtract(Duration(days: 1)));
                      final matchesEndDate = _endDate == null ||
                          appointmentDate
                              .isBefore(_endDate!.add(Duration(days: 1)));

                      return matchesSearch &&
                          matchesStartDate &&
                          matchesEndDate;
                    }).toList();

                    String _formatDate(String rawDate) {
                      try {
                        final DateTime parsedDate = DateTime.parse(rawDate);
                        return DateFormat('dd MMMM yy').format(parsedDate); // Changed 'yyyy' to 'yy'
                      } catch (e) {
                        return rawDate; // Fallback to original if parsing fails
                      }
                    }


                    if (filteredDocs.isEmpty) {
                      return Center(
                        child: Text(
                          'No data between selected dates!',
                          style: TextStyle(
                            fontFamily: 'Times New Roman',
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

// ✅ Export button before the list
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ✅ Export PDF Button
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    if (filteredDocs.isNotEmpty) {
                                      await exportReceptionDataAsPDF(filteredDocs, context);
                                    } else {
                                      showCustomSnackBar(context, 'No data to export.', '');
                                    }
                                  },
                                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                                  label: const Text(
                                    'Export as PDF',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // ✅ Export Excel Button
                                ElevatedButton.icon(
                                  onPressed: () {
                                    print(
                                        '📊 Exporting ${filteredDocs.length} reception records to Excel');
                                    exportReceptionDataAsExcel(
                                        docs: filteredDocs, context: context);
                                  },
                                  icon: const Icon(Icons.grid_on, color: Colors.white),
                                  label: const Text(
                                    'Export as Excel',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),


                    Expanded(
                          child: ListView.builder(
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              final doc = filteredDocs[index];

                              return Builder(
                                builder: (BuildContext newContext) {
                                  return Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Dismissible(
                                      key: Key(doc.id),
                                      direction: DismissDirection.endToStart,
                                      confirmDismiss: (direction) async {
                                        final delete =
                                        await _showDeleteConfirmationDialog();
                                        return delete == true;
                                      },
                                      onDismissed: (direction) async {
                                        await _deleteRecord(
                                            doc.id); // now no context needed
                                      },
                                      background: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.cyanAccent,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Padding(
                                            padding:
                                            const EdgeInsets.only(right: 20.0),
                                            child: Icon(Icons.delete,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF0A2A5A),
                                              Color(0xFF15489C),
                                              Color(0xFF1E64D8),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blue.shade900
                                                  .withOpacity(0.2),
                                              blurRadius: 10,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        padding: EdgeInsets.all(15.0),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text("Employee Information",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: "Times New Roman",
                                                    fontSize: 16,
                                                    color: Colors.white)),
                                            buildFormField(
                                              'Employee Name: ',
                                              (() {
                                                final empInfo = doc['emp_info'];

                                                if (empInfo is List) {
                                                  return empInfo.join(', ');
                                                } else if (empInfo is String) {
                                                  return empInfo;
                                                } else {
                                                  return 'N/A';
                                                }
                                              })(),
                                            ),
                                            SizedBox(
                                              height: 10,
                                            ),
                                            Text("Client Information",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: "Times New Roman",
                                                    fontSize: 16,
                                                    color: Colors.white)),
                                            SizedBox(
                                              height: 10,
                                            ),
                                            buildFormField('Client Full Name: ',
                                                doc['client_name']),

                                            buildTappableField('Contact Number:', doc['phone_number'],_launchPhone),
                                            buildTappableField('Whatsapp Number:',
                                                doc['whatsaapp_number'],_launchWhatsApp),
                                            SizedBox(
                                              height: 10,
                                            ),
                                            Text(
                                              "Appointment Scheduling",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: "Times New Roman",
                                                  fontSize: 16,
                                                  color: Colors.white),
                                            ),
                                            SizedBox(
                                              height: 10,
                                            ),
                                            buildFormField(
                                                'Appointment Date: ',
                                                _formatDate(
                                                    doc['appointment_date'])),
                                            buildFormField('Appointment Time: ',
                                                doc['appointment_time']),
                                            buildFormField('Meeting Purpose: ',
                                                doc['meeting_purpose']),
                                            buildFormField('Meeting Location: ',
                                                doc['location']),
                                            buildFormField('Assigned Staff/CEO: ',
                                                doc['assigned_staff']),
                                            SizedBox(
                                              height: 10,
                                            ),
                                            Text(
                                              "Task Management",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: "Times New Roman",
                                                  fontSize: 16,
                                                  color: Colors.white),
                                            ),
                                            SizedBox(
                                              height: 10,
                                            ),
                                            buildFormField('Task Priority: ',
                                                doc['task_priority']),
                                            buildFormField('Task Due Date: ',
                                                _formatDate(doc['task_due_date'])),
                                            buildFormField('Task Status: ',
                                                doc['task_status']),
                                            buildFormField(
                                                'Client Meeting Status: ',
                                                doc['client_meeting_status']),
                                            SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment.end,
                                              children: [
                                                Container(
                                                  child: FloatingActionButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .push(MaterialPageRoute(
                                                        builder: (context) =>
                                                            Editreceptionpage(
                                                              docId: doc.id,
                                                              initialData: doc.data()
                                                              as Map<String,
                                                                  dynamic>,
                                                            ),
                                                      ));
                                                    },
                                                    backgroundColor:
                                                    Color(0xFF0A2A5A),
                                                    child: const Icon(Icons.edit,
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ))
                    ]);
                  }),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFormField(String title, String value) {
    final isLocationField = title.toLowerCase().contains('location');
    final isPhoneField = title.toLowerCase().contains('contact number');
    final isWhatsappField = title.toLowerCase().contains('whatsapp');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Arial',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () async {
                    if (isLocationField && value.isNotEmpty) {
                      final encodedLocation = Uri.encodeComponent(value);
                      final googleMapsUrl =
                          'https://www.google.com/maps/search/?api=1&query=$encodedLocation';
                      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
                        await launchUrl(Uri.parse(googleMapsUrl),
                            mode: LaunchMode.externalApplication);
                      }
                    } else if (isPhoneField && value.isNotEmpty) {
                      final phoneUrl = Uri.parse("tel:$value");
                      if (await canLaunchUrl(phoneUrl)) {
                        await launchUrl(phoneUrl, mode: LaunchMode.externalApplication);
                      }
                    }else if (isWhatsappField && value.isNotEmpty) {
                      final cleanNumber = value.replaceAll(RegExp(r'[^0-9]'), ''); // keep only digits
                      final whatsappUrl = Uri.parse("https://wa.me/91$cleanNumber");

                      if (await canLaunchUrl(whatsappUrl)) {
                        await launchUrl(
                          whatsappUrl,
                          mode: LaunchMode.externalApplication, // 🔥 open directly in WhatsApp
                        );
                      } else {
                        print("❌ WhatsApp not installed on device or invalid number");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("WhatsApp not installed or invalid number")),
                        );
                      }
                    }



                  },


                child: Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Arial',
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: (isLocationField || isPhoneField || isWhatsappField)
                          ? Colors.lightBlueAccent
                          : Colors.white,
                      decoration: (isLocationField ||
                          isPhoneField ||
                          isWhatsappField)
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            ],
          ),
    ]
    ),
    );
  }


  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.blue.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.all(15.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Delete Confirmation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Are you sure you want to delete this record?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors
                        .cyan.shade100, // Cyan accent for the content text
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.cyanAccent.shade200,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


Future<void> _launchPhone(String phoneNumber) async {
  final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
  if (await canLaunchUrl(phoneUri)) {
    await launchUrl(phoneUri);
  }
}

Future<void> _launchWhatsApp(String number) async {
  // clean digits only (e.g., remove spaces, +, -)
  final cleanNumber = number.replaceAll(RegExp(r'[^0-9]'), '');

  // 👇 WhatsApp direct app scheme
  final whatsappUri = Uri.parse("https://wa.me/91$cleanNumber");

  if (await canLaunchUrl(whatsappUri)) {
    await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
  } else {
    // fallback → open in browser
    final fallbackUri = Uri.parse("https://wa.me/$cleanNumber");
    if (await canLaunchUrl(fallbackUri)) {
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    } else {
      print("❌ Could not launch WhatsApp");
    }
  }
}


Widget buildTappableField(String title, String value, Function(String) onTap) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(title, style: TextStyle(fontFamily: 'Arial', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
            ),
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: () => onTap(value),
                child: Text(value, style: TextStyle(decoration: TextDecoration.underline, fontFamily: 'Arial', fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}