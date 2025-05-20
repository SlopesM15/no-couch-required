import 'package:no_couch_needed/models/transcript_line.dart';

class TherapySession {
  final String id, userId, therapistAgent;
  final DateTime createdAt;
  final List<TranscriptLine> transcript;

  TherapySession({
    required this.id,
    required this.userId,
    required this.therapistAgent,
    required this.createdAt,
    required this.transcript,
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
  );
  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'therapist_agent': therapistAgent,
    'created_at': createdAt.toIso8601String(),
    'transcript': transcript.map((e) => e.toMap()).toList(),
  };
}
