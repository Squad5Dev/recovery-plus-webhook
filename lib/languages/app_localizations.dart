import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'welcome': 'Welcome to Recovery Plus',
      'pain_tracker': 'Pain Tracker',
      'medications': 'Medications',
      'exercises': 'Exercises',
      'profile': 'Profile',
    },
    'es': {
      'welcome': 'Bienvenido a Recovery Plus',
      'pain_tracker': 'Seguidor de Dolor',
      'medications': 'Medicamentos',
      'exercises': 'Ejercicios',
      'profile': 'Perfil',
    },
    // Add more languages as needed
  };

  String get welcome => _localizedValues[locale.languageCode]!['welcome']!;
  String get painTracker =>
      _localizedValues[locale.languageCode]!['pain_tracker']!;
  String get medications =>
      _localizedValues[locale.languageCode]!['medications']!;
  String get exercises => _localizedValues[locale.languageCode]!['exercises']!;
  String get profile => _localizedValues[locale.languageCode]!['profile']!;
}
