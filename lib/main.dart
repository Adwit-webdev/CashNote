import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/main_wrapper.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Notifications
  await NotificationService.init(); 

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CashNote',
      theme: ThemeData(
        searchBarTheme: SearchBarThemeData(
        textStyle: WidgetStateProperty.all(const TextStyle(color: Colors.white)),
        hintStyle: WidgetStateProperty.all(const TextStyle(color: Colors.grey)),
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black, // True Black
        // Modern Color Scheme
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD700), // Gold/Yellow
          onPrimary: Colors.black,
          surface: Color(0xFF1E1E1E), // Dark Grey for Cards
          onSurface: Colors.white,
        ),
      ),
      home: const MainWrapper(),
    );
  }
}