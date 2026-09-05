/// Serializes a calendar date (year/month/day only — as picked from a date
/// field like date-of-birth) to an ISO 8601 string anchored at UTC midnight.
///
/// [date] is whatever `showDatePicker` handed back: a local `DateTime` with
/// the day the person picked but midnight in the *device's* timezone. Naively
/// calling `toIso8601String()` on that serializes the local wall-clock time
/// without a timezone suffix, so a server parsing it as UTC (or a filter that
/// compares against UTC day boundaries, like the Club roster's birth-year
/// filter) can read back the day *before* the one actually picked — e.g.
/// midnight "Jan 1" in a UTC+3 timezone is "Dec 31, 21:00" once shifted to
/// UTC. Rebuilding the same Y/M/D as UTC midnight keeps the calendar date the
/// person chose intact no matter what timezone either side runs in.
String dateOnlyIso(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).toIso8601String();
