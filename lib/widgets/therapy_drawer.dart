import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TherapyDrawer extends StatelessWidget {
  final Function onLogout;

  const TherapyDrawer({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    // Fetch the current user (if logged in)
    final user = Supabase.instance.client.auth.currentUser;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      child: Drawer(
        child: Container(
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
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey[800]!, Colors.grey[900]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.cyanAccent.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Colors.cyanAccent, Colors.cyan],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/ncnlogo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Welcome!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'No Couch Required',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'NAVIGATION',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              _DrawerTile(
                icon: Icons.home_rounded,
                title: 'Home',
                color: Colors.cyanAccent,
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
              ),
              _DrawerTile(
                icon: Icons.person_rounded,
                title: 'Profile',
                color: Colors.pinkAccent,
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/profile');
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Divider(thickness: 1, color: Colors.grey[800]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'SESSION',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              _DrawerTile(
                icon: Icons.event_note_rounded,
                title: 'My Sessions',
                color: Colors.greenAccent,
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/sessions');
                },
              ),
              _DrawerTile(
                icon: Icons.book_rounded,
                title: 'Journal',
                color: Colors.purpleAccent,
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/journal');
                },
              ),

              _DrawerTile(
                icon: Icons.library_books_rounded,
                title: 'Resources',
                color: Colors.orangeAccent,
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/resources');
                },
              ),
              const SizedBox(height: 24),
              _DrawerTile(
                icon: Icons.logout_rounded,
                title: 'Logout',
                color: Colors.redAccent,
                isDestructive: true,
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();

                  onLogout();
                },
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Take care of your mind 🌱",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
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

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[900]?.withOpacity(0.3),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDestructive ? color : Colors.white,
                    fontWeight: FontWeight.w500,
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
