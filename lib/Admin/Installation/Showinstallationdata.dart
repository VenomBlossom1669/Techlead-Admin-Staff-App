import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart' as flutter;
import 'package:excel/excel.dart' as excel;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:excel/excel.dart' as xls;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart' as flutter;
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Employee/Categoryscreen/FileViwerscreen.dart';
import 'package:flutter/material.dart' hide Border;
import 'package:flutter/material.dart' as flutter show Border;
import 'Edit_Installation_Page/edit_installation_page.dart';

class Showinstallationdata extends StatefulWidget {
  @override
  _ShowinstallationdataState createState() => _ShowinstallationdataState();
}

class _ShowinstallationdataState extends State<Showinstallationdata> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';

  String _formatDate(String rawDate) {
    try {
      final DateTime parsedDate = DateTime.parse(rawDate);
      return DateFormat('dd MMMM yyyy').format(parsedDate);
    } catch (e) {
      return rawDate; // Fallback to original if parsing fails
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  void initState() {
    super.initState();
    _requestStoragePermission();
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

  DateTime? _startDate;
  DateTime? _endDate;

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



  Future<void> _deleteRecord(String docId) async {
    try {
      await _firestore.collection('Installation').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Installation Record deleted successfully',
            style:
                TextStyle(fontFamily: "Times New Roman", color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
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

  void showInstallationSnackBar(BuildContext context, String filePath,
      {String fileType = 'PDF'}) {
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
                colors: [Color(0xFF1E293B), Color(0xFF64748B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.file_download, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$fileType file saved!',
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
                        color: Colors.white, fontWeight: FontWeight.w600),
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

  Future<void> exportInstallationDataAsPDF({
    required List<dynamic> docs,
    required BuildContext context,
  }) async {
    final pdf = pw.Document();

    // Load logo
    final ByteData logoData = await rootBundle.load('assets/images/ppo.jpg');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    final pw.ImageProvider logoImage = pw.MemoryImage(logoBytes);

    // Load icons helper
    Future<pw.MemoryImage> loadIcon(String path) async {
      final data = await rootBundle.load(path);
      return pw.MemoryImage(data.buffer.asUint8List());
    }

    // Load all icons
    final technicianIcon = await loadIcon('assets/images/prof.png');
    final siteIcon = await loadIcon('assets/images/location.png');
    final calendarIcon = await loadIcon('assets/images/cal.png');
    final productIcon = await loadIcon('assets/images/product.png');
    final statusIcon = await loadIcon('assets/images/status.png');
    final customerIcon = await loadIcon('assets/images/customer.png');
    final phoneIcon = await loadIcon('assets/images/call.png');
    final remarksIcon = await loadIcon('assets/images/task.png');
    final fileIcon = await loadIcon('assets/images/file.png');
    final whatsapp = await loadIcon('assets/images/whatsapp.png');

    final icons = {
      'technician': technicianIcon,
      'site': siteIcon,
      'calendar': calendarIcon,
      'product': productIcon,
      'status': statusIcon,
      'customer': customerIcon,
      'whatsapp': whatsapp,
      'phone': phoneIcon,
      'remarks': remarksIcon,
      'file': fileIcon,
      'person': technicianIcon,
    };

    // Helper to fetch image bytes from Firebase Storage URL
    Future<Uint8List?> fetchImageBytes(String url,
        {int maxSize = 5 * 1024 * 1024}) async {
      try {
        final ref = FirebaseStorage.instance.refFromURL(url);
        final data = await ref.getData(maxSize);
        return data;
      } catch (e) {
        print('Error fetching image from $url: $e');
        return null;
      }
    }

    // Loop through docs and add a separate page per report
    for (int index = 0; index < docs.length; index++) {
      final data = docs[index].data() as Map<String, dynamic>;
      final contentWidget = await buildInstallationRecordContent(
          data, index, icons, fetchImageBytes);

      pdf.addPage(
        pw.Page(
          margin: pw.EdgeInsets.all(24),
          build: (context) {
            return pw.Column(
              children: [
                pw.Container(width: 80, height: 80, child: pw.Image(logoImage)),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Installation Reports',
                  style: pw.TextStyle(
                    fontSize: 22,
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
                pw.SizedBox(height: 10),
                contentWidget,
                pw.Spacer(),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Page ${index + 1} of ${docs.length}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    // Request storage permission
    final granted = await _requestStoragePermission();
    if (!granted) {
      showInstallationSnackBar(context, 'Storage permission denied.');
      return;
    }

    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        showInstallationSnackBar(context, 'Failed to access storage.');
        return;
      }

      final filePath =
          '${directory.path}/InstallationReport_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);

      await file.writeAsBytes(await pdf.save());

      // ✅ OPTION 1: Show snackbar without auto-opening
      showInstallationSnackBar(context, filePath, fileType: 'PDF');

      // User can click OPEN button in snackbar to open the file
      // No automatic OpenFile.open() call here

      /*
    // ✅ OPTION 2: Show snackbar and auto-open after delay
    showInstallationSnackBar(context, filePath, fileType: 'PDF');

    // Wait 1 second then auto-open
    await Future.delayed(Duration(seconds: 1));
    final result = await OpenFile.open(filePath);
    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file: ${result.message}')),
      );
    }
    */

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving PDF: $e')),
      );
    }
  }

// Returns a pw.Widget (NOT async) to use inside pdf.MultiPage.build
  Future<pw.Widget> buildInstallationRecordContent(
    Map<String, dynamic> data,
    int reportIndex,
    Map<String, pw.ImageProvider> icons,
    Future<Uint8List?> Function(String url) fetchImageBytes,
  ) async {
    final defaultFont = pw.Font.helvetica();
    String fmt(String? val) => val == null || val.trim().isEmpty ? 'N/A' : val;

    // Section title helper
    pw.Widget buildSectionTitle(
        String title, PdfColor color, pw.ImageProvider icon) {
      return pw.Row(
        children: [
          pw.Image(icon, width: 18, height: 18),
          pw.SizedBox(width: 6),
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      );
    }

    // Table row helper
    pw.TableRow buildTableRow(
      pw.ImageProvider icon,
      String label1,
      String val1,
      String label2,
      String val2,
    ) {
      return pw.TableRow(
        children: [
          pw.Container(
              width: 20,
              height: 20,
              margin: pw.EdgeInsets.only(top: 4),
              child: pw.Image(icon)),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label1,
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.Text(val1,
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label2,
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.Text(val2,
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      );
    }

    // 🔽 Embedded image list with wrapping rows
    List<pw.Widget> fileWidgets = [];

    if (data['files'] is List && (data['files'] as List).isNotEmpty) {
      // Add a page break before images to ensure they start fresh on a new page
      pw.Container(height: PdfPageFormat.a4.height);

      fileWidgets.add(buildSectionTitle(
          '📎 Attached Files', PdfColors.purple800, icons['file']!));
      fileWidgets.add(pw.SizedBox(height: 8));

      const int imagesPerRow = 3;
      List<pw.Widget> imageRows = [];
      List<pw.Widget> currentRowChildren = [];

      for (var i = 0; i < (data['files'] as List).length; i++) {
        var file = (data['files'] as List)[i];
        final name = file['fileName'] ?? 'Unnamed';
        final url = file['downloadUrl'] ?? '';
        final isLocal = file['isLocal'] == true;

        Uint8List? imageBytes;

        if (isLocal) {
          try {
            imageBytes = await File(url).readAsBytes();
          } catch (e) {
            print('Error reading local file: $e');
          }
        } else {
          imageBytes = await fetchImageBytes(url);
        }

        final imageWidget = pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(name, style: pw.TextStyle(font: defaultFont, fontSize: 12)),
            pw.SizedBox(height: 4),
            if (imageBytes != null)
              pw.Image(
                pw.MemoryImage(imageBytes),
                height: 180,
                fit: pw.BoxFit.contain,
              )
            else
              pw.Text(
                '(Image could not be loaded)',
                style: pw.TextStyle(
                    font: defaultFont, fontSize: 10, color: PdfColors.red),
              ),
            pw.SizedBox(height: 12),
          ],
        );

        currentRowChildren.add(
          pw.Expanded(child: imageWidget),
        );

        if ((i + 1) % imagesPerRow == 0 ||
            i == (data['files'] as List).length - 1) {
          imageRows.add(
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: currentRowChildren,
            ),
          );
          currentRowChildren = [];
        }
      }

      fileWidgets.addAll(imageRows);
    }

    // 🔽 Return full content layout
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 24),
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '📄 Report ${reportIndex + 1}',
            style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo800),
          ),
          pw.SizedBox(height: 12),
          buildSectionTitle('🧰 Technician & Site Info', PdfColors.blue800,
              icons['technician']!),
          pw.SizedBox(height: 6),
          pw.Table(
            columnWidths: {
              0: pw.FixedColumnWidth(24),
              1: pw.FlexColumnWidth(),
              2: pw.FlexColumnWidth(),
            },
            children: [
              buildTableRow(
                icons['technician']!,
                'Technician Name',
                fmt(data['technician_name']),
                'Installation Site',
                fmt(data['installation_site']),
              ),
              buildTableRow(
                icons['calendar']!,
                'Installation Date',
                fmt(data['installation_date']),
                'Service Time',
                fmt(data['service_time']),
              ),
              buildTableRow(
                icons['product']!,
                'Automation Product',
                fmt(data['selected_product']),
                'Service Status',
                fmt(data['service_status']),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          buildSectionTitle(
              '👤 Customer Info', PdfColors.teal700, icons['customer']!),
          pw.SizedBox(height: 6),
          pw.Table(
            columnWidths: {
              0: pw.FixedColumnWidth(24),
              1: pw.FlexColumnWidth(),
              2: pw.FlexColumnWidth(),
            },
            children: [
              buildTableRow(
                icons['customer']!,
                'Customer Name',
                fmt(data['customer_name']),
                'Contact Number',
                fmt(data['customer_contact']),
              ),
              buildTableRow(
                icons['whatsapp']!, // ✅ Use a WhatsApp icon from icons map
                'WhatsApp Number',
                fmt(data['whasapp_contact']), // ✅ Add whatsapp field
                '',
                '',
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          buildSectionTitle('📝 Service Description & Remarks',
              PdfColors.deepOrange800, icons['remarks']!),
          pw.SizedBox(height: 6),
          pw.Text("Description: ${fmt(data['service_description'])}",
              style: pw.TextStyle(font: defaultFont)),
          pw.SizedBox(height: 4),
          pw.Text("Remarks: ${fmt(data['remarks'])}",
              style: pw.TextStyle(font: defaultFont)),
          pw.SizedBox(height: 12),
          ...fileWidgets,
        ],
      ),
    );
  }

/* === Excel code for the downloading file == */
  Future<void> exportInstallationDataAsExcel({
    required List<dynamic> docs,
    required BuildContext context,
  }) async {
    final excel = xls.Excel.createExcel();
    final xls.Sheet sheet = excel['Installation Reports'];

    // Define headers
    final headers = [
      'Technician Name',
      'Installation Site',
      'Installation Date',
      'Service Time',
      'Product',
      'Service Status',
      'Customer Name',
      'Contact Number',
      'Whatsapp Number',
      'Service Description',
      'Remarks',
    ];

    // Define a bold header style with background color
    final xls.CellStyle headerStyle = xls.CellStyle(
      bold: true,
      fontColorHex: xls.ExcelColor.fromHexString("#FFFFFF"),
      backgroundColorHex: xls.ExcelColor.fromHexString("#0F172A"),
      horizontalAlign: xls.HorizontalAlign.Center,
      verticalAlign: xls.VerticalAlign.Center,
      fontFamily: 'Calibri',
    );

    // Append styled headers
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet
          .cell(xls.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = xls.TextCellValue(headers[i]); // ✅ Already correct
      cell.cellStyle = headerStyle;
    }

    // Add each row of data
    for (int row = 0; row < docs.length; row++) {
      final data = docs[row].data() as Map<String, dynamic>;
      final values = [
        data['technician_name'] ?? 'N/A',
        data['installation_site'] ?? 'N/A',
        data['installation_date'] ?? 'N/A',
        data['service_time'] ?? 'N/A',
        data['selected_product'] ?? 'N/A',
        data['service_status'] ?? 'N/A',
        data['customer_name'] ?? 'N/A',
        data['customer_contact'] ?? 'N/A',
        data['whasapp_contact'] ?? 'N/A',
        data['service_description'] ?? 'N/A',
        data['remarks'] ?? 'N/A',
      ];

      for (int col = 0; col < values.length; col++) {
        final cell = sheet.cell(xls.CellIndex.indexByColumnRow(
            columnIndex: col, rowIndex: row + 1));

        // ✅ FIX: Wrap the string value in TextCellValue
        cell.value = xls.TextCellValue(values[col].toString());
      }
    }

    // Ask for permission and save the file
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
          '${directory.path}/InstallationReport_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final fileBytes = excel.encode();
      final file = File(filePath);
      await file.writeAsBytes(fileBytes!);

      showInstallationSnackBar(context, filePath, fileType: 'Excel');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving Excel file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(
            color: Colors.white), // Make the default background transparent
        elevation: 0, // Remove the default shadow
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
            Icon(
              FontAwesomeIcons.info,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Text(
              "Installation Summary",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1,
                color: Colors.white,
                fontFamily: 'Times New Roman',
              ),
            ),
          ],
        ),
        centerTitle: true,
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
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'Search by Technician name..',
                  labelStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  hintText: 'Enter Technician full name',
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
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('Installation').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    itemCount: 5,
                    padding: EdgeInsets.all(10),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey.shade800,
                          highlightColor: Colors.grey.shade600,
                          child: Container(
                            height: 160,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No Installation info available!',
                      style: TextStyle(fontFamily: 'Times New Roman'),
                    ),
                  );
                }

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final fullName =
                      doc['technician_name']?.toString()?.toLowerCase() ?? '';
                  final dateString = doc['installation_date'] ?? '';
                  DateTime? appointmentDate;

                  try {
                    appointmentDate = DateTime.parse(dateString);
                  } catch (e) {
                    return false;
                  }

                  final matchesSearch =
                      fullName.contains(_searchQuery.toLowerCase());
                  final matchesStartDate = _startDate == null ||
                      appointmentDate
                          .isAfter(_startDate!.subtract(Duration(days: 1)));
                  final matchesEndDate = _endDate == null ||
                      appointmentDate
                          .isBefore(_endDate!.add(Duration(days: 1)));

                  return matchesSearch && matchesStartDate && matchesEndDate;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text("No reports match your search/date range!",
                        style: TextStyle(
                            color: Colors.black,
                            fontFamily: "Times New Roman")),
                  );
                }

                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              print(
                                  '📄 Exporting ${filteredDocs.length} records');
                              exportInstallationDataAsPDF(
                                  docs: filteredDocs, context: context);
                            },
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Export as PDF'),
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
                          ElevatedButton.icon(
                            onPressed: () {
                              print(
                                  '📊 Exporting ${filteredDocs.length} records to Excel');
                              exportInstallationDataAsExcel(
                                  docs: filteredDocs, context: context);
                            },
                            icon: const Icon(Icons.grid_on),
                            label: const Text('Export as Excel'),
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
                              await _deleteRecord(doc.id);
                            },
                            background: Container(
                              decoration: BoxDecoration(
                                color: Colors.cyanAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 20.0),
                                  child:
                                      Icon(Icons.delete, color: Colors.white),
                                ),
                              ),
                            ),
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
                                    color:
                                        Colors.blue.shade900.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(15.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 10,
                                  ),
                                  buildFormField('Technician/Executive Name: ',
                                      doc['technician_name']),
                                  buildFormField('Installation Site:',
                                      doc['installation_site']),
                                  buildFormField('Installation Date:',
                                      _formatDate(doc['installation_date'])),
                                  buildFormField(
                                      'Service Time: ', doc['service_time']),
                                  buildFormField('Automation Product: ',
                                      doc['selected_product']),
                                  buildFormField('Service Status: ',
                                      doc['service_status']),
                                  buildFormField(
                                      'Customer Name: ', doc['customer_name']),
                                  buildTappableField('Contact Number:',
                                      doc['customer_contact'], _launchPhone),
                                  buildTappableField('Whatsapp Number:',
                                      doc['whasapp_contact'], _launchWhatsApp),
                                  buildFormField('Service Description: ',
                                      doc['service_description']),
                                  buildFormField('Remarks: ', doc['remarks']),
                                  if (doc['files'] != null &&
                                      doc['files'] is List &&
                                      (doc['files'] as List).isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Attached Files:",
                                            style: TextStyle(
                                              color: Colors.tealAccent,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            height: 120,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount:
                                                  (doc['files'] as List).length,
                                              itemBuilder:
                                                  (context, fileIndex) {
                                                var file = (doc['files']
                                                    as List)[fileIndex];
                                                final String url =
                                                    file['downloadUrl'] ?? '';
                                                final String fileType =
                                                    (file['fileType'] ?? '')
                                                        .toLowerCase();
                                                final String fileName =
                                                    file['fileName'] ??
                                                        'Unnamed';

                                                bool isImage = [
                                                  'jpg',
                                                  'jpeg',
                                                  'png',
                                                  'gif',
                                                  'bmp',
                                                  'webp'
                                                ].contains(fileType);

                                                return GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            FileViewerScreen(
                                                          url: url,
                                                          fileType: fileType,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: Container(
                                                    width: 120,
                                                    margin:
                                                        const EdgeInsets.only(
                                                            right: 10),
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.1),
                                                      border:
                                                          flutter.Border.all(
                                                        // ✅ Border.all() સાચું છે
                                                        color:
                                                            Colors.tealAccent,
                                                        width: 1.5,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                          child: isImage
                                                              ? Image.network(
                                                                  url,
                                                                  width: 100,
                                                                  height: 70,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  errorBuilder: (context,
                                                                          error,
                                                                          stackTrace) =>
                                                                      const Icon(
                                                                    Icons
                                                                        .broken_image,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                )
                                                              : Icon(
                                                                  fileType == 'pdf'
                                                                      ? Icons
                                                                          .picture_as_pdf
                                                                      : Icons
                                                                          .insert_drive_file,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 50,
                                                                ),
                                                        ),
                                                        const SizedBox(
                                                            height: 5),
                                                        Text(
                                                          fileName,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 12),
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
                                  SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        child: FloatingActionButton(
                                          onPressed: () {
                                            Navigator.of(context)
                                                .push(MaterialPageRoute(
                                              builder: (context) =>
                                                  Editinstallationpage(
                                                docId: doc.id,
                                                initialData: doc.data()
                                                    as Map<String, dynamic>,
                                              ),
                                            ));
                                          },
                                          backgroundColor: Color(0xFF0A2A5A),
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
                    ),
                  ),
                ]);
              },
            ),
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

  Widget buildFormField(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
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
                color: Colors.cyanAccent,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Arial',
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
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
