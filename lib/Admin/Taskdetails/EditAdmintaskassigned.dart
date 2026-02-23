import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Default/customwidget.dart';
import '../../Employee/Homescreen/Date_And_Time_Code/Customize_Time_001.dart';

class EditTaskPage extends StatefulWidget {
  final QueryDocumentSnapshot taskDoc;

  const EditTaskPage({Key? key, required this.taskDoc}) : super(key: key);

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  final _formKey = GlobalKey<FormState>();
  int? selectedFileIndex;
  String selectedTaskStatus = 'Pending';
  String? matchedDocId;
  FocusNode checkbox1Focus = FocusNode();
  Map<String, List<String>> employeeCategoryMap = {};
  Map<String, bool> checkboxValues = {};

  late TextEditingController employeeIdController;
  late TextEditingController employeeNamesController;
  late TextEditingController projectNameController;
  late TextEditingController departmentController;
  late TextEditingController siteLocationController;
  late TextEditingController taskDescriptionController;
  late TextEditingController assignedDateController;
  late TextEditingController deadlineDateController;
  late TextEditingController timeController;
  late TextEditingController deadlinetimeController;
  late TextEditingController taskStatusController;
  late TextEditingController employeeDescriptionController;
  TextEditingController empIdController = TextEditingController();

  List<String> employeeNames = [];

  List<Map<String, dynamic>> files = [];
  List<File?> selectedFiles = [];

  String? selectedDepartment;
  List<Map<String, dynamic>> filteredDepartmentList = [];

  List<String> fileNames = [];
  List<String> fileTypes = [];
  List<TextEditingController> fileNameControllers = [];
  bool isLoading = false;

  Map<String, String> employeeNameIdMap = {};
  List<String> selectedEmployeeNames = [];

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

  File? _image;

