import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:no_couch_needed/helper/supabase_helper.dart';
import 'package:no_couch_needed/models/therapy_sessions.dart';
import 'package:no_couch_needed/pages/therapist_selection_page.dart';
import 'package:no_couch_needed/widgets/therapy_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<TherapySession> sessions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('therapy_sessions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        sessions =
            (response as List)
                .map((json) => TherapySession.fromMap(json))
                .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading sessions: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Generate session tracker for the past 7 days
  List<bool> _generateSessionTracker() {
    final now = DateTime.now();
    final List<bool> tracker = [];

    // Start from Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));

    for (int i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(Duration(days: 1));

      // Check if any session exists for this day
      final hasSession = sessions.any(
        (session) =>
            session.createdAt.isAfter(dayStart) &&
            session.createdAt.isBefore(dayEnd),
      );

      tracker.add(hasSession);
    }

    return tracker;
  }

  @override
  Widget build(BuildContext context) {
    final sessionTracker = _generateSessionTracker();

    return Scaffold(
      drawer: TherapyDrawer(
        onLogout: () async {
          await Supabase.instance.client.auth.signOut();
        },
      ),
      appBar: AppBar(
        title: const Text('Home', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF414345),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.transparent,
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Top Card for New Session
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey[500]!,
                        Colors.grey[600]!,
                        Colors.grey[800]!,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Start New Session',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Begin a new therapy conversation with one of our AI therapists.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[200],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyanAccent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              final userId =
                                  Supabase.instance.client.auth.currentUser?.id;
                              if (userId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "You must be logged in to start a session.",
                                    ),
                                  ),
                                );
                                return;
                              }
                              // Create new session object
                              final session = TherapySession(
                                id: const Uuid().v4(),
                                userId: userId,
                                therapistAgent: '',
                                createdAt: DateTime.now(),
                                transcript: [],
                                moodEntries: [],
                              );

                              // Navigate to therapist selection page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => TherapistSelectionPage(
                                        session: session,
                                      ),
                                ),
                              ).then(
                                (_) => _loadSessions(),
                              ); // Reload sessions when returning
                            },
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text(
                              "Start Session",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Weekly Tracker Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.black.withOpacity(0.3),
                    border: Border.all(color: Colors.grey[800]!, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'This Week',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Tracker Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(sessionTracker.length, (index) {
                          final hasSession = sessionTracker[index];
                          return Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient:
                                  hasSession
                                      ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.cyanAccent,
                                          Colors.cyan[700]!,
                                        ],
                                      )
                                      : null,
                              color: hasSession ? null : Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                              boxShadow:
                                  hasSession
                                      ? [
                                        BoxShadow(
                                          color: Colors.cyanAccent.withOpacity(
                                            0.4,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                      : null,
                            ),
                            child:
                                hasSession
                                    ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                    : null,
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      // Days label under the tracker
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children:
                            ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                                .map(
                                  (d) => SizedBox(
                                    width: 36,
                                    child: Text(
                                      d,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[400],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Session History Section
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey[800]!.withOpacity(0.5),
                        Colors.grey[900]!.withOpacity(0.5),
                      ],
                    ),
                    border: Border.all(color: Colors.grey[700]!, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Session History',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            if (sessions.isNotEmpty)
                              Text(
                                '${sessions.length} sessions',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isLoading)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: LoadingAnimationWidget.newtonCradle(
                              color: Colors.cyanAccent,
                              size: 50,
                            ),
                          ),
                        )
                      else if (sessions.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.psychology_outlined,
                                  size: 48,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No sessions yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start your first session above',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sessions.length,
                          itemBuilder: (context, index) {
                            final session = sessions[index];
                            final duration =
                                session.transcript.isNotEmpty
                                    ? session.transcript.last.timestamp
                                        .difference(session.createdAt)
                                        .inMinutes
                                    : 0;

                            return Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  top:
                                      index == 0
                                          ? BorderSide.none
                                          : BorderSide(
                                            color: Colors.grey[800]!,
                                            width: 1,
                                          ),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                title: Text(
                                  session.therapistAgent.isNotEmpty
                                      ? session.therapistAgent
                                      : 'Therapy Session',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        DateFormat(
                                          'MMM d, yyyy',
                                        ).format(session.createdAt),
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        DateFormat(
                                          'h:mm a',
                                        ).format(session.createdAt),
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.timer,
                                        size: 14,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${duration}m',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                onTap: () {
                                  // TODO: Navigate to session detail page

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => TherapistSelectionPage(
                                            session: session,
                                          ),
                                    ),
                                  ).then((_) => _loadSessions());
                                },
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
