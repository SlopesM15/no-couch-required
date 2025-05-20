// Each transcript line as an object
class TranscriptLine {
  final String text;
  final String role; // 'user' or 'assistant'
  final DateTime timestamp;

  TranscriptLine(this.text, this.role, this.timestamp);

  Map<String, dynamic> toMap() => {
    'text': text,
    'role': role,
    'timestamp': timestamp.toIso8601String(),
  };

  factory TranscriptLine.fromMap(Map<String, dynamic> map) => TranscriptLine(
    map['text'],
    map['role'],
    DateTime.parse(map['timestamp']),
  );
}
