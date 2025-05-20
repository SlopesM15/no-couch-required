import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:no_couch_needed/models/therapy_sessions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final sessionsProvider = FutureProvider<List<TherapySession>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  final res = await Supabase.instance.client
      .from('therapy_sessions')
      .select()
      .eq('user_id', user!.id)
      .order('created_at', ascending: false);
  return (res as List).map((e) => TherapySession.fromMap(e)).toList();
});
