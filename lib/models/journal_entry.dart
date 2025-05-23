// models/journal_entry.dart

import 'package:no_couch_needed/models/transcript_line.dart';

class JournalEntry {
  final String id;
  final String userId;
  final List<TranscriptLine> transcript;
  final String? summary;
  final String? overallMood;
  final String? moodColor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int duration; // in seconds

  JournalEntry({
    required this.id,
    required this.userId,
    required this.transcript,
    this.summary,
    this.overallMood,
    this.moodColor,
    required this.createdAt,
    DateTime? updatedAt,
    required this.duration,
  }) : updatedAt = updatedAt ?? createdAt;

  // Convert to Map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'transcript':
          transcript
              .map(
                (t) => {
                  'text': t.text,
                  'role': t.role,
                  'timestamp': t.timestamp.toIso8601String(),
                },
              )
              .toList(),
      'summary': summary,
      'overall_mood': overallMood,
      'mood_color': moodColor,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'duration': duration,
    };
  }

  // Create from Supabase response
  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      transcript:
          (map['transcript'] as List)
              .map(
                (t) => TranscriptLine(
                  t['text'] as String,
                  t['role'] as String,
                  DateTime.parse(t['timestamp'] as String),
                ),
              )
              .toList(),
      summary: map['summary'] as String?,
      overallMood: map['overall_mood'] as String?,
      moodColor: map['mood_color'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      duration: map['duration'] as int,
    );
  }

  // Copy with method for updates
  JournalEntry copyWith({
    String? id,
    String? userId,
    List<TranscriptLine>? transcript,
    String? summary,
    String? overallMood,
    String? moodColor,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? duration,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      transcript: transcript ?? this.transcript,
      summary: summary ?? this.summary,
      overallMood: overallMood ?? this.overallMood,
      moodColor: moodColor ?? this.moodColor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      duration: duration ?? this.duration,
    );
  }

  // Helper methods
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  bool get hasSummary => summary != null && summary!.isNotEmpty;

  bool get hasMood => overallMood != null && overallMood!.isNotEmpty;

  String get transcriptText => transcript.map((t) => t.text).join(' ');

  int get wordCount => transcriptText.split(' ').length;

  // Convert mood to emoji
  String get moodEmoji {
    switch (overallMood?.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'anxious':
        return '😰';
      case 'calm':
        return '😌';
      case 'angry':
        return '😠';
      case 'excited':
        return '🤗';
      case 'confused':
        return '😕';
      case 'frustrated':
        return '😤';
      case 'hopeful':
        return '🤞';
      case 'neutral':
      default:
        return '😐';
    }
  }

  @override
  String toString() {
    return 'JournalEntry(id: $id, userId: $userId, createdAt: $createdAt, mood: $overallMood, duration: $duration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JournalEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Extension for list of journal entries
extension JournalEntryListExtensions on List<JournalEntry> {
  // Get entries for a specific date
  List<JournalEntry> forDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return where(
      (entry) =>
          entry.createdAt.isAfter(startOfDay) &&
          entry.createdAt.isBefore(endOfDay),
    ).toList();
  }

  // Get entries for current week
  List<JournalEntry> get thisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );

    return where((entry) => entry.createdAt.isAfter(startDate)).toList();
  }

  // Get entries for current month
  List<JournalEntry> get thisMonth {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    return where((entry) => entry.createdAt.isAfter(startOfMonth)).toList();
  }

  // Group entries by mood
  Map<String, List<JournalEntry>> get groupedByMood {
    final grouped = <String, List<JournalEntry>>{};

    for (final entry in this) {
      if (entry.overallMood != null) {
        grouped.putIfAbsent(entry.overallMood!, () => []).add(entry);
      }
    }

    return grouped;
  }

  // Get mood statistics
  Map<String, double> get moodPercentages {
    if (isEmpty) return {};

    final moodCounts = <String, int>{};
    var totalWithMood = 0;

    for (final entry in this) {
      if (entry.overallMood != null) {
        moodCounts[entry.overallMood!] =
            (moodCounts[entry.overallMood!] ?? 0) + 1;
        totalWithMood++;
      }
    }

    if (totalWithMood == 0) return {};

    return moodCounts.map(
      (mood, count) => MapEntry(mood, (count / totalWithMood) * 100),
    );
  }
}
