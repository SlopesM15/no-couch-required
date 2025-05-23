class MoodEntry {
  final double sessionTime; // seconds since session start
  final String mood;
  final String colour;

  MoodEntry({
    required this.sessionTime,
    required this.mood,
    required this.colour,
  });

  factory MoodEntry.fromMap(Map<String, dynamic> map) => MoodEntry(
    sessionTime: (map['session_time'] as num).toDouble(),
    mood: map['mood'],
    colour: map['colour'],
  );

  Map<String, dynamic> toMap() => {
    'session_time': sessionTime,
    'mood': mood,
    'colour': colour,
  };
}
