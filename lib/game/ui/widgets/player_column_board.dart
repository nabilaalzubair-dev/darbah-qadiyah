import 'package:darbah_qadiyah/game/game_controller.dart';
import 'package:darbah_qadiyah/game/game_models.dart';
import 'package:darbah_qadiyah/theme.dart';
import 'package:flutter/material.dart';

class PlayerColumnBoard extends StatelessWidget {
  const PlayerColumnBoard({super.key, required this.player, required this.level, required this.isWinner});

  final GamePlayer player;
  final ColorLevel level;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isZero = player.points == 0;
    final nameBg = isZero ? Colors.black : (isWinner ? cs.primary : cs.primaryContainer);
    final nameFg = isZero ? Colors.white : (isWinner ? cs.onPrimary : cs.onPrimaryContainer);

    final pointsBg = isZero ? cs.error : AppGameColors.scorePointsBg;
    final pointsFg = isZero ? cs.onError : AppGameColors.scorePointsFg;
    final pointsBorder = isZero ? null : Colors.white.withValues(alpha: 0.18);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Tile(
          widthFactor: 0.95,
          height: 36,
          color: nameBg,
          child: Center(
            child: Text(player.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.titleSmall?.withColor(nameFg).semiBold),
          ),
        ),
        const SizedBox(height: 3),
        _Tile(
          widthFactor: 0.95,
          height: 38,
          color: pointsBg,
          borderColor: pointsBorder,
          child: Center(
            child: Text(
              '${player.points} (ألف)',
              style: context.textStyles.titleSmall?.withColor(pointsFg).semiBold,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              // Prevent overflows on short screens by adapting the meter tile height.
              // User request: make the tiles taller (~6%) while staying safe on short screens.
              // Best lever here is reducing the gap between tiles.
              // Slightly smaller gap makes the meter section taller without changing
              // the outer scoreboard background size.
              const gap = 1.5;
              const tiles = 9;
              final available = c.maxHeight.isFinite ? c.maxHeight : 0.0;
              final computed = (available - (gap * (tiles - 1))) / tiles;
              // IMPORTANT: Fill the available height as much as possible without changing
              // the outer scoreboard background size. Using a tight lower bound only
              // avoids leaving unused space at the bottom on taller layouts.
              final tileHeight = computed.isFinite ? (computed < 10.0 ? 10.0 : computed) : 14.0;

              final levels = const [
                ColorLevel.green1,
                ColorLevel.green2,
                ColorLevel.green3,
                ColorLevel.yellow1,
                ColorLevel.yellow2,
                ColorLevel.yellow3,
                ColorLevel.red1,
                ColorLevel.red2,
                ColorLevel.red3,
              ];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < levels.length; i++) ...[
                    _meterTile(context, height: tileHeight, activeAt: levels[i], current: level),
                    if (i != levels.length - 1) const SizedBox(height: gap),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _meterTile(BuildContext context, {required double height, required ColorLevel activeAt, required ColorLevel current}) {
    if (player.points == 0) return _Tile(widthFactor: 0.95, height: height, color: Colors.black);
    final active = _isActiveMeter(activeAt: activeAt, current: current);
    final color = active ? _levelColor(activeAt) : Colors.black;
    return _Tile(widthFactor: 0.95, height: height, color: color);
  }

  bool _isActiveMeter({required ColorLevel activeAt, required ColorLevel current}) {
    if (current == ColorLevel.none) return false;
    final rank = _rank(current);
    return _rank(activeAt) <= rank;
  }

  int _rank(ColorLevel l) => switch (l) {
    ColorLevel.none => 0,
    ColorLevel.green1 => 1,
    ColorLevel.green2 => 2,
    ColorLevel.green3 => 3,
    ColorLevel.yellow1 => 4,
    ColorLevel.yellow2 => 5,
    ColorLevel.yellow3 => 6,
    ColorLevel.red1 => 7,
    ColorLevel.red2 => 8,
    ColorLevel.red3 => 9,
  };

  Color _levelColor(ColorLevel l) => switch (l) {
    ColorLevel.green1 || ColorLevel.green2 || ColorLevel.green3 => AppGameColors.levelGreen,
    ColorLevel.yellow1 || ColorLevel.yellow2 || ColorLevel.yellow3 => AppGameColors.levelYellow,
    ColorLevel.red1 || ColorLevel.red2 || ColorLevel.red3 => AppGameColors.levelRed,
    ColorLevel.none => Colors.black,
  };
}

class _Tile extends StatelessWidget {
  const _Tile({required this.height, required this.color, this.widthFactor = 1.0, this.borderColor, this.child});

  final double height;
  final Color color;
  final double widthFactor;
  final Color? borderColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: borderColor == null ? null : Border.all(color: borderColor!),
        ),
        child: child,
      ),
    );
  }
}
