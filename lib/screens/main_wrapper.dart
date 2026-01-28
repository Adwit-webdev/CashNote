import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'notes_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const NotesScreen(), // The new screen
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.black,
        indicatorColor: const Color(0xFFFFD700), // Yellow indicator
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.account_balance_wallet, color: Colors.black),
            label: 'Money',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.assignment, color: Colors.black),
            label: 'Notes',
          ),
        ],
      ),
    );
  }
}