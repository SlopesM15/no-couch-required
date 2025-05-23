import 'dart:math';
import 'package:flutter/material.dart';

class AiAgentWidget extends StatefulWidget {
  final bool isSpeaking;
  final String? activeSpeaker; // "user" or "assistant" or null
  final Color therapistColor; // Therapist color (cyan, pink, or green)
  final Color userColor; // User color (purple)

  const AiAgentWidget({
    Key? key,
    required this.isSpeaking,
    required this.activeSpeaker,
    required this.therapistColor,
    required this.userColor,
  }) : super(key: key);

  @override
  State<AiAgentWidget> createState() => _AiAgentWidgetState();
}

class _AiAgentWidgetState extends State<AiAgentWidget>
    with TickerProviderStateMixin {
  late final AnimationController _arcController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  late final AnimationController _waveController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _arcController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return Column(
      children: [
        SizedBox(
          width: width,
          height: 180,
          child: AnimatedBuilder(
            animation: Listenable.merge([_arcController, _waveController]),
            builder: (context, _) {
              return CustomPaint(
                painter: AiAgentPainter(
                  arcProgress: _arcController.value,
                  isSpeaking: widget.isSpeaking,
                  waveProgress: _waveController.value,
                  widgetWidth: width,
                  activeSpeaker: widget.activeSpeaker,
                  therapistColor: widget.therapistColor,
                  userColor: widget.userColor,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class AiAgentPainter extends CustomPainter {
  final double arcProgress;
  final bool isSpeaking;
  final double waveProgress;
  final double widgetWidth;
  final String? activeSpeaker;
  final Color therapistColor;
  final Color userColor;

  static const double arcWidth = 2.5;
  static const Color idleColor = Colors.grey;

  // Color logic for active speaker
  Color get arcColor {
    if (activeSpeaker == 'user') return userColor;
    if (activeSpeaker == 'assistant') return therapistColor;
    return idleColor;
  }

  AiAgentPainter({
    required this.arcProgress,
    required this.isSpeaking,
    required this.waveProgress,
    required this.widgetWidth,
    required this.activeSpeaker,
    required this.therapistColor,
    required this.userColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.height * 0.36;

    if (isSpeaking) {
      // Enhanced glowing effect for speaking state
      Paint outerGlowPaint =
          Paint()
            ..color = arcColor.withOpacity(0.3)
            ..strokeWidth = arcWidth + 16
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawCircle(center, radius, outerGlowPaint);

      Paint glowPaint =
          Paint()
            ..color = arcColor.withOpacity(0.7)
            ..strokeWidth = arcWidth + 8
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(center, radius, glowPaint);

      Paint mainPaint =
          Paint()
            ..color = arcColor
            ..strokeWidth = arcWidth
            ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius, mainPaint);
    } else {
      Paint ringPaint =
          Paint()
            ..color = arcColor.withOpacity(0.15)
            ..strokeWidth = arcWidth
            ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius, ringPaint);

      double sweepAngle = pi / 3;
      double startAngle = arcProgress * 2 * pi;

      final Rect arcRect = Rect.fromCircle(center: center, radius: radius);

      // Create comet effect with fading at the end
      final SweepGradient gradient = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [arcColor.withOpacity(0.03), arcColor],
        stops: [0.0, 1.0],
      );

      Paint arcPaint =
          Paint()
            ..shader = gradient.createShader(arcRect)
            ..strokeWidth = arcWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;

      canvas.drawArc(arcRect, startAngle, sweepAngle, false, arcPaint);
    }

    // Sine waves when speaking
    if (isSpeaking) {
      _drawHorizontalSineWave(
        canvas,
        size,
        center,
        radius,
        waveProgress,
        isLeft: true,
      );
      _drawHorizontalSineWave(
        canvas,
        size,
        center,
        radius,
        waveProgress,
        isLeft: false,
      );
    }
  }

  void _drawHorizontalSineWave(
    Canvas canvas,
    Size size,
    Offset center,
    double baseRadius,
    double progress, {
    required bool isLeft,
  }) {
    final Paint wavePaint =
        Paint()
          ..color = arcColor.withOpacity(0.7)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final double amplitude = 20.0;
    final int points = size.width.toInt() ~/ 2;

    double startX = isLeft ? center.dx - baseRadius : center.dx + baseRadius;
    double startY = center.dy;
    double length = isLeft ? startX : (size.width - startX);

    Path path = Path();
    path.moveTo(startX, startY);

    for (int i = 1; i <= points; i++) {
      double frac = i / points;
      double x = isLeft ? startX - length * frac : startX + length * frac;

      double wavePhase = progress * 2 * pi;
      double theta = frac * 2 * pi + wavePhase + (isLeft ? 0 : pi);
      double y =
          startY + sin(theta) * amplitude * (1 - frac); // Fade amplitude to 0

      path.lineTo(x, y);
    }

    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant AiAgentPainter old) =>
      arcProgress != old.arcProgress ||
      isSpeaking != old.isSpeaking ||
      waveProgress != old.waveProgress ||
      activeSpeaker != old.activeSpeaker ||
      therapistColor != old.therapistColor ||
      userColor != old.userColor;
}
