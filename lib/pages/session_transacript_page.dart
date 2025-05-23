import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:no_couch_needed/models/therapy_sessions.dart';
import 'package:no_couch_needed/models/transcript_line.dart';
import 'package:fl_chart/fl_chart.dart';

class SessionTranscriptPage extends StatefulWidget {
  final TherapySession session;

  const SessionTranscriptPage({super.key, required this.session});

  @override
  State<SessionTranscriptPage> createState() => _SessionTranscriptPageState();
}

class _SessionTranscriptPageState extends State<SessionTranscriptPage> {
  bool showMoodGraph = true;

  @override
  Widget build(BuildContext context) {
    final sessionDate = DateFormat(
      'MMMM dd, yyyy',
    ).format(widget.session.createdAt);
    final sessionTime = DateFormat('h:mm a').format(widget.session.createdAt);

    // Calculate duration
    final duration =
        widget.session.transcript.isNotEmpty
            ? widget.session.transcript.last.timestamp
                .difference(widget.session.createdAt)
                .inMinutes
            : 0;

    // Determine therapist color
    Color therapistColor = Colors.cyanAccent;
    if (widget.session.therapistAgent.contains('Maya')) {
      therapistColor = Colors.pinkAccent;
    } else if (widget.session.therapistAgent.contains('Emily')) {
      therapistColor = Colors.greenAccent;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Session Transcript',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF414345),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              showMoodGraph
                  ? Icons.chat_bubble_rounded
                  : Icons.show_chart_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                showMoodGraph = !showMoodGraph;
              });
            },
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
              // Session info header
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(20.0),
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
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: therapistColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: therapistColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.psychology_rounded,
                            color: therapistColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.session.therapistAgent.isNotEmpty
                                    ? widget.session.therapistAgent
                                    : 'Therapy Session',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$sessionDate at $sessionTime',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: '${widget.session.transcript.length} messages',
                        ),
                        const SizedBox(width: 4),
                        _InfoChip(
                          icon: Icons.timer_outlined,
                          label: '${duration}m',
                        ),
                        const SizedBox(width: 4),
                        _InfoChip(
                          icon: Icons.mood,
                          label: '${widget.session.moodEntries.length} moods',
                          color: Colors.purpleAccent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Mood Graph or Transcript
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child:
                      showMoodGraph
                          ? _MoodGraph(
                            session: widget.session,
                            therapistColor: therapistColor,
                          )
                          : _TranscriptView(
                            session: widget.session,
                            therapistColor: therapistColor,
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.grey[400]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color ?? Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

class _MoodGraph extends StatelessWidget {
  final TherapySession session;
  final Color therapistColor;

  const _MoodGraph({required this.session, required this.therapistColor});

  // Convert mood to numeric value for graphing
  double _moodToValue(String mood) {
    final moodValues = {
      'excited': 5.0,
      'happy': 4.0,
      'hopeful': 3.0,
      'calm': 2.0,
      'neutral': 0.0,
      'confused': -1.0,
      'anxious': -2.0,
      'frustrated': -3.0,
      'sad': -4.0,
      'angry': -5.0,
    };
    return moodValues[mood.toLowerCase()] ?? 0.0;
  }

  Color _moodToColor(String mood) {
    final moodColors = {
      'excited': Colors.yellow,
      'happy': Colors.green,
      'hopeful': Colors.lightGreen,
      'calm': Colors.cyan,
      'neutral': Colors.grey,
      'confused': Colors.purple,
      'anxious': Colors.orange,
      'frustrated': Colors.deepOrange,
      'sad': Colors.blue,
      'angry': Colors.red,
    };
    return moodColors[mood.toLowerCase()] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (session.moodEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mood_bad_rounded, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No mood data available',
              style: TextStyle(fontSize: 18, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Prepare data for the graph
    final spots =
        session.moodEntries.map((entry) {
          return FlSpot(
            entry.sessionTime / 60, // Convert to minutes
            _moodToValue(entry.mood),
          );
        }).toList();

    // Sort spots by time
    spots.sort((a, b) => a.x.compareTo(b.x));

    final maxTime = spots.isNotEmpty ? spots.last.x : 1.0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Graph Title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900]?.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Emotional Journey',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your mood throughout the session',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Line Chart
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900]?.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[800]!, width: 1),
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 1,
                    verticalInterval: maxTime / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: Colors.grey[800]!, strokeWidth: 1);
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(color: Colors.grey[800]!, strokeWidth: 1);
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: maxTime / 5,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}m',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 80,
                        getTitlesWidget: (value, meta) {
                          String mood = '';
                          switch (value.toInt()) {
                            case 5:
                              mood = 'Excited';
                              break;
                            case 4:
                              mood = 'Happy';
                              break;
                            case 3:
                              mood = 'Hopeful';
                              break;
                            case 2:
                              mood = 'Calm';
                              break;
                            case 0:
                              mood = 'Neutral';
                              break;
                            case -2:
                              mood = 'Anxious';
                              break;
                            case -3:
                              mood = 'Frustrated';
                              break;
                            case -4:
                              mood = 'Sad';
                              break;
                            case -5:
                              mood = 'Angry';
                              break;
                            default:
                              return const SizedBox();
                          }
                          return Text(
                            mood,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey[800]!, width: 1),
                  ),
                  minX: 0,
                  maxX: maxTime,
                  minY: -5,
                  maxY: 5,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.purpleAccent,
                          Colors.purpleAccent.withOpacity(0.5),
                        ],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final moodEntry = session.moodEntries[index];
                          return FlDotCirclePainter(
                            radius: 6,
                            color: _moodToColor(moodEntry.mood),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.purpleAccent.withOpacity(0.2),
                            Colors.purpleAccent.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.grey[800]!,
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          final moodEntry =
                              session.moodEntries[barSpot.spotIndex];
                          return LineTooltipItem(
                            '${moodEntry.mood}\n${barSpot.x.toStringAsFixed(1)}m',
                            TextStyle(
                              color: _moodToColor(moodEntry.mood),
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Mood Legend
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[900]?.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 8),
                Text(
                  'Tap on points to see mood details',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TranscriptView extends StatelessWidget {
  final TherapySession session;
  final Color therapistColor;

  const _TranscriptView({required this.session, required this.therapistColor});

  @override
  Widget build(BuildContext context) {
    if (session.transcript.isEmpty) {
      return Center(
        child: Text(
          'No transcript available',
          style: TextStyle(fontSize: 16, color: Colors.grey[500]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: session.transcript.length,
      itemBuilder: (context, index) {
        final line = session.transcript[index];
        final isUser = line.role.toLowerCase() == 'user';
        final messageTime = DateFormat('h:mm a').format(line.timestamp);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      isUser
                          ? Colors.purpleAccent.withOpacity(0.2)
                          : therapistColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isUser
                            ? Colors.purpleAccent.withOpacity(0.4)
                            : therapistColor.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Icon(
                  isUser ? Icons.person_rounded : Icons.psychology_rounded,
                  color: isUser ? Colors.purpleAccent : therapistColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Message bubble
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Role and timestamp
                    Row(
                      children: [
                        Text(
                          isUser
                              ? 'You'
                              : (session.therapistAgent.isNotEmpty
                                  ? session.therapistAgent.split(' ').first
                                  : 'Therapist'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                isUser ? Colors.purpleAccent : therapistColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          messageTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Message content
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.grey[800]!.withOpacity(0.3),
                            Colors.grey[900]!.withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[700]!, width: 1),
                      ),
                      child: Text(
                        line.text,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
