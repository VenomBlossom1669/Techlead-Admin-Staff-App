import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:provider/provider.dart';
import '../Attendacescreen/Attendancemodel.dart';
import '../../Default/Themeprovider.dart';

class Calendarscreen extends StatefulWidget {
  const Calendarscreen({Key? key}) : super(key: key);

  @override
  State<Calendarscreen> createState() => _CalendarscreenState();
}

class _CalendarscreenState extends State<Calendarscreen> {
  DateTime selectedDate = DateTime.now();
  String currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());

  Set<int> expandedItems = {};

  @override
  void initState() {
    super.initState();
  }

  Stream<List<AttendanceRecord>> getAttendanceRecords() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('Attendance')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              print('Raw data from Firestore: ${doc.data()}');
              return AttendanceRecord.fromMap(
                  doc.data() as Map<String, dynamic>, doc.id);
            }).toList());
  }

  List<AttendanceRecord> getFilteredRecords(List<AttendanceRecord> records) {
    List<AttendanceRecord> filtered = records.where((record) {
      if (record.date == null || record.date!.isEmpty) return false;
      try {
        DateTime recordDate = DateFormat('dd/MM/yyyy').parse(record.date!);
        return recordDate.month == selectedDate.month &&
            recordDate.year == selectedDate.year;
      } catch (e) {
        print('Error parsing date: ${record.date}, Error: $e');
        return false;
      }
    }).toList();

    filtered.sort((a, b) {
      DateTime dateA = DateFormat('dd/MM/yyyy').parse(a.date ?? '');
      DateTime dateB = DateFormat('dd/MM/yyyy').parse(b.date ?? '');
      return dateA.compareTo(dateB);
    });

    print('Filtered and sorted records: $filtered');
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF000F89), // Royal Blue
                Color(0xFF0F52BA), // Cobalt Blue
                Color(0xFF002147), // Dark Navy
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'My Attendance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 15),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(width: 15),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF000F89), // Royal Blue
                        Color(0xFF0F52BA), // Cobalt Blue
                        Color(0xFF002147), // Dark Navy
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    currentMonth,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: GestureDetector(
                    onTap: () {
                      _selectMonth(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2), // border thickness
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF000F89), // Royal Blue
                            Color(0xFF0F52BA), // Cobalt Blue
                            Color(0xFF002147), // Dark Navy
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF000F89), // Royal Blue
                              Color(0xFF0F52BA), // Cobalt Blue
                              Color(0xFF002147), // Dark Navy
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Pick a Month",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<List<AttendanceRecord>>(
                stream: getAttendanceRecords(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: CircularProgressIndicator(
                      color: Colors.white,
                    ));
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  List<AttendanceRecord> records = snapshot.data ?? [];
                  List<AttendanceRecord> filteredRecords =
                      getFilteredRecords(records);

                  if (filteredRecords.isEmpty) {
                    return Center(
                      child: Text(
                        "No data available",
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredRecords.length,
                    itemBuilder: (context, index) {
                      AttendanceRecord record = filteredRecords[index];
                      bool isExpanded = expandedItems.contains(index);

                      String formattedDate = 'N/A';
                      String shortDayOfWeek = 'N/A';

                      DateTime now = DateTime.now();

                      try {
                        DateTime dateTime =
                            DateFormat('dd/MM/yyyy').parse(record.date ?? '');
                        formattedDate = DateFormat('d').format(dateTime);
                        shortDayOfWeek = DateFormat('EEE').format(dateTime);
                      } catch (e) {
                        formattedDate = DateFormat('d').format(now);
                        shortDayOfWeek = DateFormat('EEE').format(now);
                        print('Error formatting date: $e');
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Left date panel
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF000F89),
                                          Color(0xFF0F52BA),
                                          Color(0xFF002147),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$shortDayOfWeek\n$formattedDate',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Right info panel
                                Expanded(
                                  flex: 7,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF000F89),
                                          Color(0xFF0F52BA),
                                          Color(0xFF002147),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildLabelRow('Employee Name:',
                                            record.employeeName ?? 'N/A',
                                            icon: Icons.person),
                                        _buildLabelRow('Address:',
                                            record.department ?? 'N/A',
                                            icon: Icons.location_city),
                                        if (isExpanded) ...[
                                          const SizedBox(height: 8.0),
                                          _buildLabelRow('Check-In:',
                                              record.checkIn ?? 'N/A',
                                              icon: Icons.login),
                                          _buildLabelRow('Check In Location:',
                                              record.checkInLocation ?? 'N/A',
                                              icon: Icons.place),
                                          const SizedBox(height: 5),
                                          _buildLabelRow('Check-Out:',
                                              record.checkOut ?? 'N/A',
                                              icon: Icons.logout),
                                          _buildLabelRow('Check Out Location:',
                                              record.checkOutLocation ?? 'N/A',
                                              icon: Icons.place_outlined),
                                          const SizedBox(height: 5),
                                          _buildLabelRow(
                                              'Record:', record.record ?? 'N/A',
                                              icon: Icons.calendar_today),
                                          _buildLabelRow(
                                              'Status:', record.status ?? 'N/A',
                                              icon: Icons.verified),
                                        ],
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () {
                                              setState(() {
                                                if (isExpanded) {
                                                  expandedItems.remove(index);
                                                } else {
                                                  expandedItems.add(index);
                                                }
                                              });
                                            },
                                            child: Text(
                                              isExpanded
                                                  ? "See Less"
                                                  : "See More",
                                              style: const TextStyle(
                                                color: Colors.cyanAccent,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.cyanAccent),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime initialDate =
        DateTime(selectedDate.year, selectedDate.month);
    final DateTime? pickedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Month and Year'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MonthYearPicker(
                  selectedDate: initialDate,
                  onChanged: (date) {
                    Navigator.of(context).pop(date);
                  },
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
      }); // Re-fetch records for the selected month
    }
  }
}

int hexColor(String color) {
  String newColor = '0xff' + color.replaceAll('#', '');
  return int.parse(newColor);
}

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
    _years = List.generate(101, (index) => DateTime.now().year - 50 + index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF000F89), Color(0xFF0F52BA), Color(0xFF03448C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Select Month and Year',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Month Dropdown
          DropdownButtonFormField<int>(
            dropdownColor: const Color(0xFF001f4d),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF001f4d),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white70),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(width: 1, color: Colors.white),
              ),
            ),
            iconEnabledColor: Colors.white,
            value: _selectedDate.month,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            items: List.generate(12, (index) => index + 1)
                .map((month) => DropdownMenuItem<int>(
                      value: month,
                      child: Text(
                        DateFormat('MMMM').format(DateTime(0, month)),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedDate = DateTime(
                  _selectedDate.year,
                  value ?? _selectedDate.month,
                );
              });
            },
          ),

          const SizedBox(height: 16),

          // Year Dropdown
          DropdownButtonFormField<int>(
            dropdownColor: const Color(0xFF001f4d),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF001f4d),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white70),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(width: 1, color: Colors.white),
              ),
            ),
            iconEnabledColor: Colors.white,
            value: _selectedDate.year,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            items: _years
                .map((year) => DropdownMenuItem<int>(
                      value: year,
                      child: Text(
                        year.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedDate = DateTime(
                  value ?? _selectedDate.year,
                  _selectedDate.month,
                );
              });
            },
          ),

          const SizedBox(height: 24),

          // Select Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onChanged(_selectedDate);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002147),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Select',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
