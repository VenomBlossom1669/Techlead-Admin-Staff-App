import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../Employee/Categoryscreen/FileViwerscreen.dart';
import 'EditAdmintaskassigned.dart';

class Admintaskassigneddata extends StatefulWidget {
  final String? projectName;
  final int? unreadCount;
  final String? highlightedTaskId;

  const Admintaskassigneddata({
    this.projectName,
    this.unreadCount,
    this.highlightedTaskId,
    Key? key,
  }) : super(key: key);

  @override
  _AdmintaskassigneddataState createState() => _AdmintaskassigneddataState();
}

class _AdmintaskassigneddataState extends State<Admintaskassigneddata> {
  String searchQuery = "";
  String? filterDepartment;
  String? filterProject;
  String? filterStatus;
  String? filterEmployeeName;
  DateTime? startDate;
  DateTime? endDate;
  String? _flashTaskId;

  String? selectedFilterType;
  String? highlightedTaskId;
  bool _scrolledToHighlighted = false;

  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _taskKeys = {};

  int _limit = 4; // 🔹 first 4 tasks
  final int _limitIncrement = 4; // 🔹 load next 4 on scroll


  final List<String> filterTypes = [
    'Department',
    'Project',
    'Project Status',
    'Employee Name',
  ];

  @override
  void initState() {
    super.initState();
    highlightedTaskId = widget.highlightedTaskId;

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        setState(() {
          _limit += _limitIncrement;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            AppBar(
              title: const Text(
                "Assigned Tasks From Admin",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: "Times New Roman",
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.blue.shade900,
              iconTheme: const IconThemeData(color: Colors.white),
            ),

            if ((widget.unreadCount ?? 0) > 0)
              Container(
                width: double.infinity,
                color: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Text(
                    '🔔 You have ${widget.unreadCount} unread task(s) as a green color card',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Times New Roman",
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),
            _buildDropdownFilters(),
            _buildDateFilters(),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('TaskAssign')
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return _noRecordsWidget("No tasks assigned.");
                  }

                  List<QueryDocumentSnapshot> docs = snap.data!.docs;
                  if (highlightedTaskId != null && !_scrolledToHighlighted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final key = _taskKeys[highlightedTaskId];
                      if (key?.currentContext != null) {
                        Scrollable.ensureVisible(
                          key!.currentContext!,
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                        );
                        _scrolledToHighlighted = true;
                      }
                    });
                  }




                  final filtered = docs.where((doc) {
                    final t = doc.data() as Map<String, dynamic>;
                    final dep = t['department']?.toString() ?? '';
                    final proj = t['projectName']?.toString() ?? '';
                    final status = t['taskstatus']?.toString() ?? '';
                    final employeeField = t['employeeNames'];

                    if (searchQuery.isNotEmpty &&
                        !proj.toLowerCase().contains(searchQuery.toLowerCase())) {
                      return false;
                    }

                    if (filterDepartment != null &&
                        filterDepartment!.isNotEmpty &&
                        dep.toLowerCase() != filterDepartment!.toLowerCase()) {
                      return false;
                    }

                    if (filterProject != null &&
                        filterProject!.isNotEmpty &&
                        proj.toLowerCase() != filterProject!.toLowerCase()) {
                      return false;
                    }

                    if (filterStatus != null &&
                        filterStatus!.isNotEmpty &&
                        status.toLowerCase() != filterStatus!.toLowerCase()) {
                      return false;
                    }

                    if (filterEmployeeName != null &&
                        filterEmployeeName!.isNotEmpty) {
                      bool matches = false;
                      if (employeeField is List) {
                        matches = employeeField.contains(filterEmployeeName);
                      } else if (employeeField is String) {
                        matches = employeeField == filterEmployeeName;
                      }
                      if (!matches) return false;
                    }

                    if (startDate != null && endDate != null) {
                      DateTime assigned;
                      try {
                        assigned = t['date'] is Timestamp
                            ? (t['date'] as Timestamp).toDate()
                            : DateFormat('dd MMMM yy').parse(t['date']);
                      } catch (_) {
                        return false;
                      }
                      final start = DateTime(
                          startDate!.year, startDate!.month, startDate!.day);
                      final end = DateTime(endDate!.year, endDate!.month,
                          endDate!.day, 23, 59, 59);
                      if (assigned.isBefore(start) || assigned.isAfter(end)) {
                        return false;
                      }
                    }

                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return _noRecordsWidget(
                        "No records match selected filters.");
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      return _buildTaskCard(doc);
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

  Widget _noRecordsWidget(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(
          fontFamily: "Times New Roman",
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDropdownFilters() {
    final cobaltBlueWithOpacity = const Color(0xFF0F52BA).withOpacity(0.3);

    final filterLabelTextStyle = TextStyle(
      fontFamily: "Times New Roman",
      color: const Color(0xFF002147),
      fontWeight: FontWeight.w700,
      fontSize: 16,
      letterSpacing: 0.8,
      shadows: [
        Shadow(
          offset: const Offset(0, 1),
          blurRadius: 1.5,
          color: cobaltBlueWithOpacity,
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list,
                  color: Color(0xFF0F52BA), size: 20),
              const SizedBox(width: 6),
              Text("Filter by...", style: filterLabelTextStyle),
            ],
          ),
          const SizedBox(height: 6),
          Container(
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
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String>(
              value: selectedFilterType,
              onChanged: (val) => setState(() => selectedFilterType = val),
              decoration: const InputDecoration(
                hintText: "Select filter type",
                hintStyle: TextStyle(
                  fontFamily: "Times New Roman",
                  color: Colors.white70,
                  fontSize: 13,
                ),
                border: InputBorder.none,
              ),
              dropdownColor: const Color(0xFF223D64),
              iconEnabledColor: Colors.white,
              style: const TextStyle(color: Colors.white),
              items: [null, ...filterTypes].map((val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(
                    val ?? 'None',
                    style: const TextStyle(
                      fontFamily: "Times New Roman",
                      color: Colors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          if (selectedFilterType != null)
            _buildDynamicFilterDropdown(selectedFilterType!),
        ],
      ),
    );
  }

  Widget _buildDynamicFilterDropdown(String type) {
    switch (type) {
      case 'Department':
        return _buildFilterDropdown(
          "Department",
          filterDepartment,
              (val) => setState(() => filterDepartment = val),
          getOptions: () {
            return FirebaseFirestore.instance
                .collection('TaskAssign')
                .snapshots()
                .map((snap) => snap.docs
                .map((d) => (d.data())['department']?.toString() ?? '')
                .toSet()
                .toList());
          },
        );
      case 'Project':
        return _buildFilterDropdown(
          "Project",
          filterProject,
              (val) => setState(() => filterProject = val),
          getOptions: () {
            return FirebaseFirestore.instance
                .collection('TaskAssign')
                .snapshots()
                .map((snap) => snap.docs
                .map((d) => (d.data())['projectName']?.toString() ?? '')
                .toSet()
                .toList());
          },
        );
      case 'Project Status':
        return _buildFilterDropdown(
          "Project Status",
          filterStatus,
              (val) => setState(() => filterStatus = val),
          getOptions: () {
            return FirebaseFirestore.instance
                .collection('TaskAssign')
                .snapshots()
                .map((snap) => snap.docs
                .map((d) => (d.data())['taskstatus']?.toString() ?? '')
                .toSet()
                .toList());
          },
        );
      case 'Employee Name':
        return _buildFilterDropdown(
          "Employee Name",
          filterEmployeeName,
              (val) => setState(() => filterEmployeeName = val),
          getOptions: () {
            return FirebaseFirestore.instance
                .collection('TaskAssign')
                .snapshots()
                .map((snap) {
              final names = <String>{};
              for (var doc in snap.docs) {
                final data = doc.data();
                final field = data['employeeNames'];
                if (field is List) {
                  names.addAll(field.map((e) => e.toString()));
                } else if (field is String) {
                  names.add(field);
                }
              }
              return names.toList();
            });
          },
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildFilterDropdown(
      String label,
      String? currentValue,
      ValueChanged<String?> onChanged, {
        required Stream<List<String>> Function() getOptions,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.filter_alt_outlined,
                color: Color(0xFF0F52BA), size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                  fontFamily: "Times New Roman",
                  color: Color(0xFF002147),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.8,
                )),
          ],
        ),
        const SizedBox(height: 6),
        Container(
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
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: StreamBuilder<List<String>>(
            stream: getOptions(),
            builder: (context, snap) {
              final options = snap.hasData
                  ? (List<String>.from(snap.data!)
                ..removeWhere((e) => e.trim().isEmpty)
                ..sort())
                  : <String>[];
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  hintText: "Select value",
                  hintStyle: TextStyle(
                    fontFamily: "Times New Roman",
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                ),
                dropdownColor: const Color(0xFF223D64),
                iconEnabledColor: Colors.white,
                style: const TextStyle(
                  fontFamily: "Times New Roman",
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                isDense: true,
                value: currentValue,
                items: [null, ...options].map<DropdownMenuItem<String>>((val) {
                  return DropdownMenuItem<String>(
                    value: val,
                    child: Text(
                      val ?? 'Any',
                      style: const TextStyle(
                        fontFamily: "Times New Roman",
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _buildDateButton("Start Date", startDate,
                    (d) => setState(() => startDate = d)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDateButton("End Date", endDate,
                    (d) => setState(() => endDate = d)),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(
      String label, DateTime? date, ValueChanged<DateTime> onDateSelected) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onDateSelected(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF000F89),
              Color(0xFF0F52BA),
              Color(0xFF002147),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              offset: const Offset(0, 3),
              blurRadius: 6,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          date != null ? DateFormat('dd-MMMM-yy').format(date) : label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(QueryDocumentSnapshot doc) {
    final task = doc.data() as Map<String, dynamic>;
    final taskId = doc.id;  // ✅ use doc.id always
    final key = _taskKeys.putIfAbsent(taskId, () => GlobalKey());

    final isHighlighted = widget.highlightedTaskId == taskId;

    TextStyle labelStyle = const TextStyle(
      fontFamily: 'Roboto',
      color: Colors.white70,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    );

    TextStyle valueStyle = const TextStyle(
      fontFamily: 'Roboto',
      color: Colors.white,
      fontWeight: FontWeight.w500,
      fontSize: 15,
    );

    Widget buildDetailRow(IconData icon, String label, String? value) {
      if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  text: '$label: ',
                  style: labelStyle,
                  children: [
                    TextSpan(text: value, style: valueStyle),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Dismissible(
      key: ValueKey(taskId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(taskId),
      onDismissed: (_) async {
        await FirebaseFirestore.instance
            .collection('TaskAssign')
            .doc(doc.id)
            .delete();
        Fluttertoast.showToast(
          msg: "Task deleted successfully!",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        key: key,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: isHighlighted
                      ? [Colors.green.shade800, Colors.green.shade600]
                      : const [
                    Color(0xFF000F89),       // 🔹 Dark blue
                    Color(0xFF0F52BA),       // 🔹 Medium blue
                    Color(0xFF002147),       // 🔹 Navy blue
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildDetailRow(Icons.admin_panel_settings, 'Admin Name', task['adminName']),
                  buildDetailRow(
                    Icons.badge,
                    'Employee Id',
                    task['empIds'] == null
                        ? 'N/A'
                        : (task['empIds'] is List
                        ? (task['empIds'] as List).join(', ')
                        : task['empIds'].toString()),
                  ),
                  SizedBox(height: 5,),

                  buildDetailRow(Icons.person, 'Employee Name', (task['employeeNames'] as List).join(', ')),
                  SizedBox(height: 5,),
                  buildDetailRow(Icons.work, 'Project Name', task['projectName']),
                  SizedBox(height: 5,),
                  buildDetailRow(Icons.business, 'Department', task['department']),
                  SizedBox(height: 5,),

                  if (['Installation', 'Sales', 'Reception', 'Social Media'].contains(task['department']) &&
                      task['siteLocation'] != null) ...[
                    const SizedBox(height: 10),
                    buildDetailRow(Icons.location_on, 'Site Location', task['siteLocation']),
                  ],

                  if (task['files'] != null && task['files'] is List && task['files'].isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Text(
                      "Attached Files:",
                      style: TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: task['files'].length,
                        itemBuilder: (context, fileIndex) {
                          var file = task['files'][fileIndex];
                          final String url = file['downloadUrl'] ?? '';
                          final String fileType = (file['fileType'] ?? '').toLowerCase();
                          final String fileName = file['fileName'] ?? 'Unnamed';
                          final bool isLocal = file['isLocal'] == true;

                          bool isImage = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(fileType);

                          Widget filePreview;
                          if (isImage) {
                            if (isLocal) {
                              // Show local file image
                              filePreview = Image.file(
                                File(url),
                                width: 100,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, color: Colors.white),
                              );
                            } else {
                              // Show network image
                              filePreview = Image.network(
                                url,
                                width: 100,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, color: Colors.white),
                              );
                            }
                          } else {
                            filePreview = Icon(
                              fileType == 'pdf' ? Icons.picture_as_pdf : Icons.insert_drive_file,
                              color: Colors.white,
                              size: 50,
                            );
                          }

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FileViewerScreen(
                                    url: url,
                                    fileType: fileType, // pass if needed
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                border: Border.all(color: Colors.tealAccent),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: filePreview,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    fileName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Roboto'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  ],

                  const SizedBox(height: 10),

                  buildDetailRow(Icons.description, 'Task Description', task['taskDescription']),
                  SizedBox(height: 5,),
                  buildDetailRow(Icons.calendar_today, 'Assigned Date', task['date']),
                  SizedBox(height: 5,),
                  buildDetailRow(Icons.event_busy, 'Deadline Date', task['deadlineDate']),
                  SizedBox(height: 5,),
                  buildDetailRow(Icons.access_time, 'Assigned Time', task['time']),
                  SizedBox(height: 5,),
                  buildDetailRow(Icons.access_time, 'Deadline Time', task['deadlinetime']),
                  SizedBox(height: 5,),
                  buildDetailRow(Icons.task, 'Task Status', task['taskstatus']),
                  SizedBox(height: 5,),
                  buildDetailRow(Icons.note_alt, 'Employees Description', task['employeeDescription']),
                ],
              ),
            ),

            // Edit button on top right
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white70),
                tooltip: 'Edit Task',
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditTaskPage(taskDoc: doc),
                    ),
                  );

                  if (result == true) {
                    // Refresh UI or reload tasks
                    setState(() {});
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<bool?> _confirmDelete(String? taskId) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 12,
          backgroundColor: const Color(0xFF1E2A38),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 50),
              const SizedBox(height: 16),
              const Text('Confirm Delete', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600, fontFamily: "Times New Roman")),
              const SizedBox(height: 12),
              const Text('Are you sure you want to delete this task?', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16, fontFamily: "Times New Roman")),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: "Times New Roman")),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Yes', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: "Times New Roman")),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        );
      },
    );
  }
}