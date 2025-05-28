import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:no_couch_needed/config/api_config.dart';
import 'package:vapinew/vapinew.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:no_couch_needed/models/journal_entry.dart';
import 'package:no_couch_needed/models/transcript_line.dart';
import 'package:no_couch_needed/providers/journal_provider.dart';
import 'package:no_couch_needed/widgets/ai_agent_widget.dart';
import 'package:no_couch_needed/pages/journal_detail_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

enum JournalMode { voice, written }

// Updated Journal Page
class JournalPage extends ConsumerStatefulWidget {
  @override
  _JournalPageState createState() => _JournalPageState();
}

class _JournalPageState extends ConsumerState<JournalPage> {
  // Voice recording related variables
  String buttonText = 'Start Recording';
  bool isLoading = false;
  bool isRecording = false;
  bool isSpeaking = false;
  DateTime? recordingStartTime;
  Vapi vapi = Vapi(ApiConfig.vapiApiKey);
  final List<TranscriptLine> currentTranscript = [];

  // Written journal related variables
  final TextEditingController _writtenController = TextEditingController();
  final FocusNode _writtenFocusNode = FocusNode();
  DateTime? writingStartTime;

  // Common variables
  JournalMode currentMode = JournalMode.voice;
  bool isSavingEntry = false;

  @override
  void initState() {
    super.initState();

    // Voice recording event listeners
    vapi.onEvent.listen((event) {
      print("Event: ${event.label} - ${event.value}");
      if (event.label == "call-start") {
        setState(() {
          buttonText = 'Stop Recording';
          isLoading = false;
          isRecording = true;
          recordingStartTime = DateTime.now();
          isSpeaking = true;
        });
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted)
            setState(() {
              isSpeaking = false;
            });
        });
      }

