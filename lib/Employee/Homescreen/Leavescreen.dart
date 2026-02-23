import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:http/http.dart' as http;

final RegExp emailRegExp = RegExp(
  r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
);

class Leavescreen extends StatefulWidget {
  const Leavescreen({super.key});

  @override
  State<Leavescreen> createState() => _LeavescreenState();
}

class _LeavescreenState extends State<Leavescreen> {
  List<String> leaveinfo = ['Leave Type', 'Full Leave', 'First Half Leave','Second Half Leave'];
  String? selectedLeaveinfo = 'Leave Type';
  bool isLoading = false;
  String userName = '';
  String empId = '';
  String email = '';
  DateTime? startdate;
  DateTime? enddate;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController empIdController = TextEditingController();
  final TextEditingController empNameController = TextEditingController();
  final TextEditingController empemailidController = TextEditingController();
  final TextEditingController startdateController = TextEditingController();
  final TextEditingController enddateController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();

  // Validation flags
  bool showLeaveTypeError = false;
  bool showReasonError = false;
  bool showStartDateError = false;
  bool showEndDateError = false;

  // Store applied leave dates
  Set<String> appliedLeaveDates = {};
  bool hasAppliedToday = false;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your EmailID';
    } else if (!emailRegExp.hasMatch(value)) {
      return 'Please enter a valid email address';
    } else if (!value.contains('@') || !value.contains('.com') || !value.contains('gmail')) {
      return 'Please enter a valid email';
    }
    return null;
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
          empNameController.text = userSnapshot.get('fullName') ?? "Unknown";
          empIdController.text = userSnapshot.get('empId') ?? "Unknown";
          empemailidController.text = userSnapshot.get('email') ?? "Unknown";
        });
        print("Fetched Data: ${empNameController.text}, ${empIdController.text}, ${empemailidController.text}");
      } else {
        print("No user data found for userId: $userId");
      }

      // Fetch applied leaves to disable dates
      await _fetchAppliedLeaves();
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _fetchAppliedLeaves() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection('Empleave')
          .where('userId', isEqualTo: userId)
          .get();

      Set<String> dates = {};
      DateTime today = DateTime.now();
      String todayFormatted = DateFormat('dd/MM/yyyy').format(today);
      bool todayApplied = false;

      for (var doc in querySnapshot.docs) {
        String startDateStr = doc.data()['startdate'] ?? '';
        String endDateStr = doc.data()['enddate'] ?? '';
        String reportedDateStr = doc.data()['reportedDateTime'] != null
            ? DateFormat('dd/MM/yyyy').format(
            (doc.data()['reportedDateTime'] as Timestamp).toDate())
            : '';

        if (reportedDateStr == todayFormatted) {
          todayApplied = true;
        }

        if (startDateStr.isNotEmpty && endDateStr.isNotEmpty) {
          try {
            DateTime start = DateFormat('dd/MM/yyyy').parse(startDateStr);
            DateTime end = DateFormat('dd/MM/yyyy').parse(endDateStr);

            for (DateTime date = start;
            date.isBefore(end.add(Duration(days: 1)));
            date = date.add(Duration(days: 1))) {
              dates.add(DateFormat('dd/MM/yyyy').format(date));
            }
          } catch (e) {
            print('Error parsing dates: $e');
          }
        }
      }

      setState(() {
        appliedLeaveDates = dates;
        hasAppliedToday = todayApplied;
      });
    } catch (e) {
      print('Error fetching applied leaves: $e');
    }
  }

  Future<void> _deleteLeaveRequest(String docId) async {
    try {
      await _firestore.collection('Empleave').doc(docId).delete();

      // Refresh the applied leaves
      await _fetchAppliedLeaves();

      if (!mounted) return;
      _showSnackBar('Leave request deleted successfully!', const Color(0xFF10B981));
    } catch (e) {
      print('Error deleting leave request: $e');
      if (!mounted) return;
      _showSnackBar('Failed to delete leave request. Please try again.', Colors.red);
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, String docId, Map<String, dynamic> leaveData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Delete Leave Request?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete this leave request?',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leave Type: ${leaveData['leavetype'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Duration: ${leaveData['startdate'] ?? 'N/A'} - ${leaveData['enddate'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.orange.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.orange.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'You can apply for leave again after deletion.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteLeaveRequest(docId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addToFirestore() async {
    // Reset validation flags
    setState(() {
      showLeaveTypeError = false;
      showReasonError = false;
      showStartDateError = false;
      showEndDateError = false;
    });

    // Check if user has already applied today
    if (hasAppliedToday) {
      _showSnackBar(
        'You have already applied for leave today. Please apply tomorrow.',
        Colors.orange,
      );
      return;
    }

    bool hasError = false;

    // Validate Leave Type
    if (selectedLeaveinfo == 'Leave Type') {
      setState(() => showLeaveTypeError = true);
      hasError = true;
    }

    // Validate Start Date
    if (startdateController.text.trim().isEmpty) {
      setState(() => showStartDateError = true);
      hasError = true;
    }

    // Validate End Date
    if (enddateController.text.trim().isEmpty) {
      setState(() => showEndDateError = true);
      hasError = true;
    }

    // Validate Reason
    if (reasonController.text.trim().isEmpty) {
      setState(() => showReasonError = true);
      hasError = true;
    }

    if (hasError) {
      _showSnackBar('Please fill all required fields correctly', Colors.red);
      return;
    }

    if (!_validateFields()) {
      _showSnackBar('All fields must be filled.', Colors.red);
      return;
    }

    String? emailError = _validateEmail(empemailidController.text.trim());
    if (emailError != null) {
      _showSnackBar(emailError, Colors.red);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        throw Exception("User not logged in");
      }

      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection('Empleave')
          .where('empid', isEqualTo: empIdController.text.trim())
          .where('name', isEqualTo: empNameController.text.trim())
          .where('emailid', isEqualTo: empemailidController.text.trim())
          .where('startdate', isEqualTo: _formatDate(startdate!))
          .where('enddate', isEqualTo: _formatDate(enddate!))
          .where('reason', isEqualTo: reasonController.text.trim())
          .where('userId', isEqualTo: userId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        if (!mounted) return;
        _showSnackBar('Leave request already exists.', Colors.orange);
      } else {
        await _firestore.collection('Empleave').add({
          'empid': empIdController.text.trim(),
          'name': empNameController.text.trim(),
          'emailid': empemailidController.text.trim(),
          'leavetype': selectedLeaveinfo,
          'startdate': _formatDate(startdate!),
          'enddate': _formatDate(enddate!),
          'reason': reasonController.text.trim(),
          'status': 'Pending',
          'reportedDateTime': FieldValue.serverTimestamp(),
          'userId': userId,
        });

        await _sendEmail();

        if (!mounted) return;

        setState(() {
          startdateController.clear();
          enddateController.clear();
          reasonController.clear();
          selectedLeaveinfo = 'Leave Type';
          startdate = null;
          enddate = null;
          showLeaveTypeError = false;
          showReasonError = false;
          showStartDateError = false;
          showEndDateError = false;
        });

        // Refresh applied leaves
        await _fetchAppliedLeaves();

        _showSnackBar('Leave request submitted successfully!', const Color(0xFF10B981));
      }
    } catch (e) {
      print('Error adding data to Firestore: $e');
      if (!mounted) return;
      _showSnackBar('Failed to add data. Please try again.', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _sendEmail() async {
    final userEmail = empemailidController.text.trim();
    String username = "manthanpatel26510@gmail.com";
    String appSpecificPassword = "uqvcfqumgbynnpzq";

    final smtpServer = gmail(username, appSpecificPassword);
    DateTime now = DateTime.now();
    String formattedDateTime = DateFormat('dd-MM-yyyy hh:mm:ss a').format(now);
    final message = Message()
      ..from = Address(userEmail, empNameController.text.trim())
      ..recipients.add('Deep6796@gmail.com')
      ..subject = 'New Leave Request'
      ..text = 'Leave Request Details:\n'
          'Empid:${empIdController.text.trim()}\n'
          'Name: ${empNameController.text.trim()}\n'
          'Empemailid: ${empemailidController.text.trim()}\n'
          'Leave Type: ${selectedLeaveinfo}\n'
          'Start Date: ${startdateController.text.trim()}\n'
          'End Date: ${enddateController.text.trim()}\n'
          'Reason: ${reasonController.text.trim()}\n'
          'reportedDateTime: $formattedDateTime';

    try {
      print('Sending email...');
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('Message not sent. \n' + e.toString());
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    } catch (e) {
      print('Unexpected error: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, {required bool isStart}) async {
    final DateTime today = DateTime.now();
    final DateTime onlyDate = DateTime(today.year, today.month, today.day);

    // Calculate initial date
    DateTime tempInitialDate = isStart
        ? (startdate ?? onlyDate)
        : (enddate ?? (startdate ?? onlyDate));

    // Find next available date if initial date is disabled
    DateTime initialDate = tempInitialDate;
    String initialDateStr = DateFormat('dd/MM/yyyy').format(initialDate);

    // If the initial date is disabled, find the next available date
    if (appliedLeaveDates.contains(initialDateStr)) {
      DateTime searchDate = initialDate;
      bool foundAvailable = false;

      // Search for next 365 days
      for (int i = 0; i < 365; i++) {
        searchDate = searchDate.add(Duration(days: 1));
        String searchDateStr = DateFormat('dd/MM/yyyy').format(searchDate);

        if (!appliedLeaveDates.contains(searchDateStr)) {
          initialDate = searchDate;
          foundAvailable = true;
          break;
        }
      }

      // If no available date found in future, search backwards from today
      if (!foundAvailable) {
        searchDate = onlyDate;
        if (!appliedLeaveDates.contains(DateFormat('dd/MM/yyyy').format(searchDate))) {
          initialDate = searchDate;
        }
      }
    }

    DateTime firstDate = isStart
        ? onlyDate
        : (startdate ?? onlyDate);

    DateTime lastDate = isStart
        ? (enddate ?? DateTime(2101))
        : DateTime(2101);

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: (DateTime date) {
        // Disable dates that already have leave applied
        String dateStr = DateFormat('dd/MM/yyyy').format(date);
        return !appliedLeaveDates.contains(dateStr);
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E3A8A),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (isStart && enddate != null && pickedDate.isAfter(enddate!)) {
        _showValidationDialog(context, "Start date cannot be after End date.");
        return;
      }

      if (!isStart && startdate != null && pickedDate.isBefore(startdate!)) {
        _showValidationDialog(context, "End date cannot be before Start date.");
        return;
      }

      setState(() {
        if (isStart) {
          startdate = pickedDate;
          startdateController.text = _formatDate(pickedDate);
          showStartDateError = false;
        } else {
          enddate = pickedDate;
          enddateController.text = _formatDate(pickedDate);
          showEndDateError = false;
        }
      });
    }
  }

  void _showValidationDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text("Invalid Selection"),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  bool _validateFields() {
    return empNameController.text.trim().isNotEmpty &&
        empemailidController.text.trim().isNotEmpty &&
        startdateController.text.trim().isNotEmpty &&
        enddateController.text.trim().isNotEmpty &&
        reasonController.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text(
          "Leave Request",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1E3A8A),
                        const Color(0xFF1E40AF),
                        const Color(0xFF2563EB),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3A8A).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.edit_document,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Apply for Leave',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Fill in the details below',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                buildLeaveFields(),
                const SizedBox(height: 24),
                _buildSubmitButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: Color(0xFF1E3A8A),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Your Leave History",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Color(0xFF1F2937),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildLeaveData(),
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }

  Widget buildLeaveFields() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPremiumField(
            controller: empIdController,
            labelText: 'Employee ID',
            icon: Icons.badge_outlined,
            readOnly: empIdController.text.isNotEmpty,
          ),
          const SizedBox(height: 16),
          _buildPremiumField(
            controller: empNameController,
            labelText: 'Full Name',
            icon: Icons.person_outline_rounded,
            readOnly: empNameController.text.isNotEmpty,
          ),
          const SizedBox(height: 16),
          _buildPremiumField(
            controller: empemailidController,
            labelText: 'Email Address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            readOnly: empemailidController.text.isNotEmpty,
          ),
          const SizedBox(height: 16),
          _buildPremiumDropdown(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPremiumField(
                  controller: startdateController,
                  labelText: "Start Date",
                  icon: Icons.calendar_today_outlined,
                  readOnly: true,
                  onTap: () => _selectDate(context, isStart: true),
                  hasError: showStartDateError,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPremiumField(
                  controller: enddateController,
                  labelText: "End Date",
                  icon: Icons.event_outlined,
                  readOnly: true,
                  onTap: () => _selectDate(context, isStart: false),
                  hasError: showEndDateError,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPremiumField(
            controller: reasonController,
            labelText: "Reason for Leave",
            icon: Icons.description_outlined,
            maxLines: 4,
            hintText: "Please describe your reason...",
            hasError: showReasonError,
            onChanged: (value) {
              if (showReasonError && value.isNotEmpty) {
                setState(() => showReasonError = false);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
    String? hintText,
    TextInputType? keyboardType,
    bool hasError = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: hasError ? Colors.red : Colors.grey.shade700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? Colors.red : Colors.grey.shade200,
              width: hasError ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: hasError ? Colors.red : const Color(0xFF1E3A8A),
                size: 20,
              ),
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Leave Type',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: showLeaveTypeError ? Colors.red : Colors.grey.shade700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: showLeaveTypeError ? Colors.red : Colors.grey.shade200,
              width: showLeaveTypeError ? 2 : 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: selectedLeaveinfo,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.category_outlined,
                color: showLeaveTypeError ? Colors.red : const Color(0xFF1E3A8A),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            dropdownColor: Colors.white,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade700),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
            items: leaveinfo
                .map((item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            ))
                .toList(),
            onChanged: (item) {
              setState(() {
                selectedLeaveinfo = item;
                if (showLeaveTypeError && item != 'Leave Type') {
                  showLeaveTypeError = false;
                }
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: isLoading ? null : _addToFirestore,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            shadowColor: const Color(0xFF1E3A8A).withOpacity(0.3),
          ),
          child: isLoading
              ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          )
              : const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.send_rounded, size: 20),
              SizedBox(width: 8),
              Text(
                "Submit Leave Request",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveData() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('Empleave')
          .orderBy('reportedDateTime', descending: true)
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Error: ${snapshot.error}'),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.folder_open_rounded,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No leave requests yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final leaveDocs = snapshot.data!.docs;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final leave = leaveDocs[index].data();
              final docId = leaveDocs[index].id;
              final status = leave['status'] ?? 'pending';
              final reportedDateTime = leave['reportedDateTime'];

              Color statusColor;
              IconData statusIcon;
              switch (status.toLowerCase()) {
                case 'approved':
                  statusColor = const Color(0xFF10B981);
                  statusIcon = Icons.check_circle_rounded;
                  break;
                case 'pending':
                  statusColor = const Color(0xFFF59E0B);
                  statusIcon = Icons.access_time_rounded;
                  break;
                default:
                  statusColor = const Color(0xFFEF4444);
                  statusIcon = Icons.cancel_rounded;
              }

              return Dismissible(
                key: Key(docId),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  // Show confirmation dialog
                  _showDeleteConfirmationDialog(context, docId, leave);
                  return false; // Return false to prevent auto-dismiss
                },
                background: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delete_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1E3A8A),
                        const Color(0xFF1E40AF),
                        const Color(0xFF2563EB),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3A8A).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Colors.white.withOpacity(0.4),
                            width: 5,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Request #${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: statusColor.withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(statusIcon, color: statusColor, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        status[0].toUpperCase() + status.substring(1),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildLeaveInfoRow(
                              Icons.badge_outlined,
                              'Employee ID',
                              leave['empid'] ?? 'N/A',
                            ),
                            const SizedBox(height: 14),
                            _buildLeaveInfoRow(
                              Icons.person_outline_rounded,
                              'Name',
                              leave['name'] ?? 'N/A',
                            ),
                            const SizedBox(height: 14),
                            _buildLeaveInfoRow(
                              Icons.email_outlined,
                              'Email',
                              leave['emailid'] ?? 'N/A',
                            ),
                            const SizedBox(height: 14),
                            _buildLeaveInfoRow(
                              Icons.category_outlined,
                              'Leave Type',
                              leave['leavetype'] ?? 'N/A',
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today_outlined,
                                              size: 14,
                                              color: Colors.cyan.shade200,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Start Date',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white.withOpacity(0.8),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          leave['startdate'] ?? 'N/A',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.event_outlined,
                                                size: 14,
                                                color: Colors.cyan.shade200,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'End Date',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white.withOpacity(0.8),
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            leave['enddate'] ?? 'N/A',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.description_outlined,
                                        size: 14,
                                        color: Colors.cyan.shade200,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Reason',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white.withOpacity(0.8),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    leave['reason'] ?? 'No reason provided',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 13, color: Colors.cyan.shade200),
                                    const SizedBox(width: 6),
                                    Text(
                                      reportedDateTime != null
                                          ? 'Reported: ${DateFormat('dd MMM yyyy, hh:mm a').format(reportedDateTime.toDate())}'
                                          : 'Reported: N/A',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withOpacity(0.7),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.swipe_left_rounded,
                                  size: 18,
                                  color: Colors.white.withOpacity(0.5),
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
            childCount: leaveDocs.length,
          ),
        );
      },
    );
  }

  Widget _buildLeaveInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.cyan.shade300),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}