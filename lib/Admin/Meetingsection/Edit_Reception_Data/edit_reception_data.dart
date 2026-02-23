import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../Employee/Homescreen/Date_And_Time_Code/Customize_Date_001.dart';
import '../../../Employee/Homescreen/Date_And_Time_Code/Customize_Time_001.dart';

class Editreceptionpage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> initialData;

  Editreceptionpage({required this.docId, required this.initialData});

  @override
  _EditreceptionpageState createState() => _EditreceptionpageState();


}



class _EditreceptionpageState extends State<Editreceptionpage> {

  final _formKey = GlobalKey<FormState>();
  late String fullName, contactNumber,Whatsappnumber, email, preferredContactMethod, clientmeetingstatus,leadSource, leadType,taskstatus,meetingcstatus, propertyType, propertySize, currentHomeAutomation, budgetRange, additionalDetails;
  DateTime? selectedAppointmentDate;
  TimeOfDay? selectedAppointmentTime;
  DateTime? selectedTaskDueDate;

  final FocusNode meetingPurposeFocus = FocusNode();
  final FocusNode meetingLocationFocus = FocusNode();
  final FocusNode assignedStaffFocus = FocusNode();
  final FocusNode dateFocus = FocusNode();
  final FocusNode appointmentTimeFocus = FocusNode();
  final FocusNode nextFieldFocus = FocusNode();
  final FocusNode taskPriorityFocus = FocusNode();
  final FocusNode clientmeetingfocus = FocusNode();
  @override
  void dispose() {
    meetingPurposeFocus.dispose();
    meetingLocationFocus.dispose();
    assignedStaffFocus.dispose();
    taskPriorityFocus.dispose();
    clientmeetingfocus.dispose();
    super.dispose();
  }



  final List<Map<String, dynamic>> meetingPurposes = [

    {'text': 'Initial Consultation', 'icon': FontAwesomeIcons.handshake},
    {'text': 'Installation Request', 'icon': FontAwesomeIcons.cogs},
    {'text': 'Service Inquiry', 'icon': FontAwesomeIcons.questionCircle},
    {'text': 'System Upgrade', 'icon': FontAwesomeIcons.arrowUp},
    {'text': 'Troubleshooting', 'icon': FontAwesomeIcons.tools},
    {'text': 'Home Automation \n Advice', 'icon': FontAwesomeIcons.lightbulb},
    {'text': 'Smart Home \n Integration', 'icon': FontAwesomeIcons.networkWired},
    {'text': 'Maintenance Request', 'icon': FontAwesomeIcons.wrench},
    {'text': 'Security System Setup', 'icon': FontAwesomeIcons.shieldAlt},
    {'text': 'Energy Efficiency \n Consultation', 'icon': FontAwesomeIcons.solarPanel},
    {'text': 'Product Demonstration', 'icon': FontAwesomeIcons.tv},
    {'text': 'Follow-Up on Services', 'icon': FontAwesomeIcons.userMd},
    {'text': 'Client Training Session', 'icon': FontAwesomeIcons.chalkboardTeacher},
    {'text': 'Custom Solutions \n Discussion', 'icon': FontAwesomeIcons.cogs},
    {'text': 'Troubleshooting Follow-Up', 'icon': FontAwesomeIcons.bug},

  ];


  final List<Map<String, dynamic>> taskstatusupdated = [
    {'text': 'Pending', 'icon': FontAwesomeIcons.hourglassHalf},
    {'text': 'In Progress', 'icon': FontAwesomeIcons.spinner},
    {'text': 'Completed', 'icon': FontAwesomeIcons.checkCircle},
  ];

  final List<Map<String, dynamic>> clientmeetingstatusfinal = [
    {'text': 'Scheduled', 'icon': FontAwesomeIcons.calendarCheck},
    {'text': 'Completed', 'icon': FontAwesomeIcons.checkCircle},
    {'text': 'Cancelled', 'icon': FontAwesomeIcons.timesCircle},
  ];

