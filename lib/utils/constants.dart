class AppConstants {
  static const String appName = 'Recovery Plus';
  static const String appVersion = '1.0.0';
  static const String supportEmail = 'support@recoveryplus.com';

  // Storage paths
  static const String usersCollection = 'recovery_data';
  static const String painLogsCollection = 'pain_logs';
  static const String medicationsCollection = 'medications';
  static const String exercisesCollection = 'exercises';

  // Time formats
  static const String timeFormat = 'HH:mm';
  static const String dateFormat = 'MMM dd, yyyy';

  // Validation messages
  static const String requiredField = 'This field is required';
  static const String invalidEmail = 'Please enter a valid email';
  static const String weakPassword = 'Password must be at least 6 characters';
}

class AppAssets {
  static const String logo = 'assets/images/logo.png';
  static const String placeholder = 'assets/images/placeholder.png';
}

class AppAnimations {
  static const String success = 'assets/animations/success.json';
  static const String loading = 'assets/animations/loading.json';
}
