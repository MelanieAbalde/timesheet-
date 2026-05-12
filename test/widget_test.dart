import 'package:flutter_test/flutter_test.dart';

import 'package:timesheet_app/main.dart';

void main() {
  testWidgets('shows timesheet workflow after login', (tester) async {
    await tester.pumpWidget(const TimesheetApp());

    expect(find.text('IPSOS · TIMESHEET'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('IPSOS · TIMESHEET'), findsOneWidget);
    expect(find.text('You can log time for this week only'), findsOneWidget);
    expect(find.text('Add activity'), findsOneWidget);
    expect(find.text('Submit week'), findsOneWidget);
    expect(find.text('PREVIOUS TIMESHEETS'), findsOneWidget);
  });
}