  @override
  void initState() {
    super.initState();

    final task = widget.taskDoc.data() as Map<String, dynamic>;

    /// Admin Name // Initialize once
    // selectedAdminName = task['adminName']?.toString().trim() ?? '';

    /// Initialize other controllers
    employeeIdController = TextEditingController(
      text: task['empIds'] == null
          ? ''
          : (task['empIds'] is List
              ? (task['empIds'] as List).join(', ')
              : task['empIds'].toString()),
    );

    employeeNamesController = TextEditingController(
      text: (task['employeeNames'] as List<dynamic>?)?.join(', ') ?? '',
    );
    projectNameController =
        TextEditingController(text: task['projectName'] ?? '');
    departmentController =
        TextEditingController(text: task['department'] ?? '');
    siteLocationController =
        TextEditingController(text: task['siteLocation'] ?? '');
    taskDescriptionController =
        TextEditingController(text: task['taskDescription'] ?? '');
    assignedDateController = TextEditingController(text: task['date'] ?? '');
    deadlineDateController =
        TextEditingController(text: task['deadlineDate'] ?? '');
    timeController = TextEditingController(text: task['time'] ?? '');
    deadlinetimeController = TextEditingController(text: task['deadlinetime'] ?? '');
    selectedTaskStatus = task['taskstatus'] ?? 'Pending';
    taskStatusController = TextEditingController(text: selectedTaskStatus);
    employeeDescriptionController =
        TextEditingController(text: task['employeeDescription'] ?? '');

    /// Files setup
    files = (task['files'] as List).map((e) {
      return {
        'fileName': e['fileName'],
        'fileType': e['fileType'],
        'downloadUrl': e['downloadUrl'],
        'isLocal': false,
      };
    }).toList();

    fileNameControllers = files
        .map((f) => TextEditingController(text: f['fileName'] ?? ''))
        .toList();
    selectedFiles = List<File?>.filled(files.length, null, growable: true);
    fileNames = files.map((f) => f['fileName'] as String).toList();
    fileTypes = files.map((f) => f['fileType'] as String).toList();

    /// Fetch employee names
    _fetchEmployeeNames().then((_) {
      // Set selected admin from fetched names
      // if (!adminNames.contains(selectedAdminName) && adminNames.isNotEmpty) {
      //   selectedAdminName = adminNames.first;
      // }

      // setState(() {
      //   adminNameController.text = selectedAdminName;
      // });

      /// Handle employee name mapping, categories, and department filtering
      final taskEmployeeNames = (task['employeeNames'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList();

      if (taskEmployeeNames != null) {
        selectedEmployeeNames = taskEmployeeNames;

        /// Auto-fill Emp IDs
        List<String> selectedIds = selectedEmployeeNames
            .map((name) => employeeNameIdMap[name] ?? '')
            .where((id) => id.isNotEmpty)
            .toList();

        empIdController.text = selectedIds.join(', ');

        /// Update filteredDepartmentList based on selected employees
        final selectedCategories = <String>{};
        for (final name in selectedEmployeeNames) {
          final cats = employeeCategoryMap[name] ?? [];
          selectedCategories.addAll(cats);
        }

        filteredDepartmentList = departmentList
            .where((dep) => selectedCategories.contains(dep['name']))
            .toList();

        if (task['department'] != null &&
            filteredDepartmentList
                .any((d) => d['name'] == task['department'])) {
          selectedDepartment = task['department'];
        } else {
          selectedDepartment = null;
        }
      }
    });

    /// Handle checkbox values
    if (task.containsKey('checkboxValues')) {
      final Map<String, dynamic> storedCheckboxes = task['checkboxValues'];

      storedCheckboxes.forEach((key, value) {
        checkboxValues[key] = value == true;
      });
    }
  }

  @override
  void dispose() {
    employeeIdController.dispose();
    employeeNamesController.dispose();
    projectNameController.dispose();
    departmentController.dispose();
    siteLocationController.dispose();
    taskDescriptionController.dispose();
    assignedDateController.dispose();
    deadlineDateController.dispose();
    timeController.dispose();
    deadlinetimeController.dispose();
    taskStatusController.dispose();
    employeeDescriptionController.dispose();

    for (var controller in fileNameControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  Widget _buildGradientDropdownField({
    required String label,
    required String? selectedValue,
    required List<String> options,
    required void Function(String?) onChanged,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontFamily: 'Roboto',
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF000F89),
                  Color(0xFF0F52BA),
                  Color(0xFF002147)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonFormField<String>(
              value: selectedValue,
              isExpanded: true,
              dropdownColor: const Color(0xFF002147),
              iconEnabledColor: Colors.white,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.transparent,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white54),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.tealAccent),
                ),
              ),
              validator: isRequired
                  ? (val) => val == null || val.trim().isEmpty
                      ? '$label required'
                      : null
                  : null,
              items: options.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientTextField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    bool isRequired = false,
    int maxLines = 1,
    Future<void> Function()? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontFamily: 'Roboto',
            ),
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
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextFormField(
              controller: controller,
              readOnly: readOnly,
              onTap: readOnly ? onTap : null,
              // 👈 Only trigger onTap if readOnly
              maxLines: maxLines,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.transparent,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white54),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.tealAccent),
                ),
              ),
              validator: isRequired
                  ? (val) => val == null || val.trim().isEmpty
                      ? '$label required'
                      : null
                  : null,
            ),
          ),
        ],
      ),
    );
  }

