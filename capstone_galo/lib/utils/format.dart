import 'package:intl/intl.dart';

final _peso = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
final _time = DateFormat('MMM d, h:mm a');

String formatPeso(num amount) => _peso.format(amount);

/// e.g. 42 -> "#0042"
String formatOrderNo(int orderNo) => '#${orderNo.toString().padLeft(4, '0')}';

String formatTime(DateTime? time) =>
    time == null ? 'Just now' : _time.format(time);
