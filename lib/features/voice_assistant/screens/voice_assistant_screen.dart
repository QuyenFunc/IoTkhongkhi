import 'package:flutter/material.dart';
import '../widgets/voice_assistant_widget.dart';

class VoiceAssistantScreen extends StatelessWidget {
  const VoiceAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const VoiceAssistantWidget();
  }
}

// Floating voice assistant button for overlay
class FloatingVoiceAssistant extends StatefulWidget {
  final Widget child;
  
  const FloatingVoiceAssistant({
    super.key,
    required this.child,
  });

  @override
  State<FloatingVoiceAssistant> createState() => _FloatingVoiceAssistantState();
}

class _FloatingVoiceAssistantState extends State<FloatingVoiceAssistant> {
  bool _isVoiceAssistantOpen = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // Floating voice button
        if (!_isVoiceAssistantOpen)
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton(
              heroTag: 'voice_assistant',
              onPressed: _openVoiceAssistant,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.mic),
            ),
          ),
        
        // Voice assistant overlay
        if (_isVoiceAssistantOpen)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: VoiceAssistantWidget(
                onClose: () {
                  setState(() {
                    _isVoiceAssistantOpen = false;
                  });
                },
                showInstructions: false,
              ),
            ),
          ),
      ],
    );
  }

  void _openVoiceAssistant() {
    setState(() {
      _isVoiceAssistantOpen = true;
    });
  }
}
