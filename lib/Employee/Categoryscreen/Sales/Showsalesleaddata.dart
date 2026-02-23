import 'package:device_info_plus/device_info_plus.dart';
import 'package:excel/excel.dart';
import 'package:excel/excel.dart' as xls;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:techlead/Admin/Sales/Edit_Sales_Info_Page.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class Showsalesleaddata extends StatefulWidget {
  @override
  _ShowsalesleaddataState createState() => _ShowsalesleaddataState();
}

class _ShowsalesleaddataState extends State<Showsalesleaddata> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _requestStoragePermission();
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
        final manage = await Permission.manageExternalStorage
            .request(); // optional, risky for Play Store

        return photos.isGranted ||
            videos.isGranted ||
            audio.isGranted ||
            manage.isGranted;
      } else {
        // Android 12 અને નીચે
        final storage = await Permission.storage.request();
        return storage.isGranted;
      }
    }
    return true; // iOS → no problem
  }

  Future<void> _deleteRecord(String docId) async {
    try {
      await _firestore.collection('Salesinfo').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sales Record deleted successfully',
              style: TextStyle(
                  fontFamily: "Times New Roman", color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting record: $e',
              style: TextStyle(
                  fontFamily: "Times New Roman", color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String formatReportedDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('dd-MMMM-yyyy hh:mm:ss a').format(timestamp.toDate());
    } else if (timestamp is DateTime) {
      return DateFormat('dd-MMMM-yyyy hh:mm:ss a').format(timestamp);
    } else {
      return 'N/A';
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

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(
        emailLaunchUri,
        mode: LaunchMode.externalApplication, // ✅ open Gmail/Outlook
      );
    } else {
      print("❌ No email app found");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No email app installed on this device")),
      );
    }
  }

  void showCustomSnackBar(BuildContext context, String message,
      String filePath) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) =>
          Positioned(
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
                                content:
                                Text('Could not open file: ${result.message}'),
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

  Future<void> exportSalesDataAsPDF(List<QueryDocumentSnapshot> docs,
      BuildContext context) async {
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

    // Build PDF pages
    pdf.addPage(
      pw.MultiPage(
        margin: pw.EdgeInsets.all(24),
        header: (context) =>
            pw.Column(
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
                  'Sales Report',
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
        footer: (context) =>
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ),
        build: (context) =>
            docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return buildSalesRecord(data, icons);
            }).toList(),
      ),
    );

    // Request permission
    // ✅ નવું
    final granted = await _requestStoragePermission();
    if (!granted) {
      showCustomSnackBar(context, 'Storage permission denied.', '');
      return;
    }

    try {
      final directory = await getExternalStorageDirectory();

      if (directory == null) {
        showCustomSnackBar(context, 'Failed to access storage.', '');
        return;
      }

      final filePath =
          '${directory.path}/SalesReport_${DateTime
          .now()
          .millisecondsSinceEpoch}.pdf';
      final file = File(filePath);

      await file.writeAsBytes(await pdf.save());

      showCustomSnackBar(context, 'PDF saved successfully!', filePath);
    } catch (e) {
      showCustomSnackBar(context, 'Error saving PDF: $e', '');
    }
  }

  pw.Widget buildSalesRecord(Map<String, dynamic> data,
      Map<String, pw.ImageProvider> icons) {
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
            'Contact Information',
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
              3: pw.FlexColumnWidth(), // for WhatsApp
            },
            children: [
              _buildTableRow(
                icons['person']!,
                'Lead Owner',
                data['executivename'],
                'Full Name',
                data['fullName'],
              ),
              _buildTableRow(
                icons['phone']!,
                'Contact',
                data['contactNumber'],
                'Email',
                data['email'],
                'WhatsApp',
                data['whatsappNumber'], // ✅ added WhatsApp
              ),
              _buildTableRow(
                icons['person']!,
                'Contact Method',
                data['preferredContactMethod'],
                'Lead Source',
                data['leadSource'],
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Lead Details',
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
              _buildTableRow(icons['person']!, 'Lead Type', data['leadType'],
                  'Property Type', data['propertyType']),
              _buildTableRow(
                  icons['person']!,
                  'Property Size',
                  data['propertySize'],
                  'Automation Setup',
                  data['currentHomeAutomation']),
              _buildTableRow(icons['person']!, 'Budget', data['budgetRange'],
                  'Reported', formatReportedDateTime(data['reportedDateTime'])),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Additional Details',
            style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo900),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                  width: 20, height: 20, child: pw.Image(icons['person']!)),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: pw.Text(data['additionalDetails'] ?? 'N/A',
                    style: pw.TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.TableRow _buildTableRow(pw.ImageProvider icon, String label1,
      dynamic value1, String label2, dynamic value2,
      [String? label3, dynamic value3] // optional 3rd column
      ) {
    final children = <pw.Widget>[
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
    ];

    // Add third column if provided
    if (label3 != null) {
      children.add(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label3,
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.Text(value3?.toString() ?? 'N/A',
                style:
                pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );
    }

    return pw.TableRow(children: children);
  }

  Future<void> exportSalesDataAsExcel({
    required List<QueryDocumentSnapshot> docs,
    required BuildContext context,
  }) async {
    final excel = xls.Excel.createExcel();
    final xls.Sheet sheet = excel['Sales Report'];

    // Add header row with column names
    final headers = [
      'Full Name',
      'Contact Number',
      'Whatsapp Number',
      'Email',
      'Executive Name',
      'Lead Source',
      'Preferred Contact Method',
      'Lead Type',
      'Property Type',
      'Property Size',
      'Budget Range',
      'Current Home Automation',
      'Reported Date & Time',
      'Additional Details',
    ];

    // Header styling
    final headerStyle = xls.CellStyle(
      bold: true,
      fontColorHex: xls.ExcelColor.fromHexString("#FFFFFF"),
      backgroundColorHex: xls.ExcelColor.fromHexString("#0F172A"),
      horizontalAlign: xls.HorizontalAlign.Center,
      verticalAlign: xls.VerticalAlign.Center,
    );

    // Write headers
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        xls.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = xls.TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    for (int row = 0; row < docs.length; row++) {
      final data = docs[row].data() as Map<String, dynamic>;

      final values = [
        data['fullName'] ?? '',
        data['contactNumber'] ?? '',
        data['whatsappNumber'] ?? '',
        data['email'] ?? '',
        data['executivename'] ?? '',
        data['leadSource'] ?? '',
        data['preferredContactMethod'] ?? '',
        data['leadType'] ?? '',
        data['propertyType'] ?? '',
        data['propertySize'] ?? '',
        data['budgetRange'] ?? '',
        data['currentHomeAutomation'] ?? '',
        formatReportedDateTime(data['reportedDateTime']),
        data['additionalDetails'] ?? '',
      ];

      for (int col = 0; col < values.length; col++) {
        final cell = sheet.cell(
          xls.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1),
        );

        cell.value = xls.TextCellValue(values[col].toString());
      }
    }

    // Request permission
    final granted = await _requestStoragePermission();
    if (!granted) {
      showCustomSnackBar(context, 'Storage permission denied.', '');
      return;
    }

    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        showCustomSnackBar(context, 'Failed to access storage.', '');
        return;
      }

      final filePath =
          '${dir.path}/SalesReport_${DateTime
          .now()
          .millisecondsSinceEpoch}.xlsx';
      final fileBytes = excel.encode();
      final file = File(filePath)
        ..createSync(recursive: true);
      await file.writeAsBytes(fileBytes!);

      showCustomSnackBar(context, 'Excel saved successfully!', filePath);
    } catch (e) {
      showCustomSnackBar(context, 'Error saving Excel: $e', '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade900, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.info, color: Colors.white),
            SizedBox(width: 10),
            Text(
              "Sales Summary",
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
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade900, Colors.blue.shade700],
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
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontFamily: "Times New Roman"),
                decoration: InputDecoration(
                  labelText: 'Search by full name...',
                  labelStyle: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                  hintText: 'Enter full name',
                  hintStyle: TextStyle(color: Colors.cyan.shade300),
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

          // Date Range Pickers
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(children: [
              Expanded(
                  child: _buildDateSelector('Start Date', _startDate,
                      (picked) => setState(() => _startDate = picked))),
              SizedBox(width: 10),
              Expanded(
                  child: _buildDateSelector('End Date', _endDate,
                      (picked) => setState(() => _endDate = picked))),
            ]),
          ),

          // StreamBuilder
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('Salesinfo').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator());

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No sales report available!',
                      style: TextStyle(
                          fontFamily: 'Times New Roman',
                          fontSize: 18,
                          color: Colors.black),
                    ),
                  );
                }

                final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final fullName =
                      doc['fullName']?.toString()?.toLowerCase() ?? '';
                  if (_startDate != null || _endDate != null) {
                    dynamic ts = doc['reportedDateTime'];
                    DateTime? dt = ts is Timestamp
                        ? ts.toDate()
                        : (ts is DateTime ? ts : null);
                    if (dt == null) return false;
                    if (_startDate != null &&
                        dt.isBefore(DateTime(_startDate!.year,
                            _startDate!.month, _startDate!.day))) return false;
                    if (_endDate != null &&
                        dt.isAfter(DateTime(_endDate!.year, _endDate!.month,
                            _endDate!.day, 23, 59, 59))) return false;
                  }

                  final docUid = doc['uid']?.toString() ?? '';
                  return fullName.contains(_searchQuery.toLowerCase()) &&
                      docUid == currentUid;
                }).toList();

                if (filteredDocs.isEmpty) {
                  String message = '';
                  if (_searchQuery.isNotEmpty) {
                    message = 'No sales data found as you searched!';
                  } else if (_startDate != null || _endDate != null) {
                    message = 'No sales report found for selected date range!';
                  } else {
                    message = 'No sales report available!';
                  }

                  return Center(
                    child: Text(
                      message,
                      style: TextStyle(
                          fontFamily: 'Times New Roman',
                          fontSize: 18,
                          color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✅ Export Sales as PDF Button
                            ElevatedButton.icon(
                              onPressed: () {
                                if (filteredDocs.isNotEmpty) {
                                  exportSalesDataAsPDF(filteredDocs, context);
                                } else {
                                  showCustomSnackBar(
                                      context, 'No sales data to export.', '');
                                }
                              },
                              icon: const Icon(Icons.picture_as_pdf,
                                  color: Colors.white),
                              label: const Text(
                                "Export as PDF",
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // ✅ Export Sales as Excel Button
                            ElevatedButton.icon(
                              onPressed: () {
                                print(
                                    '📊 Exporting ${filteredDocs.length} sales records to Excel');
                                exportSalesDataAsExcel(
                                    docs: filteredDocs, context: context);
                              },
                              icon: const Icon(Icons.grid_on,
                                  color: Colors.white),
                              label: const Text(
                                "Export as Excel",
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
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
                          return buildSalesCard(doc);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSalesCard(DocumentSnapshot doc) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Dismissible(
        key: Key(doc.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async =>
            await _showDeleteConfirmationDialog(),
        onDismissed: (direction) async => await _deleteRecord(doc.id),
        background: Container(
          decoration: BoxDecoration(
            color: Colors.cyanAccent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Icon(Icons.delete, color: Colors.white),
            ),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade900, Colors.blue.shade700],
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
              buildFormField('Lead Owner Name: ', doc['executivename']),
              buildFormField('Full Name: ', doc['fullName']),
              buildTappableField(
                  'Contact Number:', doc['contactNumber'], _launchPhone),
              buildTappableField(
                  'Whatsapp Number:', doc['whatsappNumber'], _launchWhatsApp),
              buildTappableField('Email Address: ', doc['email'], _launchEmail),
              buildFormField(
                  'Preferred Contact Method: ', doc['preferredContactMethod']),
              buildFormField('Lead Source: ', doc['leadSource']),
              buildFormField('Lead Type: ', doc['leadType']),
              buildFormField('Type of Property: ', doc['propertyType']),
              buildFormField('Property Size: ', doc['propertySize']),
              buildFormField('Current Home Automation Setup: ',
                  doc['currentHomeAutomation']),
              buildFormField('Budget Range: ', doc['budgetRange']),
              buildFormField('Additional Details: ', doc['additionalDetails']),
              buildFormField('Reported Date&Time:',
                  formatReportedDateTime(doc['reportedDateTime'])),
              SizedBox(height: 10),
              Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => EditSalesInfoPage(
                        docId: doc.id,
                        initialData: doc.data() as Map<String, dynamic>,
                      ),
                    ));
                  },
                  backgroundColor: Colors.cyan,
                  child: Icon(Icons.edit, color: Colors.white),
                  mini: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<DateTime?> _pickDate(BuildContext ctx, DateTime? current) {
    return showDatePicker(
      context: ctx,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  Widget _buildDateSelector(
      String label, DateTime? date, ValueChanged<DateTime?> onPicked) {
    final gradientBg = LinearGradient(
        colors: [Colors.blue.shade900, Colors.blue.shade700],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight);

    return GestureDetector(
      onTap: () async {
        final picked = await _pickDate(context, date);
        if (picked != null) onPicked(picked);
      },
      child: Container(
        decoration: BoxDecoration(
            gradient: gradientBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.blue.shade900.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 4)),
            ]),
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Row(children: [
          Icon(Icons.date_range, color: Colors.white),
          SizedBox(width: 8),
          Text(date != null ? DateFormat('dd‑MMM‑yyyy').format(date) : label,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Times New Roman')),
        ]),
      ),
    );
  }

  Widget buildFormField(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              title,
              style: TextStyle(
                  fontFamily: 'Arial',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(value,
                style: TextStyle(
                    fontFamily: 'Arial', fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget buildTappableField(
      String title, String value, Function(String) onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(title,
                style: TextStyle(
                    fontFamily: 'Arial',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent)),
          ),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () => onTap(value),
              child: Text(value,
                  style: TextStyle(
                      decoration: TextDecoration.underline,
                      fontFamily: 'Arial',
                      fontSize: 16,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.blue.shade900, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.all(15.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Delete Confirmation',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                SizedBox(height: 10),
                Text('Are you sure you want to delete this record?',
                    style: TextStyle(fontSize: 16, color: Colors.cyan.shade100),
                    textAlign: TextAlign.center),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Cancel',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(width: 10),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('Delete',
                          style: TextStyle(
                              color: Colors.cyanAccent.shade200,
                              fontWeight: FontWeight.bold)),
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
