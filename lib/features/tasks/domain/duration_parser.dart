/// Parses flexible duration input into total seconds.
/// Examples: `1`, `1 min`, `2:30`, `2:30 min`, `45s`, `90m`
int? parseDurationInput(String raw) {
  var input = raw.trim().toLowerCase();
  if (input.isEmpty) return null;

  input = input.replaceAll('minutes', 'min');

  final colonMatch = RegExp(r'^(\d+)\s*:\s*(\d{1,2})\s*(min|m|s)?$').firstMatch(input);
  if (colonMatch != null) {
    final minutes = int.parse(colonMatch.group(1)!);
    final seconds = int.parse(colonMatch.group(2)!);
    if (seconds >= 60) return null;
    return minutes * 60 + seconds;
  }

  if (input.endsWith('s') && !input.contains(':')) {
    final value = int.tryParse(input.replaceAll(RegExp(r'[^0-9]'), ''));
    if (value != null && value > 0) return value;
  }

  if (input.endsWith('min') || RegExp(r'\d+\s*m$').hasMatch(input)) {
    final numeric = input.replaceAll(RegExp(r'[^0-9.]'), '');
    final value = double.tryParse(numeric);
    if (value != null && value > 0) {
      return (value * 60).round();
    }
  }

  final plain = int.tryParse(input.replaceAll(RegExp(r'[^0-9]'), ''));
  if (plain != null && plain > 0) {
    return plain * 60;
  }

  return null;
}

/// Formats seconds as `45m` under an hour, otherwise `9h07m`.
String formatTaskDuration(int totalSeconds) {
  if (totalSeconds <= 0) return '0m';

  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;

  if (hours == 0) {
    if (minutes == 0) return '1m';
    return '${minutes}m';
  }

  return '${hours}h${minutes.toString().padLeft(2, '0')}m';
}
