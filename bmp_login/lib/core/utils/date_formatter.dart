import 'package:intl/intl.dart';

class DateFormatter {
  // Standard date format: dd/MM/yyyy
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  // Date with time format: dd/MM/yyyy HH:mm
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  /// NEW: Robust parser to handle various date formats from the backend
  /// This prevents the FormatException when receiving different date types.
  static DateTime? parseAny(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;

    // If it's already a DateTime object, return it
    if (value is DateTime) return value;

    String dateStr = value.toString();
    try {
      // 1. Try ISO 8601 (yyyy-MM-ddTHH:mm:ss) - Default for Spring Boot
      return DateTime.parse(dateStr);
    } catch (_) {
      try {
        // 2. Try your custom display format (dd/MM/yyyy)
        return _dateFormat.parse(dateStr);
      } catch (_) {
        // 3. Last resort: Print error but don't crash the app
        print('DateFormatter: Could not parse date string: $dateStr');
        return null;
      }
    }
  }

  /// Format DateTime to dd/MM/yyyy for the UI
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return _dateFormat.format(date);
  }

  /// Format DateTime to dd/MM/yyyy HH:mm for the UI
  static String formatDateTime(DateTime? date) {
    if (date == null) return '';
    return _dateTimeFormat.format(date);
  }

  /// Format DateTime for API (ISO format) - Best practice for POST/PUT
  static String formatForApi(DateTime? date) {
    if (date == null) return '';
    return date.toIso8601String();
  }

  static DateTime? parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return null;
    }
    try {
      return _dateFormat.parse(dateStr);
    } catch (e) {
      return null;
    }
  }
}
