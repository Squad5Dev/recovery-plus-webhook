import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:recoveryplus/providers/theme_provider.dart';
import 'package:recoveryplus/screens/auth_screen.dart';
import 'package:recoveryplus/screens/home_screen.dart';
import 'package:recoveryplus/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:recoveryplus/services/notification_service.dart';
import 'package:recoveryplus/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final notificationService = NotificationService();
  await NotificationService().initialize();

  await notificationService.requestPermissions();

  runApp(MyApp());
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

    // Actual auth flow - remove the temporary bypass
    if (authService.user == null) {
      return AuthScreen();
    } else {
      return HomeScreen();
    }
  }
}
