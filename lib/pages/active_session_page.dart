import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:no_couch_needed/models/mood_entry.dart';
import 'dart:math';
import 'package:no_couch_needed/models/therapy_sessions.dart';
import 'package:no_couch_needed/models/transcript_line.dart';
import 'package:no_couch_needed/providers/profile_provider.dart';
import 'package:no_couch_needed/widgets/ai_agent_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vapinew/vapinew.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Add the mood detection function
Future<Map<String, String>> getMoodAndColour(String transcription) async {
  final apiKey =
      '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';

  try {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "system",
            "content":
                "You are an emotion analysis AI. Given TEXT, return JSON like: {\"mood\": \"sad\", \"colour\": \"blue\"}. Use moods like: happy, sad, anxious, calm, angry, excited, confused, frustrated, hopeful, neutral. Use colors: green, blue, red, cyan, orange, purple, yellow, pink, gray.",
          },
          {"role": "user", "content": "Text: $transcription"},
        ],
        "max_tokens": 50,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      return Map<String, String>.from(jsonDecode(content));
    } else {
      print('OpenAI API error: ${response.statusCode} - ${response.body}');
      return {'mood': 'neutral', 'colour': 'gray'};
    }
  } catch (e) {
    print('Error detecting mood: $e');
    return {'mood': 'neutral', 'colour': 'gray'};
  }
}

class ActiveSessionPage extends ConsumerStatefulWidget {
  final TherapySession session;
  final String assistantId;
  final Color therapistColor;

  const ActiveSessionPage({
    super.key,
    required this.session,
    required this.assistantId,
    required this.therapistColor,
  });

  @override
  _ActiveSessionPageState createState() => _ActiveSessionPageState();
}

class _ActiveSessionPageState extends ConsumerState<ActiveSessionPage> {
  String buttonText = 'Start Call';
  bool isLoading = false;
  bool isCallStarted = false;
  bool isSpeaking = false;
  String? activeSpeaker;
  DateTime? sessionStartTime;
  Vapi vapi = Vapi('30f8e0b4-a6d4-4091-b584-503f1a9bc55a');

  final List<_TranscriptLine> transcriptLines = [];
  final TextEditingController _textController = TextEditingController();

  // Add loading state for mood detection
  bool isMoodDetecting = false;

  @override
  void initState() {
    super.initState();

    vapi.onEvent.listen((event) {
      if (event.label == "call-start") {
        setState(() {
          buttonText = 'End Call';
          isLoading = false;
          isCallStarted = true;
          sessionStartTime = DateTime.now();
          isSpeaking = true;
          activeSpeaker = "assistant";
        });
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted)
            setState(() {
              isSpeaking = false;
              activeSpeaker = null;
            });
        });
      }
      if (event.label == "call-end") {
        setState(() {
          buttonText = 'Start Call';
          isLoading = false;
          isCallStarted = false;
          isSpeaking = false;
          activeSpeaker = null;
        });
      }
      if (event.label == "message") {
        var data = event.value;

        if (data is String && data.trim().startsWith("{")) {
          try {
            data = jsonDecode(data);
          } catch (e) {
            print("Failed to decode JSON: $e");
            return;
          }
        }

        if (data is Map &&
            data["type"] == "transcript" &&
            data["transcriptType"] == "final" &&
            (data["transcript"] as String?)?.isNotEmpty == true) {
          final transcriptText = data["transcript"]!;
          final speakerRole = data["role"] == "user" ? "user" : "assistant";

          setState(() {
            isSpeaking = true;
            activeSpeaker = speakerRole;
            transcriptLines.add(
              _TranscriptLine(transcriptText, speakerRole, DateTime.now()),
            );
          });

          // Auto-detect mood for user messages
          if (speakerRole == "user") {
            _detectAndAddMood(transcriptText);
          }

          Future.delayed(const Duration(milliseconds: 1600), () {
            if (mounted)
              setState(() {
                isSpeaking = false;
                activeSpeaker = null;
              });
          });
        }
      }
    });
  }

  // New method to detect mood automatically
  Future<void> _detectAndAddMood(String transcriptText) async {
    if (sessionStartTime == null || transcriptText.trim().length < 5) return;

    setState(() {
      isMoodDetecting = true;
    });

    try {
      final moodData = await getMoodAndColour(transcriptText);
      final sessionTime =
          DateTime.now().difference(sessionStartTime!).inSeconds.toDouble();

      final moodEntry = MoodEntry(
        mood: moodData['mood'] ?? 'neutral',
        colour: moodData['colour'] ?? 'gray',
        sessionTime: sessionTime,
      );

      setState(() {
        widget.session.moodEntries.add(moodEntry);
        isMoodDetecting = false;
      });
    } catch (e) {
      print('Failed to detect mood: $e');
      setState(() {
        isMoodDetecting = false;
      });
    }
  }

  Future<void> _handleEndSession() async {
    if (isCallStarted) {
      await vapi.stop();
    }

    final shouldSave = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Save Session?'),
            content: Text(
              'Do you want to save this session and its transcript to your history?',
            ),
            actions: [
              TextButton(
                child: Text('Discard'),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: Text('Save'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (shouldSave == true) {
      final transcript =
          transcriptLines
              .map((tl) => TranscriptLine(tl.text, tl.role, tl.timestamp))
              .toList();

      final sessionToSave = widget.session.copyWith(transcript: transcript);
      await saveTherapySession(sessionToSave);
    }

    if (mounted) Navigator.of(context).pop();
  }

  void _sendUserMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      isSpeaking = true;
      activeSpeaker = "user";
      transcriptLines.add(_TranscriptLine(text, "user", DateTime.now()));
    });

    // Auto-detect mood for manual text input
    _detectAndAddMood(text);

    _textController.clear();

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted)
        setState(() {
          isSpeaking = false;
          activeSpeaker = null;
        });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) async {
        await _handleEndSession();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Session with ${widget.session.therapistAgent}',
            style: TextStyle(color: Colors.white),
            textScaleFactor: 0.8,
          ),
          backgroundColor: const Color(0xFF414345),
          actions: [
            if (isMoodDetecting)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.therapistColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Analyzing mood...',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
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
                AiAgentWidget(
                  isSpeaking: isSpeaking,
                  activeSpeaker: activeSpeaker,
                  therapistColor: widget.therapistColor,
                  userColor: Colors.purpleAccent,
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.white, Colors.transparent],
                        stops: const [0.85, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: _TranscriptListView(
                      lines: transcriptLines,
                      moodEntries: widget.session.moodEntries,
                      sessionStartTime: sessionStartTime ?? DateTime.now(),
                      therapistColor: widget.therapistColor,
                    ),
                  ),
                ),

                // Bottom section - removed manual mood buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18.0,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      // Show mood detection status
                      if (isCallStarted) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.psychology,
                              color: widget.therapistColor,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Mood detection: ${isMoodDetecting ? "Analyzing..." : "Active"}',
                              style: TextStyle(
                                color:
                                    isMoodDetecting
                                        ? Colors.orange
                                        : widget.therapistColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Control buttons row
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  isLoading
                                      ? null
                                      : () async {
                                        setState(() {
                                          buttonText = 'Loading...';
                                          isLoading = true;
                                        });

                                        final profile = await ref.read(
                                          profileProvider.future,
                                        );
                                        if (!isCallStarted) {
                                          sessionStartTime = DateTime.now();
                                          await vapi.start(
                                            assistantId: widget.assistantId,
                                            assistantOverrides: {
                                              'variableValues': {
                                                'name': profile?.name,
                                              },
                                            },
                                          );
                                        } else {
                                          await vapi.stop();
                                        }
                                        setState(() {
                                          isLoading = false;
                                        });
                                      },
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(0, 50),
                              ),
                              child: Text(buttonText),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.stop, color: Colors.red),
                              label: Text('End Session'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.red,
                                minimumSize: Size(0, 50),
                              ),
                              onPressed: _handleEndSession,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Internal transcript model
