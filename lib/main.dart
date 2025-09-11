import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recoveryplus/providers/theme_provider.dart';
import 'package:recoveryplus/screens/auth_screen.dart';
import 'package:recoveryplus/screens/home_screen.dart';
import 'package:recoveryplus/services/auth_service.dart';
import 'package:recoveryplus/services/notification_service.dart';
import 'package:recoveryplus/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  // Reschedule meds after boot
  await _handleBootEvents(notificationService);

  runApp(MyApp());
}

Future<void> _handleBootEvents(NotificationService notificationService) async {
  final prefs = await SharedPreferences.getInstance();
  final lastScheduleTime = prefs.getInt('last_schedule_time') ?? 0;
  final now = DateTime.now().millisecondsSinceEpoch;

  // If device reboot or >1 hour since last schedule
  if (now - lastScheduleTime > 3600000) {
    // Here you should fetch medications from Firestore/db and call:
    // await notificationService.rescheduleAllMedications(medicationListFromDb);
    print('🔄 Device reboot detected, rescheduling notifications...');
  }
  await prefs.setInt('last_schedule_time', now);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Recovery Plus',
            theme: themeProvider.isDarkMode
                ? AppTheme.darkTheme
                : AppTheme.lightTheme,
            home: AuthWrapper(),
            debugShowCheckedModeBanner: false,
            supportedLocales: [Locale('en', 'US'), Locale('es', 'ES')],
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    if (authService.user == null) {
      return AuthScreen();
    } else {
      return HomeScreen();
    }
  }
}
