import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';
import '../../Default/customwidget.dart';
import '../../main.dart';

class TaskAssignPageDE extends StatefulWidget {
  const TaskAssignPageDE({super.key});
  @override
  State<TaskAssignPageDE> createState() => _TaskAssignPageDEState();
}

class _TaskAssignPageDEState extends State<TaskAssignPageDE> {
  Map<String, bool> checkboxValues = {};
  String? matchedDocId;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController adminNameController = TextEditingController();
  FocusNode checkbox1Focus = FocusNode();
  TextEditingController adminIdController = TextEditingController();
  TextEditingController employeeNameController = TextEditingController();
  TextEditingController employeeIdController = TextEditingController();
  TextEditingController projectNameController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController deadlinetimeController = TextEditingController();
  TextEditingController siteLocationController = TextEditingController();
  TextEditingController taskDescriptionController = TextEditingController();
  final TextEditingController deadlineDateController = TextEditingController();
  TextEditingController empIdController = TextEditingController();

  List<String> employeeNames = [];
  Map<String, String> employeeNameIdMap = {};
  List<String> selectedEmployeeNames = [];
  List<Map<String, dynamic>> filteredDepartmentList = [];
  Map<String, List<String>> employeeCategoryMap = {};


  final List<Map<String, dynamic>> departmentList = [
    {'name': 'Finance', 'icon': Icons.account_balance},
    {'name': 'Development', 'icon': Icons.code},
    {'name': 'Digital Marketing', 'icon': Icons.campaign},
    {'name': 'Reception', 'icon': Icons.phone},
    {'name': 'Account', 'icon': Icons.book},
    {'name': 'Human Resource', 'icon': Icons.group},
    {'name': 'Management', 'icon': Icons.business},
    {'name': 'Sales', 'icon': Icons.shopping_cart},
    {'name': 'Installation', 'icon': Icons.build},
    {'name': 'Social Media', 'icon': Icons.share},
  ];

  String? selectedDepartment;

  List<File> selectedFiles = [];
  List<String> fileNames = [];
  List<String> fileTypes = [];
  List<TextEditingController> fileNameControllers = [];
  bool isLoading = false;

