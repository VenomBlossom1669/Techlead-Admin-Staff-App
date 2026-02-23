import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:techlead/Widgeets/custom_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_bar_provider.dart';
import '../Employeedetails/Employee_Profile_Image_View/image_view.dart';
import 'Screen_View_For_Files/Excel_View_Screen.dart';
import 'Screen_View_For_Files/Pdf_View_Screen.dart';
import 'Screen_View_For_Files/Text_File_View_Screen.dart';

class FetchedProductPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<FetchedProductPage> createState() => _FetchedProductPageState();
}

class _FetchedProductPageState extends ConsumerState<FetchedProductPage> {
  late Future<Map<String, dynamic>> _fetchDataFuture;
  bool isSharing = false;
  TextEditingController searchController = TextEditingController();
  String selectedDate = '';
  List<Map<String, dynamic>> filteredReports = [];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            dialogBackgroundColor: const Color(0xFF0D1B3E),
            colorScheme: ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Color(0xFF0D1B3E),
              surface: const Color(0xFF0D1B3E),
              onSurface: Colors.white,
            ),
            primaryTextTheme: const TextTheme(
              titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              bodyLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              bodyMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = DateFormat('dd/MM/yyyy').format(picked);


      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDataFuture = _fetchShortageReports();
    WidgetsBinding.instance.addPostFrameCallback((_) {

      ref.read(customTitleWidgetProvider.notifier).state = Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.integration_instructions_sharp, color: Colors.white),
          SizedBox(width: 8),
          Text(
            "Installation Shortage Report",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: "Times New Roman",
                fontSize: 16),
          ),
        ],
      );
    });
  }
  void _confirmAndDelete(String reportId, List<dynamic> files) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF000F89), // Royal Blue
                Color(0xFF0F52BA), // Cobalt Blue
                Color(0xFF002147), // Midnight Blue
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 40),
              const SizedBox(height: 16),
              const Text(
                'Delete Report',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to delete this report and all attached files?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteReport(reportId, files: files);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text(
                      'Delete',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  Future<void> _deleteReport(String reportId, {List<dynamic>? files}) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('product_shortage_reports')
          .doc(reportId);

      // 🔥 Delete files from Firebase Storage
      if (files != null) {
        for (var fileData in files) {
          final fileUrl = fileData['file_url'] as String?;
          if (fileUrl != null && fileUrl.startsWith('https://')) {
            try {
              final ref = firebase_storage.FirebaseStorage.instance.refFromURL(fileUrl);
              await ref.delete();
            } catch (e) {
              debugPrint('⚠ Failed to delete file: $fileUrl - $e');
            }
          }
        }
      }

      // 🧾 Delete Firestore document
      await docRef.delete();

      // 🔄 Refresh the UI
      setState(() {
        _fetchDataFuture = _fetchShortageReports();
      });

      // ✅ Styled SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF000F89), // Royal Blue
                  Color(0xFF0F52BA), // Cobalt Blue
                  Color(0xFF002147), // Midnight Blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Report and files deleted successfully!",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Deletion error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade700, Colors.red.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Deletion failed: $e",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }


  Future<Map<String, dynamic>> _fetchShortageReports() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('product_shortage_reports')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> reports = querySnapshot.docs.map((doc) {
          return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
        }).toList();

        return {'reports': reports};
      } else {
        return {'reports': []};
      }
    } catch (e) {
      print('Error fetching reports: $e');
      return {'reports': []};
    }
  }
  Future<File?> _downloadFile(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;
      final tempDir = await getTemporaryDirectory();
      final fileName = url.split('/').last;
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (e) {
      print('Error downloading file: $e');
      return null;
    }
  }

  Widget _buildFilePreview(
      BuildContext context, Map<String, dynamic> fileData) {
    String fileName = fileData['file_name'];
    String fileType = fileData['file_type'];
    String fileUrl = fileData['file_url'];
    String fileStatus = fileData['status'] ?? 'pending';


    return GestureDetector(
      onTap: () async {
        if (fileType.toLowerCase() == 'pdf') {
          // Download PDF locally first
          final file = await _downloadFile(fileUrl);
          if (file != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PdfPreviewScreen(file: file),
              ),
            );
          }
        } else {
          _openFile(fileUrl, context);
        }
      },



      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handling images correctly
          if (fileType == 'jpg' || fileType == 'jpeg' || fileType == 'png')
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    fileUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.insert_drive_file,
                    size: 40,
                    color: Colors.cyanAccent,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 5),
          Text(
            fileName,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.cyanAccent),
          ),
        ],
      ),
    );
  }

  Future<void> _openFile(String fileUrl, BuildContext context) async {
    print('Tapped fileUrl: $fileUrl');

    try {
      // Remove query parameters from URL first
      String urlWithoutQuery = fileUrl.split('?').first;

      // Decode URL encoding (like %2F -> /)
      String decodedUrl = Uri.decodeFull(urlWithoutQuery);

      // Now get the last part of the path as the filename
      String fileName = decodedUrl.split('/').last;

      // Get file extension
      String fileType = fileName.split('.').last.toLowerCase();

      print('File name: $fileName');
      print('File type detected: $fileType');

      if (fileType == 'pdf') {
        final response = await http.get(Uri.parse(fileUrl));
        final bytes = response.bodyBytes;

        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfPreviewScreen(file: file),
          ),
        );
      } else if (['jpg', 'jpeg', 'png'].contains(fileType)) {
        // Show image preview without downloading
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullImageView(imageUrl: fileUrl),
          ),
        );
      } else if (['xls', 'xlsx'].contains(fileType) ||
          ['txt', 'csv', 'json'].contains(fileType)) {
        final response = await http.get(Uri.parse(fileUrl));
        final bytes = response.bodyBytes;

        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);

        if (['xls', 'xlsx'].contains(fileType)) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExcelPreviewScreen(file: file),
            ),
          );
        } else if (['txt', 'csv', 'json'].contains(fileType)) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TextFilePreviewScreen(file: file),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preview not available for this file type')),
        );
      }
    } catch (e) {
      print('Error in _openFile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open file: $e')),
      );
    }
  }

  Widget _buildReportFields(Map<String, dynamic> report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldRow("Product Name:", report['product_name']),
        _buildFieldRow("Required Quantity:", report['required_quantity']),
        _buildFieldRow("Available Quantity:", report['available_quantity']),
        _buildFieldRow("Site Location:", report['site_location']),
        _buildFieldRow("Description:", report['description']),
        _buildFieldRow("Contact Info:", report['contact_info']),
        _buildFieldRow("Address:", report['address']),
        _buildFieldRow("Assigned Technician:", report['assigned_technician']),
        _buildFieldRow(
          "Created Date:",
          report['created_at'] != null && report['created_at'] is Timestamp
              ? DateFormat('dd-MM-yyyy HH:mm').format(
            (report['created_at'] as Timestamp).toDate(),
          )
              : 'N/A',
        ),
        const SizedBox(height: 15),
        Text("Attached Files",style: TextStyle(fontFamily: "Times New Roman",color: Colors.white),),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildFieldRow(String fieldName, dynamic fieldValue) {
    final isLocation = fieldName.trim().toLowerCase() == 'site location:';
    final locationValue = fieldValue?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                fieldName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: isLocation
                    ? GestureDetector(
                  onTap: () async {
                    final encodedLocation = Uri.encodeComponent(locationValue);
                    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$encodedLocation';
                    if (await canLaunch(googleMapsUrl)) {
                      await launch(googleMapsUrl);
                    } else {
                      debugPrint("Could not launch Maps");
                    }
                  },
                  child: Text(
                    locationValue,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.yellow
                    ),
                  ),
                )
                    : Text(
                  locationValue,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔍 Search Bar
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF000F89), // Royal Blue
                            Color(0xFF0F52BA), // Cobalt Blue
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: searchController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search by Product, Technician or Contact',
                          hintStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          prefixIcon: const Icon(Icons.search, color: Colors.white),
                          border: InputBorder.none,
                          contentPadding:
                          const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // 📅 Date Picker Button
                  SizedBox(
                    width: 50,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF000F89), // Royal Blue
                            Color(0xFF0F52BA), // Cobalt Blue
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ElevatedButton(
                        onPressed: () => _selectDate(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                      ),
                    ),
                  ),

                  // ❌ Clear Date Button (if date is selected)
                  if (selectedDate.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(top: 6), // 👈 Pushes it downward slightly
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.shade200,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setState(() {
                              selectedDate = '';
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Row(
                              children: const [
                                Icon(Icons.clear, color: Colors.white, size: 18),
                                SizedBox(width: 4),
                                Text(
                                  'Clear',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  ],


                ],
              ),
            ),


            FutureBuilder<Map<String, dynamic>>(
              future: _fetchDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: 5, // Number of shimmer items to show
                      itemBuilder: (context, index) {
                        return Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            height: 120,
                            width: double.infinity,
                          ),
                        );
                      },
                    ),
                  );
                }

                else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  var reports = snapshot.data!['reports'] as List<dynamic>;

                  var filteredReports = reports.where((report) {
                    final query = searchController.text.toLowerCase();

                    final productName = report['product_name']?.toString().toLowerCase() ?? '';
                    final technician = report['assigned_technician']?.toString().toLowerCase() ?? '';
                    final contactInfo = report['contact_info']?.toString().toLowerCase() ?? '';

                    final matchesSearch = query.isEmpty ||
                        productName.contains(query) ||
                        technician.contains(query) ||
                        contactInfo.contains(query);

                    final reportTimestamp = report['created_at']; // 👈 use the correct field
                    String reportDateFormatted = '';

                    if (reportTimestamp is Timestamp) {
                      reportDateFormatted = DateFormat('dd/MM/yyyy').format(reportTimestamp.toDate()); // 👈 format it to match selectedDate
                    }

                    final matchesDate = selectedDate.isEmpty || reportDateFormatted == selectedDate;

                    return matchesSearch && matchesDate;
                  }).toList();

                  if (filteredReports.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 150),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.insert_drive_file_outlined, // Report-like icon
                              size: 80,
                              color: Colors.blue.shade900,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No Reports Found',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters or check back later.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }


                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: filteredReports.length,
                    itemBuilder: (context, index) {
                      var report = filteredReports[index];
                      var files = report['files'] as List<dynamic>;

                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF000F89),
                                  Color(0xFF0F52BA),
                                  Color(0xFF002147),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Row with Delete Button only
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _confirmAndDelete(report['id'], report['files']),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),
                                  _buildReportFields(report),
                                  const SizedBox(height: 10),

                                  // File Grid
                                  GridView.builder(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      childAspectRatio: 1,
                                    ),
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: files.length,
                                    itemBuilder: (context, fileIndex) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          gradient: LinearGradient(
                                            colors: [Colors.blue.shade600, Colors.blue.shade800],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: _buildFilePreview(context, files[fileIndex]),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),

                          ),
                        ),
                      );

                    },
                  );

                } else {
                  return Center(
                      child: Text(
                        'No data available!',
                        style: TextStyle(
                            color: Colors.black,
                            fontFamily: "Times New Roman",
                            fontWeight: FontWeight.bold),
                      ));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}