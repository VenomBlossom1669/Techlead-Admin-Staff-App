import 'package:cloud_firestore/cloud_firestore.dart';

class GuidelinesModel {
  final String id; // <-- Add this field
  final String headlines;
  final String guidelines;
  final String contactus;
  final Timestamp reportedDateTime;

  GuidelinesModel({
    required this.id,
    required this.headlines,
    required this.guidelines,
    required this.contactus,
    required this.reportedDateTime,
  });

  factory GuidelinesModel.fromSnapshot(DocumentSnapshot snapshot) {
    return GuidelinesModel(
      id: snapshot.id, // <-- Capture document ID
      headlines: snapshot['headlines'],
      guidelines: snapshot['guidelines'],
      contactus: snapshot['contactus'],
      reportedDateTime: snapshot['reportedDateTime'],
    );
  }
}