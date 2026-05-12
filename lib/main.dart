import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/timesheet_models.dart';
import 'views/login_view.dart';
import 'views/timesheet_home.dart';

void main() {
  runApp(const TimesheetApp());
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
      title: 'IPSOS Timesheet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CB3D4),
          primary: const Color(0xFF4CB3D4),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF4CB3D4),
            textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
        ),
        textTheme: GoogleFonts.nunitoTextTheme().copyWith(
          headlineLarge: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 24),
          headlineMedium: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 20),
          bodyLarge: GoogleFonts.nunito(fontWeight: FontWeight.w400, fontSize: 16),
          bodyMedium: GoogleFonts.nunito(fontWeight: FontWeight.w400, fontSize: 14),
        ),
      ),
      home: _contractor == null
          ? LoginView(onLogin: _login)
          : TimesheetHome(
              contractor: _contractor!,
              onLogout: _logout,
            ),
    );
  }
}
