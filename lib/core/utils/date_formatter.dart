import 'package:intl/intl.dart';

/// Utility untuk format tanggal dan waktu
class DateFormatter {
  DateFormatter._(); // Private constructor

  /// Format: 12 Jan 2024
  static String formatDate(DateTime date) {
    return DateFormat('d MMM yyyy', 'id_ID').format(date);
  }

  /// Format: 12 Januari 2024
  static String formatDateLong(DateTime date) {
    return DateFormat('d MMMM yyyy', 'id_ID').format(date);
  }

  /// Format: 14:30
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  /// Format: 12 Jan 2024, 14:30
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)}, ${formatTime(dateTime)}';
  }

  /// Format: 12 Januari 2024, 14:30
  static String formatDateTimeLong(DateTime dateTime) {
    return '${formatDateLong(dateTime)}, ${formatTime(dateTime)}';
  }

  /// Format: Senin, 12 Jan 2024
  static String formatDateWithDay(DateTime date) {
    return DateFormat('EEEE, d MMM yyyy', 'id_ID').format(date);
  }

  /// Format relatif: Hari ini, Besok, Kemarin, atau tanggal
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(date.year, date.month, date.day);

    final difference = targetDay.difference(today).inDays;

    if (difference == 0) {
      return 'Hari ini';
    } else if (difference == 1) {
      return 'Besok';
    } else if (difference == -1) {
      return 'Kemarin';
    } else if (difference > 0 && difference < 7) {
      return DateFormat('EEEE', 'id_ID').format(date);
    } else {
      return formatDate(date);
    }
  }

  /// Format waktu relatif dengan tanggal: Hari ini, 14:30
  static String formatRelativeDateTime(DateTime dateTime) {
    return '${formatRelativeDate(dateTime)}, ${formatTime(dateTime)}';
  }

  /// Cek apakah tanggal adalah hari ini
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Cek apakah tanggal adalah besok
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  /// Cek apakah waktu sudah lewat
  static bool isPast(DateTime dateTime) {
    return dateTime.isBefore(DateTime.now());
  }

  /// Cek apakah waktu akan datang
  static bool isFuture(DateTime dateTime) {
    return dateTime.isAfter(DateTime.now());
  }
}
