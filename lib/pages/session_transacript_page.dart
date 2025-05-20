import 'package:flutter/material.dart';
import 'package:no_couch_needed/models/transcript_line.dart';

class SessionTranscriptPage extends StatelessWidget {
  final DateTime dateTime;
  final List<TranscriptLine> transcript;

  SessionTranscriptPage({required this.dateTime, required this.transcript});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Session Transcript')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${dateTime.toLocal().toString().substring(0, 16)}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 16),
              ...transcript.map(
                (line) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    '[${line.role}] ${line.text}',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
