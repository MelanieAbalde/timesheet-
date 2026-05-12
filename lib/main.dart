import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const TimesheetApp());
}

enum ActivityType {
  inField('In-Field Working Time', Color(0xFF1B6BD5)),
  admin('Admin Time', Color(0xFF1B8A61)),
  travel('Travel Time + Kilometers', Color(0xFFD57F1B));

  const ActivityType(this.label, this.color);

  final String label;
  final Color color;
}

enum TimesheetStatus { draft, submitted, closed }

class TimeEntryLine {
  TimeEntryLine({
    required this.id,
    required this.date,
    required this.activity,
    this.hours = 0,
    this.kilometers = 0,
  });

  final int id;
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

class TimesheetApp extends StatefulWidget {
  const TimesheetApp({super.key});

  @override
  State<TimesheetApp> createState() => _TimesheetAppState();
}

class _TimesheetAppState extends State<TimesheetApp> {
  Contractor? _contractor;

  void _login(String name, String email) {
    setState(() {
      _contractor = Contractor(name: name, email: email, projectCode: 'NZHS');
    });
  }

  void _logout() {
    setState(() {
      _contractor = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ipsos Timesheet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        textTheme: GoogleFonts.nunitoTextTheme().copyWith(
          headlineLarge: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 24),
          headlineMedium: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 20),
          titleLarge: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 18),
          titleMedium: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16),
          bodyLarge: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 13),
          bodyMedium: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 13),
          bodySmall: GoogleFonts.nunito(fontWeight: FontWeight.w400, fontSize: 13),
          labelLarge: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 13), // Buttons
        ),
        scaffoldBackgroundColor: AppColors.page,
        colorScheme: const ColorScheme.light(
          primary: AppColors.text,
          surface: AppColors.panel,
          onSurface: AppColors.text,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.card,
          contentTextStyle: GoogleFonts.nunito(
            color: AppColors.text,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      home: _contractor == null
          ? LoginScreen(onLogin: _login)
          : TimesheetHome(
              contractor: _contractor!,
              onLogout: _logout,
            ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLogin});

  final void Function(String name, String email) onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Aroha Williams');
  final _emailController = TextEditingController(
    text: 'aroha.williams@example.com',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1D),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: LoginSurface(
              padding: const EdgeInsets.all(26),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'IPSOS · TIMESHEET',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: const Color(0xFFC8C8C1),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 18),
                    LoginTextField(
                      controller: _nameController,
                      label: 'Contractor Name',
                      validator: _required,
                    ),
                    const SizedBox(height: 6),
                    LoginTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (_required(value) != null) return _required(value);
                        return value!.contains('@')
                            ? null
                            : 'Enter a valid email address';
                      },
                    ),
                    const SizedBox(height: 14),
                    LoginActionButton(
                      label: 'Sign In',
                      icon: Icons.login,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          widget.onLogin(
                            _nameController.text.trim(),
                            _emailController.text.trim(),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
  late final DateTime _today;
  late final List<Timesheet> _timesheets;
  int _selectedDayIndex = 0;
  int _nextLineId = 100;

  @override
  void initState() {
    super.initState();
    _today = _dateOnly(DateTime.now());
    final weekStart = _startOfWeek(_today);
    _selectedDayIndex = 0;
    _timesheets = [
      Timesheet(
        weekStart: weekStart,
        weekEnd: weekStart.add(const Duration(days: 6)),
        status: TimesheetStatus.draft,
        updatedAt: DateTime.now(),
        lines: [],
      ),
      _submittedSheet(
        weekStart.subtract(const Duration(days: 7)),
        inFieldHours: 32.5,
        adminHours: 4,
        travelHours: 2.5,
        kilometers: 48,
      ),
      _submittedSheet(
        weekStart.subtract(const Duration(days: 14)),
        inFieldHours: 30,
        adminHours: 3.5,
        travelHours: 3,
        kilometers: 62,
      ),
    ];
  }

  Timesheet get _currentTimesheet => _timesheets.first;

  bool get _deadlinePassed =>
      DateTime.now().isAfter(_submissionDeadline(_currentTimesheet.weekStart));

  bool get _canEdit =>
      _currentTimesheet.status == TimesheetStatus.draft && !_deadlinePassed;

  DateTime get _selectedDate =>
      _currentTimesheet.weekStart.add(Duration(days: _selectedDayIndex));

  List<TimeEntryLine> get _selectedDayLines => _currentTimesheet.lines
      .where((line) => _isSameDay(line.date, _selectedDate))
      .toList();

  List<Timesheet> get _previousTimesheets => _timesheets
      .where((sheet) => !identical(sheet, _currentTimesheet))
      .toList();

  void _selectDay(int index) {
    final date = _currentTimesheet.weekStart.add(Duration(days: index));
    if (date.isAfter(_today)) return;
    setState(() => _selectedDayIndex = index);
  }

  void _addLine(ActivityType type) {
    if (!_canEdit || _selectedDate.isAfter(_today)) return;
    setState(() {
      _currentTimesheet.lines.add(
        TimeEntryLine(
          id: _nextLineId++,
          date: _selectedDate,
          activity: type,
        ),
      );
      _currentTimesheet.updatedAt = DateTime.now();
    });
  }

  void _removeLine(TimeEntryLine line) {
    setState(() {
      _currentTimesheet.lines.removeWhere((item) => item.id == line.id);
      _currentTimesheet.updatedAt = DateTime.now();
    });
  }

  void _markChanged() {
    setState(() => _currentTimesheet.updatedAt = DateTime.now());
  }

  void _saveDraft() {
    if (!_canEdit) return;
    _markChanged();
    _showMessage('Saved');
  }

  void _submitWeek() {
    final error = _submissionError(_currentTimesheet);
    if (error != null) {
      _showMessage(error);
      return;
    }
    setState(() {
      _currentTimesheet
        ..status = TimesheetStatus.submitted
        ..submittedAt = DateTime.now()
        ..updatedAt = DateTime.now();
    });
    _showMessage('Week submitted');
  }

  String? _submissionError(Timesheet timesheet) {
    if (!_canEdit) return 'This week is locked';
    if (timesheet.lines.where((line) => line.hours > 0).isEmpty) {
      return 'Add at least one activity before submitting';
    }
    for (final line in timesheet.lines) {
      if (line.activity == ActivityType.travel &&
          line.hours > 0 &&
          line.kilometers <= 0) {
        return 'Travel entries need kilometers';
      }
      if (line.date.isAfter(_today)) return 'Future dates cannot be submitted';
    }
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TimesheetShell(
        contractor: widget.contractor,
        currentTimesheet: _currentTimesheet,
        previousTimesheets: _previousTimesheets,
        today: _today,
        selectedDayIndex: _selectedDayIndex,
        selectedDate: _selectedDate,
        selectedDayLines: _selectedDayLines,
        canEdit: _canEdit,
        onSelectDay: _selectDay,
        onAddLine: _addLine,
        onRemoveLine: _removeLine,
        onChanged: _markChanged,
        onSave: _saveDraft,
        onSubmit: _submitWeek,
        onLogout: widget.onLogout,
      ),
    );
  }
}

