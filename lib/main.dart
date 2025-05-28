import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:no_couch_needed/auth/auth_gate.dart';
import 'package:no_couch_needed/pages/breathing_exercises_page.dart';
import 'package:no_couch_needed/pages/guided_meditation_page.dart';
import 'package:no_couch_needed/pages/profile_page.dart';
import 'package:no_couch_needed/pages/resource_page.dart';
import 'package:no_couch_needed/pages/therapist_portal_page.dart';
import 'package:no_couch_needed/providers/auth_provider.dart';
import 'package:no_couch_needed/widgets/navigation_shell.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
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
        '/resources': (_) => ResourcesPage(),
        '/portal': (_) => TherapistPortalPage(),
        '/breathing-exercises': (_) => BreathingExercisesPage(),
        '/guided-meditation': (_) => GuidedMeditationPage(),
      },
      title: 'No Couch Required',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: kIsWeb ? WebAuthGate() : AuthGate(),
    );
  }
}

// New WebAuthGate for platform-specific routing
class WebAuthGate extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (state) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          // Check if user is a therapist (you might want to add a role check here)
          // For now, we'll check if they have a specific metadata or email domain
          final userEmail = session.user.email ?? '';
          final isTherapist =
              userEmail.endsWith('@therapist.com') ||
              session.user.userMetadata?['role'] == 'therapist';

          if (isTherapist) {
            return TherapistPortalPage();
          } else {
            // Regular users on web can still use the app
            return AuthGate();
          }
        } else {
          return TherapistAuthPage();
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

// Therapist-specific auth page for web
class TherapistAuthPage extends StatefulWidget {
  @override
  _TherapistAuthPageState createState() => _TherapistAuthPageState();
}

class _TherapistAuthPageState extends State<TherapistAuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user == null) {
        _showSnackBar('Sign in failed', isError: true);
      }
    } catch (e) {
      _showSnackBar('An error occurred: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.greenAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF414345),
              Color(0xFF232526),
              Color.fromARGB(255, 0, 0, 0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[900]?.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.cyanAccent, Colors.cyan],
                      ),
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'Therapist Portal',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Access client session transcripts',
                    style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 32),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(
                        Icons.email_rounded,
                        color: Colors.grey[600],
                      ),
                      filled: true,
                      fillColor: Colors.grey[800]?.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.cyanAccent,
                          width: 2,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator:
                        (val) =>
                            val != null && val.contains('@')
                                ? null
                                : 'Enter a valid email',
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(
                        Icons.lock_rounded,
                        color: Colors.grey[600],
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.grey[800]?.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.cyanAccent,
                          width: 2,
                        ),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator:
                        (val) =>
                            (val == null || val.length < 6)
                                ? 'Password must be at least 6 characters'
                                : null,
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _isLoading
                              ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black,
                                  ),
                                ),
                              )
                              : const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mobile app link
                  TextButton(
                    onPressed: () {
                      // Could show a dialog or redirect
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              backgroundColor: Colors.grey[900],
                              title: const Text(
                                'Mobile App',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: Text(
                                'The No Couch Required mobile app is available for clients on iOS and Android.',
                                style: TextStyle(color: Colors.grey[300]),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                      );
                    },
                    child: Text(
                      'Looking for the client app?',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
