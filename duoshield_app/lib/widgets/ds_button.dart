import 'package:flutter/material.dart';
import '../core/colors.dart';

class DSButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool gradient;
  final bool enabled;
  final double height;
  final double? width;

  const DSButton({
    super.key,
    required this.text,
    required this.onTap,
    this.gradient = false,
    this.enabled = true,
    this.height = 52,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveCallback = (enabled && onTap != null) ? onTap : null;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: effectiveCallback,
        child: Container(
          width: width ?? double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: gradient ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF9A81FF), Color(0xFF7A61DF), Color(0xFF6A51CF)],
              stops: [0.0, 0.5, 1.0],
            ) : null,
            color: gradient ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: gradient
                ? null
                : Border.all(color: colorAccent, width: 1.5),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: gradient ? colorOnAccent : colorAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
