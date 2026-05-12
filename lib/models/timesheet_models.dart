import 'package:flutter/material.dart';

enum ActivityType {
  inField('In-Field Working Time', Color(0xFF1B6BD5)),
  admin('Admin Time', Color(0xFF1B8A61)),
  travel('Travel Time + Km', Color(0xFFD57F1B));

  const ActivityType(this.label, this.color);

  final String label;
  final Color color;
}

enum TimesheetStatus { draft, submitted, closed }

class TimeEntryLine {
  TimeEntryLine({
    required this.id,
    required this.rowId, // Link to a specific UI row
    required this.date,
    required this.activity,
    this.hours = 0,
    this.kilometers = 0,
  });

  final int id;
  final String rowId;
  final DateTime date;
  ActivityType activity;
  double hours;
  double kilometers;
}

class Timesheet {
  Timesheet({
    required this.weekStart,
    required this.weekEnd,
    required this.status,
    required this.lines,
    required this.updatedAt,
    this.submittedAt,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  TimesheetStatus status;
  List<TimeEntryLine> lines;
  DateTime updatedAt;
  DateTime? submittedAt;
}

class Contractor {
  const Contractor({
    required this.name,
    required this.email,
    required this.projectCode,
  });

  final String name;
  final String email;
  final String projectCode;
}
