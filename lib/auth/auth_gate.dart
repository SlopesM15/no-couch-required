import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:no_couch_needed/pages/auth_page.dart';
import 'package:no_couch_needed/pages/home_page.dart';
import 'package:no_couch_needed/pages/profile_page.dart';
import 'package:no_couch_needed/providers/auth_provider.dart';
import 'package:no_couch_needed/providers/profile_provider.dart';
import 'package:no_couch_needed/widgets/navigation_shell.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (state) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          final profileAsync = ref.watch(profileProvider);

          // Check if the profile is loaded
          if (profileAsync.isLoading) {
            return Scaffold(
              body: Center(
                child: LoadingAnimationWidget.newtonCradle(
                  color: Colors.black,
                  size: 50,
                ),
              ),
            );
          }

          return profileAsync.when(
            data: (profile) {
              if (profile == null) {
                // Profile incomplete, direct to Profile tab in NavigationShell
                return NavigationShell(initialIndex: 1);
              }
              final isComplete =
                  profile.name.isNotEmpty &&
                  profile.surname.isNotEmpty &&
                  profile.username.isNotEmpty &&
                  profile.profilePictureUrl.isNotEmpty;
              if (isComplete) {
                // Profile complete, direct to Home tab in NavigationShell
                return NavigationShell(initialIndex: 0);
              } else {
                // Incomplete, show Profile tab
                return NavigationShell(initialIndex: 1);
              }
            },
            loading:
                () => Scaffold(
                  body: Center(
                    child: LoadingAnimationWidget.newtonCradle(
                      color: Colors.black,
                      size: 50,
                    ),
                  ),
                ),
            error:
                (e, _) => Scaffold(
                  body: Center(child: Text('Error loading profile: $e')),
                ),
          );
        } else {
          return AuthPage();
        }
      },
      loading:
          () => Scaffold(
            body: Center(
              child: LoadingAnimationWidget.newtonCradle(
                color: Colors.cyanAccent,
                size: 50,
              ),
            ),
          ),
      error:
          (_, __) => Scaffold(body: Center(child: Text('Error loading Auth'))),
    );
  }
}
