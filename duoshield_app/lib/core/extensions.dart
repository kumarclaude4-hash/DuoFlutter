import 'package:intl/intl.dart';

extension StringExtensions on String {
  String get initials {
    final parts = trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

extension DateTimeExtensions on DateTime {
  String toConversationTime() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(year, month, day);
    if (date == today) return DateFormat.jm().format(this);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == yesterday) return 'Yesterday';
    if (now.difference(this).inDays < 7) return DateFormat.E().format(this);
    return DateFormat('MM/dd/yy').format(this);
  }

  String toFullDateTime() => DateFormat('MMM d, yyyy • h:mm a').format(this);

  String toDateOnly() => DateFormat('MMM d, yyyy').format(this);
}

extension IntExtensions on int {
  DateTime toDateTime() => DateTime.fromMillisecondsSinceEpoch(this);

  String toDurationString() {
    final d = Duration(seconds: this);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
