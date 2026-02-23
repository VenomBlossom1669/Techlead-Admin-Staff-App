import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'dart:io';
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:techlead/Employee/Homescreen/Leavemodel.dart';
import 'package:techlead/Widgeets/custom_app_bar.dart';
import 'package:techlead/core/app_bar_provider.dart';

class LeaveInfo extends ConsumerStatefulWidget {
  const LeaveInfo({super.key});

  @override
  ConsumerState<LeaveInfo> createState() => _LeaveInfoState();
}

class _LeaveInfoState extends ConsumerState<LeaveInfo> {

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (mounted) {
        ref.read(appBarTitleProvider.notifier).state = "Employee Leave Records";
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
      if (mounted) {
        resetAppBar(ref);
      }
    });
    super.dispose();
  }



  bool isAdmin = true;
  TextEditingController searchController = TextEditingController();
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  String? selectedFilter = 'All';
  final List<String> filters = ['All', 'Approved', 'Rejected', 'Pending'];
  bool isLoading = false;
  bool isLoading2 = false;
  bool isToastVisible = false;

  void _updateLeaveStatus(String docId, String status) async {
    try {
      await FirebaseFirestore.instance.collection('Empleave').doc(docId).update({
        'status': status,
      });

      Fluttertoast.showToast(
        msg: "Leave status updated to $status",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );

      setState(() {});
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error updating status: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  DateTime selectedDate = DateTime.now();
  String currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime initialDate = DateTime(selectedDate.year, selectedDate.month);

    final DateTime? pickedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        DateTime tempSelectedDate = initialDate;

        return Dialog(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0A2A5A),
                  Color(0xFF1E64D8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Month and Year',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 20),
                Theme(
                  data: ThemeData(
                    dialogBackgroundColor: const Color(0xFF0A2A5A), // List background
                    canvasColor: const Color(0xFF0A2A5A), // Dropdown popup background
                    inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: const Color(0xFF0A2A5A), // Field background
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    textTheme: const TextTheme(
                      titleMedium: TextStyle(
                        color: Colors.white, // Field text
                        fontWeight: FontWeight.bold,
                      ),
                      bodyMedium: TextStyle(
                        color: Colors.white, // Dropdown list item text
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    iconTheme: const IconThemeData(color: Colors.white), // Arrow icon
                    dropdownMenuTheme: DropdownMenuThemeData(
                      menuStyle: MenuStyle(
                        backgroundColor: MaterialStatePropertyAll(Color(0xFF0A2A5A)),
                      ),
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  child: MonthYearPicker(
                    selectedDate: tempSelectedDate,
                    onChanged: (date) {
                      tempSelectedDate = date;
                    },
                  ),
                ),



                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A2A5A), Color(0xFF0A2A5A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).pop(tempSelectedDate);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Text(
                            'Select',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = DateTime(pickedDate.year, pickedDate.month, 1);
        currentMonth = DateFormat('MMMM yyyy').format(selectedDate);
      });
      // Add your logic here if you want to re-fetch records or update UI
    }
  }



  Future<void> downloadMonthlyLeaveExcel(DateTime startDate, DateTime endDate) async {
    if (!mounted) return;
    setState(() => isLoading2 = true);

    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('Empleave').get();

      List<LeaveModel> records =
      querySnapshot.docs.map((doc) => LeaveModel.fromSnapshot(doc)).toList();

      records = records.where((record) {
        DateTime? recordStartDate = parseDate(record.startdate);
        if (recordStartDate == null) return false;

        bool matchesDateRange = recordStartDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            recordStartDate.isBefore(endDate.add(const Duration(days: 1)));

        bool matchesSearchQuery = searchController.text.isEmpty ||
            record.name.toLowerCase().contains(searchController.text.toLowerCase());
        bool matchesFilter =
            selectedFilter == null || selectedFilter == 'All' || record.status == selectedFilter;

        return matchesDateRange && matchesSearchQuery && matchesFilter;
      }).toList();

      if (records.isEmpty) {
        Fluttertoast.showToast(
          msg: "No records found for this month!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      var excel = ex.Excel.createExcel();
      ex.Sheet sheet = excel['Leave Records'];

      var pendingStyle = ex.CellStyle(
        backgroundColorHex: ex.ExcelColor.fromHexString('#FFFF00'),
      );
      var approvedStyle = ex.CellStyle(
        backgroundColorHex: ex.ExcelColor.fromHexString('#00FF00'),
      );
      var rejectedStyle = ex.CellStyle(
        backgroundColorHex: ex.ExcelColor.fromHexString('#FF0000'),
      );

      sheet.appendRow([
        for (var value in [
          'EMPID',
          'Employee Name',
          'Email ID',
          'Leave Type',
          'Start Date',
          'End Date',
          'Reason',
          'Status',
          'Reported Date'
        ])
          ex.TextCellValue(value)
      ]);

      for (var record in records) {
        int rowIndex = sheet.maxRows + 1;
        sheet.appendRow([
          ex.TextCellValue(record.empid ?? 'N/A'),
          ex.TextCellValue(record.name ?? 'N/A'),
          ex.TextCellValue(record.emailid ?? 'N/A'),
          ex.TextCellValue(record.leavetype ?? 'N/A'),
          ex.TextCellValue(record.startdate ?? 'N/A'),
          ex.TextCellValue(record.enddate ?? 'N/A'),
          ex.TextCellValue(record.reason ?? 'N/A'),
          ex.TextCellValue(record.status ?? 'N/A'),
          ex.TextCellValue(record.reportedDateTime.toDate().toString()),
        ]);

        if (record.status == 'Pending') {
          sheet.cell(ex.CellIndex.indexByString('H$rowIndex')).cellStyle = pendingStyle;
        } else if (record.status == 'Approved') {
          sheet.cell(ex.CellIndex.indexByString('H$rowIndex')).cellStyle = approvedStyle;
        } else if (record.status == 'Rejected') {
          sheet.cell(ex.CellIndex.indexByString('H$rowIndex')).cellStyle = rejectedStyle;
        }
      }

      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/monthly_leave_data.xlsx');
        await tempFile.writeAsBytes(fileBytes);

        final smtpServer = gmail("manthanpatel26510@gmail.com", "uqvcfqumgbynnpzq");
        final message = Message()
          ..from = Address('Deep6796@gmail.com', 'Techlead')
          ..recipients.add('Deep6796@gmail.com')
          ..subject = 'Monthly Leave Records Data'
          ..text = 'Please find the attached monthly leave records Excel sheet.\n'
          ..attachments.add(FileAttachment(tempFile)..fileName = 'monthly_leave_data.xlsx');

        await send(message, smtpServer);
        Fluttertoast.showToast(
          msg: "Monthly Leave Excel file sent successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error generating Monthly Leave Excel file! $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() => isLoading2 = false);
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


  Future<void> downloadLeaveExcel() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('Empleave').get();

      List<LeaveModel> records =
      querySnapshot.docs.map((doc) => LeaveModel.fromSnapshot(doc)).toList();

      records = records.where((record) {
        bool matchesSearchQuery = searchController.text.isEmpty ||
            record.name.toLowerCase().contains(searchController.text.toLowerCase());
        bool matchesFilter =
            selectedFilter == null || selectedFilter == 'All' || record.status == selectedFilter;
        return matchesSearchQuery && matchesFilter;
      }).toList();

      if (records.isEmpty) {
        Fluttertoast.showToast(
          msg: "No records found!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      var excel = ex.Excel.createExcel();
      ex.Sheet sheet = excel['Leave Records'];
      var pendingStyle = ex.CellStyle(
        backgroundColorHex: ex.ExcelColor.fromHexString('#FFFF00'),
      );
      var approvedStyle = ex.CellStyle(
        backgroundColorHex: ex.ExcelColor.fromHexString('#00FF00'),
      );
      var rejectedStyle = ex.CellStyle(
        backgroundColorHex: ex.ExcelColor.fromHexString('#FF0000'),
      );

      // var pendingStyle = ex.CellStyle(backgroundColorHex: '#FFFF00');
      // var approvedStyle = ex.CellStyle(backgroundColorHex: '#00FF00');
      // var rejectedStyle = ex.CellStyle(backgroundColorHex: '#FF0000');

      // Header Row
      sheet.appendRow([
        for (var value in [
          'EMPID',
          'Employee Name',
          'Email ID',
          'Leave Type',
          'Start Date',
          'End Date',
          'Reason',
          'Status',
          'Reported Date'
        ])
          ex.TextCellValue(value)
      ]);

      for (var record in records) {
        int rowIndex = sheet.maxRows + 1;
        sheet.appendRow([
          ex.TextCellValue(record.empid ?? 'N/A'),
          ex.TextCellValue(record.name ?? 'N/A'),
          ex.TextCellValue(record.emailid ?? 'N/A'),
          ex.TextCellValue(record.leavetype ?? 'N/A'),
          ex.TextCellValue(record.startdate ?? 'N/A'),
          ex.TextCellValue(record.enddate ?? 'N/A'),
          ex.TextCellValue(record.reason ?? 'N/A'),
          ex.TextCellValue(record.status ?? 'N/A'),
          ex.TextCellValue(record.reportedDateTime.toDate().toString()),
        ]);

        if (record.status == 'Pending') {
          sheet.cell(ex.CellIndex.indexByString('H$rowIndex')).cellStyle = pendingStyle;
        } else if (record.status == 'Approved') {
          sheet.cell(ex.CellIndex.indexByString('H$rowIndex')).cellStyle = approvedStyle;
        } else if (record.status == 'Rejected') {
          sheet.cell(ex.CellIndex.indexByString('H$rowIndex')).cellStyle = rejectedStyle;
        }
      }

      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/leave_data.xlsx');
        await tempFile.writeAsBytes(fileBytes);

        final smtpServer = gmail("manthanpatel26510@gmail.com", "uqvcfqumgbynnpzq");
        final message = Message()
          ..from = Address('Deep6796@gmail.com', 'Techlead')
          ..recipients.add('Deep6796@gmail.com')
          ..subject = 'Leave Records Data'
          ..text = 'Please find the attached leave records Excel sheet.\n'
          ..attachments.add(FileAttachment(tempFile)..fileName = 'leave_data.xlsx');

        await send(message, smtpServer);
        Fluttertoast.showToast(
          msg: "Leave Excel file sent successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error generating Leave Excel file! $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(fontSize: 15),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE6EDF3),
              Color(0xFFCAD7E1),
              Color(0xFFB3C5D3),
            ],


            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: OrientationBuilder(
          builder: (context, orientation) {
            return SingleChildScrollView(
              child: Center(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 20,
                            ),
                            child: SizedBox(
                              height: 50,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade900, Colors.blue.shade900],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: TextFormField(
                                  controller: searchController,
                                  onChanged: (value) {
                                    setState(() {});
                                  },
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white, // text color white
                                  ),
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.search_outlined,
                                      color: Colors.white, // white icon
                                    ),
                                    labelText: 'Search by Employee Name...',
                                    labelStyle: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,
                                    fontSize: 14),
                                  // white label text
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide.none, // no border, since container has bg
                                      borderRadius: BorderRadius.all(Radius.circular(8)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.all(Radius.circular(8)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.all(Radius.circular(8)),
                                    ),
                                    fillColor: Colors.transparent,
                                    filled: true,
                                  ),
                                ),
                              ),

                            ),
                          ),
                        ),
                        Row(
                          children: [
                             Text(
                              "Filter: ",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900, // Same as other label texts
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1E5BB8), // Darker blue from 0xFF4A90E2
                                    Color(0xFF005FCC), // Darker blue from 0xFF007AFF
                                  ],

                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),

                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  dropdownColor: Colors.blue.shade900, // Background color of dropdown list
                                  value: selectedFilter,
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  items: filters.map((item) {
                                    return DropdownMenuItem<String>(
                                      value: item,
                                      child: Text(item),
                                    );
                                  }).toList(),
                                  onChanged: (item) => setState(() => selectedFilter = item),
                                ),
                              ),
                            ),
                          ],
                        )

                      ],
                    ),
                    SizedBox(height: 10,),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 11),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade900, Colors.blue.shade900],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                                child: ElevatedButton(
                                  onPressed: downloadLeaveExcel,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                      : const Text(
                                    "Download",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 11),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade900, Colors.blue.shade900],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    _selectMonth(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                  child: const Text(
                                    "Pick a Month",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )

                      ],
                    ),
                    StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('Empleave')
                          .orderBy('reportedDateTime', descending: false)
                          .snapshots(),
                      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return _buildShimmerList();
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }
                        if (snapshot.data!.docs.isEmpty) {
                          return Center(child: Text('No data available!', style: TextStyle(fontWeight: FontWeight.bold),));
                        }

                        List<LeaveModel> leaveList = snapshot.data!.docs.map((doc) {
                          return LeaveModel.fromSnapshot(doc);
                        }).toList();

                        leaveList = leaveList.where((leave) {
                          bool matchesSearch = searchController.text.isEmpty ||
                              leave.name.toLowerCase().contains(searchController.text.toLowerCase());
                          bool matchesFilter = selectedFilter == null ||
                              selectedFilter == 'All' ||
                              leave.status == selectedFilter;
                          return matchesSearch && matchesFilter;
                        }).toList();

                        if (leaveList.isEmpty) {
                          return const Center(child: Text('No Data Found!',style: TextStyle(fontWeight: FontWeight.bold,),));
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: leaveList.length,
                          itemBuilder: (BuildContext context, int index) {
                            var leaveModel = leaveList[index];
                            var showButtons = (leaveModel.status == "Pending" || leaveModel.status == null) && isAdmin;
                            var docId = leaveModel.documentId;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade900, Colors.blue.shade900],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10), // same radius as Card
                                ),
                                margin: EdgeInsets.all(5.0),
                                padding: EdgeInsets.all(15.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'Record: ',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.cyanAccent,
                                                ),
                                              ),
                                              TextSpan(
                                                text: '${index + 1}',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    _buildRichTextCustom('EmpId: ', leaveModel.empid),
                                    _buildRichTextCustom('EmpName: ', leaveModel.name),
                                    _buildRichTextCustom('EmpEmailId: ', leaveModel.emailid),
                                    _buildRichTextCustom('Leavetype: ', leaveModel.leavetype),
                                    _buildRichTextCustom('StartDate: ', leaveModel.startdate),
                                    _buildRichTextCustom('EndDate: ', leaveModel.enddate),
                                    _buildRichTextCustom('Reason: ', leaveModel.reason),
                                    _buildStatusRichTextCustom('Status: ', leaveModel.status ?? 'Unknown'),
                                    if (leaveModel.status == "Pending") ...[
                                      SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              _updateLeaveStatus(docId, 'Approved');
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10)),
                                            ),
                                            child: Text(
                                              'Approve',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              _updateLeaveStatus(docId, 'Rejected');
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10)),
                                            ),
                                            child: Text(
                                              'Reject',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Text(
                                          'Reported Date&Time: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.cyanAccent,
                                              fontSize: 13),
                                        ),
                                        Text(
                                          leaveModel.reportedDateTime != null
                                              ? DateFormat('dd/MM/yyyy HH:mm:ss')
                                              .format((leaveModel.reportedDateTime as Timestamp).toDate())
                                              : 'N/A',
                                          style: TextStyle(color: Colors.white, fontSize: 13),
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
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRichTextCustom(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6, // Number of shimmer placeholders
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Shimmer.fromColors(
            baseColor: Colors.blue.shade800.withOpacity(0.5),
            highlightColor: Colors.white.withOpacity(0.6),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade900,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(15.0),
              height: 160,
            ),
          ),
        );
      },
    );
  }


  Widget _buildStatusRichTextCustom(String label, String value) {
    Color statusColor;

    switch (value.toLowerCase()) {
      case 'approved':
        statusColor = Colors.greenAccent;
        break;
      case 'rejected':
        statusColor = Colors.redAccent;
        break;
      case 'pending':
        statusColor = Colors.orangeAccent;
        break;
      default:
        statusColor = Colors.white;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

}




int hexColor(String color) {
  String newColor = '0xff' + color.replaceAll('#', '');
  return int.parse(newColor);
}

// Custom Month-Year Picker Widget
class MonthYearPicker extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  const MonthYearPicker({
    Key? key,
    required this.selectedDate,
    required this.onChanged,
  }) : super(key: key);

  @override
  _MonthYearPickerState createState() => _MonthYearPickerState();
}

