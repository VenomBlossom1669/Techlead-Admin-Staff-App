import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget buildGradientTimePicker(
    BuildContext context,
    TimeOfDay selectedTime, {
      required Function(TimeOfDay) onTimeSelected,
      TimeOfDay? minTime, // optional minimum time
    }) {

  DateTime initialDateTime = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
    selectedTime.hour,
    selectedTime.minute,
  );

  DateTime? minDateTime;
  if (minTime != null) {
    minDateTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      minTime.hour,
      minTime.minute,
    );
  }

  return Container(
    padding: const EdgeInsets.all(12),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF000F89), Color(0xFF0F52BA), Color(0xFF002147)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    height: 280,
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Select Time',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
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
              mode: CupertinoDatePickerMode.time,
              initialDateTime: initialDateTime,
              use24hFormat: false,
              onDateTimeChanged: (DateTime newDateTime) {
                // 🔹 Block time before minTime
                if (minDateTime != null && newDateTime.isBefore(minDateTime)) return;

                onTimeSelected(TimeOfDay.fromDateTime(newDateTime));
              },
            ),
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
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
      ],
    ),
  );
}
