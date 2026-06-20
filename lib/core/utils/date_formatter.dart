/// Human-friendly date formatting for list items.
///
/// Wraps intl so the rest of the app doesn't sprinkle format strings around.
library;
import 'package:intl/intl.dart';

class AppDateFormatter {
  AppDateFormatter._();

  static String relative(DateTime time, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24 && time.day == reference.day) {
      return 'Today ${DateFormat.jm().format(time)}';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat.yMMMd().format(time);
  }

  static String full(DateTime time) =>
      DateFormat('MMM d, yyyy • h:mm a').format(time);
}
