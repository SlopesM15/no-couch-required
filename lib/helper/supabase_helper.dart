import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:no_couch_needed/models/therapy_sessions.dart';
import 'package:no_couch_needed/models/transcript_line.dart';

// Fetch a therapy session by id.
Future<TherapySession?> fetchTherapySession(String id) async {
  final supabase = Supabase.instance.client;
  try {
    final data =
        await supabase.from('therapy_sessions').select().eq('id', id).single();
    return TherapySession.fromMap(data);
  } catch (e) {
    // Optionally log the error
    return null;
  }
}

// Update transcript list for a session.
Future<void> updateTranscript(
  String sessionId,
  List<TranscriptLine> lines,
) async {
  final supabase = Supabase.instance.client;
  await supabase
      .from('therapy_sessions')
      .update({'transcript': lines.map((e) => e.toMap()).toList()})
      .eq('id', sessionId);
}

// Create a new therapy session.
Future<void> createTherapySession(TherapySession session) async {
  final supabase = Supabase.instance.client;
  await supabase.from('therapy_sessions').insert([session.toMap()]);
}
