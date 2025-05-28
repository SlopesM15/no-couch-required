import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:no_couch_needed/models/therapy_sessions.dart';
import 'package:no_couch_needed/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider for therapist's clients
final therapistClientsProvider = FutureProvider<List<Profile>>((ref) async {
  final supabase = Supabase.instance.client;
  final therapistId = supabase.auth.currentUser?.id;

  if (therapistId == null) throw Exception('Not authenticated');

  // Get all unique user IDs from therapy sessions
  final sessions = await supabase
      .from('therapy_sessions')
      .select('user_id')
      .neq('user_id', therapistId);

  final uniqueUserIds =
      (sessions as List).map((s) => s['user_id'] as String).toSet().toList();

  if (uniqueUserIds.isEmpty) return [];

  // Get profiles for these users
  final profiles = await supabase
      .from('profiles')
      .select()
      .contains('id', uniqueUserIds);

  return (profiles as List).map((p) => Profile.fromMap(p)).toList();
});

// Provider for client sessions
final clientSessionsProvider =
    FutureProvider.family<List<TherapySession>, String>((ref, clientId) async {
      final supabase = Supabase.instance.client;

      final sessions = await supabase
          .from('therapy_sessions')
          .select()
          .eq('user_id', clientId)
          .order('created_at', ascending: false);

      return (sessions as List).map((s) => TherapySession.fromMap(s)).toList();
    });

class TherapistPortalPage extends ConsumerStatefulWidget {
  @override
  _TherapistPortalPageState createState() => _TherapistPortalPageState();
}

class _TherapistPortalPageState extends ConsumerState<TherapistPortalPage> {
  String? selectedClientId;
  TherapySession? selectedSession;

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(therapistClientsProvider);

    return Scaffold(
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
        child: Row(
          children: [
            // Sidebar with clients
            Container(
              width: 300,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                border: Border(
                  right: BorderSide(color: Colors.grey[800]!, width: 1),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey[800]!, Colors.grey[900]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.cyanAccent.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Colors.cyanAccent, Colors.cyan],
                                ),
                              ),
                              child: const Icon(
                                Icons.medical_services_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Therapist Portal',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Client Management System',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search clients...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                        filled: true,
                        fillColor: Colors.grey[900]?.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        // Implement search functionality
                      },
                    ),
                  ),

