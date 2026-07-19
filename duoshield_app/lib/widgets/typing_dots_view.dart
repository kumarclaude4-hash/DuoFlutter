import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/colors.dart';

class TypingDotsView extends StatelessWidget {
  const TypingDotsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          _buildDot(i),
        ],
      ],
    );
  }

  Widget _buildDot(int index) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: colorAccent,
        shape: BoxShape.circle,
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(),
        )
        .moveY(
          begin: 0,
          end: -8,
          duration: 300.ms,
          delay: Duration(milliseconds: index * 200),
          curve: Curves.easeInOut,
        )
        .then()
        .moveY(
          begin: -8,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeInOut,
        );
  }
}
