import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Categoryscreen/Account/Accountshowdata.dart';
import '../Categoryscreen/Digital Marketing/Digitlmarketingshowdata.dart';
import '../Categoryscreen/Finance/Financeshowdata.dart';
import '../Categoryscreen/HR/hrreceivedscreen.dart';
import '../Categoryscreen/Installation/Installtionemployeedata.dart';
import '../Categoryscreen/Management/Managementshowdata.dart';
import '../Categoryscreen/Reception/Receptionshowdata.dart';
import '../Categoryscreen/Sales/Receivesaleshdata.dart';
import '../Categoryscreen/Social Media/Socialmediamarketingshowdata.dart';

class Admintasksummury extends StatefulWidget {
  const Admintasksummury({Key? key}) : super(key: key);

  @override
  State<Admintasksummury> createState() => _AdmintasksummuryState();
}

class _AdmintasksummuryState extends State<Admintasksummury> {
  String searchQuery = "";
  DateTime? startDate;
  DateTime? endDate;
  String selectedStatus = 'All';
  bool _isExpanded = false;
  final TextEditingController searchController = TextEditingController();
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  final DateTime now = DateTime.now();
  late final DateTime startOfMonth;
  late final DateTime endOfMonth;

  @override
  void initState() {
    super.initState();
    startOfMonth = DateTime(now.year, now.month, 1);
    endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF002147), // Deep Navy Blue for a strong professional look
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.3),
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          "My Admin Tasks",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Segoe UI', // More modern and widely used for clean UI
            letterSpacing: 0.5,
          ),
        ),
      ),

      body: Column(
        children: [
          _buildSearchAndStatusRow(),
          const SizedBox(height: 10),
          _buildDateFilters(),
          const SizedBox(height: 10),

          Expanded(
            child: currentUserId == null
                ? const Center(
                child: Text("User not logged in",
                    style: TextStyle(fontFamily: 'Times New Roman')))
                : FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('EmpProfile')
                    .doc(currentUserId)
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(
                        child: Text("User profile not found.",
                            style: TextStyle(
                                color: Colors.red,
                                fontFamily: 'Times New Roman')));
                  }

                  final fullName = snapshot.data!.get('fullName');
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('TaskAssign')
                        .where('employeeNames', arrayContains: fullName)
                        .snapshots(),
                    builder: (context, taskSnapshot) {
                      if (!taskSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Center(
                          child: Text(
                            "No tasks available",
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: 'Times New Roman',
                              color: Colors.black,
                            ),
                          ),
                        );
                      }

                      final filteredTasks = taskSnapshot.data!.docs.where((doc) {
                        final task = doc.data() as Map<String, dynamic>;
                        final status = task['taskstatus'] ?? 'Pending';
                        final name = task['projectName']?.toString().toLowerCase() ?? '';

                        if (selectedStatus != 'All' && status != selectedStatus) return false;
                        if (searchQuery.isNotEmpty && !name.contains(searchQuery.toLowerCase())) return false;

                        try {
                          DateTime taskDate = DateFormat('dd MMMM yyyy').parse(task['date']);
                          if (taskDate.isBefore(startOfMonth) || taskDate.isAfter(endOfMonth)) {
                            return false;
                          }
                        } catch (_) {
                          return false;
                        }

                        if (startDate != null && endDate != null) {
                          try {
                            DateTime assignedDate = DateFormat('dd MMMM yyyy').parse(task['date']);
                            DateTime start = DateTime(startDate!.year, startDate!.month, startDate!.day);
                            DateTime end = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59);
                            if (assignedDate.isBefore(start) || assignedDate.isAfter(end)) {
                              return false;
                            }
                          } catch (_) {
                            return false;
                          }
                        }

                        return true;
                      }).toList();

                      if (filteredTasks.isEmpty) {
                        String message;

                        if (searchQuery.isNotEmpty) {
                          message = "No tasks found matching your search.";
                        } else {
                          switch (selectedStatus) {
                            case 'Pending':
                              message = "No pending task data available.";
                              break;
                            case 'In Progress':
                              message = "No in-progress task data available.";
                              break;
                            case 'Completed':
                              message = "No completed task data available.";
                              break;
                            default:
                              message = "No current month task data available.";
                          }
                        }

                        return Center(
                          child: Text(
                            message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'Times New Roman',
                              color: Colors.black,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index].data() as Map<String, dynamic>;

                          void navigateToDepartmentPage(String department) {
                              switch (department) {
                                case 'Account':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => Accountshowdata()),
                                  );
                                  break;
                                case 'Digital Marketing':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => Digitlmarketingshowdata()),
                                  );
                                  break;
                                case 'Finance':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => Financeshowdata()),
                                  );
                                  break;
                                case 'Human Resource':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => Hrreceiveddata()),
                                  );
                                  break;
                                case 'Installation':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => AssignedTaskForInstallation()),
                                  );
                                  break;
                                case 'Management':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => Managementshowdata()),
                                  );
                                  break;
                                case 'Reception':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => Receptionshowdata()),
                                  );
                                  break;
                                case 'Sales':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => Receivesalesdata()),
                                  );
                                  break;
                                case 'Social Media':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => Socialmediamarketingshowdata()),
                                  );
                                  break;
                                default:
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('No route defined for department: $department')),
                                  );
                              }
                          }

                          return GestureDetector(
                            onTap: () {
                              final department = task['department'] ?? '';
                              navigateToDepartmentPage(department);
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              elevation: 6,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              child: Container(
                                width: double.infinity, // ✅ responsive both sides
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF000F89), Color(0xFF0F52BA), Color(0xFF002147)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 📋 Header
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: const [
                                        Text(
                                          "Task Summary",
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    _buildTaskDetail(Icons.person, 'Admin', task['adminName']),
                                    _buildTaskDetail(Icons.apartment, 'Department', task['department']),
                                    const Divider(color: Colors.white24),
                                    _buildTaskDetail(Icons.business, 'Project Name', task['projectName']),

                                    // ⬇ Expandable Description (short preview)
                                    GestureDetector(
                                      onTap: () {
                                        setState(() => _isExpanded = !_isExpanded);
                                      },
                                      child: _buildTaskDetail(
                                        Icons.description,
                                        'Description',
                                        _isExpanded
                                            ? task['taskDescription']
                                            : (task['taskDescription'] != null &&
                                            task['taskDescription'].length > 50
                                            ? '${task['taskDescription'].substring(0, 50)}... Tap to expand'
                                            : task['taskDescription']),
                                      ),
                                    ),

                                    const Divider(color: Colors.white24),
                                    Row(
                                      children: [
                                        Expanded(
                                            child: _buildTaskDetail(
                                                Icons.calendar_today, 'Assigned Date', task['date'])),
                                        const SizedBox(width: 12),
                                        Expanded(
                                            child: _buildTaskDetail(
                                                Icons.event, 'Deadline Date', task['deadlineDate'])),
                                      ],
                                    ),
                                    SizedBox(height: 10,),
                                    _buildTaskDetail(Icons.access_time, ' Assigned Time', task['time']),
                                    SizedBox(height: 5,),
                                    _buildTaskDetail(Icons.access_time, ' Deadline Time', task['deadlinetime']),
                                    const Divider(color: Colors.white24),

                                    _buildTaskDetail(
                                        Icons.comment, 'Employee Feedback', task['employeeDescription']),

                                    const SizedBox(height: 12),
                                    _buildTaskDetail(Icons.info_outline, 'Status', task['taskstatus']),

                                    // ✅ NEW Note Section (after Status)
                                    const Divider(color: Colors.white24),
                                    const Text(
                                      "Note: Tap here to view full description",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red, // 🔴 red color
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
                  );
                }),
          ),
        ],
      ),
    );
  }


  Widget _buildSearchAndStatusRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF000F89), // Royal Blue
              Color(0xFF0F52BA), // Cobalt Blue
              Color(0xFF002147), // Deep Navy
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          children: [
            // 🔍 Search Field
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TextField(
                  controller: searchController,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                    color: Colors.black87,
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search by Project Name",
                    hintStyle: TextStyle(
                      color: Colors.blue.shade900,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD6DDEB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                      const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                    ),
                  ),
                ),
              ),
            ),

            // 🔽 Status Dropdown
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: DropdownButtonFormField<String>(
                  value: selectedStatus,
                  isExpanded:
                  true, // ✅ important to make text visible properly
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedStatus = value;
                      });
                    }
                  },
                  items: [
                    _buildDropdownItem(
                        'Pending', Icons.pending_actions, Colors.orange),
                    _buildDropdownItem(
                        'In Progress', Icons.autorenew, Colors.blue),
                    _buildDropdownItem(
                        'Completed', Icons.check_circle, Colors.green),
                    _buildDropdownItem('All', Icons.all_inbox, Colors.grey),
                  ],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: "Filter by Status",
                    hintStyle: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Roboto',
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0F52BA),
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                      const BorderSide(color: Colors.white, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                      const BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                  dropdownColor: const Color(0xFF0F52BA),
                  iconEnabledColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Dropdown Item with proper wrap
  DropdownMenuItem<String> _buildDropdownItem(
      String value, IconData icon, Color iconColor) {
    return DropdownMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'Roboto',
              ),
              softWrap: true,
              overflow: TextOverflow.visible, // ✅ show full text
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildDateFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: _buildDateButton(
              context,
              "Start Date",
              startDate,
                  (date) {
                setState(() {
                  startDate = date;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDateButton(
              context,
              "End Date",
              endDate,
                  (date) {
                setState(() {
                  endDate = date;
                });
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDateButton(
      BuildContext context,
      String label,
      DateTime? date,
      Function(DateTime) onDateSelected,
      ) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF000F89), // Royal Blue
            Color(0xFF0F52BA), // Cobalt Blue
            Color(0xFF002147), // Deep Navy
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.calendar_today_rounded, color: Colors.white),
        label: Text(
          date != null ? DateFormat('dd MMM yyyy').format(date) : label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold, // Bold font
            fontFamily: 'Seogi Ui',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            onDateSelected(picked);
          }
        },
      ),
    );
  }




  Widget _buildTaskDetail(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.tealAccent),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontFamily: 'Roboto'),
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  TextSpan(
                    text: value != null && value.toString().isNotEmpty ? value.toString() : 'N/A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                      fontSize: 15,
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

}