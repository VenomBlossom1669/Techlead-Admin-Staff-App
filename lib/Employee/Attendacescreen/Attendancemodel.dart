import 'package:flutter/material.dart';
class AttendanceRecord {
  String? id;
  String? employeeName;
  String? department;
  String? date;
  String? checkIn;
  String? checkInLocation;
  String? checkOut;
  String? checkOutLocation;
  String? status;
  String? record;

  AttendanceRecord({
    this.id,
    this.employeeName,
    this.department,
    this.date,
    this.checkIn,
    this.checkInLocation,
    this.checkOut,
    this.checkOutLocation,
    this.status,
    this.record,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> data, String documentId) {
    return AttendanceRecord(
      id: documentId,
      employeeName: data['employeeName']?.toString(),
      department: data['department']?.toString(),
      date: data['date']?.toString(),
      checkIn: data['checkIn']?.toString(),
      checkInLocation: data['checkInLocation']?.toString(),
      checkOut: data['checkOut']?.toString(),
      checkOutLocation: data['checkOutLocation']?.toString(),
      status: data['status']?.toString(),
      record: data['record']?.toString(),
    );
  }
}
