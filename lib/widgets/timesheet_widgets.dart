import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/timesheet_models.dart';
import '../theme/app_colors.dart';
import '../utils/helpers.dart';

class HeaderBar extends StatelessWidget {
  const HeaderBar({
    super.key,
    required this.contractor,
    required this.weekStart,
    required this.onLogout,
  });

  final Contractor contractor;
  final DateTime weekStart;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final dateRangeStr = '${weekStart.day} ${monthName(weekStart).substring(0, 3)} ${weekStart.year} — ${weekEnd.day} ${monthName(weekEnd).substring(0, 3)} ${weekEnd.year}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 48), 
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                dateRangeStr,
                style: GoogleFonts.nunito(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            Text(
              toTitleCase(contractor.name),
              style: GoogleFonts.nunito(
                color: AppColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class TimesheetTable extends StatefulWidget {
  const TimesheetTable({
    super.key,
    required this.timesheet,
    required this.onChanged,
    required this.onCancel,
    required this.onSubmit,
  });

  final Timesheet timesheet;
  final VoidCallback onChanged;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  State<TimesheetTable> createState() => _TimesheetTableState();
}

class _RowData {
  String id;
  ActivityType type;
  _RowData(this.id, this.type);
}

class _TimesheetTableState extends State<TimesheetTable> {
  late List<_RowData> _rows;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    // Initialize rows based on existing lines
    final Map<String, ActivityType> rowMap = {};
    for (final line in widget.timesheet.lines) {
      rowMap[line.rowId] = line.activity;
    }

    if (rowMap.isEmpty) {
      _rows = [_RowData(_uuid.v4(), ActivityType.inField)];
    } else {
      _rows = rowMap.entries.map((e) => _RowData(e.key, e.value)).toList();
    }
  }

  void _addRow() {
    setState(() {
      _rows.add(_RowData(_uuid.v4(), ActivityType.inField));
    });
  }

  void _removeRow(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Confirm Delete', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to delete this row?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No', style: TextStyle(color: Color(0xFFEF9A9A))),
          ),
          TextButton(
            onPressed: () {
              final rowId = _rows[index].id;
              setState(() {
                _rows.removeAt(index);
                widget.timesheet.lines.removeWhere((l) => l.rowId == rowId);
              });
              widget.onChanged();
              Navigator.pop(context);
            },
            child: const Text('Yes', style: TextStyle(color: Color(0xFF4CB3D4))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = widget.timesheet.status == TimesheetStatus.draft;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Spacer(),
                _ActionButton(
                  label: 'Cancel',
                  color: Colors.red,
                  onPressed: canEdit ? widget.onCancel : null,
                ),
                const SizedBox(width: 12),
                _ActionButton(
                  label: 'Submit',
                  color: const Color(0xFF4CB3D4),
                  onPressed: canEdit ? widget.onSubmit : null,
                ),
              ],
            ),
          ),
          _TableHeader(weekStart: widget.timesheet.weekStart),
          for (int i = 0; i < _rows.length; i++)
            _ActivityRow(
              rowId: _rows[i].id,
              type: _rows[i].type,
              timesheet: widget.timesheet,
              canEdit: canEdit,
              onChanged: widget.onChanged,
              onTypeChanged: (newType) {
                setState(() => _rows[i].type = newType);
                // Update activity type for all lines in this row
                for (final line in widget.timesheet.lines) {
                  if (line.rowId == _rows[i].id) {
                    line.activity = newType;
                  }
                }
                widget.onChanged();
              },
              onDelete: () => _removeRow(i),
            ),
          if (canEdit)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 200,
                    child: TextButton.icon(
                      onPressed: _addRow,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Row', style: TextStyle(fontWeight: FontWeight.w900)),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF4CB3D4),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.weekStart});
  final DateTime weekStart;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.text, width: 1.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text(
                'Activity',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
          ),
          for (int i = 0; i < 7; i++)
            _buildHeaderCell(weekStart.add(Duration(days: i)), today),
          const Expanded(
            child: Center(
              child: Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(DateTime date, DateTime today) {
    final isToday = isSameDay(date, today);
    final isPast = date.isBefore(today);
    final calmBlue = const Color(0xFF4CB3D4);

    Color textColor;
    Color? bgColor;
    Border? border;

    if (isToday) {
      textColor = calmBlue;
      bgColor = textColor.withOpacity(0.1);
      border = Border(bottom: BorderSide(color: calmBlue, width: 2));
    } else if (isPast) {
      textColor = calmBlue;
      bgColor = textColor.withOpacity(0.05);
    } else {
      textColor = Colors.grey;
      bgColor = Colors.grey.withOpacity(0.05);
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: bgColor, border: border),
        child: Center(
          child: Text(
            _formatHeaderDate(date),
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: textColor),
          ),
        ),
      ),
    );
  }

  String _formatHeaderDate(DateTime date) {
    final dayNames = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${dayNames[date.weekday - 1]}, ${monthName(date)} ${date.day}';
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.rowId,
    required this.type,
    required this.timesheet,
    required this.canEdit,
    required this.onChanged,
    required this.onTypeChanged,
    required this.onDelete,
  });

