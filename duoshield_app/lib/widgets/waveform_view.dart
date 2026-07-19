import 'package:flutter/material.dart';
import '../core/colors.dart';

class WaveformView extends StatelessWidget {
  final List<double> amplitudes;
  final double progress;
  final Color playedColor;
  final Color unplayedColor;
  final ValueChanged<double>? onSeek;

  const WaveformView({
    super.key,
    required this.amplitudes,
    this.progress = 0.0,
    this.playedColor = colorAccent,
    this.unplayedColor = colorSurfaceVariant,
    this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        if (onSeek == null) return;
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final localX = details.localPosition.dx;
        final newProgress = (localX / box.size.width).clamp(0.0, 1.0);
        onSeek!(newProgress);
      },
      child: CustomPaint(
        painter: _WaveformPainter(
          amplitudes: amplitudes,
          progress: progress,
          playedColor: playedColor,
          unplayedColor: unplayedColor,
        ),
        child: const SizedBox(height: 40, width: double.infinity),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final double progress;
  final Color playedColor;
  final Color unplayedColor;

  _WaveformPainter({
    required this.amplitudes,
    required this.progress,
    required this.playedColor,
    required this.unplayedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const barWidth = 3.0;
    const barSpacing = 2.0;
    final maxHeight = size.height;
    final progressX = size.width * progress;

    for (int i = 0; i < amplitudes.length; i++) {
      final x = i * (barWidth + barSpacing);
      if (x > size.width) break;
      final barHeight = (amplitudes[i] * maxHeight).clamp(2.0, maxHeight);
      final y = (maxHeight - barHeight) / 2;
      final paint = Paint()
        ..color = x < progressX ? playedColor : unplayedColor
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(1.5),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress || old.amplitudes != amplitudes;
}
