import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class TaskAssignment {
  final String adminId;
  final String adminName;
  final DateTime date;
  final DateTime deadlineDate;
  final String department;
  final String employeeDescription;
  final String taskDescription;
  final String taskstatus;

  TaskAssignment({
    required this.adminId,
    required this.adminName,
    required this.date,
    required this.deadlineDate,
    required this.department,
    required this.employeeDescription,
    required this.taskDescription,
    required this.taskstatus,
  });

  factory TaskAssignment.fromMap(Map<String, dynamic> data) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      } else {
        throw FormatException("Invalid date format");
      }
    }

    return TaskAssignment(
      adminId: data['adminId'] ?? '',
      adminName: data['adminName'] ?? '',
      date: parseDate(data['date']),
      deadlineDate: parseDate(data['deadlineDate']),
      department: data['department'] ?? '',
      employeeDescription: data['employeeDescription'] ?? '',
      taskDescription: data['taskDescription'] ?? '',
      taskstatus: data['taskstatus'] ?? '',
    );
  }

}


// Syncfusion calendar appointments data source
class TaskDataSource extends CalendarDataSource {
  TaskDataSource(List<Appointment> source) {
    appointments = source;
  }
}