  Future<void> _selectDeadlineDate(BuildContext context) async {
    DateTime today = DateTime.now();

    DateTime startDate = today;
    if (dateController.text.isNotEmpty) {
      try {
        startDate = DateFormat('dd MMMM yyyy').parse(dateController.text);
      } catch (e) {
        startDate = today; // fallback
      }
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: startDate,
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        String formattedDate = DateFormat('dd MMMM yyyy').format(pickedDate);
        deadlineDateController.text = formattedDate;
      });
    }
  }
  void pickFiles() async {
    FilePickerResult? result =
    await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null) {
      for (var file in result.files) {
        selectedFiles.add(File(file.path!));
        fileNames.add(file.name);
        fileTypes.add(file.extension ?? '');
        fileNameControllers.add(TextEditingController(text: file.name));
      }
      setState(() {});
    }
  }

  void openFile(File file) async {
    await OpenFile.open(file.path);
  }

  void renameFile(int index) {
    setState(() {
      fileNames[index] = fileNameControllers[index].text.isNotEmpty
          ? fileNameControllers[index].text
          : fileNames[index];
      fileNameControllers[index].clear();
    });
  }

  Future<void> updateCheckboxValue(String field, bool? value) async {
    if (matchedDocId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('EmpProfile')
          .doc(matchedDocId)
          .update({field: value ?? false});
      print("Updated $field to $value");
    } catch (e) {
      print("Error updating $field: $e");
    }
  }

  Future<void> _fetchEmployeeNames() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('EmpProfile').get();

      print("📌 EmpProfile docs: ${snapshot.docs.length}");
      for (var doc in snapshot.docs) {
        print("➡️ ${doc.data()}");
      }

      setState(() {
        employeeNameIdMap = {};
        employeeCategoryMap = {};

        for (var doc in snapshot.docs) {
          final fullName = doc['fullName'];
          final empId = doc['empId'];
          final categories = doc['categories'];

          if (fullName != null && empId != null && fullName.toString().isNotEmpty) {
            employeeNameIdMap[fullName] = empId;

            if (categories is List) {
              employeeCategoryMap[fullName] = categories
                  .map((e) => e.toString().trim())
                  .where((e) => e.isNotEmpty)
                  .toSet()
                  .toList();
            } else {
              employeeCategoryMap[fullName] = [];
            }
          }
        }
        employeeNames = employeeNameIdMap.keys.where((name) => name.isNotEmpty).toList();
        print("✅ Employee Names Loaded: $employeeNames");
      });
    } catch (e) {
      print("❌ Error fetching employee names and IDs: $e");
    }
  }



  Future<void> uploadFiles() async {
    setState(() {
      isLoading = true;
    });

    try {
      for (int index = 0; index < selectedFiles.length; index++) {
        String fileName = fileNames[index];
        File file = selectedFiles[index];
        String fileType = fileTypes[index];

        Uint8List fileBytes = await file.readAsBytes();

        Reference storageRef = _storage.ref().child("TaskAssign/$fileName");

        UploadTask uploadTask = storageRef.putData(
            fileBytes,
            SettableMetadata(
              contentType: _getContentType(fileType),
            ));
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        await _firestore.collection('TaskAssign').add({
          'fileName': fileName,
          'fileType': fileType,
          'downloadUrl': downloadUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Files uploaded successfully!')),
      );
    } catch (e) {
      print("Error uploading files: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading files: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'mp4':
      case 'mov':
      case 'avi':
        return 'video/mp4';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  Future<DateTime?> _selectDate(BuildContext context) async {
    DateTime currentDate = DateTime.now();
    DateTime today =
    DateTime(currentDate.year, currentDate.month, currentDate.day);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        String formattedDate = DateFormat('dd MMMM yyyy').format(pickedDate);
        dateController.text = formattedDate;
      });
    }

    return pickedDate;
  }


// 🔹 Assigned Time Picker
  Future<TimeOfDay?> _selectAssignedTime(BuildContext context) async {
    // 🔹 Check if date is selected
    if (dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select Assigned Date first."),
          backgroundColor: Colors.orange,
        ),
      );
      return null;
    }

    // 🔹 Parse selected date
    DateTime selectedDate;
    try {
      selectedDate = DateFormat('dd MMMM yyyy').parse(dateController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid date format."),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    // 🔹 Current time (rounded to minute)
    DateTime now = DateTime.now();
    DateTime nowRounded = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );

    DateTime todayDate = DateTime(now.year, now.month, now.day);
    DateTime assignedDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    // 🔹 Initial time
    TimeOfDay initialTime = TimeOfDay(
      hour: now.hour,
      minute: now.minute,
    );

    // 🔹 Show time picker
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      // 🔹 Create DateTime from picked time
      DateTime pickedDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // 🔹 Validation: Today → no past time
      if (assignedDate.isAtSameMomentAs(todayDate)) {
        if (pickedDateTime.isBefore(nowRounded)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You cannot select a past time for today."),
              backgroundColor: Colors.red,
            ),
          );
          return null;
        }
      }
    }

    return pickedTime;
  }


