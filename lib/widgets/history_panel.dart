import 'package:flutter/material.dart';
import '../models/lotto_result.dart';
import '../utils/ball_colors.dart';

class HistoryPanel extends StatelessWidget {
  final List<LottoResult> history;

  const HistoryPanel({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: history.length,
        itemBuilder: (context, index) {
          final result = history[index];
          return _HistoryRow(result: result);
        },
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final LottoResult result;

  const _HistoryRow({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${result.round}회',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 4),
          ...result.mainNumbers.map((n) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _SmallBall(number: n),
              )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '+',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
          ),
          _SmallBall(number: result.bonusNumber, isBonus: true),
        ],
      ),
    );
  }
}

class _SmallBall extends StatelessWidget {
  final int number;
  final bool isBonus;

  const _SmallBall({required this.number, this.isBonus = false});

  @override
  Widget build(BuildContext context) {
    final colors = BallColors.getGradient(number);
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        border: isBonus
            ? Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$number',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