class TimesheetShell extends StatelessWidget {
  const TimesheetShell({
    super.key,
    required this.contractor,
    required this.currentTimesheet,
    required this.previousTimesheets,
    required this.today,
    required this.selectedDayIndex,
    required this.selectedDate,
    required this.selectedDayLines,
    required this.canEdit,
    required this.onSelectDay,
    required this.onAddLine,
    required this.onRemoveLine,
    required this.onChanged,
    required this.onSave,
    required this.onSubmit,
    required this.onLogout,
  });

  final Contractor contractor;
  final Timesheet currentTimesheet;
  final List<Timesheet> previousTimesheets;
  final DateTime today;
  final int selectedDayIndex;
  final DateTime selectedDate;
  final List<TimeEntryLine> selectedDayLines;
  final bool canEdit;
  final ValueChanged<int> onSelectDay;
  final ValueChanged<ActivityType> onAddLine;
  final ValueChanged<TimeEntryLine> onRemoveLine;
  final VoidCallback onChanged;
  final VoidCallback onSave;
  final VoidCallback onSubmit;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isLargeWeb = width > 1100;
    final compact = width < 760;

    final mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeaderBar(
          contractor: contractor,
          weekStart: currentTimesheet.weekStart,
          weekEnd: currentTimesheet.weekEnd,
          onSignOut: onLogout,
        ),
        const SizedBox(height: 24),
        DashboardView(timesheet: currentTimesheet),
        const SizedBox(height: 20),
        const Divider(color: AppColors.border, height: 1),
        const SizedBox(height: 16),
        DayTabs(
          weekStart: currentTimesheet.weekStart,
          selectedIndex: selectedDayIndex,
          today: today,
          onSelect: onSelectDay,
        ),
        const SizedBox(height: 12),
        Text(
          '${weekdayName(selectedDate)}, ${selectedDate.day} ${monthName(selectedDate)}',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: compact ? 16 : 20),
        DayEntryArea(
          lines: selectedDayLines,
          canEdit: canEdit && !selectedDate.isAfter(today),
          onAddLine: onAddLine,
          onRemoveLine: onRemoveLine,
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
        RunningTotalsStrip(timesheet: currentTimesheet),
        const SizedBox(height: 16),
        ActionRow(canEdit: canEdit, onSave: onSave, onSubmit: onSubmit),
      ],
    );

    final previousContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'PREVIOUS TIMESHEETS',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        for (final timesheet in previousTimesheets)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PreviousTimesheetTile(timesheet: timesheet),
          ),
      ],
    );

    return Column(
      children: [
        Image.asset(
          'assets/branding.png',
          width: double.infinity,
          height: 70,
          fit: BoxFit.fill,
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: EdgeInsets.all(compact ? 20 : 32),
                  child: isLargeWeb
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: mainContent),
                            const SizedBox(width: 40),
                            Expanded(flex: 1, child: previousContent),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            mainContent,
                            const SizedBox(height: 40),
                            previousContent,
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({
    super.key,
    required this.timesheet,
  });

  final Timesheet timesheet;

  @override
  Widget build(BuildContext context) {
    final totals = totalsByActivity(timesheet.lines);
    final kilometers = totalKilometers(timesheet.lines);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tab row: This week | History
        Row(
          children: [
            _TabButton(label: 'This Week', icon: Icons.access_time, selected: true),
            const SizedBox(width: 4),
            _TabButton(label: 'History', icon: Icons.history, selected: false),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 700;
            final cardWidth = isCompact
                ? constraints.maxWidth
                : (constraints.maxWidth - 2 * 12) / 3;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SummaryCard(
                  label: 'In-Field Hours',
                  value: trimDouble(totals[ActivityType.inField] ?? 0),
                  sublabel: 'Hours',
                  width: cardWidth,
                ),
                SummaryCard(
                  label: 'Admin Hours',
                  value: trimDouble(totals[ActivityType.admin] ?? 0),
                  sublabel: 'Hours',
                  width: cardWidth,
                ),
                SummaryCard(
                  label: 'Travel',
                  value: trimDouble(totals[ActivityType.travel] ?? 0),
                  sublabel: 'Hours  ·  ${trimDouble(kilometers)} Kilometers',
                  width: cardWidth,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.sublabel,
    required this.width,
  });

  final String label;
  final String value;
  final String sublabel;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w800, // Title weight
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.nunito(
              color: AppColors.text,
              fontSize: 24,
              fontWeight: FontWeight.w900, // Headline weight
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sublabel,
            style: GoogleFonts.nunito(
              color: AppColors.dim,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
  });
  final String label;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(
          color: selected ? AppColors.borderStrong : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.muted),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              color: selected ? AppColors.text : AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w900, // Button weight
            ),
          ),
        ],
      ),
    );
  }
}

