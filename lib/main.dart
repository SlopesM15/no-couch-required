import 'package:flutter/material.dart';
import 'package:no_couch_needed/auth/auth_gate.dart';
import 'package:no_couch_needed/pages/profile_page.dart';

import 'package:no_couch_needed/widgets/navigation_shell.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qyzgjjgzxjutkwoiuiga.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF5emdqamd6eGp1dGt3b2l1aWdhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc0OTY3MDgsImV4cCI6MjA2MzA3MjcwOH0.kEfqfOrUuM-9m4GCCn9NWf68X0WiW-Sa70j6Bs6wn1g',
  );

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/home': (_) => const NavigationShell(initialIndex: 0),
        '/sessions': (_) => const NavigationShell(initialIndex: 1),
        '/journal': (_) => const NavigationShell(initialIndex: 2),
        '/profile': (context) => ProfilePage(),
      },
      title: 'No Couch Needed',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthGate(),
    );
  }
}
