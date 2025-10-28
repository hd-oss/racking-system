import 'package:intl/intl.dart';

// DateFormat with Indonesia locale
final timeFormat = DateFormat('HH:mm:ss', 'id');
final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id'); // Senin, 27 Oktober 2025
final dateTimeFormat = DateFormat('EEEE, dd MMMM yyyy HH:mm:ss', 'id'); // Senin, 27 Oktober 2025 14:30:45

/// Convert UTC timestamp to WIB (UTC+7)
/// Indonesia Standard Time is UTC+7
DateTime convertUtcToWib(DateTime utcTime) {
  return utcTime.add(const Duration(hours: 7));
}

/// Format date to Indonesia format: "Senin, 27 Oktober 2025"
String formatTanggalIndonesia(DateTime date) {
  final wibTime = convertUtcToWib(date);
  return dateFormat.format(wibTime);
}

/// Format datetime lengkap dengan timezone info: "Senin, 27 Oktober 2025 14:30:45 WIB"
String formatDateTimeIndonesia(DateTime date) {
  final wibTime = convertUtcToWib(date);
  return '${dateTimeFormat.format(wibTime)} WIB';
}
