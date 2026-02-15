// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/session_data_service.dart';
import 'end_popup.dart';

class Footer extends StatefulWidget {
  final bool isActive;
  final VoidCallback onStartSession;

  const Footer({
    super.key,
    required this.isActive,
    required this.onStartSession,
  });

  @override
  State<Footer> createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  final SessionDataService _session = SessionDataService();
  void _startSession() {
    _session.start();
    widget.onStartSession();
  }

  void _confirmEndSession() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EndSessionPopup(),
    );
  }

  String _formatTime(int ms) {
    final minutes = (ms ~/ 60000).toString().padLeft(2, '0');
    final seconds =
        ((ms % 60000) ~/ 1000).toString().padLeft(2, '0');
    final milliseconds =
        ((ms % 1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds:$milliseconds';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('appBox').listenable(),
      builder: (_, __, ___) {
        final elapsed = _session.elapsedMs;
        final isRunning = _session.isRunning;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.blue)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Recording Time Elapsed"),
              Text(
                _formatTime(elapsed),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed:
                    widget.isActive 
                      ? (isRunning ? _confirmEndSession : _startSession)
                      : null,
                icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
                label: Text(isRunning ? 'End Session' : 'Start Session'),
              ),
            ],
          ),
        );
      },
    );
  }
}