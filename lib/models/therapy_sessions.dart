import 'package:no_couch_needed/models/mood_entry.dart';
import 'package:no_couch_needed/models/transcript_line.dart'
    show TranscriptLine;

class TherapySession {
  final String id, userId, therapistAgent;
  final DateTime createdAt;
  final List<TranscriptLine> transcript;
  final List<MoodEntry> moodEntries;

  TherapySession({
    required this.id,
    required this.userId,
    required this.therapistAgent,
    required this.createdAt,
    required this.transcript,
    required this.moodEntries,
  });

  factory TherapySession.fromMap(Map<String, dynamic> map) => TherapySession(
    id: map['id'],
    userId: map['user_id'],
    therapistAgent: map['therapist_agent'],
    createdAt: DateTime.parse(map['created_at']),
    transcript:
        (map['transcript'] as List)
            .map((e) => TranscriptLine.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
    moodEntries:
        (map['mood_entries'] as List? ?? [])
            .map((e) => MoodEntry.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'therapist_agent': therapistAgent,
    'created_at': createdAt.toIso8601String(),
    'transcript': transcript.map((e) => e.toMap()).toList(),
    'mood_entries': moodEntries.map((e) => e.toMap()).toList(),
  };

  TherapySession copyWith({
    String? id,
    String? userId,
    String? therapistAgent,
    DateTime? createdAt,
    List<TranscriptLine>? transcript,
    List<MoodEntry>? moodEntries,
  }) {
    return TherapySession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      therapistAgent: therapistAgent ?? this.therapistAgent,
      createdAt: createdAt ?? this.createdAt,
      transcript: transcript ?? this.transcript,
      moodEntries: moodEntries ?? this.moodEntries,
    );
  }
}