class HeaderBar extends StatelessWidget {
  const HeaderBar({
    super.key,
    required this.contractor,
    required this.weekStart,
    required this.weekEnd,
    required this.onSignOut,
  });

  final Contractor contractor;
  final DateTime weekStart;
  final DateTime weekEnd;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    // Top Row: Username + Buttons
    final topRow = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          contractor.name.toLowerCase().replaceAll(' ', '.'),
          style: GoogleFonts.nunito(
            color: AppColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: onSignOut,
          icon: const Icon(Icons.logout_rounded, size: 16),
          label: const Text('Sign out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.text,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );

    // Bottom Row: Week Title + Date Range
    final bottomRow = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            'Week of ${weekStart.day} ${monthName(weekStart)}',
            style: GoogleFonts.nunito(
              color: AppColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            '${weekStart.day} ${monthName(weekStart)} — ${weekEnd.day} ${monthName(weekEnd)}',
            style: GoogleFonts.nunito(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    return Column(
      children: [
        topRow,
        const SizedBox(height: 24),
        bottomRow,
      ],
    );
  }
}


class DayTabs extends StatelessWidget {
  const DayTabs({
    super.key,
    required this.weekStart,
    required this.selectedIndex,
    required this.today,
    required this.onSelect,
  });

  final DateTime weekStart;
  final int selectedIndex;
  final DateTime today;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return Row(
          children: [
            for (var index = 0; index < 7; index++) ...[
              Expanded(
                child: DayTab(
                  date: weekStart.add(Duration(days: index)),
                  selected: selectedIndex == index,
                  compact: compact,
                  onTap: () => onSelect(index),
                ),
              ),
              if (index < 6) SizedBox(width: compact ? 10 : 10),
            ],
          ],
        );
      },
    );
  }
}

