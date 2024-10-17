import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:learner/firebase_options.dart';
import 'package:learner/ui/auth/splash_screen.dart'; // Ensure this file path is correct

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: SplashScreen(),  // Ensure this widget is correctly defined in splash_screen.dart
    );
  }
}
