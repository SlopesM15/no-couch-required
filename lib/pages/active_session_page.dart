import 'dart:async';

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

  // Add timer for auto-stop speaking animation
  Timer? _speakingTimer;

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
          // Don't immediately set speaking to true on call start
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
        _speakingTimer?.cancel();
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

        if (data is Map && data["type"] == "transcript") {
          final transcriptType = data["transcriptType"];
          final transcript = data["transcript"] as String?;
          final role = data["role"] == "user" ? "user" : "assistant";

          if (transcript?.isNotEmpty == true) {
            // Handle both partial and final transcripts
            if (transcriptType == "partial") {
              // For partial transcripts, update speaking state
              setState(() {
                isSpeaking = true;
                activeSpeaker = role;
              });

              // Cancel any existing timer
              _speakingTimer?.cancel();

              // Set a timer to stop speaking animation if no new partials come
              _speakingTimer = Timer(const Duration(milliseconds: 4000), () {
                if (mounted) {
                  setState(() {
                    isSpeaking = false;
                    // Keep the last speaker visible for a bit longer
                    Future.delayed(const Duration(milliseconds: 1000), () {
                      if (mounted && !isSpeaking) {
                        setState(() {
                          activeSpeaker = null;
                        });
                      }
                    });
                  });
                }
              });
            } else if (transcriptType == "final") {
              // Cancel the timer since we got the final transcript
              _speakingTimer?.cancel();

              setState(() {
                // Keep speaking state for a brief moment
                isSpeaking = true;
                activeSpeaker = role;

                // Add the final transcript to the list
                transcriptLines.add(
                  _TranscriptLine(transcript!, role, DateTime.now()),
                );
              });

              // Auto-detect mood for user messages
              if (role == "user") {
                _detectAndAddMood(transcript!);
              }

              // Gradually fade out the speaking animation
              Future.delayed(const Duration(milliseconds: 400), () {
                if (mounted) {
                  setState(() {
                    isSpeaking = false;
                  });

                  // Clear active speaker a bit later
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted && !isSpeaking) {
                      setState(() {
                        activeSpeaker = null;
                      });
                    }
                  });
                }
              });
            }
          }
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
    _speakingTimer?.cancel();

    if (isCallStarted) {
      await vapi.stop();
    }

    final shouldSave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (BuildContext context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF414345), Color(0xFF232526)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.therapistColor.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.therapistColor.withOpacity(0.2),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: widget.therapistColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.therapistColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.save_outlined,
                      color: widget.therapistColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    'Save Session?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Content
                  Text(
                    'Do you want to save this session and its transcript to your history?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Session info
                  if (transcriptLines.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                color: widget.therapistColor,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${transcriptLines.length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Messages',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          Column(
                            children: [
                              Icon(
                                Icons.psychology_outlined,
                                color: widget.therapistColor,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.session.moodEntries.length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Moods',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Text(
                            'Discard',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.therapistColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Save',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
    _speakingTimer?.cancel();
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
          iconTheme: IconThemeData(color: Colors.white),
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
                                backgroundColor: widget.therapistColor,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: widget.therapistColor
                                    .withOpacity(0.5),
                                disabledForegroundColor: Colors.white70,
                                minimumSize: Size(0, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                              ),
                              child:
                                  isLoading
                                      ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            buttonText,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      )
                                      : Text(
                                        buttonText,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.stop, color: Colors.white),
                              label: Text(
                                'End Session',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withOpacity(0.8),
                                foregroundColor: Colors.white,
                                minimumSize: Size(0, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                shadowColor: Colors.transparent,
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
