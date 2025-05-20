import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:no_couch_needed/models/therapy_sessions.dart';
import 'package:no_couch_needed/pages/active_session_page.dart';
import 'package:no_couch_needed/pages/session_transacript_page.dart';
import 'package:no_couch_needed/providers/sessions_provider.dart';
// import your ActiveSessionPage and SessionTranscriptPage as appropriate

class SessionsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Your Therapy Sessions')),
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(child: Text('No sessions yet. Start a new session!'));
          }
          return ListView.separated(
            itemCount: sessions.length,
            separatorBuilder: (context, i) => Divider(),
            itemBuilder: (context, i) {
              final session = sessions[i];
              final sessionDate = DateFormat(
                'yyyy-MM-dd – kk:mm',
              ).format(session.createdAt);
              final isCompleted =
                  session
                      .transcript
                      .isNotEmpty; // adjust logic if you add status

              return ListTile(
                leading: Icon(isCompleted ? Icons.article : Icons.chat_bubble),
                title: Text(
                  '${session.therapistAgent} • $sessionDate',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  isCompleted ? 'Completed session' : 'Ongoing conversation',
                ),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  if (!isCompleted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActiveSessionPage(session: session),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => SessionTranscriptPage(
                              dateTime: session.createdAt,
                              transcript: session.transcript,
                            ),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error:
            (err, stack) => Center(child: Text('Error loading sessions: $err')),
      ),
    );
  }
}
