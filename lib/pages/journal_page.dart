import 'package:flutter/material.dart';

class JournalPage extends StatefulWidget {
  @override
  _JournalPageState createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final _journalController = TextEditingController();
  String? _selectedMood;

  // Dummy mood log for 7 days; in reality, fetch/save to database
  // Each day is a map: {'date': ..., 'mood': ...}
  final List<Map<String, dynamic>> moodLog = [
    {'day': 'Mon', 'mood': 'Happy'},
    {'day': 'Tue', 'mood': 'Sad'},
    {'day': 'Wed', 'mood': 'Calm'},
    {'day': 'Thu', 'mood': 'Frustrated'},
    {'day': 'Fri', 'mood': 'Happy'},
    {'day': 'Sat', 'mood': 'Excited'},
    {'day': 'Sun', 'mood': 'Worried'},
  ];

  final List<String> emotions = [
    'Calm',
    'Happy',
    'Sad',
    'Angry',
    'Disappointed',
    'Worried',
    'Scared',
    'Frustrated',
    'Excited',
  ];

  void _saveJournalEntry() {
    // Save logic here (to DB, Supabase, or local)
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Journal entry saved!')));
    _journalController.clear();
    setState(() {
      _selectedMood = null;
    });
  }

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Journal & Mood Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Mood Tracker Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How are you feeling today?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          emotions.map((emotion) {
                            final selected = emotion == _selectedMood;
                            return ChoiceChip(
                              label: Text(emotion),
                              selected: selected,
                              onSelected: (bool value) {
                                setState(
                                  () => _selectedMood = value ? emotion : null,
                                );
                              },
                              selectedColor: Colors.blueAccent.shade100,
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Journal Entry
            Text(
              'Your Journal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _journalController,
              maxLines: 6,
              minLines: 3,
              decoration: InputDecoration(
                hintText: 'Write your thoughts here...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _saveJournalEntry,
                icon: Icon(Icons.save),
                label: Text('Save Entry'),
              ),
            ),

            SizedBox(height: 32),

            // Mood Log Table
            Text(
              'Mood Log: This Week',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Day')),
                  ...emotions.map((e) => DataColumn(label: Text(e))),
                ],
                rows:
                    moodLog.map((entry) {
                      return DataRow(
                        cells: [
                          DataCell(Text(entry['day'])),
                          ...emotions.map(
                            (e) => DataCell(
                              entry['mood'] == e
                                  ? Icon(Icons.check_circle, color: Colors.blue)
                                  : SizedBox(),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
