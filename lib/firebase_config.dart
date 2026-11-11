import 'package:firebase_core/firebase_core.dart';

abstract final class PricegentFirebaseConfig {
  static const apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyBaTwvkrrjFWvGS16EcnIVFmkNlUCG-LqA',
  );
  static const appId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '1:180345476578:android:232de889706af22e3095bb',
  );
  static const messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '180345476578',
  );
  static const projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'pricegent',
  );
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '180345476578-nf4v4j22ktk1249jlp3l7tn82mjrl776.apps.googleusercontent.com',
  );

  static bool get isConfigured =>
      apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      projectId.isNotEmpty &&
      googleServerClientId.isNotEmpty;

  static FirebaseOptions get options => FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
      );
}
