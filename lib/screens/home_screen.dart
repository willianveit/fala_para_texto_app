import 'package:flutter/material.dart';

import '../services/audio_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioService _audioService = AudioService();
  String _recognizedText = '';
  bool _isListening = false;
  final bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeAudioService();
    _audioService.textStream.listen((text) {
      setState(() {
        _recognizedText = text;
      });
    });
  }

  Future<void> _initializeAudioService() async {
    await _audioService.initialize();
  }

  Future<void> _toggleListening() async {
    await _audioService.toggleListening();
    setState(() {
      _isListening = _audioService.isListening;
      if (!_isListening) {
        // Reset the text when we stop listening
        _recognizedText = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fala para Texto'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.pushNamed(context, '/files');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Text(
                    _recognizedText.isEmpty
                        ? 'Clique no botão "Escutar" para começar a reconhecer fala'
                        : _recognizedText,
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: _toggleListening,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  _isListening ? 'Parar' : 'Escutar',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
