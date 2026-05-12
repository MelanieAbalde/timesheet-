# Ipsos Contractor Timesheet Prototype

Flutter web prototype for contractor weekly timesheets.

## What It Covers

- Mock contractor login
- Current-week timesheet entry
- Multiple activity lines per day
- Activity dropdowns for in-field, admin, and travel time
- Decimal hour entry, such as `5.5` or `5.75`
- Kilometer entry required for travel rows
- Separate totals by activity type
- Save draft vs submit-and-lock behavior
- Timesheet list with edit only for the current open draft

## Run Locally

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

Open `http://127.0.0.1:8080`.

## Verify

```bash
flutter analyze
flutter test
flutter build web
```
# timesheet