  List<Map<String, dynamic>> staffList = [];
  final List<Map<String, dynamic>> taskPriorities = [
    {'text': 'High', 'icon': FontAwesomeIcons.exclamationCircle},
    {'text': 'Medium', 'icon': FontAwesomeIcons.exclamationTriangle},
    {'text': 'Low', 'icon': FontAwesomeIcons.circle},
  ];

  void _showDatePicker(BuildContext context, DateTime initialDate, Function(DateTime) onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => buildGradientCalendar(context, initialDate, onSelected),
    );
  }
  void _showTimePicker(
      BuildContext context,
      TimeOfDay initialTime,
      Function(TimeOfDay) onSelected, {
        TimeOfDay? minTime,
      }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => buildGradientTimePicker(
        context,
        initialTime,
        onTimeSelected: onSelected,
        minTime: minTime,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchStaffList();
    fullName = widget.initialData['client_name'] ?? '';
    contactNumber = widget.initialData['phone_number'] ?? '';
    Whatsappnumber = widget.initialData['whatsaapp_number'] ?? '';
    email = widget.initialData['appointment_date'] ?? '';
    preferredContactMethod = widget.initialData['appointment_time'] ?? '';
    leadSource = widget.initialData['meeting_purpose'] ?? meetingPurposes[0]['text'];
    propertySize = widget.initialData['location'] ?? '';
    currentHomeAutomation = widget.initialData['assigned_staff'] ?? staffList[0]['text'];
    budgetRange = widget.initialData['task_priority'] ?? taskPriorities[0]['text'];
    additionalDetails = widget.initialData['task_due_date'] ?? taskstatusupdated[0]['text'];
    taskstatus = widget.initialData['task_status'] ?? '';
    clientmeetingstatus = widget.initialData['client_meeting_status'] ?? clientmeetingstatusfinal[0]['text'];
    selectedAppointmentDate = DateTime.tryParse(widget.initialData['appointment_date'] ?? '') ?? DateTime.now();
    selectedAppointmentTime = TimeOfDay(
      hour: int.tryParse(widget.initialData['appointment_time']?.split(":")[0] ?? '9') ?? 9,
      minute: int.tryParse(widget.initialData['appointment_time']?.split(":")[1] ?? '0') ?? 0,
    );
    selectedTaskDueDate = DateTime.tryParse(widget.initialData['task_due_date'] ?? '') ?? DateTime.now();

  }

  Future<void> _fetchStaffList() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Admin_Profiles')
          .get();

      setState(() {
        staffList = snapshot.docs.map((doc) {
          return {
            'text': doc['name'] ?? 'Unknown',
            'icon': FontAwesomeIcons.userTie, // default icon
          };
        }).toList();
      });
    } catch (e) {
      print("❌ Error fetching staff list: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              FontAwesomeIcons.penNib,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Text(
              "Edit Reception Page",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
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
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A2A5A), // Deep navy blue
                  Color(0xFF15489C), // Strong steel blue
                  Color(0xFF1E64D8), // Vivid rich blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 100),
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          buildTextFormField('Client Full Name', fullName, Icons.person, (value) => fullName = value, validator: (value) => value == null || value.isEmpty ? 'Please enter client name' : null,),
                          buildTextFormField(
                            'Contact Number',
                            contactNumber,
                            Icons.phone,
                                (value) => contactNumber = value,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(10),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter contact number';
                              if (!RegExp(r'^\d{10}$').hasMatch(value)) return 'Enter 10-digit contact number';
                              return null;
                            },
                          ),
                          buildTextFormField(
                            'Whatsapp Number',
                            Whatsappnumber,
                            Icons.phone_android,
                                (value) => Whatsappnumber = value,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(10),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter whatsapp number';
                              if (!RegExp(r'^\d{10}$').hasMatch(value)) return 'Enter 10-digit whatsapp number';
                              return null;
                            },
                          ),
                          buildDateTimeSelector(
                            label: 'Appointment Date',
                            displayValue: selectedAppointmentDate != null
                                ? "${selectedAppointmentDate!.day.toString().padLeft(2, '0')}/"
                                "${selectedAppointmentDate!.month.toString().padLeft(2, '0')}/"
                                "${selectedAppointmentDate!.year}"
                                : 'Select Date',
                            icon: Icons.calendar_today,
                            onTap: () => _showDatePicker(
                              context,
                              selectedAppointmentDate ?? DateTime.now(),
                                  (picked) {
                                setState(() {
                                  selectedAppointmentDate = picked;
                                });
                              },
                            ),
                          ),

                          buildDateTimeSelector(
                            label: 'Appointment Time',
                            displayValue: selectedAppointmentTime != null
                                ? selectedAppointmentTime!.format(context)
                                : 'Select Time',
                            icon: Icons.access_time,
                            onTap: () => _showTimePicker(
                              context,
                              selectedAppointmentTime ?? TimeOfDay.now(),
                                  (picked) {
                                setState(() {
                                  selectedAppointmentTime = picked;
                                });
                              },
                              minTime: TimeOfDay.now(), // 🔹 Set minimum selectable time
                            ),
                            currentFocus: appointmentTimeFocus,
                            nextFocus: nextFieldFocus,
                          ),


                          buildDropdownField(
                            'Meeting Purpose',
                            leadSource,
                            FontAwesomeIcons.user,
                            meetingPurposes,
                                (newValue) => setState(() => leadSource = newValue!),
                            validator: (value) =>
                            value == null || value.isEmpty ? 'Please select a meeting purpose' : null,
                            currentFocus: meetingPurposeFocus,
                            nextFocus: meetingLocationFocus,
                          ),
                          buildTextFormField('Meeting Location', propertySize, Icons.location_on_outlined, (value) => propertySize = value,  validator: (value) {
                            if (value == null || value.isEmpty) return 'Meeting Location';
                            return null;
                          },),
                          buildDropdownField(
                            'Assigned Staff/CEO',
                            currentHomeAutomation,
                            Icons.square_foot,
                            staffList,
                                (newValue) => setState(() => currentHomeAutomation = newValue!),
                            validator: (value) =>
                            value == null || value.isEmpty ? 'Please select a staff/CEO' : null,
                            currentFocus: assignedStaffFocus,
                            nextFocus: taskPriorityFocus,
                          ),

                          buildDropdownField(
                            'Task Priority',
                            budgetRange,
                            FontAwesomeIcons.cogs,
                            taskPriorities,
                                (newValue) => setState(() => budgetRange = newValue!),
                            validator: (value) =>
                            value == null || value.isEmpty ? 'Please select task priority' : null,
                            currentFocus: taskPriorityFocus,
                          ),
                          buildDateTimeSelector(
                            label: 'Task Due Date',
                            displayValue: selectedTaskDueDate != null
                                ? "${selectedTaskDueDate!.day.toString().padLeft(2, '0')}/"
                                "${selectedTaskDueDate!.month.toString().padLeft(2, '0')}/"
                                "${selectedTaskDueDate!.year}"
                                : 'Select Date',
                            icon: Icons.calendar_today,
                            onTap: () => _showDatePicker(
                              context,
                              selectedTaskDueDate ?? DateTime.now(),
                                  (picked) {
                                setState(() {
                                  selectedTaskDueDate = picked;
                                });
                              },
                            ),
                            currentFocus: dateFocus,
                            nextFocus: nextFieldFocus,
                          ),

                          buildDropdownField(
                            'Task Status',
                            taskstatus,
                            Icons.details,
                            taskstatusupdated,
                                (newValue) => setState(() => taskstatus = newValue!),
                            validator: (value) =>
                            value == null || value.isEmpty ? 'Please select task status' : null,
                          ),
                          buildDropdownField(
                            'Client Meeting Status',
                            clientmeetingstatus,
                            Icons.details,
                            clientmeetingstatusfinal,
                                (newValue) => setState(() => clientmeetingstatus = newValue!),
                            validator: (value) =>
                            value == null || value.isEmpty ? 'Please select client meeting status' : null,
                            currentFocus: clientmeetingfocus,
                          ),

                          SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 12),
                              child: ElevatedButton(
                                onPressed: _updateRecord,
                                child: Text(
                                  'Update',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  backgroundColor: Colors.blue.shade900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _updateRecord,
        backgroundColor: Colors.blue.shade900,
        child: Icon(Icons.save, size: 30, color: Colors.white),
      ),
    );
  }

  Widget buildDropdownField(
      String label,
      String value,
      IconData icon,
      List<Map<String, dynamic>> items,
      ValueChanged<String?> onChanged, {
        String? Function(String?)? validator,
        FocusNode? currentFocus,
        FocusNode? nextFocus,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF02274C),
            ),
          ),
          const SizedBox(height: 6),
          Theme(
            data: Theme.of(context).copyWith(
              canvasColor: const Color(0xFF0A2A5A),
            ),
            child: Focus(
              focusNode: currentFocus,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: items.any((item) => item['text'] == value) ? value : null,
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, color: Colors.cyanAccent),
                  filled: true,
                  fillColor: const Color(0xFF0A2A5A),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                dropdownColor: const Color(0xFF0A2A5A),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                onChanged: (val) {
                  onChanged(val);
                  if (nextFocus != null && currentFocus?.context != null) {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      FocusScope.of(currentFocus!.context!).requestFocus(nextFocus);
                    });
                  }
                },
                validator: validator,
                items: items.map<DropdownMenuItem<String>>((item) {
                  return DropdownMenuItem<String>(
                    value: item['text'],
                    child: Row(
                      children: [
                        Icon(item['icon'], color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['text'],
                            softWrap: true,
                            overflow: TextOverflow.visible,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextFormField(
      String label,
      String initialValue,
      IconData icon,
      Function(String) onChanged, {
        String? Function(String?)? validator,
        List<TextInputFormatter>? inputFormatters,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF02274C),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: initialValue,
            textInputAction: TextInputAction.next,
            onEditingComplete: () => FocusScope.of(context).nextFocus(),
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.cyanAccent),
              filled: true,
              fillColor: const Color(0xFF0A2A5A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white24),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.cyanAccent, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: onChanged,
            validator: validator,
            inputFormatters: inputFormatters,
          ),
        ],
      ),
    );
  }


  // Update the record in Firestore
  void _updateRecord() async {
    if (_formKey.currentState!.validate()) {
      if (selectedAppointmentDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Select Appointment Date",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (selectedAppointmentTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Select Appointment Time",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (selectedTaskDueDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Select Task Due Date",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

    try {
        await FirebaseFirestore.instance.collection('ReceptionPage').doc(widget.docId).update({
          'client_name': fullName,
          'phone_number': contactNumber,
          'whatsaapp_number':Whatsappnumber,
          'appointment_date': selectedAppointmentDate?.toIso8601String().split('T').first ?? '',
          'appointment_time': selectedAppointmentTime?.format(context) ?? '',
          'meeting_purpose': leadSource,
          'location': propertySize,
          'assigned_staff': currentHomeAutomation,
          'task_priority': budgetRange,
          'task_due_date': selectedTaskDueDate?.toIso8601String().split('T').first ?? '',
          'task_status': taskstatus,
          'client_meeting_status': clientmeetingstatus,
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Reception Record updated successfully'),
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error updating record: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }
}

Widget buildDateTimeSelector({
  required String label,
  required String displayValue,
  required IconData icon,
  required VoidCallback onTap,
  FocusNode? currentFocus,
  FocusNode? nextFocus,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF02274C),
          ),
        ),
        const SizedBox(height: 6),
        Focus(
          focusNode: currentFocus,
          child: InkWell(
            onTap: () {
              onTap();
              // Move to next focus node after tap if provided
              if (nextFocus != null && currentFocus?.context != null) {
                Future.delayed(const Duration(milliseconds: 150), () {
                  FocusScope.of(currentFocus!.context!).requestFocus(nextFocus);
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0A2A5A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.cyanAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      displayValue.isEmpty ? 'Required *' : displayValue,
                      style: GoogleFonts.poppins(
                        color: displayValue.isEmpty
                            ? Colors.redAccent
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