class DayTab extends StatelessWidget {
  const DayTab({
    super.key,
    required this.date,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final locked = date.isAfter(today);

    final Color bgColor = selected
        ? const Color(0xFF1C1C1B)
        : Colors.transparent;
    final Color textColor = selected
        ? Colors.white
        : locked
        ? AppColors.disabled
        : AppColors.dim;

    return InkWell(
      onTap: locked ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: bgColor,
          border: Border.all(
            color: selected ? const Color(0xFF1C1C1B) : AppColors.border,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                shortWeekday(date),
                style: GoogleFonts.nunito(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${date.day}',
                style: GoogleFonts.nunito(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DayEntryArea extends StatefulWidget {
  const DayEntryArea({
    super.key,
    required this.lines,
    required this.canEdit,
    required this.onAddLine,
    required this.onRemoveLine,
    required this.onChanged,
  });

  final List<TimeEntryLine> lines;
  final bool canEdit;
  final ValueChanged<ActivityType> onAddLine;
  final ValueChanged<TimeEntryLine> onRemoveLine;
  final VoidCallback onChanged;

  @override
  State<DayEntryArea> createState() => _DayEntryAreaState();
}

class _DayEntryAreaState extends State<DayEntryArea> {
  final GlobalKey _buttonKey = GlobalKey();

  Future<void> _showPicker(BuildContext context) async {
    final RenderBox? renderBox = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final position = RelativeRect.fromLTRB(
      offset.dx,
      offset.dy - 220, // Position above the button
      offset.dx + renderBox.size.width,
      offset.dy,
    );

    final result = await showMenu<ActivityType>(
      context: context,
      position: position,
      color: AppColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 8,
      items: [
        for (final type in ActivityType.values)
          PopupMenuItem<ActivityType>(
            value: type,
            height: 48,
            padding: EdgeInsets.zero,
            child: _PickerRow(
              color: type.color,
              label: type.label,
            ),
          ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<ActivityType>(
          height: 48,
          padding: EdgeInsets.zero,
          onTap: () => Navigator.of(context).pop(),
          child: const _PickerCancelRow(),
        ),
      ],
    );

    if (result != null) widget.onAddLine(result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.lines.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No entries yet for this day. Add an activity below.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
              ),
            ),
          )
        else
          Column(
            children: [
              for (final line in widget.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ActivityLine(
                    line: line,
                    enabled: widget.canEdit,
                    onRemove: () => widget.onRemoveLine(line),
                    onChanged: widget.onChanged,
                  ),
                ),
            ],
          ),
        const SizedBox(height: 6),
        ActionButton(
          key: _buttonKey,
          label: 'Add Activity',
          icon: Icons.add,
          onPressed: widget.canEdit ? () => _showPicker(context) : null,
          expanded: true,
        ),
      ],
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.color,
    required this.label,
  });
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerCancelRow extends StatelessWidget {
  const _PickerCancelRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.close, size: 16, color: AppColors.muted),
          SizedBox(width: 6),
          Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


class ActivityLine extends StatefulWidget {
  const ActivityLine({
    super.key,
    required this.line,
    required this.enabled,
    required this.onRemove,
    required this.onChanged,
  });

  final TimeEntryLine line;
  final bool enabled;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  State<ActivityLine> createState() => _ActivityLineState();
}

class _ActivityLineState extends State<ActivityLine> {
  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: dot + activity label + trash button
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: widget.line.activity.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ActivityType>(
                    value: widget.line.activity,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    items: ActivityType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          ),
                        )
                        .toList(),
                    onChanged: widget.enabled
                        ? (value) {
                            setState(() {
                              widget.line.activity = value!;
                              if (widget.line.activity != ActivityType.travel) {
                                widget.line.kilometers = 0;
                              }
                            });
                            widget.onChanged();
                          }
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Styled trash button
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: widget.enabled ? widget.onRemove : null,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: AppColors.muted,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Decimal Hours field
          Row(
            children: [
              Expanded(
                child: DecimalField(
                  label: 'Hours',
                  value: widget.line.hours,
                  enabled: widget.enabled,
                  onChanged: (value) {
                    widget.line.hours = value;
                    widget.onChanged();
                  },
                ),
              ),
              if (widget.line.activity == ActivityType.travel) ...[
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kilometers',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      DecimalField(
                        label: '',
                        value: widget.line.kilometers,
                        enabled: widget.enabled,
                        onChanged: (value) {
                          widget.line.kilometers = value;
                          widget.onChanged();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: AppColors.surface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderStrong, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
    );
  }
}

class _SpinButton extends StatelessWidget {
  const _SpinButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 20,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 14, color: AppColors.muted),
      ),
    );
  }
}


class RunningTotalsStrip extends StatelessWidget {
  const RunningTotalsStrip({super.key, required this.timesheet});

  final Timesheet timesheet;

  @override
  Widget build(BuildContext context) {
    final totals = totalsByActivity(timesheet.lines);
    final kilometers = totalKilometers(timesheet.lines);

    String fmt(double v) => v > 0 ? trimDouble(v) : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _TotalCell(label: 'In-field', value: fmt(totals[ActivityType.inField] ?? 0)),
          const SizedBox(width: 24),
          _TotalCell(label: 'Admin', value: fmt(totals[ActivityType.admin] ?? 0)),
          const SizedBox(width: 24),
          _TotalCell(label: 'Travel', value: fmt(totals[ActivityType.travel] ?? 0)),
          const SizedBox(width: 24),
          _TotalCell(label: 'Kilometers', value: fmt(kilometers)),
        ],
      ),
    );
  }
}

