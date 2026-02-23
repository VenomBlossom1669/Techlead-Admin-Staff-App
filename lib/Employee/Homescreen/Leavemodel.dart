import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveModel {
  final String documentId;
  final String empid;
  final String name;
  final String emailid;
  final String leavetype;
  final String startdate;
  final String enddate;
  final String reason;
  final String status;
  final Timestamp reportedDateTime;

  LeaveModel({
    required this.documentId,
    required this.empid,
    required this.name,
    required this.emailid,
    required this.leavetype,
    required this.startdate,
    required this.enddate,
    required this.reason,
    required this.status,
    required this.reportedDateTime,
  });

  factory LeaveModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaveModel(
        documentId: doc.id,
        empid: data['empid'],
        name: data['name'] ?? '',
        emailid: data['emailid'] ?? '',
        leavetype: data['leavetype'] ?? '',
        startdate: data['startdate'] ?? '',
        enddate: data['enddate'] ?? '',
        reason: data['reason'] ?? '',
        status: data['status'] ?? '',
        reportedDateTime: data['reportedDateTime']
    );
  }
}
