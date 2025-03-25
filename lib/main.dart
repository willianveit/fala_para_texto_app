import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';

import 'screens/files_screen.dart';
import 'screens/home_screen.dart';
import 'services/audio_service.dart';

const backgroundTaskName = "speechToTextTask";

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case backgroundTaskName:
        // Background task to continue speech recognition
        AudioService().continueRecognitionInBackground();
        break;
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Workmanager for background tasks
  await Workmanager().initialize(callbackDispatcher);

  // Request permissions on app start
  await [
    Permission.microphone,
    Permission.storage,
  ].request();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fala para Texto',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/files': (context) => const FilesScreen(),
      },
    );
  }
}
