import 'package:flutter/material.dart';
import '../core/colors.dart';

class DSBottomSheet extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final double initialChildSize;
  final double maxChildSize;

  const DSBottomSheet({
    super.key,
    this.title,
    required this.children,
    this.initialChildSize = 0.4,
    this.maxChildSize = 0.9,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required List<Widget> children,
    double initialChildSize = 0.4,
    double maxChildSize = 0.9,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DSBottomSheet(
        title: title,
        children: children,
        initialChildSize: initialChildSize,
        maxChildSize: maxChildSize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      maxChildSize: maxChildSize,
      minChildSize: 0.25,
      expand: false,
      builder: (_, controller) => ListView(
        controller: controller,
        shrinkWrap: true,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: colorTextMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                title!,
                style: const TextStyle(
                  color: colorTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(color: colorDivider, height: 1),
          ],
          ...children,
        ],
      ),
    );
  }
}