//files methods
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
        // Replace the file entry in `files` list
        files[index] = {
          'fileName': file.name,
          'fileType': file.extension ?? 'unknown',
          'downloadUrl': file.path!, // Local file path
          'isLocal': true, // Mark as local file
        };

        // Optional: Also update controller text if you're using it
        if (index < fileNameControllers.length) {
          fileNameControllers[index].text = file.name;
        } else {
          fileNameControllers.add(TextEditingController(text: file.name));
        }
      });
    } else {
      print("No file selected.");
    }
  }

  void renameFile(int index) {
    final newName = fileNameControllers[index].text.trim();

    if (newName.isNotEmpty) {
      setState(() {
        files[index]['fileName'] = newName;
        fileNameControllers[index].clear();
      });
    }
  }

  void closeFile(int index) {
    setState(() {
      files.removeAt(index);
      fileNameControllers.removeAt(index);

      if (selectedFileIndex == index) {
        selectedFileIndex = null;
      } else if (selectedFileIndex != null && selectedFileIndex! > index) {
        selectedFileIndex = selectedFileIndex! - 1;
      }
    });
  }

  void openFile(String pathOrUrl, bool isLocal) async {
    if (isLocal) {
      await OpenFile.open(pathOrUrl);
    } else {
      await OpenFile.open(pathOrUrl);
    }
  }

  void closeDetailPanel(int index) {
    setState(() {
      selectedFileIndex = null;
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
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('EmpProfile').get();

      setState(() {
        employeeNameIdMap = {};
        employeeCategoryMap = {};

        for (var doc in snapshot.docs) {
          final fullName = doc['fullName'];
          final empId = doc['empId'];
          final categories = doc['categories']; // ✅ LIST

          if (fullName != null &&
              empId != null &&
              fullName.toString().isNotEmpty) {
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

        employeeNames =
            employeeNameIdMap.keys.where((name) => name.isNotEmpty).toList();
      });
    } catch (e) {
      print("❌ Error fetching employee names and IDs: $e");
    }
  }

  void _showConfirmationDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Confirm",
      pageBuilder: (ctx, anim1, anim2) {
        return const SizedBox.shrink(); // Required for `transitionBuilder`
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Transform.scale(
            scale: Curves.easeOutBack.transform(anim1.value),
            child: Opacity(
              opacity: anim1.value,
              child: Dialog(
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF000F89), // Royal Blue
                        Color(0xFF0F52BA), // Cobalt Blue
                        Color(0xFF002147), // Deep Blue
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 60, color: Colors.white),
                      const SizedBox(height: 16),
                      const Text(
                        'Update Task?',
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Are you sure you want to update this task?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              elevation: 4,
                            ),
                            icon: const Icon(Icons.cancel),
                            label: const Text('No'),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.green.shade600,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              elevation: 4,
                            ),
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Yes'),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _saveTask();
                              _showSuccessSnackBar();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F52BA),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Task updated successfully!',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    List<String> errors = [];

    if (empIdController.text.isEmpty) {
      errors.add('Please select At least Admin Id');
    }

    if (selectedEmployeeNames.isEmpty) {
      errors.add('Please select at least one employee');
    }
    if (projectNameController.text.trim().isEmpty) {
      errors.add('Project Name is missing');
    }
    if (selectedDepartment == null || selectedDepartment!.trim().isEmpty) {
      errors.add('Department not selected');
    }
    if (siteLocationController.text.isEmpty) {
      errors.add('Site location required');
    }
    if (taskDescriptionController.text.isEmpty) {
      errors.add('TaskDescription required');
    }

    if (assignedDateController.text.isEmpty) {
      errors.add('Assigned Date required');
    }

    if (deadlineDateController.text.isEmpty) {
      errors.add('Deadline Date required');
    }

    if (timeController.text.isEmpty) {
      errors.add('Assigned Time required');
    }

    if (deadlinetimeController.text.isEmpty) {
      errors.add('Deadline Time required');
    }

    if (selectedTaskStatus.isEmpty) {
      errors.add('Task Status Required');
    }

    // if (selectedFiles.isEmpty) {
    //   errors.add('At least one file must be selected');
    // }

    final updatedData = {
      /*  'adminName': selectedAdminName,*/
      'empIds':
          empIdController.text.trim().split(',').map((e) => e.trim()).toList(),
      'employeeNames': selectedEmployeeNames,
      'projectName': projectNameController.text.trim(),
      'department': selectedDepartment,
      'siteLocation': siteLocationController.text.trim(),
      'taskDescription': taskDescriptionController.text.trim(),
      'date': assignedDateController.text.trim(),
      'deadlineDate': deadlineDateController.text.trim(),
      'time': timeController.text.trim(),
      'deadlinetime':deadlinetimeController.text.trim(),
      'taskstatus': selectedTaskStatus,
      "read": false,
      'files': files,
    };

    try {
      await FirebaseFirestore.instance
          .collection('TaskAssign')
          .doc(widget.taskDoc.id)
          .update(updatedData);

      Fluttertoast.showToast(
          msg: "Task updated successfully!", backgroundColor: Colors.green);
      Navigator.of(context).pop();
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Failed to update task: $e", backgroundColor: Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Task Report",
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: "Times New Roman"),
        ),
        backgroundColor: const Color(0xFF0F52BA),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: isLoading ? null : _saveTask,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 20),
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    shadowColor: Colors.deepPurpleAccent,
                    child: Padding(
                        padding: const EdgeInsets.all(13.0),
                        child: Column(children: [
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
                                    .map(
                                        (name) => employeeNameIdMap[name] ?? '')
                                    .where((id) => id.isNotEmpty)
                                    .toList();

                                empIdController.text = selectedIds.join(', ');

                                final selectedCategories = <String>{};
                                for (final name in selected) {
                                  final cats = employeeCategoryMap[name] ?? [];
                                  selectedCategories.addAll(cats);
                                }

                                filteredDepartmentList = departmentList
                                    .where((dep) => selectedCategories
                                        .contains(dep['name']))
                                    .toList();

                                if (selectedDepartment != null &&
                                    !filteredDepartmentList.any((d) =>
                                        d['name'] == selectedDepartment)) {
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
                        ])),
                  ),

                  _buildGradientTextField(
                    controller: projectNameController,
                    label: 'Project Name',
                  ),
                  if (siteLocationController.text.trim().isNotEmpty)
                    _buildGradientTextField(
                      controller: siteLocationController,
                      label: 'Site Location',
                    ),

                  _buildGradientTextField(
                    controller: taskDescriptionController,
                    label: 'Task Description',
                    maxLines: 3,
                  ),

                  // 🔹 ASSIGNED DATE TEXTFIELD
                  _buildGradientTextField(
                    controller: assignedDateController,
                    label: 'Assigned Date',
                    readOnly: true,
                    onTap: () async {
                      await showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (_) => buildGradientDatePicker(
                          context,
                          DateTime.now(),
                          (newDate) {
                            assignedDateController.text =
                                DateFormat('dd MMMM yyyy').format(newDate);
                          },
                          isAssignedDate: true,
                        ),
                      );
                    },
                  ),

