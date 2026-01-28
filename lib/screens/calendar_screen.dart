import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Calendar"), backgroundColor: Colors.black),
      body: TableCalendar(
        // LATEST: Minimalist 2026 styling
        firstDay: DateTime.utc(2025, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
        },
        calendarStyle: const CalendarStyle(
          todayDecoration: BoxDecoration(color: Color(0xFFFFD700), shape: BoxShape.circle),
          selectedDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
          defaultTextStyle: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}