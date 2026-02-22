import 'package:flutter/material.dart';

class BallColors {
  static List<Color> getGradient(int number) {
    if (number <= 10) {
      return [const Color(0xFFFFD32A), const Color(0xFFE6AC00)];
    } else if (number <= 20) {
      return [const Color(0xFF3498DB), const Color(0xFF2175B0)];
    } else if (number <= 30) {
      return [const Color(0xFFE74C3C), const Color(0xFFC0392B)];
    } else if (number <= 40) {
      return [const Color(0xFF7F8C8D), const Color(0xFF5D6D6E)];
    } else {
      return [const Color(0xFF2ECC71), const Color(0xFF1FA85A)];
    }
  }
}
