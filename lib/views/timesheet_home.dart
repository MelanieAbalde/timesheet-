import 'package:flutter/material.dart';
import '../models/timesheet_models.dart';
import '../theme/app_colors.dart';
import '../widgets/timesheet_widgets.dart';

class TimesheetHome extends StatefulWidget {
  const TimesheetHome({
    super.key,
    required this.contractor,
    required this.onLogout,
  });

  final Contractor contractor;
  final VoidCallback onLogout;

  @override
  State<TimesheetHome> createState() => _TimesheetHomeState();
}

class _TimesheetHomeState extends State<TimesheetHome> {
  late Timesheet _activeSheet;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    _activeSheet = Timesheet(
      weekStart: DateTime(monday.year, monday.month, monday.day),
      weekEnd: DateTime(sunday.year, sunday.month, sunday.day),
      status: TimesheetStatus.draft,
      lines: [],
      updatedAt: DateTime.now(),
    );
  }

  void _onChanged() {
    setState(() {
      _activeSheet.updatedAt = DateTime.now();
    });
  }

  void _onSubmit() {
    showDialog(
      context: context,
      builder: (context) => ReviewDialog(
        timesheet: _activeSheet,
        onConfirm: () {
          setState(() {
            _activeSheet.status = TimesheetStatus.submitted;
            _activeSheet.submittedAt = DateTime.now();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Timesheet submitted successfully')),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Branding Image at the very top, no margins
            Image.asset(
              'assets/branding.png',
              height: 120,
              fit: BoxFit.cover,
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HeaderBar(
                        contractor: widget.contractor,
                        weekStart: _activeSheet.weekStart,
                        onLogout: widget.onLogout,
                      ),
                      const SizedBox(height: 32),
                      TimesheetTable(
                        timesheet: _activeSheet,
                        onChanged: _onChanged,
                        onCancel: () {},
                        onSubmit: _onSubmit,
                      ),
                      const SizedBox(height: 32),
                      NotesSection(
                        controller: _notesController,
                        canEdit: _activeSheet.status == TimesheetStatus.draft,
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
