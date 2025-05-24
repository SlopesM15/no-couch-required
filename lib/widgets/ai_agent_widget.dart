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

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _arcController.dispose();
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return Column(
      children: [
        SizedBox(
          width: width,
          height: 220,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _arcController,
              _waveController,
              _pulseController,
            ]),
            builder: (context, _) {
              return CustomPaint(
                painter: AiAgentPainter(
                  arcProgress: _arcController.value,
                  isSpeaking: widget.isSpeaking,
                  waveProgress: _waveController.value,
                  pulseProgress: _pulseController.value,
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
  final double pulseProgress;
  final double widgetWidth;
  final String? activeSpeaker;
  final Color therapistColor;
  final Color userColor;

  static const double arcWidth = 5.0; // Increased from 2.5
  static const double innerArcWidth = 3.0; // New inner arc
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
    required this.pulseProgress,
    required this.widgetWidth,
    required this.activeSpeaker,
    required this.therapistColor,
    required this.userColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double baseRadius = size.height * 0.4; // Increased from 0.36

    if (isSpeaking) {
      // Draw multiple glow layers for enhanced effect
      _drawSpeakingState(canvas, center, baseRadius);
    } else {
      // Draw idle state with enhanced visuals
      _drawIdleState(canvas, center, baseRadius);
    }

    // Draw center dot
    _drawCenterDot(canvas, center);

    // Sine waves when speaking
    if (isSpeaking) {
      _drawEnhancedWaves(canvas, size, center, baseRadius);
    }
  }

  void _drawSpeakingState(Canvas canvas, Offset center, double radius) {
    // Animated outer glow with pulse
    final double pulseRadius = radius + (pulseProgress * 15);
    Paint outerPulsePaint =
        Paint()
          ..color = arcColor.withOpacity(0.1 + (pulseProgress * 0.1))
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(center, pulseRadius, outerPulsePaint);

    // Multiple glow layers
    for (int i = 3; i >= 1; i--) {
      Paint glowPaint =
          Paint()
            ..color = arcColor.withOpacity(0.2 * (i / 3))
            ..strokeWidth = arcWidth + (i * 6)
            ..style = PaintingStyle.stroke
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, i * 8.0);
      canvas.drawCircle(center, radius, glowPaint);
    }

    // Inner circle
    Paint innerPaint =
        Paint()
          ..color = arcColor.withOpacity(0.3)
          ..strokeWidth = innerArcWidth
          ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 15, innerPaint);

    // Main circle
    Paint mainPaint =
        Paint()
          ..color = arcColor
          ..strokeWidth = arcWidth
          ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, mainPaint);

    // Accent dots around the circle
    _drawAccentDots(canvas, center, radius, true);
  }

  void _drawIdleState(Canvas canvas, Offset center, double radius) {
    // Background ring with subtle gradient
    Paint bgRingPaint =
        Paint()
          ..color = arcColor.withOpacity(0.1)
          ..strokeWidth = arcWidth
          ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgRingPaint);

    // Inner ring
    Paint innerRingPaint =
        Paint()
          ..color = arcColor.withOpacity(0.05)
          ..strokeWidth = innerArcWidth
          ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 15, innerRingPaint);

    // Rotating arc with enhanced comet effect
    double sweepAngle = pi / 2; // Increased from pi/3
    double startAngle = arcProgress * 2 * pi;

    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);

    // Trail effect
    for (int i = 0; i < 3; i++) {
      double trailStart = startAngle - (i * 0.3);
      double trailOpacity = 0.3 - (i * 0.1);

      Paint trailPaint =
          Paint()
            ..color = arcColor.withOpacity(trailOpacity)
            ..strokeWidth = arcWidth - (i * 0.5)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;

      canvas.drawArc(arcRect, trailStart, sweepAngle * 0.3, false, trailPaint);
    }

    // Main arc with gradient
    final SweepGradient gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: [
        arcColor.withOpacity(0.0),
        arcColor.withOpacity(0.3),
        arcColor.withOpacity(0.7),
        arcColor,
      ],
      stops: [0.0, 0.3, 0.7, 1.0],
    );

    Paint arcPaint =
        Paint()
          ..shader = gradient.createShader(arcRect)
          ..strokeWidth = arcWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, startAngle, sweepAngle, false, arcPaint);

    // Leading dot
    final double dotAngle = startAngle + sweepAngle;
    final Offset dotPosition = Offset(
      center.dx + radius * cos(dotAngle),
      center.dy + radius * sin(dotAngle),
    );

    Paint dotGlowPaint =
        Paint()
          ..color = arcColor.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(dotPosition, 8, dotGlowPaint);

    Paint dotPaint = Paint()..color = arcColor;
    canvas.drawCircle(dotPosition, 4, dotPaint);

    // Accent dots
    _drawAccentDots(canvas, center, radius, false);
  }

  void _drawCenterDot(Canvas canvas, Offset center) {
    // Center glow
    Paint centerGlowPaint =
        Paint()
          ..color = arcColor.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, 12, centerGlowPaint);

    // Center dot with gradient
    final RadialGradient centerGradient = RadialGradient(
      colors: [arcColor, arcColor.withOpacity(0.7)],
    );

    Paint centerPaint =
        Paint()
          ..shader = centerGradient.createShader(
            Rect.fromCircle(center: center, radius: 6),
          );
    canvas.drawCircle(center, 6, centerPaint);
  }

  void _drawAccentDots(
    Canvas canvas,
    Offset center,
    double radius,
    bool animated,
  ) {
    final int dotCount = 8;
    final double dotRadius = animated ? 2.5 : 1.5;

    for (int i = 0; i < dotCount; i++) {
      double angle = (i / dotCount) * 2 * pi;
      double dotOffset =
          animated ? (sin(waveProgress * 2 * pi + angle) * 5) : 0;
      double currentRadius = radius + dotOffset;

      Offset dotPos = Offset(
        center.dx + currentRadius * cos(angle),
        center.dy + currentRadius * sin(angle),
      );

      double opacity =
          animated ? 0.3 + (sin(waveProgress * 2 * pi + angle) * 0.3) : 0.2;

      Paint dotPaint = Paint()..color = arcColor.withOpacity(opacity);

      canvas.drawCircle(dotPos, dotRadius, dotPaint);
    }
  }

  void _drawEnhancedWaves(
    Canvas canvas,
    Size size,
    Offset center,
    double baseRadius,
  ) {
    // Draw multiple wave layers
    for (int layer = 0; layer < 2; layer++) {
      double layerOffset = layer * 10;
      double layerOpacity = layer == 0 ? 0.7 : 0.4;

      _drawHorizontalSineWave(
        canvas,
        size,
        center,
        baseRadius + layerOffset,
        waveProgress + (layer * 0.2),
        opacity: layerOpacity,
        amplitude: 25.0 - (layer * 5),
        isLeft: true,
      );

      _drawHorizontalSineWave(
        canvas,
        size,
        center,
        baseRadius + layerOffset,
        waveProgress + (layer * 0.2),
        opacity: layerOpacity,
        amplitude: 25.0 - (layer * 5),
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
    double opacity = 0.7,
    double amplitude = 25.0,
  }) {
    final Paint wavePaint =
        Paint()
          ..color = arcColor.withOpacity(opacity)
          ..strokeWidth =
              3 // Increased from 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

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
      double theta = frac * 3 * pi + wavePhase + (isLeft ? 0 : pi);

      // Enhanced wave formula with multiple frequencies
      double wave1 = sin(theta) * amplitude * (1 - frac);
      double wave2 = sin(theta * 2) * (amplitude * 0.3) * (1 - frac);
      double y = startY + wave1 + wave2;

      path.lineTo(x, y);
    }

    // Draw wave with glow effect
    Paint glowPaint =
        Paint()
          ..color = arcColor.withOpacity(opacity * 0.3)
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant AiAgentPainter old) =>
      arcProgress != old.arcProgress ||
      isSpeaking != old.isSpeaking ||
      waveProgress != old.waveProgress ||
      pulseProgress != old.pulseProgress ||
      activeSpeaker != old.activeSpeaker ||
      therapistColor != old.therapistColor ||
      userColor != old.userColor;
}