class _TotalCell extends StatelessWidget {
  const _TotalCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}


class ActionRow extends StatelessWidget {
  const ActionRow({
    super.key,
    required this.canEdit,
    required this.onSave,
    required this.onSubmit,
  });

  final bool canEdit;
  final VoidCallback onSave;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        final saveButton = ActionButton(
          label: 'Save',
          icon: Icons.save_outlined,
          onPressed: canEdit ? onSave : null,
        );
        final submitButton = ActionButton(
          label: 'Submit Week',
          icon: Icons.near_me_outlined,
          onPressed: canEdit ? onSubmit : null,
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [saveButton, const SizedBox(height: 4), submitButton],
          );
        }

        return Row(
          children: [
            Expanded(child: saveButton),
            const SizedBox(width: 10),
            Expanded(child: submitButton),
          ],
        );
      },
    );
  }
}

class PreviousTimesheetTile extends StatelessWidget {
  const PreviousTimesheetTile({super.key, required this.timesheet});

  final Timesheet timesheet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Week Ending ${timesheet.weekEnd.day} ${monthName(timesheet.weekEnd)} ${timesheet.weekEnd.year}',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timesheetSummary(timesheet),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusPill(status: timesheet.status),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.expanded = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        disabledForegroundColor: AppColors.disabled,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        minimumSize: Size(expanded ? double.infinity : 0, 54),
        side: const BorderSide(color: AppColors.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class DarkSurface extends StatelessWidget {
  const DarkSurface({super.key, required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final TimesheetStatus status;

  @override
  Widget build(BuildContext context) {
    final submitted = status == TimesheetStatus.submitted;
    final draft = status == TimesheetStatus.draft;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: submitted
            ? AppColors.submitted
            : draft
            ? AppColors.draft
            : AppColors.open,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (draft) ...[
              const Icon(Icons.access_time, color: AppColors.draftText, size: 14),
              const SizedBox(width: 4),
            ],
            Text(
              submitted
                  ? 'Submitted'
                  : draft
                  ? 'Draft'
                  : 'Open',
              style: TextStyle(
                color: submitted
                    ? AppColors.submittedText
                    : draft
                    ? AppColors.draftText
                    : AppColors.openText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class DecimalField extends StatefulWidget {
  const DecimalField({
    super.key,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  State<DecimalField> createState() => _DecimalFieldState();
}

class _DecimalFieldState extends State<DecimalField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value == 0 ? '' : trimDouble(widget.value),
    );
  }

  @override
  void didUpdateWidget(covariant DecimalField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        _controller.text != trimDouble(widget.value)) {
      _controller.text = widget.value == 0 ? '' : trimDouble(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      decoration: darkInputDecoration(widget.label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      onChanged: (value) => widget.onChanged(double.tryParse(value) ?? 0),
    );
  }
}

class DarkTextField extends StatelessWidget {
  const DarkTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      decoration: darkInputDecoration(label),
    );
  }
}

class LoginSurface extends StatelessWidget {
  const LoginSurface({super.key, required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF30302E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF555553)),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class LoginTextField extends StatelessWidget {
  const LoginTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.nunito(
        color: const Color(0xFFF8F8F3),
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.nunito(color: const Color(0xFFC8C8C1), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF10100F),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF555553)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF676765)),
        ),
      ),
    );
  }
}

class LoginActionButton extends StatelessWidget {
  const LoginActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFF8F8F3),
        textStyle: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w900),
        minimumSize: const Size(0, 54),
        side: const BorderSide(color: Color(0xFF676765)),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

