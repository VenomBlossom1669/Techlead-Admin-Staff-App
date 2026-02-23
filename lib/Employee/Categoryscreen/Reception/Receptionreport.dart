// Dart core
import 'dart:io';
import 'dart:typed_data';

// Flutter & UI
import 'package:device_info_plus/device_info_plus.dart';
import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Firebase
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Utils
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

// PDF generation
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// Internal files
import 'package:techlead/Admin/Meetingsection/Edit_Reception_Data/edit_reception_data.dart';

class Receptionreport extends StatefulWidget {
  @override
  _ReceptionreportState createState() => _ReceptionreportState();
}

class _ReceptionreportState extends State<Receptionreport> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
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
    final status = await Permission.storage.request();
    if (!status.isGranted) {
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

  String _extractEmpInfo(dynamic empInfoField) {
    if (empInfoField is List) {
      return empInfoField.join(', ');
    } else if (empInfoField is String) {
      return empInfoField;
    }
    return 'N/A';
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null) return 'N/A';
    try {
      final parsedDate = DateTime.parse(rawDate);
      return DateFormat('dd MMM yyyy').format(parsedDate);
    } catch (e) {
      return rawDate; // fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          SizedBox(
            height: 10,
          ),


          Expanded(
            child: currentUserId == null
                ? const Center(child: Text("User not logged in"))
                : FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('EmpProfile')
                    .doc(currentUserId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(
                      child: Text(
                        "User profile not found.",
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final empFullName = snapshot.data!
                      .get('fullName')
                      .toString()
                      .trim()
                      .toLowerCase();
                  print("👤 Logged-in user: $empFullName");

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('ReceptionPage')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No Reception info available!',
                            style: TextStyle(fontFamily: 'Times New Roman'),
                          ),
                        );
                      }

                      final filteredDocs = snapshot.data!.docs.where((doc) {
                        final empInfoField = doc['emp_info'];
                        final dateString = doc['appointment_date'] ?? '';
                        DateTime? appointmentDate;

                        try {
                          appointmentDate = DateTime.parse(dateString);
                        } catch (e) {
                          return false; // Skip invalid date formats
                        }

                        List<String> empList = [];

                        if (empInfoField is List) {
                          empList = List<String>.from(empInfoField)
                              .map((e) => e.toLowerCase().trim())
                              .toList();
                        } else if (empInfoField is String) {
                          empList = empInfoField
                              .toLowerCase()
                              .split(',')
                              .map((e) => e.trim())
                              .toList();
                        }

                        final isAssigned = empList.contains(empFullName);

                        final clientName = (doc['client_name'] ?? '')
                            .toString()
                            .toLowerCase();

                        final matchesSearch = _searchQuery.isEmpty ||
                            clientName.contains(_searchQuery.toLowerCase());

                        final matchesStartDate = _startDate == null ||
                            appointmentDate.isAfter(_startDate!
                                .subtract(const Duration(days: 1)));

                        final matchesEndDate = _endDate == null ||
                            appointmentDate.isBefore(
                                _endDate!.add(const Duration(days: 1)));

                        return isAssigned &&
                            matchesSearch &&
                            matchesStartDate &&
                            matchesEndDate;
                      }).toList();

                      String _formatDate(String rawDate) {
                        try {
                          final DateTime parsedDate =
                          DateTime.parse(rawDate);
                          return DateFormat('dd MMMM yyyy')
                              .format(parsedDate);
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
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

// ✅ Export Button and ListView.builder share the same filteredDocs scope
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // ✅ Export Reception as PDF Button
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

                                  // ✅ Export Reception as Excel Button
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
                                return Padding(
                                  padding: const EdgeInsets.all(10),
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
                                          color: Colors.blue.shade900.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    padding: EdgeInsets.all(15.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Employee Information",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontFamily: "Times New Roman",
                                                fontSize: 16,
                                                color: Colors.white)),
                                        SizedBox(height: 10),
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
                                        SizedBox(height: 10),
                                        Text("Client Information",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontFamily: "Times New Roman",
                                                fontSize: 16,
                                                color: Colors.white)),
                                        SizedBox(height: 10),
                                        buildFormField('Client Full Name: ', doc['client_name']),

                                        buildTappableField('Contact Number:', doc['phone_number'],_launchPhone),
                                        buildTappableField('Whatsapp Number:',
                                            doc['whatsaapp_number'],_launchWhatsApp),
                                        SizedBox(height: 10),
                                        Text(
                                          "Appointment Scheduling",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontFamily: "Times New Roman",
                                              fontSize: 16,
                                              color: Colors.white),
                                        ),
                                        SizedBox(height: 10),
                                        buildFormField('Appointment Date: ',
                                            _formatDate(doc['appointment_date'])),
                                        buildFormField(
                                            'Appointment Time: ', doc['appointment_time']),
                                        buildFormField('Meeting Purpose: ', doc['meeting_purpose']),
                                        buildFormField('Meeting Location: ', doc['location']),
                                        buildFormField(
                                            'Assigned Staff/CEO: ', doc['assigned_staff']),
                                        SizedBox(height: 10),
                                        Text(
                                          "Task Management",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontFamily: "Times New Roman",
                                              fontSize: 16,
                                              color: Colors.white),
                                        ),
                                        SizedBox(height: 10),
                                        buildFormField('Task Priority: ', doc['task_priority']),
                                        buildFormField(
                                            'Task Due Date: ', _formatDate(doc['task_due_date'])),
                                        buildFormField('Task Status: ', doc['task_status']),
                                        buildFormField(
                                            'Client Meeting Status: ', doc['client_meeting_status']),
                                        SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            FloatingActionButton(
                                              onPressed: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) => Editreceptionpage(
                                                      docId: doc.id,
                                                      initialData:
                                                      doc.data() as Map<String, dynamic>,
                                                    ),
                                                  ),
                                                );
                                              },
                                              backgroundColor: Color(0xFF0A2A5A),
                                              child: const Icon(Icons.edit, color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );


                      return ListView.builder(
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          return Padding(
                            padding: const EdgeInsets.all(10),
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
                                  SizedBox(
                                    height: 10,
                                  ),
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
                                  buildFormField('Contact Number:',
                                      doc['phone_number']),
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
                                  buildFormField('Appointment Date: ',
                                      _formatDate(doc['appointment_date'])),
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
                                  buildFormField(
                                      'Task Status: ', doc['task_status']),
                                  buildFormField('Client Meeting Status: ',
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
                                                    as Map<String, dynamic>,
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
                          );
                        },
                      );
                    },
                  );
                }),
          ),
        ],
      ),
    );
  }

  Widget buildFormField(String title, String value) {
    final isLocationField = title.toLowerCase().contains('location');

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
                  onTap: isLocationField && value.isNotEmpty
                      ? () async {
                    final encodedLocation = Uri.encodeComponent(value);
                    final googleMapsUrl =
                        'https://www.google.com/maps/search/?api=1&query=$encodedLocation';
                    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
                      await launchUrl(Uri.parse(googleMapsUrl),
                          mode: LaunchMode.externalApplication);
                    } else {
                      debugPrint('Could not open map for $value');
                    }
                  }
                      : null,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Arial',
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: isLocationField
                          ? Colors.lightBlueAccent
                          : Colors.white,
                      decoration: isLocationField
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
        ],
      ),
    );
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