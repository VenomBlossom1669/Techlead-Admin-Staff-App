import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techlead/Default/customwidget.dart';

class ReceptionPage extends StatefulWidget {
  @override
  _ReceptionPageState createState() => _ReceptionPageState();
}

class _ReceptionPageState extends State<ReceptionPage> {
  DateTime? _appointmentDate;
  TimeOfDay? _appointmentTime;
  DateTime? _taskDueDate;
  String? _meetingPurpose;
  String? _assignedStaff;
  String? _taskPriority;
  String? _taskStatus;
  bool _isTaskCompleted = false;
  String? _clientMeetingStatus;

  final List<Map<String, dynamic>> meetingPurposes = [
    {'text': 'Initial Consultation', 'icon': FontAwesomeIcons.handshake},
    {'text': 'Installation Request', 'icon': FontAwesomeIcons.cogs},
    {'text': 'Service Inquiry', 'icon': FontAwesomeIcons.questionCircle},
    {'text': 'System Upgrade', 'icon': FontAwesomeIcons.arrowUp},
    {'text': 'Troubleshooting', 'icon': FontAwesomeIcons.tools},
    {'text': 'Home Automation Advice', 'icon': FontAwesomeIcons.lightbulb},
    {'text': 'Smart Home Integration', 'icon': FontAwesomeIcons.networkWired},
    {'text': 'Maintenance Request', 'icon': FontAwesomeIcons.wrench},
    {'text': 'Security System Setup', 'icon': FontAwesomeIcons.shieldAlt},
    {
      'text': 'Energy Efficiency Consultation',
      'icon': FontAwesomeIcons.solarPanel
    },
    {'text': 'Product Demonstration', 'icon': FontAwesomeIcons.tv},
    {'text': 'Follow-Up on Services', 'icon': FontAwesomeIcons.userMd},
    {
      'text': 'Client Training Session',
      'icon': FontAwesomeIcons.chalkboardTeacher
    },
    {'text': 'Custom Solutions Discussion', 'icon': FontAwesomeIcons.cogs},
    {'text': 'Troubleshooting Follow-Up', 'icon': FontAwesomeIcons.bug},
  ];

  List<Map<String, dynamic>> staffList = [];

  final List<Map<String, dynamic>> taskPriorities = [
    {'text': 'High', 'icon': FontAwesomeIcons.exclamationCircle},
    {'text': 'Medium', 'icon': FontAwesomeIcons.exclamationTriangle},
    {'text': 'Low', 'icon': FontAwesomeIcons.circle},
  ];

