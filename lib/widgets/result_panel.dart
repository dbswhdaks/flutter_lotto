import 'package:flutter/material.dart';
import '../models/lotto_result.dart';
import 'lotto_ball.dart';

class ResultPanel extends StatelessWidget {
  final LottoResult? result;
  final List<int> revealedNumbers;
  final bool showPlus;
  final bool showBonus;

  const ResultPanel({
    super.key,
    this.result,
    this.revealedNumbers = const [],
    this.showPlus = false,
    this.showBonus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      constraints: const BoxConstraints(minHeight: 60),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8446A), Color(0xFFC42B50)],
        ),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: const Color(0xFFFF7A9A).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE94560).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: result == null ? _buildPlaceholder() : _buildResult(),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Text(
        '번호를 추첨하세요',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildResult() {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...revealedNumbers.map(
                  (n) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: AnimatedLottoBall(
                      number: n,
                      size: 36,
                      delay: Duration.zero,
                    ),
                  ),
                ),
                if (showPlus)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text(
                      '+',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                if (showBonus)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: AnimatedLottoBall(
                      number: result!.bonusNumber,
                      size: 36,
                      isBonus: true,
                      delay: Duration.zero,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