  final String rowId;
  final ActivityType type;
  final Timesheet timesheet;
  final bool canEdit;
  final VoidCallback onChanged;
  final ValueChanged<ActivityType> onTypeChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    double rowTotal = 0;
    double kmTotal = 0;
    for (int i = 0; i < 7; i++) {
      final date = timesheet.weekStart.add(Duration(days: i));
      rowTotal += _getValue(date);
      kmTotal += _getKm(date);
    }

    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ActivityType>(
                    value: type,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(12),
                    dropdownColor: Colors.white,
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    items: ActivityType.values.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: t.color, shape: BoxShape.circle)),
                              const SizedBox(width: 10),
                              Text(t.label, style: GoogleFonts.nunito(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: canEdit ? (val) { if (val != null) onTypeChanged(val); } : null,
                  ),
                ),
              ),
            ),
          ),
          for (int i = 0; i < 7; i++)
            _buildCell(context, timesheet.weekStart.add(Duration(days: i)), today),
          Expanded(
            child: Center(
              child: Text(
                kmTotal > 0 ? '${formatHours(rowTotal)} / ${trimDouble(kmTotal)}km' : formatHours(rowTotal),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
              onPressed: canEdit ? onDelete : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell(BuildContext context, DateTime date, DateTime today) {
    final isFuture = date.isAfter(today);
    final val = _getValue(date);
    final km = _getKm(date);

    String displayText = '';
    if (val > 0 || km > 0) {
      if (type == ActivityType.travel) {
        displayText = '${formatHours(val)} / ${trimDouble(km)}km';
      } else {
        displayText = formatHours(val);
      }
    }

    return Expanded(
      child: GestureDetector(
        onTap: (canEdit && !isFuture) ? () => _showEntryDialog(context, date) : null,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          height: 36,
          decoration: BoxDecoration(
            color: isFuture ? Colors.grey.withOpacity(0.05) : AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              displayText,
              style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: isFuture ? Colors.grey : AppColors.text),
            ),
          ),
        ),
      ),
    );
  }

  double _getValue(DateTime date) {
    final line = timesheet.lines.cast<TimeEntryLine?>().firstWhere(
      (l) => l!.rowId == rowId && isSameDay(l.date, date),
      orElse: () => null,
    );
    return line?.hours ?? 0;
  }

  double _getKm(DateTime date) {
    final line = timesheet.lines.cast<TimeEntryLine?>().firstWhere(
      (l) => l!.rowId == rowId && isSameDay(l.date, date),
      orElse: () => null,
    );
    return line?.kilometers ?? 0;
  }

  void _showEntryDialog(BuildContext context, DateTime date) {
    final existingLine = timesheet.lines.cast<TimeEntryLine?>().firstWhere(
      (l) => l!.rowId == rowId && isSameDay(l.date, date),
      orElse: () => null,
    );

    double total = existingLine?.hours ?? 0;
    int hours = total.toInt();
    int minutes = ((total - hours) * 100).round();
    double kilometers = existingLine?.kilometers ?? 0;

    final hController = TextEditingController(text: hours == 0 ? '' : hours.toString());
    final mController = TextEditingController(text: minutes == 0 ? '' : minutes.toString());
    final kController = TextEditingController(text: kilometers == 0 ? '' : trimDouble(kilometers));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(toTitleCase(type.label), style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 18)),
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPillInput('Hours', hController),
                const SizedBox(width: 20),
                _buildPillInput(type == ActivityType.travel ? 'Mins' : 'Minutes', mController),
                if (type == ActivityType.travel) ...[
                  const SizedBox(width: 20),
                  _buildPillInput('Kilometers Travelled', kController),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.nunito(color: const Color(0xFFEF9A9A), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              final h = int.tryParse(hController.text) ?? 0;
              final m = int.tryParse(mController.text) ?? 0;
              final k = double.tryParse(kController.text) ?? 0;
              final val = h + (m / 100.0);
              _setValue(date, val, k);
              onChanged();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CB3D4), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: Text('Save', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildPillInput(String label, TextEditingController controller) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text)),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: Color(0xFF7E7983), width: 2.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: Color(0xFF4CB3D4), width: 2.5)),
            ),
          ),
        ),
      ],
    );
  }

  void _setValue(DateTime date, double hours, double km) {
    final index = timesheet.lines.indexWhere(
      (l) => l.rowId == rowId && isSameDay(l.date, date)
    );
    if (index != -1) {
      if (hours == 0 && km == 0) {
        timesheet.lines.removeAt(index);
      } else {
        timesheet.lines[index].hours = hours;
        timesheet.lines[index].kilometers = km;
      }
    } else if (hours > 0 || km > 0) {
      timesheet.lines.add(TimeEntryLine(
        id: DateTime.now().millisecondsSinceEpoch,
        rowId: rowId,
        date: date,
        activity: type,
        hours: hours,
        kilometers: km,
      ));
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.color, required this.onPressed});
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), elevation: 0),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
    );
  }
}

