import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A quick-select button for fabric roll lengths.
/// Displays the length value and optionally a multiplier badge.
/// Supports tap to increment, and hold to decrement once, then rapidly if held longer.
class LengthButton extends StatefulWidget {
  final double length;
  final String unit;
  final int multiplier;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const LengthButton({
    super.key,
    required this.length,
    this.unit = 'meter',
    this.multiplier = 0,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<LengthButton> createState() => _LengthButtonState();
}

class _LengthButtonState extends State<LengthButton> {
  Timer? _initialDelayTimer;
  Timer? _periodicTimer;

  void _startTimer() {
    _stopTimer();
    if (widget.onLongPress == null) return;
    
    // Decrement once immediately on long press start
    widget.onLongPress!();
    
    // Set a delay (e.g. 500ms) before starting rapid repeat
    _initialDelayTimer = Timer(const Duration(milliseconds: 500), () {
      if (widget.multiplier <= 0) {
        _stopTimer();
        return;
      }
      
      // Start rapid periodic decrementing
      _periodicTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (widget.multiplier <= 0) {
          _stopTimer();
        } else {
          widget.onLongPress!();
        }
      });
    });
  }

  void _stopTimer() {
    _initialDelayTimer?.cancel();
    _initialDelayTimer = null;
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  String get _displayLength {
    final valText = widget.length == widget.length.roundToDouble()
        ? widget.length.toInt().toString()
        : widget.length.toStringAsFixed(1);
    return valText;
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.multiplier > 0;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPressStart: (_) => _startTimer(),
      onLongPressEnd: (_) => _stopTimer(),
      onLongPressUp: () => _stopTimer(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentAmber.withValues(alpha: 0.15)
              : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.accentAmber : AppTheme.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.accentAmber.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _displayLength,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppTheme.accentAmber
                    : AppTheme.textPrimary,
              ),
            ),
            if (widget.multiplier > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentAmber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '×${widget.multiplier}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.surfaceDark,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