  final TextEditingController _adminNameController = TextEditingController();


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchEmployeeNames();
    _loadAdminData();
  }



  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();

    final name = prefs.getString('name') ?? '';

    if (mounted) {
      setState(() {
        _adminNameController.text = name;
      });
    }
  }

  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _WhatsappNumberController = TextEditingController();
  final _locationController = TextEditingController();
  Map<String, List<String>> employeeCategoryMap = {};
  Map<String, String> employeeNameIdMap = {};
  List<String> employeeNames = [];
  bool _isSubmitting = false;

  List<String> selectedEmployeeNames = [];

  TextEditingController empIdController =
      TextEditingController();

  List<Map<String, dynamic>> departmentList =
      [];
  List<Map<String, dynamic>> filteredDepartmentList = [];

  String? selectedDepartment;


  String? _validateNonEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  void _selectAppointmentDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _appointmentDate = pickedDate;
      });
    }
  }

  void _selectAppointmentTime(BuildContext context) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _appointmentTime = pickedTime;
      });
    }
  }

  Future<void> _fetchEmployeeNames() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('EmpProfile').get();

      setState(() {
        employeeNameIdMap = {};
        employeeCategoryMap = {};
        employeeNames = [];

        for (var doc in snapshot.docs) {
          final fullName = doc['fullName'];
          final empId = doc['empId'];
          final categories = doc['categories'];

          if (fullName != null &&
              empId != null &&
              fullName.toString().isNotEmpty &&
              categories is List &&
              categories.contains('Reception')) {
            // Add only if 'Reception' is in categories
            employeeNameIdMap[fullName] = empId;

            employeeCategoryMap[fullName] = categories
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toSet()
                .toList();

            employeeNames.add(fullName);
          }
        }
      });
    } catch (e) {
      print("❌ Error fetching employee names and IDs: $e");
    }
  }

  void _selectTaskDueDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _taskDueDate = pickedDate;
      });
    }
  }

  final user = FirebaseAuth.instance.currentUser;
  String? userId;

  void _submitForm() async {
    final form = _formKey.currentState;

    // 1) Task completed check
    if (!_isTaskCompleted) {
      _showError("Please mark the task as completed");
      return;
    }

    // 2) TextFormField validators check
    if (form != null && form.validate()) {
      // 3) Extra Manual Checks

      // 🔹 Employee select required
      if (selectedEmployeeNames.isEmpty) {
        _showError("Please select at least one employee");
        return;
      }

      // 🔹 Client full name required
      if (_clientNameController.text.trim().isEmpty) {
        _showError("Please enter client full name");
        return;
      }

      // 🔹 Phone number required & valid
      final phone = _phoneNumberController.text.trim();
      if (phone.isEmpty) {
        _showError("Please enter client phone number");
        return;
      }

      final whatsapp = _WhatsappNumberController.text.trim();
      if (whatsapp.isEmpty) {
        _showError("Please enter client Whatsapp number");
        return;
      }
      if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
        _showError("Enter a valid 10-digit phone number");
        return;
      }

      // 🔹 Other required fields
      if (_appointmentDate == null) {
        _showError("Please select appointment date");
        return;
      }
      if (_appointmentTime == null) {
        _showError("Please select appointment time");
        return;
      }
      if (_meetingPurpose == null) {
        _showError("Please select meeting purpose");
        return;
      }
      if (_taskPriority == null) {
        _showError("Please select task priority");
        return;
      }
      if (_taskDueDate == null) {
        _showError("Please select task due date");
        return;
      }
      if (_taskStatus == null) {
        _showError("Please select task status");
        return;
      }
      if (_clientMeetingStatus == null) {
        _showError("Please select client meeting status");
        return;
      }

      // ✅ All good → Save data
      setState(() => _isSubmitting = true);

      Map<String, dynamic> formData = {
        'emp_info': selectedEmployeeNames, // 🔹 selected employee(s)
        'client_name': _clientNameController.text.trim(), // 🔹 client full name
        'phone_number': phone,
        'whatsaapp_number':
            _WhatsappNumberController.text.trim(), // 🔹 client phone number
        'location': _locationController.text.trim(),
        'appointment_date': _appointmentDate?.toIso8601String(),
        'appointment_time': _appointmentTime?.format(context),
        'meeting_purpose': _meetingPurpose,
        'assigned_staff': _adminNameController.text.trim(),
        'task_priority': _taskPriority,
        'task_due_date': _taskDueDate?.toIso8601String(),
        'task_status': _taskStatus,
        'is_task_completed': _isTaskCompleted,
        'client_meeting_status': _clientMeetingStatus,
      };

      try {
        await FirebaseFirestore.instance
            .collection('ReceptionPage')
            .add(formData);

        Fluttertoast.showToast(
          msg: "Reception Data stored successfully",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        _resetFormFields();
      } catch (e) {
        _showError("Error storing data: $e");
      } finally {
        setState(() => _isSubmitting = false);
      }
    } else {
      _showError("Please fill all fields");
    }
  }

  // 🔹 Common toast helper
  void _showError(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _resetFormFields() {
    setState(() {
      _clientNameController.clear();
      _phoneNumberController.clear();
      _WhatsappNumberController.clear();
      _locationController.clear();
      _appointmentDate = null;
      _appointmentTime = null;
      _meetingPurpose = null;
      selectedEmployeeNames = [];
      _taskPriority = null;
      _taskDueDate = null;
      _taskStatus = null;
      _isTaskCompleted = false;
      _clientMeetingStatus = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.accusoft,
              color: Colors.white,
            ),
            SizedBox(width: 15),
            Text(
              "Meeting Page",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: 1.5,
                color: Colors.white,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.indigo.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                buildSection("Employee Information", [
                  buildMultiSelectDropdownField(
                    labelText: 'Select Employees',
                    icon: Icons.person_outline,
                    context: context,
                    items:
                        employeeNames, // now only includes Reception category names
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
                            .where((dep) =>
                                selectedCategories.contains(dep['name']))
                            .toList();

                        if (selectedDepartment != null &&
                            !filteredDepartmentList
                                .any((d) => d['name'] == selectedDepartment)) {
                          selectedDepartment = null;
                        }
                      });
                    },
                  ),
                ]),
                SizedBox(height: 24),
                buildSection("Client Information", [
                  buildTextField(
                    context: context,
                    controller: _clientNameController,
                    labelText: "Client's Full Name",
                    hintText: "Enter client's full name",
                    icon: FontAwesomeIcons.user,
                    validator: (value) =>
                        _validateNonEmpty(value, "the client's full name"),
                  ),
                  SizedBox(height: 16),
                  buildTextField(
                    controller: _phoneNumberController,
                    context: context,
                    labelText: "Client's Phone Number",
                    hintText: "Enter client's phone number",
                    icon: FontAwesomeIcons.phone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(10),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Mobile number is required.';
                      } else if (value.length != 10) {
                        return 'Mobile number must be 10 digits.';
                      } else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                        return 'Enter a valid 10-digit number.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  buildTextField(
                    controller: _WhatsappNumberController,
                    context: context,
                    labelText: "Client's Whatsapp Number",
                    hintText: "Enter client's Whatsapp number",
                    icon: FontAwesomeIcons.whatsapp,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(10),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Whatsapp number is required.';
                      } else if (value.length != 10) {
                        return 'Whatsapp number must be 10 digits.';
                      } else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                        return 'Enter a valid 10-digit Whatsapp number.';
                      }
                      return null;
                    },
                  ),
                ]),
                SizedBox(height: 24),
                buildSection("Appointment Scheduling", [
                  buildDatePickerField(
                    context,
                    label: "Select Appointment Date",
                    date: _appointmentDate,
                    onTap: () => _selectAppointmentDate(context),
                  ),
                  SizedBox(height: 16),
                  buildTimePickerField(
                    context,
                    label: "Select Appointment Time",
                    time: _appointmentTime,
                    onTap: () => _selectAppointmentTime(context),
                  ),
                  SizedBox(height: 16),
                  buildDropdownField(
                    labelText: "Select Meeting Purpose",
                    context: context,
                    icon: FontAwesomeIcons.calendarCheck,
                    value: _meetingPurpose,
                    items: meetingPurposes,
                    onChanged: (value) {
                      setState(() {
                        _meetingPurpose = value;
                      });
                    },
                    validator: (value) =>
                        _validateNonEmpty(value, "a meeting purpose"),
                  ),
                  SizedBox(height: 16),
                  buildTextField(
                    controller: _locationController,
                    labelText: "Meeting Location",
                    context: context,
                    hintText: "Enter meeting location",
                    icon: FontAwesomeIcons.mapMarkerAlt,
                    validator: (value) =>
                        _validateNonEmpty(value, "the meeting location"),
                  ),
                  SizedBox(height: 16),
                  buildTextField(
                    readOnly: true,
                    controller: _adminNameController,
                    context: context,
                    labelText: "Assigned Staff/CEO",
                    hintText: "Auto-filled from login",
                    icon: FontAwesomeIcons.userTie,
                    validator: (value) =>
                        _validateNonEmpty(value, "assigned staff"),
                  ),
                ]),
                SizedBox(height: 24),
                buildSection("Task Management", [
                  buildDropdownField(
                    labelText: "Task Priority",
                    context: context,
                    icon: FontAwesomeIcons.exclamationCircle,
                    value: _taskPriority,
                    items: taskPriorities,
                    onChanged: (value) {
                      setState(() {
                        _taskPriority = value;
                      });
                    },
                    validator: (value) =>
                        _validateNonEmpty(value, "a task priority"),
                  ),
                  SizedBox(height: 16),
                  buildDatePickerField(
                    context,
                    label: "Select Task Due Date",
                    date: _taskDueDate,
                    onTap: () => _selectTaskDueDate(context),
                  ),
                  SizedBox(height: 16),
                  buildDropdownField(
                    labelText: "Task Status",
                    context: context,
                    icon: FontAwesomeIcons.cogs,
                    value: _taskStatus,
                    items: [
                      {
                        'text': 'Pending',
                        'icon': FontAwesomeIcons.hourglassHalf
                      },
                      {'text': 'In Progress', 'icon': FontAwesomeIcons.spinner},
                      {
                        'text': 'Completed',
                        'icon': FontAwesomeIcons.checkCircle
                      },
                    ],
                    onChanged: (value) {
                      setState(() {
                        _taskStatus = value;
                      });
                    },
                    validator: (value) =>
                        _validateNonEmpty(value, "a task status"),
                  ),
                  SizedBox(height: 16),
                  buildCheckboxField(
                    label: "Mark Task as Completed",
                    context: context,
                    value: _isTaskCompleted,
                    onChanged: (value) {
                      setState(() {
                        _isTaskCompleted = value!;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  buildDropdownField(
                    labelText: "Client Meeting Status",
                    context: context,
                    icon: FontAwesomeIcons.users,
                    value: _clientMeetingStatus,
                    items: [
                      {
                        'text': 'Scheduled',
                        'icon': FontAwesomeIcons.calendarCheck
                      },
                      {
                        'text': 'Completed',
                        'icon': FontAwesomeIcons.checkCircle
                      },
                      {
                        'text': 'Cancelled',
                        'icon': FontAwesomeIcons.timesCircle
                      },
                    ],
                    onChanged: (value) {
                      setState(() {
                        _clientMeetingStatus = value;
                      });
                    },
                    validator: (value) =>
                        _validateNonEmpty(value, "a client meeting status"),
                  ),
                ]),
                SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      child: ElevatedButton(
                        onPressed: (_isSubmitting)
                            ? null
                            : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade900,
                          shadowColor: Colors.purpleAccent.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                        ),
                        child: _isSubmitting
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Submit',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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
}
