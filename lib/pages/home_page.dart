import 'package:flutter/material.dart';
import 'package:no_couch_needed/helper/supabase_helper.dart';
import 'package:no_couch_needed/models/therapy_sessions.dart';
import 'package:no_couch_needed/pages/active_session_page.dart';
import 'package:no_couch_needed/widgets/therapy_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class HomePage extends StatelessWidget {
  // Dummy session data. Replace with your dynamic data source.
  final List<Map<String, String>> sessionHistory = [
    {"date": "2024-06-29", "time": "09:30 AM", "duration": "20m"},
    {"date": "2024-06-28", "time": "10:45 AM", "duration": "15m"},
    {"date": "2024-06-26", "time": "04:10 PM", "duration": "35m"},
  ];

  // Example: tracker for the past 7 days (true means a session was had that day)
  final List<bool> sessionTracker = [
    true,
    false,
    true,
    true,
    false,
    false,
    true,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: TherapyDrawer(
        onLogout: () async {
          await Supabase.instance.client.auth.signOut();
        },
      ),
      appBar: AppBar(title: Text('Home')),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Top Card for New Session
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start New Session',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Begin a new therapy conversation with one of our AI therapists.',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final userId =
                                Supabase.instance.client.auth.currentUser?.id;
                            if (userId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "You must be logged in to start a session.",
                                  ),
                                ),
                              );
                              return;
                            }
                            // 1. Create new session object
                            final session = TherapySession(
                              id: Uuid().v4(),
                              userId: userId,
                              therapistAgent: 'Dr. Jonathan Lee', // or dynamic
                              createdAt: DateTime.now(),
                              transcript: [],
                            );
                            // 2. Insert into Supabase
                            await createTherapySession(session);
                            // 3. Navigate to session screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => ActiveSessionPage(session: session),
                              ),
                            );
                          },
                          icon: Icon(Icons.play_arrow_rounded),
                          label: Text("Start Session"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 22),

              // Tracker Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(sessionTracker.length, (index) {
                  return Container(
                    width: 28,
                    height: 28,
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color:
                          sessionTracker[index]
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                  );
                }),
              ),
              SizedBox(height: 10),
              // Days label under the tracker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                    ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                        .map((d) => Text(d, style: TextStyle(fontSize: 12)))
                        .toList(),
              ),

              SizedBox(height: 24),

              // Session History Table
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Session History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(height: 10),
              Card(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Time')),
                    DataColumn(label: Text('Duration')),
                  ],
                  rows:
                      sessionHistory
                          .map(
                            (session) => DataRow(
                              cells: [
                                DataCell(Text(session['date']!)),
                                DataCell(Text(session['time']!)),
                                DataCell(Text(session['duration']!)),
                              ],
                            ),
                          )
                          .toList(),
                ),
              ),
              // Add more widgets if you want!
            ],
          ),
        ),
      ),
    );
  }
}
