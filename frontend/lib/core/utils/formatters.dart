import 'package:intl/intl.dart';

class AppFormatters {
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(amount);
  }
}