// 🔹 DEADLINE DATE TEXTFIELD
                  // 🔹 DEADLINE DATE TEXTFIELD
                  _buildGradientTextField(
                    controller: deadlineDateController,
                    label: 'Deadline Date',
                    readOnly: true,
                    onTap: () async {
                      // Parse assigned date first
                      DateTime assignedDate;
                      try {
                        assignedDate = DateFormat('dd MMMM yyyy')
                            .parseLoose(assignedDateController.text);
                      } catch (e) {
                        assignedDate = DateTime.now();
                      }

                      await showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (_) => buildGradientDatePicker(
                          context,
                          assignedDate,
                              (newDate) {
                            // Only allow dates >= assignedDate
                            if (newDate.isBefore(assignedDate)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Deadline cannot be before Assigned Date",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            final formatted = DateFormat('dd MMMM yyyy').format(newDate);
                            deadlineDateController.text = formatted;
                          },
                          minDate: assignedDate, // 🔹 start from assigned date
                        ),
                      );
                    },
                  ),


// Time
                  _buildGradientTextField(
                    controller: timeController,
                    label: 'Assigned Time',
                    readOnly: true,
                    onTap: () async {
                      TimeOfDay now = TimeOfDay.now();
                      await showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => buildGradientTimePicker(
                          context,
                          now,
                          onTimeSelected: (pickedTime) {
                            timeController.text = pickedTime.format(context);
                          },
                          minTime: now, // 🔹 Cannot select before current time
                        ),
                      );
                    },
                  ),


                  _buildGradientTextField(
                    controller: deadlinetimeController,
                    label: 'Deadline Time',
                    readOnly: true,
                    onTap: () async {
                      if (timeController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please select Assigned Time first"),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      final parts = timeController.text.split(RegExp(r'[: ]'));
                      int hour = int.parse(parts[0]);
                      int minute = int.parse(parts[1]);
                      final isPM = parts[2] == 'PM';
                      if (isPM && hour != 12) hour += 12;
                      if (!isPM && hour == 12) hour = 0;

                      TimeOfDay assignedTime = TimeOfDay(hour: hour, minute: minute);

                      await showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => buildGradientTimePicker(
                          context,
                          assignedTime,
                          onTimeSelected: (pickedTime) {
                            deadlinetimeController.text = pickedTime.format(context);
                          },
                          minTime: assignedTime,
                        ),
                      );
                    },
                  ),


                  _buildGradientDropdownField(
                    label: 'Task Status',
                    selectedValue: selectedTaskStatus,
                    options: ['Pending', 'In Progress', 'Completed'],
                    onChanged: (val) {
                      setState(() => selectedTaskStatus = val ?? '');
                      taskStatusController.text = selectedTaskStatus;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Existing attached files (uploaded files from Firebase)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Attached Files:',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    height: 130,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: files.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final file = files[index];
                        final url = file['downloadUrl'] ?? '';
                        final fileName = file['fileName'] ?? '';
                        final ext =
                            (file['fileType'] ?? '').toString().toLowerCase();
                        final isLocal = file['isLocal'] == true;
                        Widget iconWidget;

                        if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp']
                            .contains(ext)) {
                          iconWidget = isLocal
                              ? Image.file(
                                  File(url),
                                  width: 100,
                                  height: 80,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  url,
                                  width: 100,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.broken_image,
                                        size: 50, color: Colors.grey);
                                  },
                                );
                        } else if (['mp4', 'mov', 'avi'].contains(ext)) {
                          iconWidget = const Icon(Icons.videocam,
                              size: 50, color: Colors.blue);
                        } else if (ext == 'pdf') {
                          iconWidget = const Icon(Icons.picture_as_pdf,
                              size: 50, color: Colors.red);
                        } else {
                          iconWidget = const Icon(Icons.insert_drive_file,
                              size: 50, color: Colors.grey);
                        }

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedFileIndex = index;
                            });
                          },
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.blue.shade400, width: 1),
                                ),
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: iconWidget,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      fileName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      files.removeAt(index);
                                      fileNameControllers.removeAt(index);

                                      if (files.isEmpty) {
                                        selectedFileIndex =
                                            null; // reset if no files
                                      } else if (selectedFileIndex == index) {
                                        selectedFileIndex =
                                            null; // close panel if removed selected file
                                      } else if (selectedFileIndex != null &&
                                          selectedFileIndex! > index) {
                                        selectedFileIndex = selectedFileIndex! -
                                            1; // adjust index if needed
                                      }
                                    });
                                  },
                                  child: const CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.red,
                                    child: Icon(Icons.close,
                                        size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "🔴 Note:\nNeed extra files?\nTap the any Attached FIles to add any file!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: "Times New Roman",
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (selectedFileIndex != null)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue, width: 2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ...List.generate(files.length, (index) {
                                  final info = files[index];
                                  final ext =
                                      (info['fileType'] as String? ?? '')
                                          .toLowerCase();
                                  final isLocal = info['isLocal'] == true;
                                  final url = info['downloadUrl'];

                                  Widget preview;
                                  if (['jpg', 'jpeg', 'png', 'gif']
                                      .contains(ext)) {
                                    preview = isLocal
                                        ? Image.file(
                                            File(url),
                                            width: 120,
                                            height: 90,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.network(
                                            url,
                                            width: 120,
                                            height: 90,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.broken_image,
                                                    size: 50,
                                                    color: Colors.grey),
                                          );
                                  } else if (['mp4', 'mov', 'avi', 'mkv']
                                      .contains(ext)) {
                                    preview = const Icon(Icons.videocam,
                                        size: 50, color: Colors.blue);
                                  } else if (ext == 'pdf') {
                                    preview = const Icon(Icons.picture_as_pdf,
                                        size: 50, color: Colors.red);
                                  } else {
                                    preview = const Icon(
                                        Icons.insert_drive_file,
                                        size: 50,
                                        color: Colors.grey);
                                  }

                                  return Container(
                                    margin: const EdgeInsets.all(10),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.blue, width: 1),
                                    ),
                                    width: 140,
                                    child: Stack(
                                      children: [
                                        Column(
                                          children: [
                                            preview,
                                            const SizedBox(height: 10),
                                            Text(
                                              info['fileName'] ?? '',
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 5),
                                            SizedBox(
                                              width: 120,
                                              child: TextField(
                                                controller:
                                                    fileNameControllers[index],
                                                decoration: InputDecoration(
                                                  labelText: 'Rename',
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  filled: true,
                                                  fillColor:
                                                      Colors.blue.shade50,
                                                ),
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  renameFile(index),
                                              style: ElevatedButton.styleFrom(
                                                minimumSize:
                                                    const Size(120, 30),
                                                backgroundColor:
                                                    Colors.blue.shade900,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text("Rename",
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.white)),
                                            ),
                                            const SizedBox(height: 5),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  replaceFile(index),
                                              style: ElevatedButton.styleFrom(
                                                minimumSize:
                                                    const Size(120, 30),
                                                backgroundColor:
                                                    Colors.blue.shade900,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text("Replace",
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.white)),
                                            ),
                                            const SizedBox(height: 5),
                                            ElevatedButton(
                                              onPressed: () {
                                                openFile(url, isLocal);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                minimumSize:
                                                    const Size(120, 30),
                                                backgroundColor:
                                                    Colors.blue.shade900,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text("Open",
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.white)),
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
                                              onPressed: () =>
                                                  closeDetailPanel(index),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),

                                // 👇 ADD FILE BUTTON HERE
                                GestureDetector(
                                  onTap: () async {
                                    FilePickerResult? result =
                                        await FilePicker.platform.pickFiles(
                                      type: FileType.any,
                                      allowMultiple: false,
                                    );

                                    if (result != null &&
                                        result.files.isNotEmpty) {
                                      final file = result.files.first;
                                      final filePath = file.path!;
                                      final fileName = file.name;
                                      final ext = file.extension ?? '';

                                      final newFile = {
                                        'fileName': fileName,
                                        'fileType': ext,
                                        'isLocal': true,
                                        'downloadUrl': filePath,
                                      };

                                      final newController =
                                          TextEditingController(text: fileName);

                                      // 👇 Insert right after selected index
                                      final insertIndex =
                                          selectedFileIndex! + 1;

                                      setState(() {
                                        files.insert(insertIndex, newFile);
                                        fileNameControllers.insert(
                                            insertIndex, newController);

                                        // Optionally, update the selected index to highlight new file
                                        selectedFileIndex = insertIndex;
                                      });

                                      // Optional: Scroll to new item here if you're using a ScrollController
                                    }
                                  },
                                  child: Container(
                                    width: 140,
                                    height: 220,
                                    margin: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                          color: Colors.grey,
                                          width: 2,
                                          style: BorderStyle.solid),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.add,
                                          size: 40, color: Colors.blue),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _showConfirmationDialog(context),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF000F89), // Royal Blue
                                Color(0xFF0F52BA), // Cobalt Blue
                                Color(0xFF002147), // Deep Blue
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.system_update_alt,
                                    color: Colors.white),
                                SizedBox(width: 10),
                                Text(
                                  'Update Task',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
  }

  Widget buildGradientDatePicker(
    BuildContext context,
    DateTime selectedDate,
    Function(DateTime) onDateSelected, {
    bool isAssignedDate = false,
    DateTime? minDate,
  }) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    // 🔹 Remove time part from all dates
    DateTime clean(DateTime d) => DateTime(d.year, d.month, d.day);

    // 🔹 For Assigned Date — today & future allowed
    DateTime minimumDate = clean(today); // no past
    DateTime maximumDate =
        clean(today.add(const Duration(days: 365 * 5))); // 5 years limit

    // 🔹 Ensure initial date valid
    DateTime safeInitialDate =
        clean(selectedDate.isBefore(minimumDate) ? minimumDate : selectedDate);

    if (safeInitialDate.isAfter(maximumDate)) safeInitialDate = maximumDate;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Select Assigned Date',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: CupertinoTheme(
              data: const CupertinoThemeData(
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: safeInitialDate,
                minimumDate: minimumDate,
                // ⛔ past disable
                maximumDate: maximumDate,
                // ✅ future allowed
                onDateTimeChanged: (DateTime newDate) {
                  onDateSelected(clean(newDate));
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Done',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
