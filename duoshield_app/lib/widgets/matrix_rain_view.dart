import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/colors.dart';

class MatrixRainView extends StatefulWidget {
  final Color color;
  final double opacity;
  final int speedMs;

  const MatrixRainView({
    super.key,
    this.color = colorAccent,
    this.opacity = 0.4,
    this.speedMs = 60,
  });

  @override
  State<MatrixRainView> createState() => _MatrixRainViewState();
}

class _MatrixRainViewState extends State<MatrixRainView> {
  static const String _glyphs =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZアイウエオカキクケコ';
  static const double _colWidth = 20.0;
  static const double _fontSize = 14.0;
  static const int _trailLength = 8;

  final Random _rng = Random();
  final List<_RainColumn> _columns = [];
  Timer? _timer;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAnimation());
  }

  void _startAnimation() {
    _timer = Timer.periodic(Duration(milliseconds: widget.speedMs), (_) {
      if (mounted) setState(() => _updateColumns());
    });
  }

  void _initColumns(Size size) {
    if (_size == size) return;
    _size = size;
    _columns.clear();
    final count = (size.width / _colWidth).ceil();
    for (int i = 0; i < count; i++) {
      _columns.add(_RainColumn(
        x: i * _colWidth,
        y: -_rng.nextDouble() * size.height,
        speed: 2.0 + _rng.nextDouble() * 4,
        glyphs: List.generate(
            _trailLength + 1,
            (_) => _glyphs[_rng.nextInt(_glyphs.length)]),
      ));
    }
  }

  void _updateColumns() {
    for (final col in _columns) {
      col.y += col.speed;
      if (col.y > _size.height + _trailLength * _fontSize) {
        col.y = -_rng.nextDouble() * _size.height * 0.5;
        col.x = _rng.nextInt((_size.width / _colWidth).ceil()) * _colWidth;
        col.glyphs = List.generate(
            _trailLength + 1,
            (_) => _glyphs[_rng.nextInt(_glyphs.length)]);
      }
      for (int i = 0; i < col.glyphs.length; i++) {
        if (_rng.nextDouble() < 0.1) {
          col.glyphs[i] = _glyphs[_rng.nextInt(_glyphs.length)];
        }
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _initColumns(size);
        return CustomPaint(
          size: size,
          painter: _MatrixPainter(
            columns: _columns,
            color: widget.color,
            opacity: widget.opacity,
          ),
        );
      },
    );
  }
}

class _RainColumn {
  double x;
  double y;
  double speed;
  List<String> glyphs;

  _RainColumn({
    required this.x,
    required this.y,
    required this.speed,
    required this.glyphs,
  });
}

class _MatrixPainter extends CustomPainter {
  final List<_RainColumn> columns;
  final Color color;
  final double opacity;

  _MatrixPainter({
    required this.columns,
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double fontSize = 14.0;
    for (final col in columns) {
      for (int i = 0; i < col.glyphs.length; i++) {
        final isHead = i == 0;
        final trailOpacity = isHead
            ? opacity
            : opacity * (1.0 - i / col.glyphs.length) * 0.7;

        final textPainter = TextPainter(
          text: TextSpan(
            text: col.glyphs[i],
            style: TextStyle(
              color: color.withOpacity(trailOpacity),
              fontSize: fontSize,
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(col.x, col.y - i * fontSize));
      }
    }
  }

  @override
  bool shouldRepaint(_MatrixPainter old) => true;
}
