import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

Widget buildGradientCalendar(BuildContext context, DateTime selectedDate, Function(DateTime) onDateSelected) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFF000F89),
          Color(0xFF0F52BA),
          Color(0xFF002147),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    child: TableCalendar(
      firstDay: DateTime.now(),
      lastDay: DateTime(DateTime.now().year + 5),
      focusedDay: selectedDate,
      selectedDayPredicate: (day) => isSameDay(day, selectedDate),
      onDaySelected: (selected, focused) {
        onDateSelected(selected);
        Navigator.pop(context);
      },
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
      ),
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        weekendStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      calendarStyle: CalendarStyle(
        defaultTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        weekendTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        selectedDecoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(
          color: Color(0xFF0F52BA),
          fontWeight: FontWeight.bold,
        ),
        todayDecoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          shape: BoxShape.circle,
        ),
        todayTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ),
  );
}