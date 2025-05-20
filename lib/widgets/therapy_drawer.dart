import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TherapyDrawer extends StatelessWidget {
  final Function onLogout;

  TherapyDrawer({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    // Fetch the current user (if logged in)
    final user = Supabase.instance.client.auth.currentUser;

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      child: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE3F2FD), Color(0xFFF8F9FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: AnimatedRotation(
                        duration: Duration(milliseconds: 800),
                        turns: 1,
                        child: Icon(
                          Icons.self_improvement,
                          color: Color(0xFF1976D2),
                          size: 32,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      user?.email ?? 'Welcome!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Therapy App',
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text(
                  'Navigation',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                    fontSize: 14,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.home, color: Color(0xFF1976D2)),
                title: Text('Home', style: TextStyle(fontSize: 18)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hoverColor: Colors.blue[50],
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
              ),
              ListTile(
                leading: Icon(Icons.person, color: Color(0xFF1976D2)),
                title: Text('Profile', style: TextStyle(fontSize: 18)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hoverColor: Colors.blue[50],
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/profile');
                },
              ),

              Divider(thickness: 1, endIndent: 25, indent: 25),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text(
                  'Session',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                    fontSize: 14,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.event_note, color: Colors.teal),
                title: Text("My Sessions", style: TextStyle(fontSize: 18)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hoverColor: Colors.teal[50],
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/sessions');
                },
              ),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.redAccent),
                title: Text(
                  'Logout',
                  style: TextStyle(fontSize: 18, color: Colors.redAccent),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hoverColor: Colors.red[100],
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
                  onLogout();
                },
              ),
              SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Take care of your mind. 🌱",
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
