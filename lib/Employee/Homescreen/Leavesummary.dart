import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaveSummaryScreen extends StatefulWidget {
  const LeaveSummaryScreen({Key? key}) : super(key: key);

  @override
  State<LeaveSummaryScreen> createState() => _LeaveSummaryScreenState();
}

class _LeaveSummaryScreenState extends State<LeaveSummaryScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final userId = FirebaseAuth.instance.currentUser?.uid;
  late TabController _tabController;
  DateTime selectedDate = DateTime.now();

  final List<String> tabs = ['All', 'Approved', 'Pending', 'Rejected'];

  @override
  void initState() {
    _tabController = TabController(length: tabs.length, vsync: this);
    super.initState();
  }

  Future<void> _selectMonth() async {
    final DateTime? pickedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: MonthYearPicker(
            selectedDate: selectedDate,
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
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getLeaveStream(String statusFilter) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('Empleave')
        .where('userId', isEqualTo: userId)
        .orderBy('reportedDateTime', descending: true);

    if (statusFilter.toLowerCase() != 'all') {
      final normalized = toBeginningOfSentenceCase(statusFilter.trim()); // ✅ Title Case
      query = query.where('status', isEqualTo: normalized);
    }

    return query.snapshots();
  }



  bool _isInSelectedMonth(DateTime date) {
    return date.year == selectedDate.year && date.month == selectedDate.month;
  }

  Widget _buildLeaveCard(Map<String, dynamic> leave, int index) {
    final reportedDate = leave['reportedDateTime']?.toDate() ?? DateTime.now();
    if (!_isInSelectedMonth(reportedDate)) return const SizedBox.shrink();

    final String status = leave['status'] ?? '';
    final String statusFormatted = toBeginningOfSentenceCase(status) ?? status;

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.greenAccent;
        break;
      case 'pending':
        statusColor = Colors.orangeAccent;
        break;
      default:
        statusColor = Colors.redAccent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [Colors.blue.shade900, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📋 Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Leave Record",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Record: ${index + 1}',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Times New Roman',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              _buildLeaveDetail(Icons.badge, 'Emp ID', leave['empid']),
              _buildLeaveDetail(Icons.person, 'Name', leave['name']),
              _buildLeaveDetail(Icons.email, 'Email', leave['emailid']),
              _buildLeaveDetail(Icons.category, 'Leave Type', leave['leavetype']),

              const Divider(color: Colors.white24),

              Row(
                children: [
                  Expanded(child: _buildLeaveDetail(Icons.calendar_today, 'Start Date', leave['startdate'])),
                  const SizedBox(width: 12),
                  Expanded(child: _buildLeaveDetail(Icons.event, 'End Date', leave['enddate'])),
                ],
              ),

              _buildLeaveDetail(Icons.info_outline, 'Status', statusFormatted, color: statusColor),
              _buildLeaveDetail(Icons.note, 'Reason', leave['reason']),

              const Divider(color: Colors.white24),

              Text(
                'Reported On: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(reportedDate)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Times New Roman',
                ),
              ),
            ],
          ),
        ),
      ),

    );
  }
  Widget _buildLeaveDetail(IconData icon, String label, String value, {Color color = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [Colors.cyanAccent, Colors.lightBlueAccent, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                    ),
                  ),
                  TextSpan(
                    text: value ?? '',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildNoData(String status) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          "No $status leave data found for selected month!",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontFamily: 'Times New Roman',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        elevation: 8,
        toolbarHeight: 70,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.cyanAccent, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            "Leave Summary",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontFamily: 'Montserrat',
              color: Colors.white, // overridden by Shader
              letterSpacing: 0.8,
            ),
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          GestureDetector(
            onTap: _selectMonth,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.calendar_month_outlined, color: Colors.black, size: 24),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(55),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 6,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00FFB4), Color(0xFF00C9FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white30,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                fontFamily: 'Montserrat',
                letterSpacing: 0.5,
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.white70,
              splashFactory: NoSplash.splashFactory,
              overlayColor: MaterialStateProperty.all(Colors.transparent),
              tabs: tabs
                  .map(
                    (tab) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Tab(text: tab),
                ),
              )
                  .toList(),
            ),
          ),
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: tabs.map((status) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _getLeaveStream(status),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final docs = snapshot.data?.docs ?? [];
              List<Widget> cards = [];

              for (int i = 0; i < docs.length; i++) {
                final leave = docs[i].data();
                final reportedDate = leave['reportedDateTime']?.toDate();
                if (reportedDate != null && _isInSelectedMonth(reportedDate)) {
                  cards.add(_buildLeaveCard(leave, i));
                }
              }

              if (cards.isEmpty) {
                return _buildNoData(status);
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(children: cards),
              );
            },
          );
        }).toList(),
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