InputDecoration darkInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.dim, fontSize: 12),
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.borderStrong, width: 2),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.borderDark),
    ),
  );
}

class AppColors {
  static const page = Color(0xFFFFFFFF); // All white
  static const panel = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF9FAFB);
  static const surfaceMuted = Color(0xFFF3F4F6);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE5E7EB);
  static const borderStrong = Color(0xFFD1D5DB);
  static const borderDark = Color(0xFFF3F4F6);
  static const text = Color(0xFF111827);
  static const muted = Color(0xFF4B5563);
  static const dim = Color(0xFF9CA3AF);
  static const disabled = Color(0xFFD1D5DB);
  static const open = Color(0xFFECFDF5);
  static const openText = Color(0xFF059669);
  static const draft = Color(0xFFFEF3C7);
  static const draftText = Color(0xFF92400E);
  static const submitted = Color(0xFFEFF6FF);
  static const submittedText = Color(0xFF2563EB);
}

Timesheet _submittedSheet(
  DateTime weekStart, {
  required double inFieldHours,
  required double adminHours,
  double travelHours = 0,
  double kilometers = 0,
}) {
  return Timesheet(
    weekStart: weekStart,
    weekEnd: weekStart.add(const Duration(days: 6)),
    status: TimesheetStatus.submitted,
    submittedAt: weekStart.add(const Duration(days: 6, hours: 18)),
    updatedAt: weekStart.add(const Duration(days: 6, hours: 18)),
    lines: [
      TimeEntryLine(
        id: weekStart.millisecondsSinceEpoch + 1,
        date: weekStart,
        activity: ActivityType.inField,
        hours: inFieldHours,
      ),
      TimeEntryLine(
        id: weekStart.millisecondsSinceEpoch + 2,
        date: weekStart,
        activity: ActivityType.admin,
        hours: adminHours,
      ),
      if (travelHours > 0)
        TimeEntryLine(
          id: weekStart.millisecondsSinceEpoch + 3,
          date: weekStart,
          activity: ActivityType.travel,
          hours: travelHours,
          kilometers: kilometers,
        ),
    ],
  );
}

