import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class MoodTrackerPage extends StatefulWidget {
  const MoodTrackerPage({super.key});

  @override
  State<MoodTrackerPage> createState() => _MoodTrackerPageState();
}

class _MoodTrackerPageState extends State<MoodTrackerPage> {
  int? _selectedMoodIndex;
  final TextEditingController _noteController = TextEditingController();
  final List<String> _selectedTriggers = [];
  bool _showAnalytics = false;

  final List<Mood> _moods = [
    Mood(emoji: '😊', label: 'Great', color: Colors.green, value: 5),
    Mood(emoji: '🙂', label: 'Good', color: Colors.lightGreen, value: 4),
    Mood(emoji: '😐', label: 'Okay', color: Colors.orange, value: 3),
    Mood(emoji: '😔', label: 'Low', color: Colors.deepOrange, value: 2),
    Mood(emoji: '😢', label: 'Difficult', color: Colors.red, value: 1),
  ];

  final List<String> _commonTriggers = [
    'Work Stress',
    'Relationships',
    'Sleep Issues',
    'Physical Health',
    'Financial Worry',
    'Social Anxiety',
    'Family Issues',
    'Loneliness',
    'Achievement',
    'Exercise',
    'Good Weather',
    'Social Connection',
  ];

  // Sample data for the chart (in real app, this would come from storage)
  final List<MoodEntry> _moodHistory = [
    MoodEntry(date: DateTime.now().subtract(Duration(days: 6)), moodValue: 3),
    MoodEntry(date: DateTime.now().subtract(Duration(days: 5)), moodValue: 4),
    MoodEntry(date: DateTime.now().subtract(Duration(days: 4)), moodValue: 4),
    MoodEntry(date: DateTime.now().subtract(Duration(days: 3)), moodValue: 2),
    MoodEntry(date: DateTime.now().subtract(Duration(days: 2)), moodValue: 3),
    MoodEntry(date: DateTime.now().subtract(Duration(days: 1)), moodValue: 5),
    MoodEntry(date: DateTime.now(), moodValue: 4),
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _saveMoodEntry() {
    if (_selectedMoodIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a mood first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // In a real app, save to database/storage
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
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
                  color: _moods[_selectedMoodIndex!].color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: _moods[_selectedMoodIndex!].color,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mood Logged!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Keep tracking to see your patterns',
                    style: TextStyle(color: Colors.grey[300], fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedMoodIndex = null;
                        _noteController.clear();
                        _selectedTriggers.clear();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _moods[_selectedMoodIndex!].color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Done',
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mood Tracker',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF414345),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_showAnalytics ? Icons.edit : Icons.analytics),
            onPressed: () {
              setState(() {
                _showAnalytics = !_showAnalytics;
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
          child: _showAnalytics ? _buildAnalytics() : _buildMoodEntry(),
        ),
      ),
    );
  }

  Widget _buildMoodEntry() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'How are you feeling?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, MMMM d').format(DateTime.now()),
            style: TextStyle(fontSize: 16, color: Colors.grey[400]),
          ),
          const SizedBox(height: 30),

          // Mood Selection
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey[800]!.withOpacity(0.5),
                  Colors.grey[900]!.withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[700]!, width: 1),
            ),
            child: Column(
              children: [
                Text(
                  'Select your mood',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_moods.length, (index) {
                    final mood = _moods[index];
                    final isSelected = _selectedMoodIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMoodIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? mood.color.withOpacity(0.2)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? mood.color : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(mood.emoji, style: TextStyle(fontSize: 32)),
                            const SizedBox(height: 4),
                            Text(
                              mood.label,
                              style: TextStyle(
                                color:
                                    isSelected ? mood.color : Colors.grey[400],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Triggers Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey[800]!.withOpacity(0.5),
                  Colors.grey[900]!.withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[700]!, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What influenced your mood?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      _commonTriggers.map((trigger) {
                        final isSelected = _selectedTriggers.contains(trigger);
                        final isPositive = [
                          'Achievement',
                          'Exercise',
                          'Good Weather',
                          'Social Connection',
                        ].contains(trigger);

                        return FilterChip(
                          label: Text(trigger),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTriggers.add(trigger);
                              } else {
                                _selectedTriggers.remove(trigger);
                              }
                            });
                          },
                          selectedColor:
                              isPositive
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.orange.withOpacity(0.3),
                          backgroundColor: Colors.grey[800]?.withOpacity(0.5),
                          side: BorderSide(
                            color:
                                isSelected
                                    ? (isPositive
                                        ? Colors.green
                                        : Colors.orange)
                                    : Colors.grey[700]!,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[400],
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Notes Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey[800]!.withOpacity(0.5),
                  Colors.grey[900]!.withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[700]!, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add a note (optional)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  maxLines: 4,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'How was your day? What happened?',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.grey[800]?.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color:
                            _selectedMoodIndex != null
                                ? _moods[_selectedMoodIndex!].color
                                : Colors.blue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Save Button
          ElevatedButton(
            onPressed: _saveMoodEntry,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _selectedMoodIndex != null
                      ? _moods[_selectedMoodIndex!].color
                      : Colors.blue,
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
                Icon(Icons.save_rounded, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Save Mood Entry',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalytics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mood Analytics',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Last 7 days',
            style: TextStyle(fontSize: 16, color: Colors.grey[400]),
          ),
          const SizedBox(height: 30),

          // Mood Chart
          Container(
            height: 250,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey[800]!.withOpacity(0.5),
                  Colors.grey[900]!.withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[700]!, width: 1),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey[800]!, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final moods = ['', '😢', '😔', '😐', '🙂', '😊'];
                        return Text(
                          moods[value.toInt()],
                          style: TextStyle(fontSize: 16),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final date = DateTime.now().subtract(
                          Duration(days: 6 - value.toInt()),
                        );
                        return Text(
                          DateFormat('E').format(date),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 5,
                lineBarsData: [
                  LineChartBarData(
                    spots:
                        _moodHistory.asMap().entries.map((entry) {
                          return FlSpot(
                            entry.key.toDouble(),
                            entry.value.moodValue.toDouble(),
                          );
                        }).toList(),
                    isCurved: true,
                    color: Colors.cyanAccent,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.cyanAccent.withOpacity(0.2),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.cyanAccent,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Average Mood',
                  value: '3.7',
                  icon: Icons.analytics,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Streak',
                  value: '7 days',
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Common Triggers
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey[800]!.withOpacity(0.5),
                  Colors.grey[900]!.withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[700]!, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Mood Influences',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _TriggerItem(
                  trigger: 'Exercise',
                  percentage: 85,
                  isPositive: true,
                ),
                _TriggerItem(
                  trigger: 'Work Stress',
                  percentage: 65,
                  isPositive: false,
                ),
                _TriggerItem(
                  trigger: 'Social Connection',
                  percentage: 70,
                  isPositive: true,
                ),
                _TriggerItem(
                  trigger: 'Sleep Issues',
                  percentage: 45,
                  isPositive: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        ],
      ),
    );
  }
}

class _TriggerItem extends StatelessWidget {
  final String trigger;
  final int percentage;
  final bool isPositive;

  const _TriggerItem({
    required this.trigger,
    required this.percentage,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                trigger,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Data Models
class Mood {
  final String emoji;
  final String label;
  final Color color;
  final int value;

  Mood({
    required this.emoji,
    required this.label,
    required this.color,
    required this.value,
  });
}

class MoodEntry {
  final DateTime date;
  final int moodValue;
  final List<String>? triggers;
  final String? note;

  MoodEntry({
    required this.date,
    required this.moodValue,
    this.triggers,
    this.note,
  });
}
