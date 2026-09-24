import 'dart:async';
import 'package:flutter/material.dart';
import 'theme/app_colors.dart';

enum CatState { idle, talking, happy }

class DuoSpeechWidget extends StatefulWidget {
  final String text;
  final CatState state;
  final double catSize;

  const DuoSpeechWidget({
    super.key,
    required this.text,
    this.state = CatState.idle,
    this.catSize = 110,
  });

  @override
  State<DuoSpeechWidget> createState() => _DuoSpeechWidgetState();
}

class _DuoSpeechWidgetState extends State<DuoSpeechWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _catAnimationController;
  String _displayText = '';
  int _currentIndex = 0;
  Timer? _typingTimer;
  bool _isTalking = false;

  @override
  void initState() {
    super.initState();
    _catAnimationController = AnimationController(
      duration: const Duration(milliseconds: 240),
      vsync: this,
    );
    _startTypewriterAnimation();
  }

  @override
  void didUpdateWidget(DuoSpeechWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _resetTypewriter();
      _startTypewriterAnimation();
    }
    if (oldWidget.state != widget.state) {
      _updateCatState();
    }
  }

  void _resetTypewriter() {
    _typingTimer?.cancel();
    setState(() {
      _displayText = '';
      _currentIndex = 0;
      _isTalking = false;
    });
  }

  void _startTypewriterAnimation() {
    if (widget.text.isEmpty) return;

    setState(() {
      _isTalking = true;
    });
    _catAnimationController.repeat(reverse: true);

    _typingTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayText += widget.text[_currentIndex];
          _currentIndex++;
          _isTalking = true;
        });
      } else {
        timer.cancel();
        setState(() {
          _isTalking = false;
        });
        _catAnimationController.reset();
        _updateCatState();
      }
    });
  }

  void _updateCatState() {
    if (widget.state == CatState.happy) {
      _catAnimationController.forward();
    } else if (!_isTalking) {
      _catAnimationController.reset();
    }
  }

  String _getCatImage() {
    if (widget.state == CatState.happy) {
      return 'assets/images/cat_celebrate.png';
    }
    if (_isTalking || widget.state == CatState.talking) {
      return 'assets/images/cat_reading.png';
    }
    return 'assets/images/cat_idle.png';
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _catAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = AppColors.card(context);
    final borderColor = AppColors.border(context);
    final textColor = AppColors.textPrimary(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_displayText.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Text(
                  _displayText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
                Positioned(
                  bottom: -12,
                  left: 24,
                  child: CustomPaint(
                    size: const Size(20, 10),
                    painter: _SpeechBubbleTailPainter(
                      fillColor: bubbleColor,
                      borderColor: borderColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        AnimatedBuilder(
          animation: _catAnimationController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_catAnimationController.value * 0.06),
              child: Image.asset(
                _getCatImage(),
                width: widget.catSize,
                height: widget.catSize,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: widget.catSize,
                    height: widget.catSize,
                    decoration: BoxDecoration(
                      color: AppColors.soft(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.pets, size: widget.catSize * 0.5, color: AppColors.accent(context)),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SpeechBubbleTailPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;

  _SpeechBubbleTailPainter({
    required this.fillColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SpeechBubbleTailPainter oldDelegate) =>
      oldDelegate.fillColor != fillColor || oldDelegate.borderColor != borderColor;
}