class _MonthYearPickerState extends State<MonthYearPicker> {
  late DateTime _selectedDate;
  late List<int> _years;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _years = List.generate(101, (index) =>
    DateTime.now().year - 50 + index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: DropdownButtonFormField<int>(
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  width: 1,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
            value: _selectedDate.month,
            items: List.generate(12, (index) => index + 1)
                .map((month) => DropdownMenuItem<int>(
              value: month,
              child: Text(
                DateFormat('MMMM').format(DateTime(0, month)),
                style: TextStyle(fontSize: 18),
              ),
            ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedDate = DateTime(
                    _selectedDate.year, value ?? _selectedDate.month);
              });
            },
            validator: (value) {
              if (value == null) {
                return "Please select a month";
              }
              return null;
            },
          ),
        ),
        SizedBox(height: 16), // Space between dropdowns
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: DropdownButtonFormField<int>(
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  width: 1,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
            value: _selectedDate.year,
            items: _years
                .map((year) => DropdownMenuItem<int>(
              value: year,
              child: Text(
                year.toString(),
                style: TextStyle(fontSize: 18),
              ),
            ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedDate = DateTime(
                    value ?? _selectedDate.year, _selectedDate.month);
              });
            },
            validator: (value) {
              if (value == null) {
                return "Please select a year";
              }
              return null;
            },
          ),
        ),

      ],
    );
  }
}
