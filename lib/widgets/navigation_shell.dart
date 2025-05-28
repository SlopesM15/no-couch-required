import 'package:flutter/material.dart';
import 'package:no_couch_needed/pages/home_page.dart';
import 'package:no_couch_needed/pages/journal_page.dart';
import 'package:no_couch_needed/pages/resource_page.dart';
import 'package:no_couch_needed/pages/sessions_page.dart';
import 'package:no_couch_needed/widgets/therapy_drawer.dart';

class NavigationShell extends StatefulWidget {
  final int initialIndex;

  const NavigationShell({super.key, this.initialIndex = 0});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  late int _selectedIndex;

  final List<Widget> _pages = [
    HomePage(),
    SessionsPage(),
    JournalPage(),
    ResourcesPage(),
  ];

  @override
  void initState() {
    _selectedIndex = widget.initialIndex;
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: TherapyDrawer(
        onLogout: () {
          Navigator.pushNamedAndRemoveUntil(context, "/", (r) => false);
        },
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[900]!, Colors.black],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Colors.cyanAccent,
            unselectedItemColor: Colors.grey[600],
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: _NavIcon(
                  icon: Icons.home_rounded,
                  isSelected: _selectedIndex == 0,
                  selectedColor: Colors.cyanAccent,
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: _NavIcon(
                  icon: Icons.spa_rounded,
                  isSelected: _selectedIndex == 1,
                  selectedColor: Colors.greenAccent,
                ),
                label: 'Sessions',
              ),
              BottomNavigationBarItem(
                icon: _NavIcon(
                  icon: Icons.book_rounded,
                  isSelected: _selectedIndex == 2,
                  selectedColor: Colors.purpleAccent,
                ),
                label: 'Journal',
              ),
              BottomNavigationBarItem(
                icon: _NavIcon(
                  icon: Icons.person_rounded,
                  isSelected: _selectedIndex == 3,
                  selectedColor: Colors.orangeAccent,
                ),
                label: 'Resources',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;

  const _NavIcon({
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:
            isSelected ? selectedColor.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 24,
        color: isSelected ? selectedColor : Colors.grey[600],
      ),
    );
  }
}
