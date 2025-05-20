import 'dart:math' as math;
import 'package:flutter/material.dart';

class AmorphousOrb extends StatefulWidget {
  final bool isTalking;
  final Color color;
  final Duration pulseDuration;

  const AmorphousOrb({
    Key? key,
    required this.isTalking,
    required this.color,
    this.pulseDuration = const Duration(milliseconds: 1200),
  }) : super(key: key);

  @override
  _AmorphousOrbState createState() => _AmorphousOrbState();
}

class _AmorphousOrbState extends State<AmorphousOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.pulseDuration,
    )..repeat(reverse: true);

    _pulse = Tween<double>(
      begin: 0.95,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant AmorphousOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTalking) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return CustomPaint(
          painter: _OrbPainter(
            progress: _pulse.value,
            color: widget.color,
            isTalking: widget.isTalking,
          ),
          child: SizedBox(
            width: 180 * _pulse.value,
            height: 180 * _pulse.value,
          ),
        );
      },
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isTalking;

  _OrbPainter({
    required this.progress,
    required this.color,
    required this.isTalking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color.withOpacity(0.75)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

    // Amorphous shape: Using a circle with "wiggles".
    final center = size.center(Offset.zero);
    final minDim = math.min(size.width, size.height) / 2 - 16;
    final path = Path();
    final points = 8;
    for (int i = 0; i <= points; i++) {
      double angle = i * math.pi * 2 / points;
      double wiggle =
          isTalking
              ? math.sin(angle * 3 + progress * 2 * math.pi) * 10 * progress
              : 0;
      double radius = minDim + wiggle;
      double x = center.dx + radius * math.cos(angle);
      double y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Optionally: Orb "core"
    canvas.drawCircle(
      center,
      minDim * 0.55,
      Paint()..color = color.withOpacity(0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.isTalking != isTalking;
}
