import 'package:flutter/material.dart';
import '../models/control_model.dart';

/// Widget điều khiển LED
class LedControlCard extends StatelessWidget {
  final DeviceControl deviceControl;
  final bool isLoading;
  final VoidCallback onToggle;

  const LedControlCard({
    super.key,
    required this.deviceControl,
    required this.isLoading,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final ledCommand = LedCommand.fromString(deviceControl.ledCommand);
    final isOn = ledCommand == LedCommand.on;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: isOn ? Colors.amber : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Điều Khiển LED',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Color(int.parse(
                      ledCommand.color.substring(1), 
                      radix: 16,
                    ) + 0xFF000000).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ledCommand.displayText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(int.parse(
                        ledCommand.color.substring(1), 
                        radix: 16,
                      ) + 0xFF000000),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // LED Control Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onToggle,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isOn ? Icons.lightbulb : Icons.lightbulb_outline,
                        color: Colors.white,
                      ),
                label: Text(
                  isLoading 
                      ? 'Đang xử lý...'
                      : isOn 
                          ? 'Tắt LED'
                          : 'Bật LED',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOn ? Colors.orange : Colors.green,
                  disabledBackgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            // Last command time
            if (deviceControl.lastCommandTime != null) ...[
              const SizedBox(height: 8),
              Text(
                'Lệnh cuối: ${_formatTime(deviceControl.lastCommandDateTime!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            
            // Visual LED indicator
            const SizedBox(height: 16),
            Center(
              child: _LedIndicator(
                isOn: isOn,
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s trước';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}p trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h trước';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// Widget hiển thị trạng thái LED bằng hình ảnh
class _LedIndicator extends StatefulWidget {
  final bool isOn;
  final bool isLoading;

  const _LedIndicator({
    required this.isOn,
    required this.isLoading,
  });

  @override
  State<_LedIndicator> createState() => _LedIndicatorState();
}

class _LedIndicatorState extends State<_LedIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isOn && !widget.isLoading) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_LedIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOn && !widget.isLoading) {
      _animationController.repeat(reverse: true);
    } else {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[200],
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Center(
        child: widget.isLoading
            ? const CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.blue,
              )
            : AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isOn 
                          ? Colors.amber.withOpacity(_animation.value)
                          : Colors.grey[400],
                      boxShadow: widget.isOn
                          ? [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.5 * _animation.value),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      Icons.lightbulb,
                      color: widget.isOn ? Colors.white : Colors.grey[600],
                      size: 20,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
