import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../Categoryscreen/HR/Hrdailytaskreport.dart';
import '../Categoryscreen/Finance/Financedailytaskreport.dart';
import '../Categoryscreen/Installation/Installationdailytaskreport.dart';
import '../Categoryscreen/Management/Managementdailytaskreport.dart';
import '../Categoryscreen/Account/Accountdailytaskreport.dart';
import '../Categoryscreen/Reception/Receptionlistdailytaskreport.dart';
import '../Categoryscreen/Sales/Salesdailytaskreport.dart';
import '../Categoryscreen/Social Media/Smdailytaskreport.dart';
import '../Categoryscreen/Digital Marketing/Digitalmarketingdailytaskreport.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String label;
  final List<String> userDepartments;

  const TaskDetailsScreen({
    Key? key,
    required this.label,
    required this.userDepartments,
  }) : super(key: key);

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> taskList = [];
  List<Map<String, dynamic>> filteredList = [];

  TextEditingController searchController = TextEditingController();
  DateTime? selectedDate;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _loadTasksByStatus();
  }

  Future<void> _selectMonth() async {
    final DateTime initialDate = selectedDate ?? DateTime.now();

    final DateTime? pickedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: MonthYearPicker(
            selectedDate: initialDate,
            onChanged: (date) {
              Navigator.of(context).pop(date);
            },
          ),
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
        _filterList(searchController.text);
      });
    }
  }

  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  Future<void> _loadTasksByStatus() async {
    final String status = widget.label == "Pending Tasks"
        ? "Pending"
        : widget.label == "InProgress Tasks"
        ? "In Progress"
        : "Completed";

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('EmpProfile')
          .doc(currentUserId).get();

      if (!userDoc.exists || userDoc.data() == null) {
        print("❌ User profile not found.");
        setState(() {
          taskList = [];
          filteredList = [];
          isLoading = false;
        });
        return;
      }

      final String empId = userDoc.get('empId') ?? '';
      if (empId.isEmpty) {
        print("❌ empId is empty.");
        return;
      }

      List<Map<String, dynamic>> collected = [];

      for (int i = 0; i < widget.userDepartments.length; i += 10) {
        final chunk = widget.userDepartments.sublist(
          i,
          (i + 10 > widget.userDepartments.length)
              ? widget.userDepartments.length
              : i + 10,
        );

        QuerySnapshot snapshot = await _firestore
            .collection('DailyTaskReport')
            .where('employeeId', isEqualTo: empId)
            .where('service_status', isEqualTo: status)
            .where('category', whereIn: chunk)
            .get();

        if (snapshot.docs.isEmpty) {
          snapshot = await _firestore
              .collection('DailyTaskReport')
              .where('employeeId', isEqualTo: empId)
              .where('service_status', isEqualTo: status)
              .where('Service_department', whereIn: chunk)
              .get();
        }

        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          data['parsedDate'] = _parseDate(data['date']);
          data['rawDate'] = _convertToDateTime(data['date']);
          collected.add(data);
        }
      }

      setState(() {
        taskList = collected;
        isLoading = false;
        _filterList(searchController.text);
      });
    } catch (e) {
      print("❌ Error loading user-specific tasks: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  DateTime? _convertToDateTime(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) {
      try {
        return DateFormat('dd/MM/yyyy').parse(raw);
      } catch (_) {}
    }
    return null;
  }

  String _parseDate(dynamic raw) {
    if (raw is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(raw.toDate());
    } else if (raw is String) {
      return raw;
    } else {
      return 'N/A';
    }
  }

  void _filterList(String query) {
    final lowerQuery = query.toLowerCase();
    final selectedMonth = selectedDate?.month;
    final selectedYear = selectedDate?.year;

    List<Map<String, dynamic>> result = taskList.where((task) {
      final title = task['taskTitle']?.toString().toLowerCase() ?? '';
      final date = task['rawDate'] as DateTime?;

      final matchesTitle = title.contains(lowerQuery);
      final matchesDate = (selectedMonth == null || selectedYear == null)
          ? true
          : (date != null &&
          date.month == selectedMonth &&
          date.year == selectedYear);

      return matchesTitle && matchesDate;
    }).toList();

    for (int i = 0; i < result.length; i++) {
      result[i]['index'] = i + 1;
    }

    setState(() {
      filteredList = result;
    });
  }

  void _handleCardTap(String category) {
    Widget target;
    switch (category) {
      case 'Human Resource':
        target = const Hrdailytaskreport();
        break;
      case 'Finance':
        target = const Financedailytaskreport();
        break;
      case 'Management':
        target = const Managementdailytaskreport();
        break;
      case 'Installation':
        target = const DailyReportRecordOfInstallation();
        break;
      case 'Sales':
        target = const DailyReportRecordOfSales();
        break;
      case 'Reception':
        target = const DailyReportRecordOfReception();
        break;
      case 'Account':
        target = const Accountdailytaskreport();
        break;
      case 'Social Media':
        target = const Smdailytaskreport();
        break;
      case 'Digital Marketing':
        target = const Digitalmarketingdailytaskreport();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => target),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> data) {
    final category = data['category'] ?? data['Service_department'] ?? 'N/A';
    final employee = data['employeeName'] ?? 'N/A';
    final location = data['location'] ?? 'N/A';
    final nextSteps = data['nextSteps'] ?? 'N/A';
    final actionsTaken = data['actionsTaken'] ?? 'N/A';
    final date = data['parsedDate'] ?? 'N/A';

    TextStyle labelStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.cyanAccent,
    );

    TextStyle valueStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

    Widget buildLabeledText(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(height: 1.4),
            children: [
              TextSpan(text: '$label: ', style: labelStyle),
              TextSpan(text: value, style: valueStyle),
            ],
          ),
          maxLines: null, // allow multiline
          overflow: TextOverflow.visible,
        ),
      );
    }

    return GestureDetector(
      onTap: () => _handleCardTap(category),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF000F89),
              Color(0xFF0F52BA),
              Color(0xFF002147),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.4),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade900,
                    child: Text(
                      '${data['index']}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data['taskTitle'] ?? 'Untitled Task',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Times New Roman',
                        fontSize: 16,
                        color: Colors.cyanAccent,
                      ),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              buildLabeledText('Category', category),
              buildLabeledText('Submitted Name', employee),
              buildLabeledText('Location', location),
              buildLabeledText('Submitted Date', date),
              buildLabeledText('Action Taken', actionsTaken),
              buildLabeledText('Next Step', nextSteps),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: Text(
          widget.label,
          style: const TextStyle(
              fontFamily: 'Times New Roman',
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: _filterList,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF000F89),
                      hintText: 'Search by Project...',
                      hintStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none, // remove border outline
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none, // no border when enabled
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.white, // white border when focused
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _selectMonth,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade900,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_month_outlined, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  searchController.text.isNotEmpty
                      ? 'In ${widget.label} search data not available right now!'
                      : 'In current month no ${widget.label} available right now!',
                  style: const TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
                : ListView.builder(
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                return _buildTaskCard(filteredList[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
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
          colors: [Color(0xFF000F89), Color(0xFF0F52BA), Color(0xFF002147)],
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
            dropdownColor: const Color(0xFF001f4d), // Bluish dropdown background
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
                    value ?? _selectedDate.year, _selectedDate.month);
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
