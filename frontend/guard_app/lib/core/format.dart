const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "Oct 5, 2026"
String formatDate(DateTime date) =>
    '${_months[date.month - 1]} ${date.day}, ${date.year}';
