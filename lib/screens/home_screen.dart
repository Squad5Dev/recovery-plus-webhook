import 'package:flutter/material.dart';
import 'package:recoveryplus/screens/dashboard_screen.dart';
import 'package:recoveryplus/screens/medication_screen.dart';
import 'package:recoveryplus/screens/exercise_screen.dart';
import 'package:recoveryplus/screens/profile_screen.dart';
import 'package:recoveryplus/screens/statistics_screen.dart';
import 'package:recoveryplus/screens/chatbot/chat_screen.dart';
import 'package:recoveryplus/screens/appointments_screen.dart'; // Import AppointmentsScreen
import 'package:recoveryplus/services/notification_service.dart'; // Added import
import 'package:recoveryplus/services/auth_service.dart'; // Added import
import 'package:shared_preferences/shared_preferences.dart'; // Added import
import 'package:firebase_auth/firebase_auth.dart'; // Added import
import 'package:recoveryplus/services/database_service.dart'; // Added import
import 'package:recoveryplus/models/appointment.dart'; // Added import
import 'package:cloud_firestore/cloud_firestore.dart'; // Added import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    MedicationScreen(),
    ExerciseScreen(),
    StatisticsScreen(),
    AppointmentsScreen(), // Added AppointmentsScreen
    ChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index >= 0 && index < _screens.length) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
      items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.medication), label: 'Meds'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Exercise'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Sched'), // Added Appointments tab
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        ],
      ),
    );
  }
}