class NotesSection extends StatelessWidget {
  const NotesSection({super.key, required this.controller, required this.canEdit});
  final TextEditingController controller;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Notes / Comments', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.muted)),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          enabled: canEdit,
          maxLines: 4,
          style: GoogleFonts.nunito(fontSize: 14, color: AppColors.text),
          decoration: InputDecoration(
            hintText: 'Enter any additional notes or comments here...',
            hintStyle: const TextStyle(color: AppColors.dim, fontSize: 14),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
          ),
        ),
      ],
    );
  }
}

class ReviewDialog extends StatelessWidget {
  const ReviewDialog({super.key, required this.timesheet, required this.onConfirm});
  final Timesheet timesheet;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final totals = totalsByActivity(timesheet.lines);
    final totalKm = totalKilometers(timesheet.lines);
    final weekEnd = timesheet.weekStart.add(const Duration(days: 6));

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        children: [
          Text('Review Submission', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 4),
          Text('${timesheet.weekStart.day} ${monthName(timesheet.weekStart).substring(0, 3)} — ${weekEnd.day} ${monthName(weekEnd).substring(0, 3)} ${weekEnd.year}', style: GoogleFonts.nunito(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            for (final entry in totals.entries)
              if (entry.value > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: entry.key.color, shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(entry.key.label, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14))),
                      Text(formatHours(entry.value), style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 14)),
                    ],
                  ),
                ),
            if (totalKm > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car, size: 16, color: AppColors.muted),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Total Distance', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14))),
                    Text('${trimDouble(totalKm)}km', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 14)),
                  ],
                ),
              ),
            const Divider(),
            const SizedBox(height: 16),
            Text('Are you sure you want to submit this timesheet?', textAlign: TextAlign.center, style: GoogleFonts.nunito(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Back', style: GoogleFonts.nunito(color: const Color(0xFFEF9A9A), fontWeight: FontWeight.w700))),
        ElevatedButton(
          onPressed: () { Navigator.pop(context); onConfirm(); },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CB3D4), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          child: Text('Confirm Submission', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
