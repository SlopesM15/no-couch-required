import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:no_couch_needed/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final profileProvider = FutureProvider<Profile?>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return null;

  // Try to fetch the user profile
  final res =
      await supabase.from('profiles').select().eq('id', user.id).maybeSingle();

  if (res != null) {
    return Profile.fromMap(res);
  } else {
    // If not found, auto-create a new, empty profile (example fields)
    final profileData = {
      'id': user.id,

      'name': '', // or use user.metadata if you have them
      'surname': '',
      'username': '',
      'profile_picture_url': '',
    };
    await supabase.from('profiles').insert(profileData);

    // After insertion, fetch it again
    final inserted =
        await supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

    if (inserted != null) {
      return Profile.fromMap(inserted);
    }
    return null;
  }
});