class _TranscriptLine {
  final String text;
  final String role;
  final DateTime timestamp;
  _TranscriptLine(this.text, this.role, this.timestamp);
}

// Transcript list view with enhanced mood display
class _TranscriptListView extends StatelessWidget {
  final List<_TranscriptLine> lines;
  final List<MoodEntry> moodEntries;
  final DateTime sessionStartTime;
  final Color therapistColor;

  const _TranscriptListView({
    required this.lines,
    required this.moodEntries,
    required this.sessionStartTime,
    required this.therapistColor,
  });

  MoodEntry? _moodForLine(_TranscriptLine line) {
    if (line.role != 'user' || moodEntries.isEmpty) return null;
    final double relSec =
        line.timestamp.difference(sessionStartTime).inSeconds.toDouble();

    MoodEntry? closest;
    double minDist = 30;
    for (final m in moodEntries) {
      double dist = (m.sessionTime - relSec).abs();
      if (dist < minDist) {
        minDist = dist;
        closest = m;
      }
    }
    return closest;
  }

  Color _fadeColorForIndex(int index, int total) {
    if (total == 0) return Colors.white;
    double t = index / max(total - 1, 1);
    if (t < 0.3) {
      return Color.lerp(Colors.white, Colors.grey[350], t / 0.3)!;
    } else if (t < 0.7) {
      return Color.lerp(Colors.grey[350], Colors.grey[600], (t - 0.3) / 0.4)!;
    } else {
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
        final tline = lines[lines.length - index - 1];
        final moodEntry = _moodForLine(tline);

        final userText = Text(
          tline.text,
          style: TextStyle(
            fontSize: 18,
            color:
                tline.role == 'assistant'
                    ? therapistColor.withOpacity(
                      _opacityForAge(tline.timestamp),
                    )
                    : _fadeColorForIndex(index, lines.length),
            fontWeight: FontWeight.normal,
          ),
        );

        if (tline.role != 'user' || moodEntry == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: AnimatedOpacity(
              opacity: _opacityForAge(tline.timestamp),
              duration: const Duration(milliseconds: 600),
              child: userText,
            ),
          );
        }

        // Enhanced mood display for user lines
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: AnimatedOpacity(
            opacity: _opacityForAge(tline.timestamp),
            duration: const Duration(milliseconds: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                userText,
                const SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _parseColor(moodEntry.colour).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _parseColor(moodEntry.colour).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _parseColor(moodEntry.colour),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        moodEntry.mood,
                        style: TextStyle(
                          color: _parseColor(moodEntry.colour),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: _parseColor(moodEntry.colour).withOpacity(0.7),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _parseColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'cyan':
        return Colors.cyan;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'blue':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  double _opacityForAge(DateTime timestamp) {
    final secondsFade = 120;
    final age = DateTime.now().difference(timestamp).inSeconds;
    if (age < secondsFade) return 1.0;
    if (age > secondsFade * 2) return 0.0;
    return 1 - ((age - secondsFade) / secondsFade);
  }
}

Future<void> saveTherapySession(TherapySession session) async {
  final supabase = Supabase.instance.client;
  await supabase.from('therapy_sessions').upsert(session.toMap());
}
