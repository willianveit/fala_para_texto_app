import 'dart:io';

import 'package:flutter/material.dart';

import '../services/audio_service.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final AudioService _audioService = AudioService();
  List<FileSystemEntity> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
    });

    final files = await _audioService.getSpeechFiles();

    setState(() {
      _files = files;
      _isLoading = false;
    });
  }

  String _getFileName(String path) {
    final file = File(path);
    final name = file.path.split('/').last;
    // Remove the .txt extension and convert ISO date to a more readable format
    final nameWithoutExt = name.replaceAll('.txt', '');
    try {
      final date = DateTime.parse(nameWithoutExt.replaceAll('-', ':'));
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}:${date.second}';
    } catch (e) {
      return nameWithoutExt;
    }
  }

  Future<void> _showFileContent(String path) async {
    final content = await _audioService.readSpeechFile(path);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getFileName(path)),
        content: SingleChildScrollView(
          child: Text(content),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arquivos Salvos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _files.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum arquivo salvo ainda',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFiles,
                  child: ListView.builder(
                    itemCount: _files.length,
                    itemBuilder: (context, index) {
                      final file = _files[index];
                      return ListTile(
                        title: Text(_getFileName(file.path)),
                        leading: const Icon(Icons.description),
                        onTap: () => _showFileContent(file.path),
                      );
                    },
                  ),
                ),
    );
  }
}
