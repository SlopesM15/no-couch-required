// navigation_shell.dart
import 'package:flutter/material.dart';
import 'package:no_couch_needed/pages/home_page.dart';
import 'package:no_couch_needed/pages/journal_page.dart';
import 'package:no_couch_needed/pages/profile_page.dart';
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
    SessionsPage(), // Or any widget if you have this
    JournalPage(), // Or any widget if you have this
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.spa), label: 'Sessions'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Journal'),
        ],
      ),
    );
  }
}
