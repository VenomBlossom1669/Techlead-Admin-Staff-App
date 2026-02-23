import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'Appoinments/Appointments_Calendar.dart';


class FirestoreService {
  final CollectionReference _meetingsCollection =
  FirebaseFirestore.instance.collection('meetings');

  // Add new meeting to Firestore
  Future<void> addMeeting(MyAppointments appointment) async {
    await _meetingsCollection.add({
      'subject': appointment.subject,
      'startTime': appointment.startTime,
      'endTime': appointment.endTime,
      'location': appointment.location ?? '',
      'notes': appointment.purpose ?? '',
      'color': appointment.color.value,
      'resourceIds': appointment.resourceIds,
      'adminId': appointment.adminId,
      'createdBy': appointment.adminId, // 👈 store ID of admin
      'createdByName': appointment.createdBy, // 👈 optional, if you already know display name
      'createdAt': FieldValue.serverTimestamp(),
    });
  }


  Future<List<MyAppointments>> fetchMeetings() async {
    try {
      final querySnapshot = await _meetingsCollection.get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Prefer startTime / endTime if present, else fallback
        DateTime startTime;
        if (data['startTime'] is Timestamp) {
          startTime = (data['startTime'] as Timestamp).toDate();
        } else if (data['startTime'] is String) {
          startTime = DateTime.tryParse(data['startTime']) ?? DateTime.now();
        } else {
          startTime = DateTime.now();
        }

        DateTime endTime;
        if (data['endTime'] is Timestamp) {
          endTime = (data['endTime'] as Timestamp).toDate();
        } else if (data['endTime'] is String) {
          endTime = DateTime.tryParse(data['endTime']) ?? startTime.add(Duration(hours: 1));
        } else {
          endTime = startTime.add(Duration(hours: 1));
        }

        // Read IDs
        final String adminId = (data['adminId'] ?? '') as String;
        final String? createdBy = data['createdBy']?.toString();
        final String? createdByName = data['createdByName']?.toString();

        return MyAppointments(
          id: doc.id,
          subject: (data['subject'] ?? '').toString(),
          startTime: startTime,
          endTime: endTime,
          location: data['location']?.toString(),
          purpose: (data['purpose'] ?? data['notes'] ?? '').toString(),
          color: Color((data['color'] is int) ? data['color'] : 0xFF6A5AE0),
          resourceIds: List<String>.from(data['resourceIds'] ?? []),
          adminId: adminId,
          createdBy: createdByName ?? createdBy, // 👈 keep name if available
        );
      }).toList();
    } catch (e) {
      print('Error fetching meetings: $e');
      throw Exception('Failed to load meetings: $e');
    }
  }


// Add this helper method to parse the date strings from your database
  DateTime _parseFirestoreDate(String dateString) {
    try {
      // Remove "UTC+5:30" part
      String cleanedDate = dateString.replaceAll(
          RegExp(r' UTC[+-]\d{1,2}:\d{2}'), '');

      final months = {
        'January': '01', 'February': '02', 'March': '03', 'April': '04',
        'May': '05', 'June': '06', 'July': '07', 'August': '08',
        'September': '09', 'October': '10', 'November': '11', 'December': '12'
      };

      // Parse "September 20, 2025 at 9:00:00 AM"
      final regex = RegExp(
          r'(\w+) (\d{1,2}), (\d{4}) at (\d{1,2}):(\d{2}):(\d{2}) (AM|PM)');
      final match = regex.firstMatch(cleanedDate);

      if (match != null) {
        final monthName = match.group(1)!;
        final day = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        int hour = int.parse(match.group(4)!);
        final minute = int.parse(match.group(5)!);
        final second = int.parse(match.group(6)!);
        final amPm = match.group(7)!;

        // Convert to 24-hour format
        if (amPm == 'PM' && hour != 12) {
          hour += 12;
        } else if (amPm == 'AM' && hour == 12) {
          hour = 0;
        }

        final monthNumber = months[monthName];
        if (monthNumber != null) {
          return DateTime(
              year, int.parse(monthNumber), day, hour, minute, second);
        }
      }

      return DateTime.now(); // fallback
    } catch (e) {
      print('Error parsing date: $dateString');
      return DateTime.now();
    }
  }
}