// 🔹 Deadline Time Picker (depends on Assigned Time)
  Future<TimeOfDay?> _selectDeadlineTime(BuildContext context) async {
    if (timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select Assigned Time first."),
          backgroundColor: Colors.orange,
        ),
      );
      return null;
    }

    if (deadlineDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select Deadline Date first."),
          backgroundColor: Colors.orange,
        ),
      );
      return null;
    }

    DateTime assignedDate;
    DateTime assignedDateTime;

    try {
      assignedDate = DateFormat('dd MMMM yyyy').parse(dateController.text);
      final parsedTime = DateFormat('HH:mm').parse(timeController.text);

      assignedDateTime = DateTime(
        assignedDate.year,
        assignedDate.month,
        assignedDate.day,
        parsedTime.hour,
        parsedTime.minute,
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid assigned date/time."),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    DateTime deadlineDate;
    try {
      deadlineDate =
          DateFormat('dd MMMM yyyy').parse(deadlineDateController.text);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid deadline date."),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    DateTime now = DateTime.now();
    DateTime nowRounded =
    DateTime(now.year, now.month, now.day, now.hour, now.minute);

    DateTime todayDate = DateTime(now.year, now.month, now.day);

    /// 🔹 INITIAL TIME LOGIC (IMPORTANT FIX)
    TimeOfDay initialTime;

    if (deadlineDate.isAtSameMomentAs(assignedDate)) {
      // Same date → start from Assigned Time
      initialTime = TimeOfDay.fromDateTime(assignedDateTime);
    } else {
      // Future date → start from 00:00
      initialTime = const TimeOfDay(hour: 0, minute: 0);
    }

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      DateTime deadlineDateTime = DateTime(
        deadlineDate.year,
        deadlineDate.month,
        deadlineDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      if (!deadlineDateTime.isAfter(assignedDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Deadline time must be after Assigned Time."),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      }

      if (deadlineDate.isAtSameMomentAs(todayDate) &&
          deadlineDateTime.isBefore(nowRounded)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You cannot select a past deadline time."),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      }
    }

    return pickedTime;
  }

  Future<void> _submitData() async {
    if (!mounted) return;

    List<String> errors = [];
    final adminName = adminNameController.text.trim();
    final adminId = adminIdController.text.trim();

    if (adminName.isEmpty || adminId.isEmpty) {
      errors.add('Admin credentials not set. Please login again.');
    }
    if (selectedEmployeeNames.isEmpty) {
      errors.add('Please select at least one employee');
    }
    if (empIdController.text.trim().isEmpty) {
      errors.add('Employee ID field is empty');
    }
    if (selectedDepartment == null || selectedDepartment!.trim().isEmpty) {
      errors.add('Department not selected');
    }
    if (dateController.text.trim().isEmpty) {
      errors.add('Assigned Date is not selected');
    }
    if (timeController.text.trim().isEmpty) {
      errors.add('Assigned Time is not selected');
    }
    if (deadlinetimeController.text.trim().isEmpty) {
      errors.add('Deadline Time is not selected');
    }

    if (projectNameController.text.trim().isEmpty) {
      errors.add('Project Name is missing');
    }
    if ((selectedDepartment == 'Installation' ||
        selectedDepartment == 'Sales' ||
        selectedDepartment == 'Services' ||
        selectedDepartment == 'Social Media Marketing') &&
        siteLocationController.text.trim().isEmpty) {
      errors.add('Site Location is required for this department');
    }
    if (taskDescriptionController.text.trim().isEmpty) {
      errors.add('Task Description is missing');
    }
    if (deadlineDateController.text.trim().isEmpty) {
      errors.add('Deadline Date is missing');
    }
    // if (selectedFiles.isEmpty) {
    //   errors.add('At least one file must be selected');
    // }

    if (errors.isNotEmpty) {
      _safeShowSnackBar(errors.join('\n'), Colors.red);
      return;
    }

    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final employeeSnapshot =
      await FirebaseFirestore.instance.collection('EmpProfile').get();
      Map<String, String> employeeTokens = {};
      Map<String, List<String>> departmentTokens = {};

      for (var doc in employeeSnapshot.docs) {
        String empId = doc['empId'];
        String fcmToken = doc['fcmToken'];
        List<String> categories = List<String>.from(doc['categories'] ?? []);

        if (empId.isNotEmpty && fcmToken.isNotEmpty) {
          employeeTokens[empId] = fcmToken;
        }

        for (String category in categories) {
          departmentTokens.putIfAbsent(category, () => []).add(fcmToken);
        }
      }

      List<String> enteredEmpIds = empIdController.text
          .trim()
          .split(',')
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toList();

      List<String> matchedTokens = [];
      List<String> assignedEmpIds = [];

      for (String empId in enteredEmpIds) {
        if (employeeTokens.containsKey(empId)) {
          matchedTokens.add(employeeTokens[empId]!);
          assignedEmpIds.add(empId);
        }
      }

      if (selectedDepartment != null) {
        for (String department in departmentTokens.keys) {
          if (department.contains(selectedDepartment!)) {
            matchedTokens.addAll(departmentTokens[department]!);
          }
        }
      }

      matchedTokens = matchedTokens.toSet().toList();

      if (matchedTokens.isEmpty) {
        _safeShowSnackBar(
          'Employee ID/Department not found! Task not assigned!',
          Colors.red,
        );
        setState(() => isLoading = false);
        return;
      }

      // ✅ Duplicate task check (today only)
      final enteredDate = dateController.text.trim();
      final projectName = projectNameController.text.trim();

      final existingTasks = await FirebaseFirestore.instance
          .collection('TaskAssign')
          .where('projectName', isEqualTo: projectName)
          .where('date', isEqualTo: enteredDate)
          .get();

      bool alreadyAssigned = false;

      for (var doc in existingTasks.docs) {
        List<dynamic> assignedEmployees = doc['employeeNames'] ?? [];
        for (var emp in selectedEmployeeNames) {
          if (assignedEmployees.contains(emp)) {
            alreadyAssigned = true;
            break;
          }
        }
        if (alreadyAssigned) break;
      }

      if (alreadyAssigned) {
        _safeShowSnackBar(
          'This task has already been assigned to this employee today by Admin!',
          Colors.orange,
        );
        setState(() => isLoading = false);
        return;
      }

      // ✅ Fast file uploads (parallel)
      List<Map<String, String>> uploadedFiles = await _uploadFiles();

      // ✅ Fetch admin email from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final adminEmail = prefs.getString('email') ?? '';

      final taskData = {
        'adminName': adminName,
        'adminId': adminId,
        'adminEmail': adminEmail,
        'taskstatus': "Pending",
        'employeeNames': selectedEmployeeNames,
        'empIds': assignedEmpIds.join(','),
        "read": false,
        'department': selectedDepartment,
        'date': dateController.text.trim(),
        'time': timeController.text.trim(),
        'deadlinetime': deadlinetimeController.text.trim(),
        'projectName': projectName,
        'siteLocation': siteLocationController.text.trim(),
        'taskDescription': taskDescriptionController.text.trim(),
        'deadlineDate': deadlineDateController.text.trim(),
        'taskId': DateTime.now().millisecondsSinceEpoch.toString(),
        'files': uploadedFiles,
      };

      await FirebaseFirestore.instance.collection('TaskAssign').add(taskData);
      for (String empId in assignedEmpIds) {
        final snapshot = await FirebaseFirestore.instance
            .collection('EmpProfile')
            .where('empId', isEqualTo: empId)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final docId = snapshot.docs.first.id;
          await FirebaseFirestore.instance
              .collection('EmpProfile')
              .doc(docId)
              .update({'assignedTask': FieldValue.delete()});
        }
      }

      for (String token in matchedTokens) {
        await sendNotification(
          [token],
          taskData,
          taskData['empIds']?.toString() ?? '',
          taskData['department']?.toString() ?? '',
        );
      }

      _safeShowSnackBar(
        'Task assigned Successfully!',
        Colors.green,
      );

      _resetForm();
    } catch (e) {
      print(' Error: $e');
      _safeShowSnackBar('Error: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _safeShowSnackBar(String msg, Color color) {
    if (rootScaffoldMessengerKey.currentState != null) {
      rootScaffoldMessengerKey.currentState!.showSnackBar(
        SnackBar(
          backgroundColor: color,
          content: Text(
            msg,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else {
      debugPrint('⚠️ Tried to show snackbar when widget is not mounted.');
    }
  }

  Future<List<Map<String, String>>> _uploadFiles() async {
    List<Map<String, String>> uploadedFiles = [];

    try {

      List<Future<Map<String, String>>> uploadFutures = [];

      for (int index = 0; index < selectedFiles.length; index++) {
        String fileName = fileNames[index];
        File file = selectedFiles[index];
        String fileType = fileTypes[index];

        Uint8List fileBytes = await file.readAsBytes();
        Reference storageRef = _storage.ref().child("TaskAssign/$fileName");

        // upload future banavo
        final uploadFuture = storageRef
            .putData(
          fileBytes,
          SettableMetadata(contentType: _getContentType(fileType)),
        )
            .then((snapshot) async {
          String downloadUrl = await snapshot.ref.getDownloadURL();
          return {
            'fileName': fileName,
            'fileType': fileType,
            'downloadUrl': downloadUrl,
          };
        });

        uploadFutures.add(uploadFuture);
      }

      uploadedFiles = await Future.wait(uploadFutures);
    } catch (e) {
      print("⚠️ Error uploading files: $e");
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error uploading files: $e')),
      );
    }

    return uploadedFiles;
  }


  void _resetForm() {
    projectNameController.clear();
    dateController.clear();
    timeController.clear();
    deadlinetimeController.clear();
    siteLocationController.clear();
    taskDescriptionController.clear();
    deadlineDateController.clear();
    empIdController.clear();

    setState(() {
      selectedDepartment = null;
      selectedEmployeeNames = [];
      selectedFiles.clear();
      fileNames.clear();
      fileTypes.clear();
    });
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
            " New Task: ${taskData['taskDescription'] ?? 'Check your task'}",
          },
          "android": {"priority": "high"},
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "screen": "CategoryScreen",
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

  Future<void> replaceFile(int index) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'mp4',
        'mov',
        'avi',
        'mkv',
        'gif'
      ],
    );

    if (result != null) {
      PlatformFile file = result.files.first;

      setState(() {
        selectedFiles[index] = File(file.path!);
        fileNames[index] = file.name;
        fileTypes[index] = file.extension ?? 'unknown';
      });
    } else {
      print("No file selected.");
    }
  }

  void closeFile(int index) {
    setState(() {
      selectedFiles.removeAt(index);
      fileNames.removeAt(index);
      fileTypes.removeAt(index);
      fileNameControllers.removeAt(index);
    });
  }

  Future<String?> getAdminFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final snapshot = await FirebaseFirestore.instance
        .collection('EmpProfile')
        .doc(user.uid)
        .get();

    return snapshot['fcmToken'];
  }

  Future<void> sendMulticastNotificationV1(
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
    final Uri url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

    final adminToken = await getAdminFcmToken();

    for (String token in fcmTokens) {
      if (token == adminToken) {
        print('🚫 Skipping admin token $token');
        continue;
      }

      final messagePayload = {
        "message": {
          "token": token,
          "notification": {
            "title": "${taskData['projectName'] ?? 'Unnamed Project'}",
            "body":
            " New Task: ${taskData['taskDescription'] ?? 'Check your task'}",
          },
          "android": {"priority": "high"},
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "screen": "CategoryScreen",
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
        print('❌ Failed to send notification to $token: ${response.body}');
      }
    }

    authClient.close();
  }

  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();

    final name = prefs.getString('name') ?? '';
    final id = prefs.getString('id') ?? '';

    if (mounted) {
      setState(() {
        adminNameController.text = name;
        adminIdController.text = id;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchEmployeeNames();
    // initializeFirebaseMessageListener();
    filteredDepartmentList = departmentList;
    _loadAdminData();
    getAdminFcmToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFF9CB5F1),
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.tasks,
                color: Colors.white,
              ),
              SizedBox(width: 10),
              Text(
                "Admin Task Assign",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 1.5,
                  color: Colors.white,
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          elevation: 8,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade900, Colors.indigo.shade700],
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
            child: Container(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          elevation: 8,
                          shadowColor: Colors.deepPurpleAccent,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  elevation: 8,
                                  shadowColor: Colors.deepPurpleAccent,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        SizedBox(height: 16),
                                        buildMultiSelectDropdownField(
                                          labelText: 'Select Employees',
                                          icon: Icons.person_outline,
                                          context: context,
                                          items: employeeNames,
                                          selectedItems: selectedEmployeeNames,
                                          onChanged: (List<String> selected) {
                                            setState(() {
                                              selectedEmployeeNames = selected;

                                              List<String> selectedIds = selected
                                                  .map((name) => employeeNameIdMap[name] ?? '')
                                                  .where((id) => id.isNotEmpty)
                                                  .toList();

                                              empIdController.text = selectedIds.join(', ');

                                              final selectedCategories = <String>{};
                                              for (final name in selected) {
                                                final cats = employeeCategoryMap[name] ?? [];
                                                selectedCategories.addAll(cats);
                                              }

                                              filteredDepartmentList = departmentList
                                                  .where((dep) => selectedCategories.contains(dep['name']))
                                                  .toList();

                                              if (selectedDepartment != null &&
                                                  !filteredDepartmentList.any((d) => d['name'] == selectedDepartment)) {
                                                selectedDepartment = null;
                                              }
                                            });
                                          },
                                        ),


                                        SizedBox(height: 16),
                                        buildTextField(
                                          context: context,
                                          controller: empIdController,
                                          labelText: 'Employee IDs',
                                          icon: Icons.badge_outlined,
                                          keyboardType: TextInputType.text,
                                          hintText: 'Auto-filled based on selected names',
                                          readOnly: true,
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Please select at least one employee';
                                            }
                                            return null;
                                          },
                                        ),

                                        SizedBox(height: 16),

                                        Column(
                                          children: checkboxValues.entries.map((entry) {
                                            final field = entry.key;
                                            final value = entry.value;

                                            return buildCustomCheckboxTile(
                                              title: field,
                                              value: value,
                                              onChanged: (val) {
                                                setState(() {
                                                  checkboxValues[field] = val ?? false;
                                                });
                                                updateCheckboxValue(field, val);
                                              },
                                              icon: Icons.check_circle_outline,
                                              focusNode: checkbox1Focus,
                                              color: Colors.blue,
                                            );
                                          }).toList(),
                                        ),


                                        SizedBox(height: 16),

                                        buildDropdownField(
                                          labelText: 'Department',
                                          icon: Icons.business,
                                          context: context,
                                          value: selectedDepartment,
                                          items: filteredDepartmentList.map((department) {
                                            return {
                                              'text': department['name'],
                                              'icon': department['icon']
                                            };
                                          }).toList(),
                                          onChanged: (String? value) {
                                            setState(() {
                                              selectedDepartment = value;
                                            });
                                          },
                                        ),

                                        SizedBox(height: 16),

                                        GestureDetector(
                                          onTap: () async {
                                            DateTime? selectedDate = await _selectDate(context);
                                            if (selectedDate != null) {
                                              setState(() {
                                                String formattedDate = DateFormat('dd MMMM yyyy').format(selectedDate);
                                                dateController.text = formattedDate;
                                              });
                                            }
                                          },
                                          child: AbsorbPointer(
                                            child: buildTextField(
                                              context: context,
                                              controller: dateController,
                                              labelText: 'Select Assigned Date',
                                              icon: Icons.calendar_today,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 16,),
                                        // Deadline Date Picker
                                        GestureDetector(
                                          onTap: () async {
                                            await _selectDeadlineDate(context);
                                          },
                                          child: AbsorbPointer(
                                            child: buildTextField(
                                              context: context,
                                              controller: deadlineDateController,
                                              labelText: 'Select Deadline Date',
                                              icon: Icons.calendar_today,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 16),

                                        // Assigned Time
                                        GestureDetector(
                                          onTap: () async {
                                            TimeOfDay? selectedTime = await _selectAssignedTime(context);
                                            if (selectedTime != null) {
                                              setState(() {
                                                String formattedTime = selectedTime.format(context);
                                                timeController.text = formattedTime;
                                              });
                                            }
                                          },
                                          child: AbsorbPointer(
                                            child: buildTextField(
                                              context: context,
                                              controller: timeController,
                                              labelText: 'Select Assigned Time',
                                              icon: Icons.access_time,
                                            ),
                                          ),
                                        ),

                                        SizedBox(height: 16),

                                        GestureDetector(
                                          onTap: () async {
                                            TimeOfDay? selectedTime = await _selectDeadlineTime(context);
                                            if (selectedTime != null) {
                                              setState(() {
                                                String formattedTime = selectedTime.format(context);
                                                deadlinetimeController.text = formattedTime;
                                              });
                                            }
                                          },
                                          child: AbsorbPointer(
                                            child: buildTextField(
                                              context: context,
                                              controller: deadlinetimeController,
                                              labelText: 'Select Deadline Time',
                                              icon: Icons.access_time,
                                            ),
                                          ),
                                        ),

                                        SizedBox(height: 16),

                                        buildTextField(
                                          context: context,
                                          controller: projectNameController,
                                          labelText: 'Project Name',
                                          icon: Icons.work_outline,
                                        ),

                                        SizedBox(height: 16,),

                                        if (selectedDepartment == 'Installation' ||
                                            selectedDepartment == 'Sales' ||
                                            selectedDepartment == 'Reception' ||
                                            selectedDepartment == 'Social Media')
                                          buildTextField(
                                            context: context,
                                            controller: siteLocationController,
                                            labelText: 'Site Location',
                                            icon: Icons.location_on,
                                          ),

                                        SizedBox(height: 16,),

                                        ElevatedButton(
                                          onPressed: pickFiles,
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: Size(200, 60),
                                            backgroundColor: Colors.blue.shade900,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            elevation: 5,
                                            shadowColor: Colors.grey.withOpacity(0.5),
                                            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                                          ),
                                          child: MouseRegion(
                                            onEnter: (_) {
                                              setState(() {});
                                            },
                                            onExit: (_) {
                                              setState(() {});
                                            },
                                            child: Text(
                                              "Choose Files",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 20),

                                        selectedFiles.isNotEmpty
                                            ? Container(
                                          padding: EdgeInsets.all(16),
                                          margin: EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.blue, width: 2),
                                          ),
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              children:
                                              List.generate(selectedFiles.length, (index) {
                                                return Container(
                                                  margin: EdgeInsets.all(10),
                                                  padding: EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    borderRadius: BorderRadius.circular(8),
                                                    border:
                                                    Border.all(color: Colors.blue, width: 1),
                                                  ),
                                                  width:
                                                  120,
                                                  child: Stack(
                                                    children: [
                                                      Column(
                                                        children: [
                                                          if (fileTypes[index] == 'jpg' ||
                                                              fileTypes[index] == 'png' ||
                                                              fileTypes[index] == 'jpeg')
                                                            Image.file(
                                                              selectedFiles[index],
                                                              width: 100,
                                                              height: 80,
                                                              fit: BoxFit.cover,
                                                            )
                                                          else if (fileTypes[index] == 'mp4' ||
                                                              fileTypes[index] == 'mov' ||
                                                              fileTypes[index] == 'avi' ||
                                                              fileTypes[index] == 'mkv')
                                                            Icon(
                                                              Icons.video_file,
                                                              size: 50,
                                                              color: Colors.blue,
                                                            )
                                                          else if (fileTypes[index] == 'gif')
                                                              Image.file(
                                                                selectedFiles[index],
                                                                width: 100,
                                                                height: 80,
                                                                fit: BoxFit.cover,
                                                              )
                                                            else
                                                              Icon(
                                                                Icons.insert_drive_file,
                                                                size: 50,
                                                                color: Colors.blue,
                                                              ),
                                                          SizedBox(height: 10),

                                                          Text(
                                                            fileNames[index],
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                          SizedBox(height: 5),

                                                          SizedBox(
                                                            width: 100,
                                                            child: TextField(
                                                              controller:
                                                              fileNameControllers[index],
                                                              decoration: InputDecoration(
                                                                labelText: 'Rename',
                                                                border: OutlineInputBorder(
                                                                  borderRadius:
                                                                  BorderRadius.circular(10),
                                                                ),
                                                                filled: true,
                                                                fillColor: Colors.blue.shade50,
                                                              ),
                                                              style: TextStyle(fontSize: 12),
                                                            ),
                                                          ),
                                                          SizedBox(height: 5),

                                                          // Rename button
                                                          ElevatedButton(
                                                            onPressed: () => renameFile(index),
                                                            style: ElevatedButton.styleFrom(
                                                              minimumSize: Size(100, 30),
                                                              backgroundColor:
                                                              Colors.blue.shade900,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                BorderRadius.circular(8),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              "Rename",
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () => replaceFile(index),
                                                            style: ElevatedButton.styleFrom(
                                                              minimumSize: Size(100, 30),
                                                              backgroundColor: Colors.blue.shade900,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                BorderRadius.circular(8),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              "Replace",
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                          ),
                                                          // Open file button
                                                          ElevatedButton(
                                                            onPressed: () =>
                                                                openFile(selectedFiles[index]),
                                                            style: ElevatedButton.styleFrom(
                                                              minimumSize: Size(100, 30),
                                                              backgroundColor:
                                                              Colors.blue.shade900,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                BorderRadius.circular(8),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              "Open",
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),

                                                      Positioned(
                                                        top: -8,
                                                        right: -5,
                                                        child: CircleAvatar(
                                                          radius:
                                                          16,
                                                          backgroundColor: Colors
                                                              .white,
                                                          child: IconButton(
                                                            icon: const Icon(Icons.close,
                                                                color: Colors.red, size: 19),
                                                            onPressed: () => closeFile(index),
                                                          ),
                                                        ),
                                                      ),

                                                      // Replace file button

                                                    ],
                                                  ),
                                                );
                                              }),
                                            ),
                                          ),
                                        )
                                            : Text("No files selected yet."),

                                        SizedBox(height: 16),

                                        buildTextField(
                                          context: context,
                                          controller: taskDescriptionController,
                                          labelText: 'Task Description',
                                          icon: Icons.description,
                                          maxLines: 4,
                                        ),
                                        SizedBox(height: 10,)
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Center(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF0A2A5A), // Deep navy blue
                                              Color(0xFF15489C), // Strong steel blue
                                              Color(0xFF1E64D8), // Vivid rich blue
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: ElevatedButton(
                                          onPressed: isLoading
                                              ? null
                                              : () async {
                                            FocusScope.of(context).unfocus();
                                            if (!mounted) return;
                                            await _submitData();
                                          },

                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent, // Make button background transparent to show gradient
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                          ),
                                          child: isLoading
                                              ? const CircularProgressIndicator(color: Colors.white)
                                              : const Text(
                                            'Submit',
                                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              ],
                            ),
                          ),
                        ),
                      ]
                  ),
                )
            )
        )
    );
  }
}