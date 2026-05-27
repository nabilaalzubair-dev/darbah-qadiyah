import 'package:flutter/foundation.dart';

@immutable
class GamePlayer {
  const GamePlayer({required this.id, required this.name, required this.points, required this.isEliminated});

  final int id;
  final String name;
  final int points; // 0..100 (each point = 1,000 SAR)
  final bool isEliminated;

  bool get isActive => !isEliminated;

  GamePlayer copyWith({String? name, int? points, bool? isEliminated}) => GamePlayer(
    id: id,
    name: name ?? this.name,
    points: points ?? this.points,
    isEliminated: isEliminated ?? this.isEliminated,
  );
}

enum QuestionCategory { islamic, history, science, geography, literature }

enum QuestionDifficulty { easy, medium, hard }

@immutable
class GameQuestion {
  const GameQuestion({
    required this.id,
    required this.category,
    required this.difficulty,
    required this.text,
    required this.options,
    required this.correctIndex,
    this.isShield = false,
  }) : assert(options.length == 4);

  final String id;
  final QuestionCategory category;
  final QuestionDifficulty difficulty;
  final String text;
  final List<String> options; // a,b,c,d (displayed)
  final int correctIndex;
  final bool isShield;
}

enum GamePhase {
  setup,
  waitingForBell,
  /// Knockout warning overlay is being displayed (no question shown, no timer).
  knockoutWarning,
  /// Knockout warning ended; user must press "السؤال التالي" to start the pending question.
  knockoutReady,
  /// Shield intro overlay is being displayed (no question shown, no timer).
  shieldIntro,
  /// Shield intro was acknowledged; user must press "السؤال التالي" to start the shield question.
  shieldReady,
  showingQuestion,
  awaitingWinnerEffect,
  roundEnded,
  finished,
}

enum WinnerEffectType { deductOther, addSelf }
