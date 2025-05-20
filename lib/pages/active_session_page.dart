import 'package:flutter/material.dart';
import 'package:no_couch_needed/models/therapy_sessions.dart';
import 'dart:math';

import 'package:no_couch_needed/widgets/glassy_orb.dart';
import 'package:vapinew/vapinew.dart';

class ActiveSessionPage extends StatefulWidget {
  final TherapySession session;
  const ActiveSessionPage({Key? key, required this.session}) : super(key: key);

  @override
  _ActiveSessionPageState createState() => _ActiveSessionPageState();
}

class _ActiveSessionPageState extends State<ActiveSessionPage> {
  String buttonText = 'Start Call';
  bool isLoading = false;
  bool isCallStarted = false;
  Vapi vapi = Vapi('30f8e0b4-a6d4-4091-b584-503f1a9bc55a');

  // Transcript storage
  final List<_TranscriptLine> transcriptLines = [];

  @override
  void initState() {
    super.initState();

    vapi.onEvent.listen((event) {
      if (event.label == "call-start") {
        setState(() {
          buttonText = 'End Call';
          isLoading = false;
          isCallStarted = true;
        });
        print('call started');
      }
      if (event.label == "call-end") {
        setState(() {
          buttonText = 'Start Call';
          isLoading = false;
          isCallStarted = false;
        });
        print('call ended');
      }
      if (event.label == "message") {
        print('message: ${event.value}');
        final data = event.value;
        // Only use "final" transcripts for readability
        if (data is Map &&
            data["type"] == "transcript" &&
            data["transcriptType"] == "final" &&
            (data["transcript"] as String?)?.isNotEmpty == true) {
          setState(() {
            transcriptLines.add(
              _TranscriptLine(data["transcript"]!, DateTime.now()),
            );
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Active Session',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF414345),
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
        child: SafeArea(
          child: Column(
            children: [
              // Button at the top
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : () async {
                            setState(() {
                              buttonText = 'Loading...';
                              isLoading = true;
                            });
                            if (!isCallStarted) {
                              await vapi.start(
                                assistantId:
                                    'e7f029cd-474c-47ff-93a0-9aaad813d0f9',
                                assistantOverrides: {
                                  'variableValues': {'name': 'Selope'},
                                },
                              );
                            } else {
                              await vapi.stop();
                            }
                          },
                  child: Text(buttonText),
                ),
              ),
              GlassyOrb(),
              const SizedBox(height: 24),
              // Transcript Area
              Expanded(
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.white, // fully visible at bottom
                        Colors.transparent, // fade out at top
                      ],
                      stops: const [0.85, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: _TranscriptListView(lines: transcriptLines),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper class for transcript lines with timestamp
class _TranscriptLine {
  final String text;
  final DateTime timestamp;

  _TranscriptLine(this.text, this.timestamp);
}

class _TranscriptListView extends StatelessWidget {
  final List<_TranscriptLine> lines;

  const _TranscriptListView({Key? key, required this.lines}) : super(key: key);

  Color _fadeColorForIndex(int index, int total) {
    // The most recent (at bottom) is white, then to grey, then to dark as they go up
    if (total == 0) return Colors.white;
    // Use interpolation factor: 0 (bottom) → 1 (top)
    double t = index / max(total - 1, 1);
    if (t < 0.3) {
      // From white → light grey
      return Color.lerp(Colors.white, Colors.grey[350], t / 0.3)!;
    } else if (t < 0.7) {
      // light grey → medium grey
      return Color.lerp(Colors.grey[350], Colors.grey[600], (t - 0.3) / 0.4)!;
    } else {
      // medium grey → dark grey
      return Color.lerp(Colors.grey[600], Colors.grey[900], (t - 0.7) / 0.3)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        // Because reverse:true, index 0 is the most recent (at bottom)
        final tline = lines[lines.length - index - 1];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: AnimatedOpacity(
            // Optionally fade out lines after e.g. 2 minutes
            opacity: _opacityForAge(tline.timestamp),
            duration: const Duration(milliseconds: 600),
            child: Text(
              tline.text,
              style: TextStyle(
                fontSize: 18,
                color: _fadeColorForIndex(index, lines.length),
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  // Optionally fade out after N seconds
  double _opacityForAge(DateTime timestamp) {
    final secondsFade = 120; // fully visible for 2 min
    final age = DateTime.now().difference(timestamp).inSeconds;
    if (age < secondsFade) return 1.0;
    if (age > secondsFade * 2) return 0.0;
    return 1 - ((age - secondsFade) / secondsFade);
  }
}