      if (event.label == "call-end") {
        setState(() {
          buttonText = 'Start Recording';
          isLoading = false;
          isRecording = false;
          isSpeaking = false;
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

          setState(() {
            isSpeaking = true;
            currentTranscript.add(
              TranscriptLine(transcriptText, "user", DateTime.now()),
            );
          });

          Future.delayed(const Duration(milliseconds: 1600), () {
            if (mounted)
              setState(() {
                isSpeaking = false;
              });
          });
        }
      }
    });

    // Listen to text changes for written journal
    _writtenController.addListener(() {
      setState(() {
        if (_writtenController.text.isNotEmpty && writingStartTime == null) {
          writingStartTime = DateTime.now();
        } else if (_writtenController.text.isEmpty) {
          writingStartTime = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _writtenController.dispose();
    _writtenFocusNode.dispose();
    super.dispose();
  }

  Future<Map<String, String>> analyzeJournalEntry(String fullTranscript) async {
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
              "content": """
Analyze this journal entry and provide:
1. A brief summary (2-3 sentences)
2. The overall mood
3. A color representing the mood

Return JSON like:
{
  "summary": "Brief summary here",
  "mood": "happy",
  "color": "green"
}

Use moods: happy, sad, anxious, calm, angry, excited, confused, frustrated, hopeful, neutral
Use colors: green, blue, red, cyan, orange, purple, yellow, pink, gray""",
            },
            {"role": "user", "content": "Journal entry: $fullTranscript"},
          ],
          "max_tokens": 150,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return Map<String, String>.from(jsonDecode(content));
      } else {
        return {
          'summary': 'Unable to generate summary',
          'mood': 'neutral',
          'color': 'gray',
        };
      }
    } catch (e) {
      print('Error analyzing journal: $e');
      return {
        'summary': 'Unable to generate summary',
        'mood': 'neutral',
        'color': 'gray',
      };
    }
  }

  Future<void> _handleSaveEntry() async {
    String fullTranscript;
    DateTime? startTime;
    List<TranscriptLine> transcript;

    if (currentMode == JournalMode.voice) {
      if (currentTranscript.isEmpty) return;
      fullTranscript = currentTranscript.map((line) => line.text).join(' ');
      startTime = recordingStartTime;
      transcript = currentTranscript;
    } else {
      if (_writtenController.text.trim().isEmpty) return;
      fullTranscript = _writtenController.text.trim();
      startTime = writingStartTime;
      transcript = [TranscriptLine(fullTranscript, "user", DateTime.now())];
    }

    setState(() {
      isSavingEntry = true;
    });

    try {
      // Analyze the journal entry
      final analysis = await analyzeJournalEntry(fullTranscript);

      // Calculate duration
      final duration =
          startTime != null
              ? DateTime.now().difference(startTime).inSeconds
              : 0;

      // Create journal entry
      final entry = JournalEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: Supabase.instance.client.auth.currentUser!.id,
        transcript: transcript,
        summary: analysis['summary'],
        overallMood: analysis['mood'],
        moodColor: analysis['color'],
        createdAt: DateTime.now(),
        duration: duration,
      );

      // Save to Supabase
      await Supabase.instance.client
          .from('journal_entries')
          .insert(entry.toMap());

      // Clear current content
      setState(() {
        if (currentMode == JournalMode.voice) {
          currentTranscript.clear();
        } else {
          _writtenController.clear();
          writingStartTime = null;
        }
        isSavingEntry = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Journal entry saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Refresh journal entries
      ref.refresh(journalEntriesProvider);
    } catch (e) {
      setState(() {
        isSavingEntry = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save entry: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearCurrentEntry() {
    setState(() {
      if (currentMode == JournalMode.voice) {
        currentTranscript.clear();
      } else {
        _writtenController.clear();
        writingStartTime = null;
      }
    });
  }

  bool _hasContent() {
    bool hasContent;
    if (currentMode == JournalMode.voice) {
      hasContent = currentTranscript.isNotEmpty;
    } else {
      hasContent = _writtenController.text.trim().isNotEmpty;
    }
    print(
      "_hasContent() called - Mode: $currentMode, Has content: $hasContent, Text: '${_writtenController.text}'",
    );
    return hasContent;
  }

  @override
  Widget build(BuildContext context) {
    final journalEntriesAsync = ref.watch(journalEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Voice Journal',
          style: TextStyle(color: Colors.white),
        ),
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
        child: SafeArea(
          child: Column(
            children: [
              // Mode Toggle
              Container(
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[800]?.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!, width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!isRecording && !isSavingEntry) {
                            setState(() {
                              currentMode = JournalMode.voice;
                              // Clear written content when switching to voice
                              _writtenController.clear();
                              writingStartTime = null;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                currentMode == JournalMode.voice
                                    ? Colors.purpleAccent
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.mic,
                                color:
                                    currentMode == JournalMode.voice
                                        ? Colors.white
                                        : Colors.grey[400],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Voice',
                                style: TextStyle(
                                  color:
                                      currentMode == JournalMode.voice
                                          ? Colors.white
                                          : Colors.grey[400],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          print("Tapping written mode toggle");
                          if (!isRecording && !isSavingEntry) {
                            print("Switching to written mode");
                            setState(() {
                              currentMode = JournalMode.written;
                              // Clear voice content when switching to written
                              currentTranscript.clear();
                              recordingStartTime = null;
                            });
                            print("Current mode is now: $currentMode");
                          } else {
                            print(
                              "Cannot switch - isRecording: $isRecording, isSavingEntry: $isSavingEntry",
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                currentMode == JournalMode.written
                                    ? Colors.purpleAccent
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.edit,
                                color:
                                    currentMode == JournalMode.written
                                        ? Colors.white
                                        : Colors.grey[400],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Written',
                                style: TextStyle(
                                  color:
                                      currentMode == JournalMode.written
                                          ? Colors.white
                                          : Colors.grey[400],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content Area
              if (currentMode == JournalMode.written && !isRecording) ...[
                // Written journal interface
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey[800]!.withOpacity(0.3),
                          Colors.grey[900]!.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[700]!, width: 1),
                    ),
                    child: TextField(
                      controller: _writtenController,
                      focusNode: _writtenFocusNode,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Start writing your thoughts...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 18,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                      ),
                    ),
                  ),
                ),
              ] else if (currentMode == JournalMode.voice &&
                  (isRecording || _hasContent())) ...[
                // Voice recording interface
                AiAgentWidget(
                  isSpeaking: isSpeaking,
                  activeSpeaker: isRecording ? "user" : null,
                  therapistColor: Colors.purpleAccent,
                  userColor: Colors.purpleAccent,
                ),
                const SizedBox(height: 24),
                // Voice transcript
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
                    child: ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 8,
                      ),
                      itemCount: currentTranscript.length,
                      itemBuilder: (context, index) {
                        final line =
                            currentTranscript[currentTranscript.length -
                                index -
                                1];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            line.text,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ] else ...[
                // Show previous entries when no active content
                Expanded(
                  child: journalEntriesAsync.when(
                    data: (entries) {
                      if (entries.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[900]?.withOpacity(0.5),
                                ),
                                child: Icon(
                                  currentMode == JournalMode.voice
                                      ? Icons.mic_none_rounded
                                      : Icons.edit_note_rounded,
                                  size: 48,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'No journal entries yet',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currentMode == JournalMode.voice
                                    ? 'Start recording your thoughts'
                                    : 'Start writing your thoughts',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return _JournalEntryCard(entry: entry);
                        },
                      );
                    },
                    loading:
                        () => Center(
                          child: LoadingAnimationWidget.newtonCradle(
                            color: Colors.purpleAccent,
                            size: 50,
                          ),
                        ),
                    error:
                        (err, stack) => Center(
                          child: Text(
                            'Error loading entries: $err',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                  ),
                ),
              ],

              // Bottom controls
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_hasContent() && !isRecording) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  isSavingEntry ? null : _handleSaveEntry,
                              icon:
                                  isSavingEntry
                                      ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : Icon(Icons.save),
                              label: Text(
                                isSavingEntry ? 'Analyzing...' : 'Save Entry',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                minimumSize: Size(0, 50),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _clearCurrentEntry,
                              icon: Icon(Icons.delete_outline),
                              label: Text('Discard'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                minimumSize: Size(0, 50),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Main action button (only for voice mode)
                    if (currentMode == JournalMode.voice)
                      ElevatedButton(
                        onPressed:
                            isLoading
                                ? null
                                : () async {
                                  setState(() {
                                    buttonText = 'Loading...';
                                    isLoading = true;
                                  });

                                  if (!isRecording) {
                                    recordingStartTime = DateTime.now();
                                    await vapi.start(
                                      assistantId:
                                          '4277ca08-7d1c-4764-ae7b-ed72c0fc943a',
                                    );
                                  } else {
                                    await vapi.stop();
                                  }

                                  setState(() {
                                    isLoading = false;
                                  });
                                },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 56),
                          backgroundColor:
                              isRecording ? Colors.red : Colors.purpleAccent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isRecording ? Icons.stop : Icons.mic,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(buttonText, style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Journal Entry Card Widget (unchanged)
class _JournalEntryCard extends StatelessWidget {
  final JournalEntry entry;

  const _JournalEntryCard({required this.entry});

  Color _parseColor(String? colorName) {
    switch (colorName?.toLowerCase()) {
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
      case 'blue':
        return Colors.blue;
      case 'grey':
      case 'gray':
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM dd, yyyy').format(entry.createdAt);
    final time = DateFormat('h:mm a').format(entry.createdAt);
    final moodColor = _parseColor(entry.moodColor);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[700]!.withOpacity(0.5),
              Colors.grey[800]!.withOpacity(0.5),
              Colors.grey[900]!.withOpacity(0.5),
            ],
          ),
          border: Border.all(color: Colors.grey[700]!, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JournalDetailPage(entry: entry),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: moodColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: moodColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          entry.transcript.length > 1
                              ? Icons.mic_rounded
                              : Icons.edit_rounded,
                          color: moodColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  date,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: moodColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: moodColor.withOpacity(0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: moodColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        entry.overallMood ?? 'neutral',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: moodColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        entry.transcript.length > 1
                                            ? Icons.mic_outlined
                                            : Icons.edit_outlined,
                                        size: 12,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        entry.transcript.length > 1
                                            ? '${(entry.duration / 60).round()}m'
                                            : 'Written',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                    ],
                  ),
                  if (entry.summary != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      entry.summary!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[300],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
