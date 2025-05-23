// providers/journal_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:no_couch_needed/models/journal_entry.dart';

// Provider for fetching all journal entries
final journalEntriesProvider = FutureProvider<List<JournalEntry>>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) {
    throw Exception('User not authenticated');
  }

  try {
    final response = await supabase
        .from('journal_entries')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((entry) => JournalEntry.fromMap(entry))
        .toList();
  } catch (e) {
    throw Exception('Failed to load journal entries: $e');
  }
});

// Provider for fetching a single journal entry
final journalEntryProvider = FutureProvider.family<JournalEntry?, String>((
  ref,
  entryId,
) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) {
    throw Exception('User not authenticated');
  }

  try {
    final response =
        await supabase
            .from('journal_entries')
            .select()
            .eq('id', entryId)
            .eq('user_id', userId)
            .single();

    return JournalEntry.fromMap(response);
  } catch (e) {
    return null;
  }
});

// Provider for journal statistics
final journalStatsProvider = FutureProvider<JournalStats>((ref) async {
  final entries = await ref.watch(journalEntriesProvider.future);

  if (entries.isEmpty) {
    return JournalStats(
      totalEntries: 0,
      totalDuration: 0,
      moodCounts: {},
      currentStreak: 0,
      longestStreak: 0,
    );
  }

  // Calculate total duration
  final totalDuration = entries.fold<int>(
    0,
    (sum, entry) => sum + entry.duration,
  );

  // Count moods
  final moodCounts = <String, int>{};
  for (final entry in entries) {
    if (entry.overallMood != null) {
      moodCounts[entry.overallMood!] =
          (moodCounts[entry.overallMood!] ?? 0) + 1;
    }
  }

  // Calculate streaks
  final streakData = _calculateStreaks(entries);

  return JournalStats(
    totalEntries: entries.length,
    totalDuration: totalDuration,
    moodCounts: moodCounts,
    currentStreak: streakData.currentStreak,
    longestStreak: streakData.longestStreak,
  );
});

// Helper function to calculate journaling streaks
_StreakData _calculateStreaks(List<JournalEntry> entries) {
  if (entries.isEmpty) {
    return _StreakData(currentStreak: 0, longestStreak: 0);
  }

  // Sort entries by date (newest first)
  final sortedEntries = List<JournalEntry>.from(entries)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  int currentStreak = 0;
  int longestStreak = 0;
  int tempStreak = 1;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  // Check if there's an entry today or yesterday for current streak
  final mostRecentDate = DateTime(
    sortedEntries.first.createdAt.year,
    sortedEntries.first.createdAt.month,
    sortedEntries.first.createdAt.day,
  );

  if (mostRecentDate == today || mostRecentDate == yesterday) {
    currentStreak = 1;

    // Count consecutive days
    for (int i = 1; i < sortedEntries.length; i++) {
      final currentDate = DateTime(
        sortedEntries[i - 1].createdAt.year,
        sortedEntries[i - 1].createdAt.month,
        sortedEntries[i - 1].createdAt.day,
      );
      final previousDate = DateTime(
        sortedEntries[i].createdAt.year,
        sortedEntries[i].createdAt.month,
        sortedEntries[i].createdAt.day,
      );

      final difference = currentDate.difference(previousDate).inDays;

      if (difference == 1) {
        tempStreak++;
        if (i == 1) currentStreak = tempStreak;
      } else if (difference > 1) {
        longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
        tempStreak = 1;
        if (i == 1) currentStreak = 1;
      }
    }
  }

  longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;

  return _StreakData(
    currentStreak: currentStreak,
    longestStreak: longestStreak,
  );
}

class _StreakData {
  final int currentStreak;
  final int longestStreak;

  _StreakData({required this.currentStreak, required this.longestStreak});
}

// Journal statistics model
class JournalStats {
  final int totalEntries;
  final int totalDuration; // in seconds
  final Map<String, int> moodCounts;
  final int currentStreak;
  final int longestStreak;

  JournalStats({
    required this.totalEntries,
    required this.totalDuration,
    required this.moodCounts,
    required this.currentStreak,
    required this.longestStreak,
  });

  String get totalDurationFormatted {
    final hours = totalDuration ~/ 3600;
    final minutes = (totalDuration % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String? get mostFrequentMood {
    if (moodCounts.isEmpty) return null;

    return moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

// Service class for journal operations
class JournalService {
  static final _supabase = Supabase.instance.client;

  static Future<void> saveJournalEntry(JournalEntry entry) async {
    try {
      await _supabase.from('journal_entries').insert(entry.toMap());
    } catch (e) {
      throw Exception('Failed to save journal entry: $e');
    }
  }

  static Future<void> updateJournalEntry(JournalEntry entry) async {
    try {
      await _supabase
          .from('journal_entries')
          .update(entry.toMap())
          .eq('id', entry.id);
    } catch (e) {
      throw Exception('Failed to update journal entry: $e');
    }
  }

  static Future<void> deleteJournalEntry(String entryId) async {
    try {
      await _supabase.from('journal_entries').delete().eq('id', entryId);
    } catch (e) {
      throw Exception('Failed to delete journal entry: $e');
    }
  }

  static Future<List<JournalEntry>> searchJournalEntries(String query) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Search in summary and transcript text
      final response = await _supabase
          .from('journal_entries')
          .select()
          .eq('user_id', userId)
          .or('summary.ilike.%$query%,transcript.cs.{"text":"*$query*"}')
          .order('created_at', ascending: false);

      return (response as List)
          .map((entry) => JournalEntry.fromMap(entry))
          .toList();
    } catch (e) {
      throw Exception('Failed to search journal entries: $e');
    }
  }

  static Future<List<JournalEntry>> getEntriesByMood(String mood) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await _supabase
          .from('journal_entries')
          .select()
          .eq('user_id', userId)
          .eq('overall_mood', mood)
          .order('created_at', ascending: false);

      return (response as List)
          .map((entry) => JournalEntry.fromMap(entry))
          .toList();
    } catch (e) {
      throw Exception('Failed to get entries by mood: $e');
    }
  }

  static Future<List<JournalEntry>> getEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await _supabase
          .from('journal_entries')
          .select()
          .eq('user_id', userId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);

      return (response as List)
          .map((entry) => JournalEntry.fromMap(entry))
          .toList();
    } catch (e) {
      throw Exception('Failed to get entries by date range: $e');
    }
  }
}
