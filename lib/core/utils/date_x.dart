/// Lightweight date formatting helpers so we avoid an intl dependency for the
/// handful of formats the app needs.
extension DateX on DateTime {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String get monthShort => _months[month - 1];
  String get dayName => _days[weekday - 1];

  /// e.g. "Aug 15"
  String get shortDate => '$monthShort $day';

  /// e.g. "Sat, Aug 15"
  String get mediumDate => '$dayName, $monthShort $day';

  /// e.g. "Sat, Aug 15 · 10:00 PM"
  String get dateTimeLabel => '$mediumDate · $timeLabel';

  /// e.g. "10:00 PM"
  String get timeLabel {
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour < 12 ? 'AM' : 'PM';
    final mm = minute.toString().padLeft(2, '0');
    return '$h12:$mm $period';
  }

  /// Relative label suitable for feeds, e.g. "2h ago", "Yesterday".
  String relativeFrom(DateTime now) {
    final diff = now.difference(this);
    if (diff.isNegative) return shortDate;
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return shortDate;
  }
}
