import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:techlead/main.dart';
import 'package:techlead/Employee/Categoryscreen/FileViwerscreen.dart';

class Digitlmarketingshowdata extends StatefulWidget {
  final String? projectName;
  final int? unreadCount;
  final String? highlightedTaskId;

  const Digitlmarketingshowdata({
    this.projectName,
    this.unreadCount,
    this.highlightedTaskId,
  });

  @override
  State<Digitlmarketingshowdata> createState() =>
      _DigitlmarketingshowdataState();
}

class _DigitlmarketingshowdataState extends State<Digitlmarketingshowdata> {
  String searchQuery = "";
  DateTime? startDate;
  DateTime? endDate;

  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool scrolledToProject = false;
  bool scrolledToUnread = false;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  void _showEditDialog(Map<String, dynamic> task, String docId) {
    String currentStatus = task['taskstatus'] ?? 'Pending';
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    final TextEditingController descriptionController = TextEditingController(
      text: task['employeeDescription'] ?? '',
    );
    bool _isUpdating = false; // 🔹 Loading state

    showDialog(
      context: context,
      barrierDismissible: false, // 🔹 Prevent closing during update
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.blue.shade900,
              title: const Text(
                "Update Task",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Project Name",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      TextField(
                        controller: TextEditingController(text: task['projectName'] ?? ''),
                        enabled: false,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.blue.shade800,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text("Task Status",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      DropdownButtonFormField<String>(
                        value: currentStatus,
                        items: ['Pending', 'In Progress', 'Completed']
                            .map((status) => DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        ))
                            .toList(),
                        onChanged: _isUpdating
                            ? null // 🔹 Disable during update
                            : (newValue) {
                          setDialogState(() {
                            currentStatus = newValue ?? currentStatus;
                          });
                        },
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text("Employee Description",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 4,
                        enabled: !_isUpdating, // 🔹 Disable during update
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.blue.shade800,
                          hintText: "Enter your Employee description",
                          hintStyle: const TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Description cannot be empty'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isUpdating ? null : () => Navigator.pop(dialogContext),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: _isUpdating ? Colors.grey : Colors.white),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isUpdating ? Colors.grey : Colors.tealAccent.shade700,
                    disabledBackgroundColor: Colors.grey.shade600,
                  ),
                  onPressed: _isUpdating
                      ? null
                      : () async {
                    if (_formKey.currentState!.validate()) {
                      setDialogState(() {
                        _isUpdating = true; // 🔹 Start loading
                      });

                      try {
                        final String projectName = task['projectName'] ?? '';
                        final String department = task['department'] ?? '';
                        final empIdsRaw = task['empIds'];
                        List<String> targetEmpIds = [];

                        if (empIdsRaw is List) {
                          targetEmpIds = List<String>.from(empIdsRaw);
                        } else if (empIdsRaw is String && empIdsRaw.isNotEmpty) {
                          targetEmpIds = [empIdsRaw];
                        }

                        // 🔹 Update Firestore
                        await FirebaseFirestore.instance
                            .collection('TaskAssign')
                            .doc(docId)
                            .update({
                          'taskstatus': currentStatus,
                          'employeeDescription': descriptionController.text.trim(),
                        });

                        // 🔹 Fetch Admin FCM Token (based on adminEmail)
                        List<String> tokens = [];
                        final String? adminEmail = task['adminEmail'];

                        if (adminEmail != null && adminEmail.isNotEmpty) {
                          final adminDoc = await FirebaseFirestore.instance
                              .collection('Admin_Profiles')
                              .doc(adminEmail)
                              .get();

                          if (adminDoc.exists) {
                            final token = adminDoc['fcmToken'] ?? '';
                            if (token.isNotEmpty) tokens.add(token);
                          } else {
                            print("❌ No admin profile found for $adminEmail");
                          }
                        }

                        final taskData = {
                          'taskId': docId,
                          'projectName': projectName,
                          'adminEmail': adminEmail,
                          'employeeDescription': descriptionController.text.trim(),
                          'deadlineDate': task['deadlineDate'] ?? '',
                          'screen': 'Admintaskassigneddata',
                        };

                        print('📢 Admin notification sent to: $tokens');

                        await sendNotification(
                            tokens, taskData, targetEmpIds.join(','), department);

                        setDialogState(() {
                          _isUpdating = false; // 🔹 Stop loading
                        });

                        if (!context.mounted) return;

                        Navigator.pop(dialogContext); // Close dialog
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Digitlmarketingshowdata()),
                        );

                        rootScaffoldMessengerKey.currentState?.showSnackBar(
                          const SnackBar(
                            content: Text("Task updated successfully!",
                                style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        setDialogState(() {
                          _isUpdating = false; // 🔹 Stop loading on error
                        });

                        if (!context.mounted) return;

                        Navigator.pop(dialogContext); // Close dialog
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Digitlmarketingshowdata()),
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Error updating task: $e",
                                style: const TextStyle(color: Colors.white)),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: _isUpdating
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text("Update", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> sendNotification(
      List<String> fcmTokens,
      Map<String, dynamic> taskData,
      String assignedEmpIds,
      String department,
      ) async {
    final jsonStr = await rootBundle.loadString('assets/service-account.json');
    final serviceAccount = ServiceAccountCredentials.fromJson(jsonStr);
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final authClient = await clientViaServiceAccount(serviceAccount, scopes);
    final accessToken = authClient.credentials.accessToken.data;

    const String projectId = 'techlead-57814';
    final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

    for (final token in fcmTokens) {
      final messagePayload = {
        "message": {
          "token": token,
          "notification": {
            "title": "${taskData['projectName'] ?? 'Unnamed Project'}",
            "body":
            "Employee Task Update: ${taskData['employeeDescription'] ?? 'Check your task'}",
          },
          "android": {"priority": "high"},
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "screen": "Admintaskassigneddata",
            "sound": "custom_sound",
            "empIds": assignedEmpIds,
            "department": department,
            "taskId": taskData['taskId'],
            "projectName": taskData['projectName'],
            "taskDescription": taskData['taskDescription'] ?? '',
            "deadlineDate": taskData['deadlineDate'] ?? '',
          }
        }
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(messagePayload),
      );

      if (response.statusCode == 200) {
        print('✅ Notification sent to $token');
      } else {
        print(
            '❌ Error sending to $token: ${response.statusCode} ${response.body}');
      }
    }
    authClient.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.white, Colors.grey],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        child: Column(
          children: [
            AppBar(
              title: const Text(
                "Assigned Tasks From Admin",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Times New Roman",
                  fontSize: 14,
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.blue.shade900,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            _buildSearchBar(),
            _buildDateFilters(),
            if ((widget.unreadCount ?? 0) > 0)
              Container(
                width: double.infinity,
                color: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Text(
                    '🔔You have ${widget.unreadCount} unread task(s) as a green color card',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Times New Roman"),
                  ),
                ),
              ),
            Expanded(
              child: currentUserId == null
                  ? const Center(child: Text("User not logged in"))
                  : FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('EmpProfile')
                    .doc(currentUserId)
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(
                        child: Text("User profile not found.",
                            style: TextStyle(color: Colors.red)));
                  }

                  final empId = snapshot.data!.get('fullName');

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('TaskAssign')
                        .where('department',
                        isEqualTo: 'Digital Marketing')
                        .where('employeeNames', arrayContains: empId)
                        .snapshots(),
                    builder: (context, taskSnapshot) {
                      if (!taskSnapshot.hasData ||
                          taskSnapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text("No tasks assigned!",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: "Times New Roman")));
                      }

                      final assignedTasks =
                      taskSnapshot.data!.docs.where((doc) {
                        final task = doc.data() as Map<String, dynamic>;
                        final isUnread = task['isUnread'] == true;
                        final name = task['projectName']
                            ?.toString()
                            .toLowerCase() ??
                            '';

                        if (searchQuery.isNotEmpty &&
                            !name.contains(searchQuery.toLowerCase()))
                          return false;

                        if (startDate != null && endDate != null) {
                          try {
                            DateTime assignedDate =
                            task['date'] is Timestamp
                                ? (task['date'] as Timestamp).toDate()
                                : DateFormat('dd MMMM yy')
                                .parse(task['date']);

                            DateTime start = DateTime(startDate!.year,
                                startDate!.month, startDate!.day);
                            DateTime end = DateTime(endDate!.year,
                                endDate!.month, endDate!.day, 23, 59, 59);

                            if (assignedDate.isBefore(start) ||
                                assignedDate.isAfter(end)) {
                              return false;
                            }
                          } catch (_) {
                            return false;
                          }
                        }

                        return true;
                      }).toList();

                      if (assignedTasks.isEmpty) {
                        return const Center(
                            child: Text(
                                "No tasks available between these dates.",
                                style: TextStyle(fontSize: 16)));
                      }

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!scrolledToProject &&
                            widget.projectName != null) {
                        } else if (!scrolledToUnread &&
                            widget.highlightedTaskId != null) {
                          final unreadIndex =
                          assignedTasks.indexWhere((doc) {
                            final task =
                            doc.data() as Map<String, dynamic>;
                            return task['taskId'] ==
                                widget.highlightedTaskId;
                          });
                          if (unreadIndex != -1) {
                            _scrollController.animateTo(
                              unreadIndex * 280.0,
                              duration: const Duration(seconds: 1),
                              curve: Curves.easeInOut,
                            );
                            scrolledToUnread = true;
                          }
                        } else if (!scrolledToUnread &&
                            (widget.unreadCount ?? 0) > 0) {
                          final unreadIndex =
                          assignedTasks.indexWhere((doc) {
                            final task =
                            doc.data() as Map<String, dynamic>;
                            return task['isUnread'] == true;
                          });
                          if (unreadIndex != -1) {
                            _scrollController.animateTo(
                              unreadIndex * 280.0,
                              duration: const Duration(seconds: 1),
                              curve: Curves.easeInOut,
                            );
                            scrolledToUnread = true;
                          }
                        }
                      });
                      return ListView.builder(
                        controller: _scrollController,
                        itemCount: assignedTasks.length,
                        itemBuilder: (context, index) {
                          final doc = assignedTasks[index];
                          final task = doc.data() as Map<String, dynamic>;

                          final isProjectHighlighted =
                              widget.projectName != null &&
                                  task['projectName']
                                      ?.toString()
                                      .toLowerCase()
                                      .trim() ==
                                      widget.projectName!
                                          .toLowerCase()
                                          .trim();

                          final isTaskIdHighlighted =
                              widget.highlightedTaskId != null &&
                                  task['taskId']?.toString() ==
                                      widget.highlightedTaskId;

                          final highlight =
                              isProjectHighlighted || isTaskIdHighlighted;

                          return _buildTaskCard(task, highlight, doc.id);
                        },
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: "Search by Project Name",
          labelStyle: const TextStyle(color: Colors.white),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          filled: true,
          fillColor: Colors.blue.shade900,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        style: const TextStyle(color: Colors.white),
        onChanged: (value) {
          setState(() => searchQuery = value);
        },
      ),
    );
  }

  Widget _buildDateFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildDateButton("Start Date", startDate,
                  (date) => setState(() => startDate = date)),
          _buildDateButton(
              "End Date", endDate, (date) => setState(() => endDate = date)),
        ],
      ),
    );
  }

  Widget _buildDateButton(
      String label, DateTime? date, Function(DateTime) onDateSelected) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
      onPressed: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onDateSelected(picked);
      },
      child: Text(
        date != null ? DateFormat('dd-MMMM-yy').format(date) : label,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildTaskCard(
      Map<String, dynamic> task, bool highlight, String docId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: highlight
                  ? [Colors.green.shade800, Colors.green.shade600]
                  : [Colors.blue.shade900, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTaskDetail("Admin Name", task['adminName']),
              _buildTaskDetail("Employee Id", task['empIds']),
              _buildTaskDetail(
                  "Employee Name", (task['employeeNames'] as List).join(', ')),
              _buildTaskDetail("Project Name", task['projectName']),
              _buildTaskDetail("Department", task['department']),
              _buildTaskDetail("Task Description", task['taskDescription']),
              _buildTaskDetail("Assigned Date", task['date']),
              _buildTaskDetail("Deadline Date", task['deadlineDate']),
              _buildTaskDetail("Assigned Time", task['time']),
              _buildTaskDetail('Deadline Time', task['deadlinetime']),
              _buildTaskDetail(
                  'Employee Task Description', task['employeeDescription']),
              if (task['files'] != null &&
                  task['files'] is List &&
                  task['files'].isNotEmpty)
                _buildFilesSection(task['files']),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () => _showEditDialog(task, docId),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskDetail(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          text: "$label: ",
          style: const TextStyle(
              color: Colors.tealAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: "Times New Roman"),
          children: [
            TextSpan(
              text: value?.toString() ?? 'N/A',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesSection(List<dynamic> files) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Attached Files:",
            style: TextStyle(
                color: Colors.tealAccent, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final url = file['downloadUrl'] ?? '';
              final fileType = (file['fileType'] ?? '').toLowerCase();
              final fileName = file['fileName'] ?? 'Unnamed';
              final isImage = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp']
                  .contains(fileType);

              return GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            FileViewerScreen(url: url, fileType: fileType))),
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
                        child: isImage
                            ? Image.network(url,
                            width: 100,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image,
                                color: Colors.white))
                            : Icon(
                          fileType == 'pdf'
                              ? Icons.picture_as_pdf
                              : Icons.insert_drive_file,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}