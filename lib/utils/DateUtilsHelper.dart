
import 'package:intl/intl.dart';

class DateUtilsHelper {
  static String formatDate(String? isoDateString, {String format = 'dd MMM yyyy'}) {
    if (isoDateString == null || isoDateString.isEmpty) return 'N/A';

    try {
      final dateTime = DateTime.parse(isoDateString);
      return DateFormat(format).format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }
}