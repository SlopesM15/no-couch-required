import 'package:flutter/material.dart';
import 'package:no_couch_needed/models/therapy_sessions.dart';
import 'package:no_couch_needed/pages/active_session_page.dart';

class TherapistSelectionPage extends StatelessWidget {
  final TherapySession session;

  const TherapistSelectionPage({super.key, required this.session});

  // Therapist data with their assistant IDs and colors
  final List<Map<String, dynamic>> therapists = const [
    {
      'name': 'Dr. Jonathan Lee',
      'specialization': 'Practical Therapist',
      'description':
          'Hello, I\'m Dr. Jonathan Lee. I help you find practical steps and solutions for your challenges so you can move forward with confidence.',
      'assistantId': 'e7f029cd-474c-47ff-93a0-9aaad813d0f9',
      'color': Colors.cyanAccent,
      'image': 'assets/images/dr_jonathan.jpg',
    },
    {
      'name': 'Dr. Maya Santos',
      'specialization': 'Empathetic Listener',
      'description':
          'Hi, I\'m Dr. Maya Santos. I provide a safe, supportive space to listen and help you feel understood as you share what\'s on your mind.',
      'assistantId': '1146c50e-7ee6-48e7-b26d-c2e1d9d16777',
      'color': Colors.pinkAccent,
      'image': 'assets/images/dr_maya.jpg',
    },
    {
      'name': 'Dr. Emily Carter',
      'specialization': 'CBT Therapist',
      'description':
          'Hello, I\'m Dr. Emily Carter. I use cognitive-behavioral tools to help you understand your patterns and make positive, practical changes.',
      'assistantId': '50132a08-e7aa-48cf-bca8-54f66953985b',
      'color': Colors.greenAccent,
      'image': 'assets/images/dr_emily.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Choose Your Therapist',
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Select the therapist that best fits your needs:',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: therapists.length,
                    itemBuilder: (context, index) {
                      final therapist = therapists[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.grey[300]!,
                                Colors.grey[500]!,
                                Colors.grey[700]!,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(-2, -2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                // Update the session with selected therapist info
                                final updatedSession = session.copyWith(
                                  therapistAgent: therapist['name'],
                                );

                                // Navigate to active session with selected therapist
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => ActiveSessionPage(
                                          session: updatedSession,
                                          assistantId:
                                              therapist['assistantId']!,
                                          therapistColor: therapist['color'],
                                        ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(20.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Therapist Avatar with Arc
                                    _TherapistAvatar(
                                      color: therapist['color'],
                                      image: therapist['image'],
                                    ),
                                    const SizedBox(width: 20),
                                    // Therapist Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            therapist['name']!,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            therapist['specialization']!,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: therapist['color'],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            therapist['description']!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[200],
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Arrow icon
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.grey[400],
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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

class _TherapistAvatar extends StatelessWidget {
  final Color color;
  final String image;

  const _TherapistAvatar({required this.color, required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[800]!, Colors.grey[900]!],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Colored arc
          CustomPaint(
            size: const Size(80, 80),
            painter: _ArcPainter(color: color),
          ),
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[700],
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: ClipOval(
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.person, size: 32, color: color);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;

  _ArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw glowing arc
    final glowPaint =
        Paint()
          ..color = color.withOpacity(0.3)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -0.5,
      2,
      false,
      glowPaint,
    );

    // Draw main arc
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -0.5,
      2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
