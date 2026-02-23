import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../Default/customwidget.dart';
import 'Date_Code/Customize_Date_001.dart';

class DailyTaskReport2 extends StatefulWidget {
  const DailyTaskReport2({super.key});

  @override
  State<DailyTaskReport2> createState() => _DailyTaskReport2State();
}

class _DailyTaskReport2State extends State<DailyTaskReport2> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _employeeNameController = TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _taskTitleController = TextEditingController();
  final TextEditingController _challengesController = TextEditingController();
  final TextEditingController _actionsTakenController = TextEditingController();
  final TextEditingController _nextStepsController = TextEditingController();
  final TextEditingController _workController1 = TextEditingController();
  final TextEditingController _workController2 = TextEditingController();
  final TextEditingController _workController3 = TextEditingController();
  final TextEditingController _workController4 = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  DateTime _selectedDate = DateTime.now();
  File? _file;
  List<File> selectedFiles = [];
  List<String> fileNames = [];
  List<String> fileTypes = [];
  List<TextEditingController> fileNameControllers = [];
  File? _image;
  bool isLoading = false;
  bool _isLoading = false;
  String? selectedServiceStatus;
  String? selectedDepartment;
  bool isLoadingDepartments = true;
  bool todayEntryExists = false;
  bool isCheckingEntry = true; // NEW: Track checking state

  List<String> serviceStatuses = ["Pending", "In Progress", "Completed"];
  List<String> serviceDepartment = [
    "Digital Marketing",
    "Sales",
    "Installation",
    "Human Resource",
    "Reception",
    "Account",
    "Finance",
    "Management",
    "Social Media"
  ];

  // NEW METHOD: Initialize app data
  Future<void> _initializeApp() async {
    await Future.wait([
      fetchUserName(),
      fetchUserDepartments(),
      checkTodayEntry(),
    ]);
  }

  // MODIFIED: Check if entry exists for today
  Future<void> checkTodayEntry() async {
    try {
      setState(() {
        isCheckingEntry = true;
      });

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          isCheckingEntry = false;
        });
        return;
      }

      String userId = user.uid;
      DateTime today = DateTime.now();
      DateTime startOfDay = DateTime(today.year, today.month, today.day);
      DateTime endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('DailyTaskReport')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThanOrEqualTo: endOfDay)
          .get();

      setState(() {
        todayEntryExists = querySnapshot.docs.isNotEmpty;
        isCheckingEntry = false;
      });

      // Show dialog after state is updated
      if (todayEntryExists) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showTodayEntryDoneDialog();
        });
      }
    } catch (e) {
      print("Error checking today's entry: $e");
      setState(() {
        isCheckingEntry = false;
      });
    }
  }

  // MODIFIED: Show dialog when today's entry is done
  void _showTodayEntryDoneDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF006400), // Dark Green
                  Color(0xFF00A86B), // Jade / Medium Green
                  Color(0xFF013220), // Deep Jungle Green
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 60,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Today's Entry Done",
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "You have already submitted your daily task report for today. Come back tomorrow!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Close the form screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      fontFamily: 'Times New Roman',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    if (todayEntryExists) {
      Fluttertoast.showToast(
        msg: "You have already submitted today's report!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 350,
              maxHeight: 420,
            ),
            child: Material(
              borderRadius: BorderRadius.circular(16),
              color: Colors.transparent,
              child: buildGradientCalendar(
                context,
                _selectedDate,
                    (pickedDate) {
                  setState(() {
                    _selectedDate = pickedDate;
                    _dateController.text =
                        DateFormat('dd MMMM yyyy').format(pickedDate);
                  });
                },
              ),
            ),
          ),
        );
      },
    );
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

  Future<void> fetchUserDepartments() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("No authenticated user.");
        return;
      }

      String userId = user.uid;
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('EmpProfile')
          .doc(userId)
          .get();

      if (userSnapshot.exists && userSnapshot.data() != null) {
        final data = userSnapshot.data() as Map<String, dynamic>;
        List<String> departments = List<String>.from(data['categories'] ?? []);

        setState(() {
          serviceDepartment = departments;
          isLoadingDepartments = false;
        });
      } else {
        print("User data not found.");
      }
    } catch (e) {
      print("Error fetching departments: $e");
    }
  }

  Future<void> fetchUserName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("No authenticated user found.");
        return;
      }

      String userId = user.uid;
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('EmpProfile')
          .doc(userId)
          .get();

      if (userSnapshot.exists && userSnapshot.data() != null) {
        setState(() {
          _employeeNameController.text =
              userSnapshot.get('fullName') ?? "Unknown";
          _employeeIdController.text = userSnapshot.get('empId') ?? "Unknown";
        });
        print(
            "Fetched Data: ${_employeeNameController.text}, ${_employeeIdController.text},}");
      } else {
        print("No user data found for userId: $userId");
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.storage.request();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _file = File(result.files.single.path!);
      });
    }
  }

  Future<void> _takePicture() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  void pickFiles() async {
    if (todayEntryExists) {
      Fluttertoast.showToast(
        msg: "You have already submitted today's report!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

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

  void closeFile(int index) {
    setState(() {
      selectedFiles.removeAt(index);
      fileNames.removeAt(index);
      fileTypes.removeAt(index);
      fileNameControllers.removeAt(index);
    });
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

        Reference storageRef =
        _storage.ref().child("DailyTaskReport/$fileName");

        UploadTask uploadTask = storageRef.putData(
            fileBytes,
            SettableMetadata(
              contentType: _getContentType(fileType),
            ));

        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        await _firestore.collection('DailyTaskReport').add({
          'fileName': fileName,
          'fileType': fileType,
          'downloadUrl': downloadUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

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
                  Color(0xFF006400),
                  Color(0xFF00A86B),
                  Color(0xFF013220),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Icon(Icons.cloud_upload_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Files uploaded successfully!",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
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

  void _showFileDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade900, Colors.blue.shade900],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Choose an Option",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera, color: Colors.white),
                title: const Text("Take a Photo",
                    style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _requestPermissions();
                  _takePicture();
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file, color: Colors.white),
                title: const Text("Upload Document",
                    style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.of(context).pop();
                  _pickFile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitReport() async {
    if (todayEntryExists) {
      Fluttertoast.showToast(
        msg: "You have already submitted today's report!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      Fluttertoast.showToast(
        msg: "Please fill out all required fields before submitting.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    if (_workController1.text.trim().isEmpty ||
        _workController2.text.trim().isEmpty ||
        _workController3.text.trim().isEmpty ||
        _workController4.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: "Please fill in all work log time slots.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      List<Map<String, dynamic>> uploadedFiles = [];

      for (int index = 0; index < selectedFiles.length; index++) {
        String fileName = fileNames[index];
        File file = selectedFiles[index];
        String fileType = fileTypes[index];

        Uint8List fileBytes = await file.readAsBytes();
        Reference storageRef = _storage.ref().child("DailyTaskReport/$fileName");

        UploadTask uploadTask = storageRef.putData(fileBytes, SettableMetadata(
          contentType: _getContentType(fileType),
        ));

        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        uploadedFiles.add({
          'fileName': fileName,
          'fileType': fileType,
          'downloadUrl': downloadUrl,
        });
      }

      List<Map<String, String>> workLog = [
        {"timeSlot": "10 AM - 12 PM", "description": _workController1.text},
        {"timeSlot": "12 PM - 2 PM", "description": _workController2.text},
        {"timeSlot": "2 PM - 6 PM", "description": _workController3.text},
        {"timeSlot": "6 PM - 8 PM", "description": _workController4.text},
      ];

      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? '';

      Map<String, dynamic> reportData = {
        'employeeId': _employeeIdController.text.trim(),
        "employeeName": _employeeNameController.text.trim(),
        "Service_department": selectedDepartment,
        "date": _selectedDate,
        "uploadedFiles": uploadedFiles,
        "workLog": workLog,
        "userId": userId,
        "timestamp": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection("DailyTaskReport").add(reportData);

      Fluttertoast.showToast(
        msg: "Task submitted successfully!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      setState(() {
        _isLoading = false;
        todayEntryExists = true;
      });

      // Clear form
      _taskTitleController.clear();
      _actionsTakenController.clear();
      _nextStepsController.clear();
      _locationController.clear();
      _workController1.clear();
      _workController2.clear();
      _workController3.clear();
      _workController4.clear();
      _file = null;
      _image = null;
      _dateController.clear();
      selectedServiceStatus = null;
      selectedDepartment = null;
      selectedFiles.clear();
      fileNames.clear();
      fileTypes.clear();

      _showTodayEntryDoneDialog();

    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      Fluttertoast.showToast(
        msg: "Failed to submit report: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // MODIFIED: Show loading while checking entry
    if (isCheckingEntry) {
      return Scaffold(
        backgroundColor: Colors.blue,
        body: Container(
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
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
                SizedBox(height: 20),
                Text(
                  "Loading...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Don't show form if entry exists - dialog will handle it
    if (todayEntryExists) {
      return Scaffold(
        backgroundColor: Colors.green[50],
        body: const Center(
          child: CircularProgressIndicator(
            color: Colors.green,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.task, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "Daily Task Report",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white),
            ),
          ],
        ),
        centerTitle: true,
        flexibleSpace: Container(
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
          ),
        ),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
        elevation: 8,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.blue,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Colors.grey, blurRadius: 8, spreadRadius: 4)
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 12.0, bottom: 4.0),
                          child: Text(
                            'Employee Name',
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        TextFormField(
                          controller: _employeeNameController,
                          readOnly: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person, color: Colors.white),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          ),
                          validator: (value) =>
                          value == null || value.isEmpty ? 'Employee name is required' : null,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 6.0, bottom: 4.0),
                          child: Text(
                            'Employee ID',
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        TextFormField(
                          controller: _employeeIdController,
                          readOnly: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.badge, color: Colors.white),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          ),
                          validator: (value) =>
                          value == null || value.isEmpty ? 'Employee ID is required' : null,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                _buildDateField(
                  controller: _dateController,
                  label: "Select Date",
                  icon: Icons.date_range,
                  onTap: () => _selectDate(context),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a date';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: pickFiles,
                    style: ElevatedButton.styleFrom(
                      elevation: 5,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.grey.withOpacity(0.5),
                    ),
                    child: Ink(
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
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 200, minHeight: 60),
                        alignment: Alignment.center,
                        child: const Text(
                          "Choose Files",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.cyanAccent,
                          ),
                        ),
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
                          width: 120,
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
                                      controller: fileNameControllers[index],
                                      decoration: InputDecoration(
                                        labelText: 'Rename',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.blue.shade50,
                                      ),
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  ElevatedButton(
                                    onPressed: () => renameFile(index),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: Size(100, 30),
                                      backgroundColor: Colors.blue.shade900,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
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
                                        borderRadius: BorderRadius.circular(8),
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
                                  ElevatedButton(
                                    onPressed: () => openFile(selectedFiles[index]),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: Size(100, 30),
                                      backgroundColor: Colors.blue.shade900,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
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
                                  radius: 16,
                                  backgroundColor: Colors.white,
                                  child: IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red, size: 19),
                                    onPressed: () => closeFile(index),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                )
                    : Center(child: Text("No files selected yet.",style: TextStyle(color: Colors.black),)),

                SizedBox(height: 16),

                if (_file != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      "File selected: ${_file!.path.split('/').last}",
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),

                const SizedBox(height: 20),
                buildDropdownField(
                  context: context,
                  labelText: "Select Department",
                  icon: Icons.assignment,
                  value: selectedDepartment,
                  items: serviceDepartment
                      .map((dept) => {'text': dept, 'icon': Icons.assignment})
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDepartment = value!;
                    });
                  },
                  validator: validateField,
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(10),
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
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Work Log - ${DateFormat('dd MMM yyyy').format(DateTime.now())}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Table(
                        border: TableBorder.all(color: Colors.white70),
                        columnWidths: const {
                          0: FlexColumnWidth(1.5),
                          1: FlexColumnWidth(3),
                        },
                        children: [
                          _buildTableRow("10 AM - 12 PM", _workController1),
                          _buildTableRow("12 PM - 2 PM", _workController2),
                          _buildTableRow("2 PM - 6 PM", _workController3),
                          _buildTableRow("6 PM - 8 PM", _workController4),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: Container(
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
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            "Submit Report",
                            style: TextStyle(color: Colors.white),
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
      ),
    );
  }

  String? validateField(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  TableRow _buildTableRow(String timeSlot, TextEditingController controller) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            timeSlot,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14,color: Colors.white),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextFormField(
              controller: controller,
              textInputAction: TextInputAction.next,
              onEditingComplete: () => FocusScope.of(context).nextFocus(),
              decoration: InputDecoration(
                hintText: "Enter work description",
                hintStyle: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              cursorColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
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
        child: TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: label,
            floatingLabelBehavior: FloatingLabelBehavior.never,
            hintStyle: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
            prefixIcon: Icon(icon, color: Colors.white),
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: validator,
          cursorColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    TextInputAction textInputAction = TextInputAction.done,
    bool disableFloatingLabel = false,
    bool readOnly = false,
  }) {
    final FocusNode focusNode = FocusNode();

    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
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
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              readOnly: readOnly,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: maxLines,
              keyboardType: keyboardType,
              validator: validator,
              textInputAction: textInputAction,
              decoration: InputDecoration(
                hintText: focusNode.hasFocus ? null : label,
                labelText: (disableFloatingLabel || focusNode.hasFocus) ? null : label,
                hintStyle: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
                labelStyle: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
                prefixIcon: Icon(icon, color: Colors.white),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
              onTap: () => setState(() {}),
              onChanged: (_) => setState(() {}),
              onEditingComplete: () => setState(() {}),
              cursorColor: Colors.white,
            ),
          ),
        );
      },
    );
  }
}