Map<ActivityType, double> totalsByActivity(List<TimeEntryLine> lines) {
  final totals = {for (final type in ActivityType.values) type: 0.0};
  for (final line in lines) {
    totals[line.activity] = (totals[line.activity] ?? 0) + line.hours;
  }
  return totals;
}

double totalKilometers(List<TimeEntryLine> lines) {
  return lines
      .where((line) => line.activity == ActivityType.travel)
      .fold<double>(0, (sum, line) => sum + line.kilometers);
}

double totalHours(List<TimeEntryLine> lines) {
  return lines.fold<double>(0, (sum, line) => sum + line.hours);
}

String timesheetSummary(Timesheet timesheet) {
  final totals = totalsByActivity(timesheet.lines);
  final parts = <String>[];
  if ((totals[ActivityType.inField] ?? 0) > 0) {
    parts.add('In-Field ${trimDouble(totals[ActivityType.inField] ?? 0)} Hours');
  }
  if ((totals[ActivityType.admin] ?? 0) > 0) {
    parts.add('Admin ${trimDouble(totals[ActivityType.admin] ?? 0)} Hours');
  }
  if ((totals[ActivityType.travel] ?? 0) > 0) {
    parts.add('Travel ${trimDouble(totals[ActivityType.travel] ?? 0)} Hours');
  }
  final kilometers = totalKilometers(timesheet.lines);
  if (kilometers > 0) parts.add('${trimDouble(kilometers)} Kilometers');
  return parts.join(' · ');
}

String? _required(String? value) {
  return value == null || value.trim().isEmpty ? 'Required' : null;
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _startOfWeek(DateTime date) {
  final normalized = _dateOnly(date);
  return normalized.subtract(
    Duration(days: normalized.weekday - DateTime.monday),
  );
}

DateTime _submissionDeadline(DateTime weekStart) {
  return weekStart.add(const Duration(days: 6, hours: 21));
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String weekdayName(DateTime date) {
  return const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][date.weekday - 1];
}

String shortWeekday(DateTime date) {
  return weekdayName(date);
}

String monthName(DateTime date) {
  return const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][date.month - 1];
}

String trimDouble(double value) {
  if (value == 0) return '0';
  return value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
}
