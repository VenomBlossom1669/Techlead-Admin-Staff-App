import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyAppointments {
  final String id;
  final String subject;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? purpose;   // renamed or alias for notes
  final Color color;
  final List<String> resourceIds;
  final String adminId;        // uid of admin who created/owns
  final String? createdBy;     // display name of admin (optional)

  MyAppointments({
    required this.id,
    required this.subject,
    required this.startTime,
    required this.endTime,
    this.location,
    this.purpose,
    required this.color,
    this.resourceIds = const [],
    required this.adminId,
    this.createdBy,
  });

  factory MyAppointments.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    // parsing helpers (robust to Timestamp or ISO string)
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    return MyAppointments(
      id: doc.id,
      subject: data['subject'] ?? '',
      startTime: parseDate(data['startTime']),
      endTime: parseDate(data['endTime']),
      location: data['location'] as String?,
      purpose: (data['purpose'] ?? data['notes']) as String?,
      color: Color((data['color'] ?? 0xFF6A5AE0) is int
          ? (data['color'] as int)
          : int.tryParse((data['color'] ?? '0xFF6A5AE0').toString()) ?? 0xFF6A5AE0),
      resourceIds: List<String>.from(data['resourceIds'] ?? []),
      adminId: (data['adminId'] ?? '') as String,
      // prefer explicit stored display name fields if present
      createdBy: (data['createdByName'] ?? data['createdBy'] ?? data['adminName']) as String?,
    );
  }

  set adminName(String? adminName) {}

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'purpose': purpose,
      'color': color.value,
      'resourceIds': resourceIds,
      'adminId': adminId,
      'createdByName': createdBy,
    };
  }
}
