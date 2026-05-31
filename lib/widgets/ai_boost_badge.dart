import 'package:flutter/material.dart';

class AiBoostBadge extends StatelessWidget {
  const AiBoostBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF4FD1C5).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF4FD1C5).withValues(alpha: 0.35),
        ),
      ),
      child: const Text(
        'AI 확률 강화',
        style: TextStyle(
          color: Color(0xFF4FD1C5),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
