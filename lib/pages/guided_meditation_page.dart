import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:no_couch_needed/config/api_config.dart';
import 'package:no_couch_needed/widgets/ai_agent_widget.dart';
import 'package:vapinew/vapinew.dart';
import 'dart:convert';

class GuidedMeditationPage extends ConsumerStatefulWidget {
  const GuidedMeditationPage({super.key});

  @override
  _GuidedMeditationPageState createState() => _GuidedMeditationPageState();
}

class _GuidedMeditationPageState extends ConsumerState<GuidedMeditationPage> {
  String buttonText = 'Start Meditation';
  bool isLoading = false;
  bool isMeditating = false;
  bool isSpeaking = false;
  String? activeSpeaker;
  DateTime? meditationStartTime;
  Duration? meditationDuration;
  Timer? _durationTimer;

  // Vapi instance
  Vapi vapi = Vapi(ApiConfig.vapiApiKey);

  // Meditation assistant ID - you'll need to replace this with your actual assistant ID
  final String meditationAssistantId = 'df9b3484-bc9c-415b-b61a-f16cea8b31db';

  // Calming blue color for the AI agent
  final Color meditationColor = const Color(0xFF4FC3F7); // Light blue

  // Timer for auto-stop speaking animation
  Timer? _speakingTimer;

  @override
  void initState() {
    super.initState();

    vapi.onEvent.listen((event) {
      if (event.label == "call-start") {
        setState(() {
          buttonText = 'End Meditation';
          isLoading = false;
          isMeditating = true;
          meditationStartTime = DateTime.now();
          _startDurationTimer();
        });
      }

      if (event.label == "call-end") {
        setState(() {
          buttonText = 'Start Meditation';
          isLoading = false;
          isMeditating = false;
          isSpeaking = false;
          activeSpeaker = null;
          _stopDurationTimer();
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

        if (data is Map && data["type"] == "transcript") {
          final transcriptType = data["transcriptType"];
          final role = data["role"] == "user" ? "user" : "assistant";

          // Only handle speaking animation, no transcript storage
          if (transcriptType == "partial") {
            setState(() {
              isSpeaking = true;
              activeSpeaker = role;
            });

            _speakingTimer?.cancel();
            _speakingTimer = Timer(const Duration(milliseconds: 4000), () {
              if (mounted) {
                setState(() {
                  isSpeaking = false;
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
            _speakingTimer?.cancel();
            setState(() {
              isSpeaking = true;
              activeSpeaker = role;
            });

            Future.delayed(const Duration(milliseconds: 400), () {
              if (mounted) {
                setState(() {
                  isSpeaking = false;
                });
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
    });
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && meditationStartTime != null) {
        setState(() {
          meditationDuration = DateTime.now().difference(meditationStartTime!);
        });
      }
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '00:00';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleEndMeditation() async {
    _speakingTimer?.cancel();
    _stopDurationTimer();

    if (isMeditating) {
      await vapi.stop();
    }

    final duration = meditationDuration?.inMinutes ?? 0;

    if (mounted) {
      await showDialog<bool>(
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
                    color: meditationColor.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: meditationColor.withOpacity(0.2),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: meditationColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: meditationColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.self_improvement,
                        color: meditationColor,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Meditation Complete',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      duration > 0
                          ? 'You meditated for $duration minutes'
                          : 'Thank you for taking this moment',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'May you carry this peace with you',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: meditationColor.withOpacity(0.8),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: meditationColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 32,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      );

      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _speakingTimer?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) async {
        await _handleEndMeditation();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Guided Meditation',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF414345),
          actions: [
            if (isMeditating)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: meditationColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: meditationColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _formatDuration(meditationDuration),
                      style: TextStyle(
                        color: meditationColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                // AI Agent Widget
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AiAgentWidget(
                          isSpeaking: isSpeaking,
                          activeSpeaker: activeSpeaker,
                          therapistColor: meditationColor,
                          userColor: meditationColor,
                        ),
                        const SizedBox(height: 40),
                        if (!isMeditating) ...[
                          Text(
                            'Find Your Peace',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Start a guided meditation session\nto relax and center yourself',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: meditationColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: meditationColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.spa,
                                  color: meditationColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Meditation in Progress',
                                  style: TextStyle(
                                    color: meditationColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Bottom controls
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Meditation tips
                      if (!isMeditating)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.grey[900]?.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[800]!,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.tips_and_updates,
                                    color: meditationColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Meditation Tips',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '• Find a quiet, comfortable space\n'
                                '• Sit or lie down in a relaxed position\n'
                                '• Focus on your breathing\n'
                                '• Let thoughts come and go without judgment',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Control button
                      ElevatedButton(
                        onPressed:
                            isLoading
                                ? null
                                : () async {
                                  setState(() {
                                    buttonText = 'Loading...';
                                    isLoading = true;
                                  });

                                  if (!isMeditating) {
                                    meditationStartTime = DateTime.now();
                                    meditationDuration = Duration.zero;
                                    await vapi.start(
                                      assistantId: meditationAssistantId,
                                    );
                                  } else {
                                    await _handleEndMeditation();
                                  }

                                  setState(() {
                                    isLoading = false;
                                  });
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isMeditating ? Colors.red : meditationColor,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isMeditating
                                  ? Icons.stop
                                  : Icons.self_improvement,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              buttonText,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
      ),
    );
  }
}
