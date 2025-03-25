import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vosk_flutter_2/vosk_flutter_2.dart';
import 'package:workmanager/workmanager.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  bool _isListening = false;
  String _currentText = '';
  String? _currentFileName;
  bool _isInitialized = false;
  final StreamController<String> _textStreamController =
      StreamController<String>.broadcast();

  // Vosk components
  final _vosk = VoskFlutterPlugin.instance();
  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService;

  Stream<String> get textStream => _textStreamController.stream;
  String get currentText => _currentText;
  bool get isListening => _isListening;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Create model - using an empty path for default model
      _model = await _vosk.createModel('');

      // Create recognizer with the model
      _recognizer = await _vosk.createRecognizer(
        model: _model!,
        sampleRate: 16000,
      );

      // Initialize speech service for microphone
      _speechService = await _vosk.initSpeechService(_recognizer!);

      _isInitialized = true;
      debugPrint('Vosk speech recognition initialized');
    } catch (e) {
      debugPrint('Error initializing speech recognition: $e');
    }
  }

  Future<void> toggleListening() async {
    if (_isListening) {
      await stopListening();
    } else {
      await startListening();
    }
  }

  Future<void> startListening() async {
    if (_isListening) return;

    if (!_isInitialized) {
      await initialize();
    }

    _isListening = true;
    _currentText = '';
    _currentFileName =
        '${DateTime.now().toIso8601String().replaceAll(':', '-')}.txt';

    // Set up listeners for speech recognition results
    _speechService?.onPartial().listen((text) {
      _currentText = text;
      _textStreamController.add(text);
    });

    _speechService?.onResult().listen((text) {
      _currentText = text;
      _textStreamController.add(text);
      _saveTextToFile();
    });

    // Start the speech service
    await _speechService?.start();

    // Register background task
    await Workmanager().registerOneOffTask(
      "speechToTextTask",
      "speechToTextTask",
      initialDelay: Duration.zero,
    );
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    _isListening = false;
    await _speechService?.stop();

    // Save the final text
    await _saveTextToFile();
  }

  Future<void> _saveTextToFile() async {
    if (_currentText.isEmpty || _currentFileName == null) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dirPath = '${appDir.path}/speech_files';
      final dir = Directory(dirPath);

      // Create directory if it doesn't exist
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final file = File('$dirPath/$_currentFileName');
      await file.writeAsString(_currentText);
      debugPrint('Saved text to file: ${file.path}');
    } catch (e) {
      debugPrint('Error saving text to file: $e');
    }
  }

  void continueRecognitionInBackground() {
    // This method will be called from a background task
    if (!_isListening) return;

    // In a real app, you would implement the logic to continue
    // speech recognition in the background
    debugPrint('Continuing speech recognition in background');
  }

  Future<List<FileSystemEntity>> getSpeechFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dirPath = '${appDir.path}/speech_files';
      final dir = Directory(dirPath);

      if (!await dir.exists()) {
        await dir.create(recursive: true);
        return [];
      }

      return dir
          .listSync()
          .where((file) => file.path.endsWith('.txt'))
          .toList();
    } catch (e) {
      debugPrint('Error getting speech files: $e');
      return [];
    }
  }

  Future<String> readSpeechFile(String path) async {
    try {
      final file = File(path);
      return await file.readAsString();
    } catch (e) {
      debugPrint('Error reading speech file: $e');
      return '';
    }
  }
}
