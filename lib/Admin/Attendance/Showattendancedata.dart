import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart' as ex;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shimmer/shimmer.dart';
import 'package:techlead/Widgeets/custom_app_bar.dart';
import 'package:techlead/Employee/Attendacescreen/Attendancemodel.dart';
import 'package:techlead/Employee/Attendacescreen/googlescreen.dart';
import 'package:techlead/core/app_bar_provider.dart';

class Attendance extends ConsumerStatefulWidget {
  const Attendance({super.key});

  @override
  ConsumerState<Attendance> createState() => _AttendanceState();
}

class _AttendanceState extends ConsumerState<Attendance> {
  Map<String, String?> imageCache = {};
  bool isLoading = false;
  bool isLoading2 = false;
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  String searchQuery = '';
  String? selectedDate;
  TextEditingController searchController = TextEditingController();
  Position? _currentLocation;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (mounted) {
        ref.read(appBarTitleProvider.notifier).state = "Employee Attendance Details";
        ref.read(appBarGradientColorsProvider.notifier).state = [
          Color(0xFF1155AA),
          Color(0xFF025BB6),
        ];
        ref.read(customTitleWidgetProvider.notifier).state = null;
      }
    });
  }

  @override
  void dispose() {
    Future.microtask(() {
      if (mounted) resetAppBar(ref);
    });
    super.dispose();
  }

  Future<void> requestLocationPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ].request();

    if (statuses[Permission.storage]!.isPermanentlyDenied) {
      await openAppSettings();
    }
    setState(() {});
  }

  Future<void> fetchImageUrls() async {
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('Attendance').get();
      for (var doc in querySnapshot.docs) {
        String? imageUrl = doc.get('Imageurl') as String?;
        imageCache[doc.id] = imageUrl;
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching image URLs: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = position;
      });
    } catch (e) {
      print('Error fetching location: $e');
    }
  }

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

  DateTime? parseDate(String dateString) {
    try {
      if (dateString.contains('/')) {
        List<String> parts = dateString.split('/');
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        return DateTime(year, month, day);
      } else {
        return DateTime.parse(dateString);
      }
    } catch (e) {
      print('Error parsing date: $e');
      return null;
    }
  }

  Future<void> _downloadMonthlyExcel(DateTime startDate, DateTime endDate) async {
    if (!mounted) return;

    setState(() {
      isLoading2 = true;
    });

    DateTime? parseDate(String dateString) {
      try {
        if (dateString.contains('/')) {
          List<String> parts = dateString.split('/');
          int day = int.parse(parts[0]);
          int month = int.parse(parts[1]);
          int year = int.parse(parts[2]);
          return DateTime(year, month, day);
        } else {
          return DateTime.parse(dateString);
        }
      } catch (e) {
        print('Error parsing date: $e');
        return null;
      }
    }

    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('Attendance').get();

      List<AttendanceRecord> records = querySnapshot.docs.map((doc) {
        return AttendanceRecord.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Filter only selected month range
      records = records.where((record) {
        if (record.date == null) return false;
        DateTime? recordDate = parseDate(record.date!);
        if (recordDate == null) return false;

        return recordDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            recordDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();

      if (records.isEmpty) {
        Fluttertoast.showToast(
          msg: "No monthly attendance data found!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        setState(() => isLoading2 = false);
        return;
      }

      var excel = ex.Excel.createExcel();
      ex.Sheet sheet = excel['Attendance'];

      var headerStyle = ex.CellStyle(
        bold: true,
        fontColorHex: ex.ExcelColor.fromHexString("#FFFFFF"),
        backgroundColorHex: ex.ExcelColor.fromHexString("#0F172A"),
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
      );

      var absentStyle = ex.CellStyle(
        backgroundColorHex: ex.ExcelColor.fromHexString('#FF0000'),
      );
      var halfDayStyle = ex.CellStyle(
        backgroundColorHex: ex.ExcelColor.fromHexString('#00FF00'),
      );
      var fullDayStyle = ex.CellStyle(
        backgroundColorHex: ex.ExcelColor.fromHexString('#FFFFFF'),
      );

      // Header row
      sheet.appendRow([
        for (var value in [
          'EMPName',
          'Department',
          'Date',
          'CheckIn',
          'CheckInLocation',
          'CheckOut',
          'CheckOutLocation',
          'Record',
          'Status'
        ])
          ex.TextCellValue(value)
      ]);

      for (var record in records) {
        int rowIndex = sheet.maxRows + 1;
        sheet.appendRow([
          ex.TextCellValue(record.employeeName ?? 'N/A'),
          ex.TextCellValue(record.department ?? 'N/A'),
          ex.TextCellValue(record.date ?? 'N/A'),
          ex.TextCellValue(record.checkIn ?? 'N/A'),
          ex.TextCellValue(record.checkInLocation ?? 'N/A'),
          ex.TextCellValue(record.checkOut ?? 'N/A'),
          ex.TextCellValue(record.checkOutLocation ?? 'N/A'),
          ex.TextCellValue(record.record ?? 'N/A'),
          ex.TextCellValue(record.status ?? 'Absent'),
        ]);

        String status = record.status ?? 'Absent';
        if (status == 'Absent') {
          sheet.cell(ex.CellIndex.indexByString('I$rowIndex')).cellStyle = absentStyle;
        } else if (status == 'Half Day') {
          sheet.cell(ex.CellIndex.indexByString('I$rowIndex')).cellStyle = halfDayStyle;
        } else {
          sheet.cell(ex.CellIndex.indexByString('I$rowIndex')).cellStyle = fullDayStyle;
        }
      }

      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/attendance_data_monthly.xlsx');
        await tempFile.writeAsBytes(fileBytes);

        String username = "manthanpatel26510@gmail.com";
        String appSpecificPassword = "uqvcfqumgbynnpzq";

        final smtpServer = gmail(username, appSpecificPassword);
        final message = Message()
          ..from = Address('Deep6796@gmail.com', 'Techlead')
          ..recipients.add('Deep6796@gmail.com')
          ..subject = 'Monthly Attendance Data'
          ..text = 'Please find the attached monthly attendance data Excel sheet.\n'
          ..attachments.add(FileAttachment(tempFile)..fileName = 'attendance_data_monthly.xlsx');

        try {
          final sendReport = await send(message, smtpServer);
          print('Message sent: ' + sendReport.toString());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Monthly Excel file sent via email successfully!'),
              ),
            );
          }
        } on MailerException catch (e) {
          print('Message not sent. $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error sending email.')),
            );
          }
        }
      }
    } catch (e) {
      print('Error generating monthly Excel: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error generating Excel file.')),
        );
      }
    } finally {
      setState(() => isLoading2 = false);
    }
  }


  Future<void> _downloadExcel() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('Attendance').get();

      List<AttendanceRecord> records = querySnapshot.docs.map((doc) {
        return AttendanceRecord.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      records = records.where((record) {
        bool matchesSearchQuery =
            record.employeeName?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false;
        bool matchesDate = selectedDate == null || record.date == selectedDate;
        return matchesSearchQuery && matchesDate;
      }).toList();

      if (records.isEmpty) {
        Fluttertoast.showToast(
          msg: "No data found to download!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        setState(() => isLoading = false);
        return;
      }

      var excel = ex.Excel.createExcel();
      ex.Sheet sheet = excel['Attendance'];

      var absentStyle = ex.CellStyle(backgroundColorHex: ex.ExcelColor.fromHexString('#FF0000'));
      var halfDayStyle = ex.CellStyle(backgroundColorHex: ex.ExcelColor.fromHexString('#00FF00'));
      var fullDayStyle = ex.CellStyle(backgroundColorHex: ex.ExcelColor.fromHexString('#FFFFFF'));

      sheet.appendRow([
        for (var value in ['EMPName', 'Department', 'Date', 'CheckIn', 'CheckInLocation',
          'CheckOut', 'CheckOutLocation', 'Record', 'Status'])
          ex.TextCellValue(value)
      ]);

      for (var record in records) {
        int rowIndex = sheet.maxRows + 1;
        sheet.appendRow([
          ex.TextCellValue(record.employeeName ?? 'N/A'),
          ex.TextCellValue(record.department ?? 'N/A'),
          ex.TextCellValue(record.date ?? 'N/A'),
          ex.TextCellValue(record.checkIn ?? 'N/A'),
          ex.TextCellValue(record.checkInLocation ?? 'N/A'),
          ex.TextCellValue(record.checkOut ?? 'N/A'),
          ex.TextCellValue(record.checkOutLocation ?? 'N/A'),
          ex.TextCellValue(record.record ?? 'N/A'),
          ex.TextCellValue(record.status ?? 'Absent'),
        ]);

        String status = record.status ?? 'Absent';
        if (status == 'Absent') {
          sheet.cell(ex.CellIndex.indexByString('I$rowIndex')).cellStyle = absentStyle;
        } else if (status == 'Half Day') {
          sheet.cell(ex.CellIndex.indexByString('I$rowIndex')).cellStyle = halfDayStyle;
        } else {
          sheet.cell(ex.CellIndex.indexByString('I$rowIndex')).cellStyle = fullDayStyle;
        }
      }

      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/attendance_data.xlsx');
        await tempFile.writeAsBytes(fileBytes);

        String username = "manthanpatel26510@gmail.com";
        String appSpecificPassword = "uqvcfqumgbynnpzq";

        final smtpServer = gmail(username, appSpecificPassword);
        final message = Message()
          ..from = Address('Deep6796@gmail.com', 'Techlead')
          ..recipients.add('Deep6796@gmail.com')
          ..subject = 'Attendance For Employee Data'
          ..text = 'Please find the attached attendance data Excel Sheet.\n'
          ..attachments.add(FileAttachment(tempFile)..fileName = 'attendance_data.xlsx');

        try {
          final sendReport = await send(message, smtpServer);
          print('Message sent: ' + sendReport.toString());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.green,
                content: const Text(
                  'Excel file sent via email successfully!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }
        } on MailerException catch (e) {
          print('Message not sent. $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red,
                content: const Text(
                  'Error sending email.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error generating Excel file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: const Text(
              'Error generating Excel file.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }


@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(fontSize: 15),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF3f2e6c), // Dark blue background
                      labelText: 'Search by Employee Name',
                      labelStyle: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4.0),
                        borderSide: const BorderSide(color: Colors.white70),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4.0),
                        borderSide: const BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4.0),
                        borderSide: const BorderSide(color: Colors.cyanAccent, width: 2),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white, // White search icon
                      ),
                    ),
                  ),

                ),
                IconButton(
                  icon: Icon(Icons.date_range,color: Color(0xFF3f2e6c),),
                  onPressed: () {
                    _selectDate(context);
                  },
                ),
              ],
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 12),
                    child: ElevatedButton(
                      onPressed: _downloadExcel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                        "Download",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 11,vertical: 11),
                    child: ElevatedButton(
                      onPressed: () {
                        DateTime startOfMonth = DateTime(selectedYear, selectedMonth, 1);
                        DateTime endOfMonth = DateTime(selectedYear, selectedMonth + 1, 0);
                        _downloadMonthlyExcel(startOfMonth, endOfMonth);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      child: isLoading2
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                        "Month Download",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('Attendance')
                  .orderBy('date', descending: true) // Sort by date, recent first
                  .orderBy('checkIn', descending: true) // Sort by check-in time within each date
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildAttendanceShimmerList();
                }

                if (snapshot.hasError) {
                  print('Firestore Error: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No data available!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }

                List<AttendanceRecord> records = snapshot.data!.docs.map((doc) {
                  return AttendanceRecord.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                }).toList();

                records = records.where((record) {
                  bool matchesSearchQuery = record.employeeName
                      ?.toLowerCase()
                      .contains(searchQuery.toLowerCase()) ??
                      false;
                  bool matchesDate = selectedDate == null || record.date == selectedDate;
                  return matchesSearchQuery && matchesDate;
                }).toList();

                if (records.isEmpty) {
                  return Center(
                    child: Text(
                      'No Attendance data available',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (BuildContext context, int index) {
                    AttendanceRecord record = records[index];

                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child:Card(
                        margin: const EdgeInsets.all(11.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF0A2A5A),
                                Color(0xFF15489C),
                                Color(0xFF1E64D8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.topRight,
                                child: _buildStyledText("Record: ", "${index + 1}"),
                              ),
                              const SizedBox(height: 10),
                              _buildStyledText("EMPName: ", record.employeeName),
                              _buildStyledText("Department: ", record.department),
                              _buildStyledText("Date: ", record.date),
                              const SizedBox(height: 10),
                              _buildStyledText("CheckIn: ", record.checkIn),
                              _buildStyledText("CheckInLocation: ", record.checkInLocation),
                              const SizedBox(height: 10),
                              _buildStyledText("CheckOut: ", record.checkOut),
                              _buildStyledText("CheckOutLocation: ", record.checkOutLocation),
                              const SizedBox(height: 10),
                              _buildStyledText("Record: ", record.record),
                              _buildStyledText("Status: ", record.status),
                              const SizedBox(height: 10),
                              Center(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (_currentLocation != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => MapScreen(
                                                initialPosition: LatLng(
                                                  _currentLocation!.latitude,
                                                  _currentLocation!.longitude,
                                                ),
                                              ),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Unable to fetch current location.')),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF3f2e6c),

                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5.0),
                                        ),
                                      ),
                                      child: const Text(
                                        "Live Map",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      )

                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
Widget _buildStyledText(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
              fontSize: 14,
            ),
          ),
          TextSpan(
            text: value ?? 'N/A',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  );
}
Widget _buildAttendanceShimmerList() {
  return ListView.builder(
    itemCount: 6, // Number of shimmer placeholders
    itemBuilder: (context, index) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Shimmer.fromColors(
          baseColor: Colors.blue.shade900.withOpacity(0.4),
          highlightColor: Colors.white.withOpacity(0.6),
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.blue.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    },
  );
}