                  // Clients list
                  Expanded(
                    child: clientsAsync.when(
                      data: (clients) {
                        if (clients.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 48,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No clients yet',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: clients.length,
                          itemBuilder: (context, index) {
                            final client = clients[index];
                            final isSelected = selectedClientId == client.id;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    setState(() {
                                      selectedClientId = client.id;
                                      selectedSession = null;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? Colors.cyanAccent.withOpacity(
                                                0.1,
                                              )
                                              : Colors.grey[900]?.withOpacity(
                                                0.3,
                                              ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? Colors.cyanAccent.withOpacity(
                                                  0.3,
                                                )
                                                : Colors.transparent,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Colors.grey[800],
                                          backgroundImage:
                                              client
                                                      .profilePictureUrl
                                                      .isNotEmpty
                                                  ? NetworkImage(
                                                    Supabase
                                                        .instance
                                                        .client
                                                        .storage
                                                        .from('avatar')
                                                        .getPublicUrl(
                                                          client
                                                              .profilePictureUrl,
                                                        ),
                                                  )
                                                  : null,
                                          child:
                                              client.profilePictureUrl.isEmpty
                                                  ? Text(
                                                    '${client.name.isNotEmpty ? client.name[0] : 'U'}${client.surname.isNotEmpty ? client.surname[0] : ''}',
                                                    style: TextStyle(
                                                      color: Colors.grey[400],
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  )
                                                  : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${client.name} ${client.surname}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                '@${client.username}',
                                                style: TextStyle(
                                                  color: Colors.grey[500],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Colors.cyanAccent,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading:
                          () => Center(
                            child: LoadingAnimationWidget.newtonCradle(
                              color: Colors.cyanAccent,
                              size: 50,
                            ),
                          ),
                      error:
                          (err, _) => Center(
                            child: Text(
                              'Error loading clients',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                    ),
                  ),

                  // Logout button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Supabase.instance.client.auth.signOut();
                        Navigator.pushReplacementNamed(context, '/');
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main content area
            Expanded(
              child:
                  selectedClientId == null
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search_rounded,
                              size: 64,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Select a client to view their sessions',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      )
                      : _ClientDetailView(
                        clientId: selectedClientId!,
                        onSessionSelected: (session) {
                          setState(() {
                            selectedSession = session;
                          });
                        },
                        selectedSession: selectedSession,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientDetailView extends ConsumerWidget {
  final String clientId;
  final Function(TherapySession) onSessionSelected;
  final TherapySession? selectedSession;

  const _ClientDetailView({
    required this.clientId,
    required this.onSessionSelected,
    this.selectedSession,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(clientSessionsProvider(clientId));

    return sessionsAsync.when(
      data: (sessions) {
        if (selectedSession != null) {
          return _SessionTranscriptView(session: selectedSession!);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Client Sessions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Sessions grid
            Expanded(
              child:
                  sessions.isEmpty
                      ? Center(
                        child: Text(
                          'No sessions found for this client',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                      : GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1.2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          final duration =
                              session.transcript.isNotEmpty
                                  ? session.transcript.last.timestamp
                                      .difference(session.createdAt)
                                      .inMinutes
                                  : 0;

                          return _SessionCard(
                            session: session,
                            duration: duration,
                            onTap: () => onSessionSelected(session),
                          );
                        },
                      ),
            ),
          ],
        );
      },
      loading:
          () => Center(
            child: LoadingAnimationWidget.newtonCradle(
              color: Colors.cyanAccent,
              size: 50,
            ),
          ),
      error:
          (err, _) => Center(
            child: Text(
              'Error loading sessions: $err',
              style: TextStyle(color: Colors.red),
            ),
          ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final TherapySession session;
  final int duration;
  final VoidCallback onTap;

  const _SessionCard({
    required this.session,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM dd, yyyy').format(session.createdAt);
    final time = DateFormat('h:mm a').format(session.createdAt);

    Color therapistColor = Colors.cyanAccent;
    if (session.therapistAgent.contains('Maya')) {
      therapistColor = Colors.pinkAccent;
    } else if (session.therapistAgent.contains('Emily')) {
      therapistColor = Colors.greenAccent;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[800]!.withOpacity(0.5),
                Colors.grey[900]!.withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[700]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: therapistColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: therapistColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.psychology_rounded,
                      color: therapistColor,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${duration}m',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                session.therapistAgent.isNotEmpty
                    ? session.therapistAgent
                    : 'Therapy Session',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$date • $time',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${session.transcript.length} messages',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.mood, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${session.moodEntries.length} moods',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionTranscriptView extends StatelessWidget {
  final TherapySession session;

  const _SessionTranscriptView({required this.session});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with back button
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            border: Border(
              bottom: BorderSide(color: Colors.grey[800]!, width: 1),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  // This will trigger a rebuild to show the sessions list
                },
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.therapistAgent.isNotEmpty
                        ? session.therapistAgent
                        : 'Therapy Session',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat(
                      'MMMM dd, yyyy • h:mm a',
                    ).format(session.createdAt),
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Transcript
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: session.transcript.length,
            itemBuilder: (context, index) {
              final line = session.transcript[index];
              final isUser = line.role == 'user';

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:
                      isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    if (!isUser) ...[
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                        child: const Icon(
                          Icons.psychology,
                          size: 20,
                          color: Colors.cyanAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              isUser
                                  ? Colors.purpleAccent.withOpacity(0.2)
                                  : Colors.grey[800]?.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('h:mm a').format(line.timestamp),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isUser) ...[
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.purpleAccent.withOpacity(0.2),
                        child: const Icon(
                          Icons.person,
                          size: 20,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
