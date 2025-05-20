import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:no_couch_needed/helper/supabase_helper.dart';
import 'package:no_couch_needed/models/therapy_sessions.dart';
import 'package:no_couch_needed/models/transcript_line.dart';

class TherapySessionNotifier
    extends StateNotifier<AsyncValue<TherapySession?>> {
  TherapySessionNotifier(this.sessionId) : super(const AsyncLoading()) {
    _loadSession();
  }

  final String sessionId;

  Future<void> _loadSession() async {
    final session = await fetchTherapySession(sessionId);
    state = AsyncValue.data(session);
  }

  // Add user or assistant line
  Future<void> addTranscriptLine(String text, String role) async {
    final session = state.value;
    if (session == null) return;
    final newLine = TranscriptLine(text, role, DateTime.now());
    final updated = TherapySession(
      id: session.id,
      userId: session.userId,
      therapistAgent: session.therapistAgent,
      createdAt: session.createdAt,
      transcript: [...session.transcript, newLine],
    );
    state = AsyncValue.data(updated);
    await updateTranscript(sessionId, updated.transcript);
  }
}

final therapySessionProvider = StateNotifierProvider.family<
  TherapySessionNotifier,
  AsyncValue<TherapySession?>,
  String
>((ref, sessionId) => TherapySessionNotifier(sessionId));
