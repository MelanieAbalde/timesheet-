import 'package:flutter_test/flutter_test.dart';
import 'package:timesheet_app/main.dart';

void main() {
  testWidgets('login flow test', (tester) async {
    await tester.pumpWidget(const TimesheetApp());

    // Verify login screen
    expect(find.text('IPSOS · TIMESHEET'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);

    // Tap Sign In (pre-filled by test user logic)
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // Verify Dashboard
    expect(find.text('PROJECT CODE: NZHS'), findsOneWidget);
    expect(find.text('ACTIVITY'), findsOneWidget);
    expect(find.text('SUBMIT'), findsOneWidget);
  });
}
