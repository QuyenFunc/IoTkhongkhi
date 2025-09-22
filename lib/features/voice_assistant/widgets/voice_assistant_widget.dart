import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/voice_assistant_service.dart';
import '../models/voice_command.dart';

class VoiceAssistantWidget extends StatefulWidget {
  final VoidCallback? onClose;
  final bool showInstructions;
  
  const VoiceAssistantWidget({
    super.key,
    this.onClose,
    this.showInstructions = true,
  });

  @override
  State<VoiceAssistantWidget> createState() => _VoiceAssistantWidgetState();
}

class _VoiceAssistantWidgetState extends State<VoiceAssistantWidget>
    with TickerProviderStateMixin {
  final VoiceAssistantService _voiceService = VoiceAssistantService();
  
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  
  VoiceAssistantState _currentState = VoiceAssistantState.ready;
  String _currentText = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVoiceService();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeVoiceService() async {
    try {
      await _voiceService.initialize();
      
      // Listen to state changes
      _voiceService.stateStream.listen((state) {
        if (mounted) {
          setState(() {
            _currentState = state;
          });
          _updateAnimations(state);
        }
      });

      // Listen to speech text
      _voiceService.speechStream.listen((text) {
        if (mounted) {
          setState(() {
            _currentText = text;
          });
        }
      });

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing voice service: $e');
      }
      setState(() {
        _currentState = VoiceAssistantState.error;
      });
    }
  }

  void _updateAnimations(VoiceAssistantState state) {
    switch (state) {
      case VoiceAssistantState.listening:
        _pulseController.repeat(reverse: true);
        _waveController.repeat();
        break;
      case VoiceAssistantState.processing:
        _pulseController.stop();
        _waveController.repeat();
        break;
      case VoiceAssistantState.speaking:
        _pulseController.repeat(reverse: true);
        _waveController.stop();
        break;
      case VoiceAssistantState.ready:
      case VoiceAssistantState.error:
        _pulseController.stop();
        _waveController.stop();
        _pulseController.reset();
        _waveController.reset();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('🎤 Trợ lý giọng nói'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: widget.onClose != null
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                )
              : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _showHelp,
              tooltip: 'Hướng dẫn sử dụng',
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildVoiceIndicator(),
                    const SizedBox(height: 32),
                    _buildStateText(),
                    const SizedBox(height: 16),
                    _buildCurrentText(),
                    const SizedBox(height: 32),
                    _buildControlButtons(),
                    if (widget.showInstructions) ...[
                      const SizedBox(height: 32),
                      _buildQuickCommands(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceIndicator() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _waveAnimation]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer wave effect
            if (_currentState == VoiceAssistantState.listening)
              Container(
                width: 150 + (_waveAnimation.value * 50),
                height: 150 + (_waveAnimation.value * 50),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(
                      alpha: 0.3 - (_waveAnimation.value * 0.2),
                    ),
                    width: 2,
                  ),
                ),
              ),
            
            // Main microphone circle
            Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getIndicatorColor(),
                  boxShadow: [
                    BoxShadow(
                      color: _getIndicatorColor().withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _getIndicatorIcon(),
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStateText() {
    final theme = Theme.of(context);
    return Text(
      _getStateText(),
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: _getIndicatorColor(),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCurrentText() {
    if (_currentText.isEmpty) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        '"$_currentText"',
        style: theme.textTheme.bodyLarge?.copyWith(
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Listen button
        FloatingActionButton.extended(
          onPressed: _isInitialized && !_voiceService.isListening
              ? _startListening
              : null,
          backgroundColor: Theme.of(context).colorScheme.primary,
          icon: const Icon(Icons.mic),
          label: const Text('Nghe'),
        ),
        
        // Stop button
        FloatingActionButton.extended(
          onPressed: _voiceService.isListening || _voiceService.isSpeaking
              ? _stopCurrent
              : null,
          backgroundColor: Theme.of(context).colorScheme.error,
          icon: const Icon(Icons.stop),
          label: const Text('Dừng'),
        ),
      ],
    );
  }

  Widget _buildQuickCommands() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lệnh nhanh:',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickCommandChip('Chất lượng KK', () => _voiceService.quickAirQualityCheck()),
              _buildQuickCommandChip('Nhiệt độ', () => _voiceService.quickTemperatureCheck()),
              _buildQuickCommandChip('Trạng thái', () => _voiceService.quickDeviceStatus()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCommandChip(String label, VoidCallback onPressed) {
    return ActionChip(
      label: Text(label),
      onPressed: _isInitialized ? onPressed : null,
      avatar: const Icon(Icons.play_arrow, size: 16),
    );
  }

  Color _getIndicatorColor() {
    switch (_currentState) {
      case VoiceAssistantState.ready:
        return Colors.blue;
      case VoiceAssistantState.listening:
        return Colors.green;
      case VoiceAssistantState.processing:
        return Colors.orange;
      case VoiceAssistantState.speaking:
        return Colors.purple;
      case VoiceAssistantState.error:
        return Colors.red;
    }
  }

  IconData _getIndicatorIcon() {
    switch (_currentState) {
      case VoiceAssistantState.ready:
        return Icons.mic_none;
      case VoiceAssistantState.listening:
        return Icons.mic;
      case VoiceAssistantState.processing:
        return Icons.psychology;
      case VoiceAssistantState.speaking:
        return Icons.volume_up;
      case VoiceAssistantState.error:
        return Icons.error;
    }
  }

  String _getStateText() {
    switch (_currentState) {
      case VoiceAssistantState.ready:
        return 'Sẵn sàng nghe';
      case VoiceAssistantState.listening:
        return 'Đang nghe...';
      case VoiceAssistantState.processing:
        return 'Đang xử lý...';
      case VoiceAssistantState.speaking:
        return 'Đang trả lời...';
      case VoiceAssistantState.error:
        return 'Có lỗi xảy ra';
    }
  }

  Future<void> _startListening() async {
    await _voiceService.startListening();
  }

  Future<void> _stopCurrent() async {
    if (_voiceService.isListening) {
      await _voiceService.stopListening();
    }
    if (_voiceService.isSpeaking) {
      await _voiceService.stopSpeaking();
    }
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎤 Hướng dẫn sử dụng'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bạn có thể hỏi về:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...VoiceIntent.values.where((intent) => intent != VoiceIntent.unknown).map(
                (intent) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Colors.blue)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              intent.displayName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              intent.examplePhrases.first,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
