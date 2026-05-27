import 'dart:async';
import 'dart:math';

import 'package:darbah_qadiyah/game/game_models.dart';
import 'package:darbah_qadiyah/game/question_bank.dart';
import 'package:darbah_qadiyah/game/sfx.dart';
import 'package:flutter/foundation.dart';

class GameController extends ChangeNotifier {
  /// When any active player reaches exactly this score, the next question becomes
  /// the “Shield” question.
  static const int shieldTriggerPoints = 30;
  GameController({QuestionBank? bank, GameSfx? sfx, Random? random})
    : _bank = bank ?? QuestionBank(random: random),
      _sfx = sfx ?? const GameSfx(),
      _random = random ?? Random();

  final QuestionBank _bank;
  final GameSfx _sfx;
  final Random _random;

  static const int maxPlayers = 4;
  static const int initialPoints = 100;
  static const int minPoints = 0;
  static const int wrongPenalty = 10;
  static const int noAnswerPenalty = 10;
  static const int roundSeconds = 25;
  static const int knockoutWarningSeconds = 25;

  GamePhase _phase = GamePhase.setup;
  GamePhase get phase => _phase;

  List<GamePlayer> _players = const [];
  List<GamePlayer> get players => _players;

  List<GameQuestion> _questions = const [];
  int _questionIndex = 0;
  GameQuestion? _currentQuestion;
  GameQuestion? get currentQuestion => _currentQuestion;

  GameQuestion? _pendingQuestion;
  bool get hasPendingQuestion => _pendingQuestion != null;
  int get questionNumber => _questionIndex + 1;
  int get totalQuestions => _questions.length;

  final Set<int> _answeredPlayersThisRound = <int>{};
  bool _roundLocked = false;

  int? _lastAnsweredPlayerId;
  int? get lastAnsweredPlayerId => _lastAnsweredPlayerId;
  int? _lastSelectedIndex;
  int? get lastSelectedIndex => _lastSelectedIndex;

  int _secondsLeft = roundSeconds;
  int get secondsLeft => _secondsLeft;
  Timer? _timer;

  Timer? _knockoutWarningTimer;
  bool _knockoutJustBecameAvailable = false;

  int? _winnerPlayerId;
  int? get winnerPlayerId => _winnerPlayerId;

  bool _knockoutAvailable = false;
  bool get knockoutAvailable => _knockoutAvailable;
  Set<int> _knockoutRightHolders = <int>{};
  Set<int> get knockoutRightHolders => _knockoutRightHolders;

  // Knockout availability announcement (UI can show a popup when KO becomes available).
  int _knockoutAvailableEvent = 0;
  int get knockoutAvailableEvent => _knockoutAvailableEvent;
  Set<int> _lastKnockoutRightHolders = <int>{};
  Set<int> get lastKnockoutRightHolders => _lastKnockoutRightHolders;

  int? _gameWinnerId;
  int? get gameWinnerId => _gameWinnerId;

  // Knockout announcement (UI can show a centered popup when a knockout happens)
  int _knockoutEvent = 0;
  int get knockoutEvent => _knockoutEvent;

  int? _shieldQuestionIndex;
  int? get shieldQuestionIndex => _shieldQuestionIndex;

  bool _shieldAsked = false;

  // Shield scheduled announcement (UI can show a centered popup when shield becomes NEXT question).
  int _shieldScheduledEvent = 0;
  int get shieldScheduledEvent => _shieldScheduledEvent;
  int? _shieldScheduledByPlayerId;
  int? get shieldScheduledByPlayerId => _shieldScheduledByPlayerId;

  // Shield announcement (UI can show a centered popup when shield question appears)
  int _shieldAnnouncementEvent = 0;
  int get shieldAnnouncementEvent => _shieldAnnouncementEvent;

  // Elimination notice (UI can show a dialog when exactly one player hits 0)
  int _eliminationEvent = 0;
  int get eliminationEvent => _eliminationEvent;
  List<int> _lastEliminatedIds = const [];
  List<int> get lastEliminatedIds => _lastEliminatedIds;

  void startNewMatch({required List<String> playerNames}) {
    if (playerNames.length != maxPlayers) {
      throw ArgumentError('يجب إدخال 4 لاعبين بالضبط.');
    }
    _players = List.generate(
      maxPlayers,
      (i) => GamePlayer(id: i, name: playerNames[i].trim(), points: initialPoints, isEliminated: false),
    );
    _questions = _bank.build200Questions();

    // NEW RULE:
    // Shield question is NOT random anymore.
    // It becomes the *next* question immediately after any player reaches exactly
    // [shieldTriggerPoints] points.
    _shieldQuestionIndex = null;
    _shieldAsked = false;
    _shieldScheduledByPlayerId = null;
    _shieldScheduledEvent = 0;
    _questionIndex = 0;
    _gameWinnerId = null;

    // Reset KO state/events per match.
    _knockoutAvailable = false;
    _knockoutRightHolders = <int>{};
    _knockoutAvailableEvent = 0;
    _lastKnockoutRightHolders = <int>{};
    _knockoutEvent = 0;
    _knockoutJustBecameAvailable = false;
    _knockoutWarningTimer?.cancel();
    _knockoutWarningTimer = null;
    // IMPORTANT: Do NOT start the first question/timer yet.
    // The first question begins only after the player presses "اقرع الجرس"
    // on the game screen (after reading rules).
    _currentQuestion = null;
    _pendingQuestion = null;
    _secondsLeft = roundSeconds;
    _timer?.cancel();
    _timer = null;
    _phase = GamePhase.waitingForBell;
    notifyListeners();
  }

  void beginGame() {
    if (_phase != GamePhase.waitingForBell) return;
    _prepareQuestionAndMaybeStart();
  }

  void disposeMatch() {
    _timer?.cancel();
    _timer = null;
    _knockoutWarningTimer?.cancel();
    _knockoutWarningTimer = null;
  }

  void _setPhase(GamePhase p) {
    _phase = p;
    notifyListeners();
  }

  void _resetRoundState() {
    _timer?.cancel();
    _timer = null;
    _knockoutWarningTimer?.cancel();
    _knockoutWarningTimer = null;
    _secondsLeft = roundSeconds;
    _answeredPlayersThisRound.clear();
    _roundLocked = false;
    _winnerPlayerId = null;
    _lastAnsweredPlayerId = null;
    _lastSelectedIndex = null;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_phase != GamePhase.showingQuestion) return;
      if (_secondsLeft <= 0) return;
      _secondsLeft -= 1;
      if (_secondsLeft <= 5 && _secondsLeft > 0) {
        _sfx.tick();
      }
      notifyListeners();
      if (_secondsLeft == 0) {
        _onTimeExpired();
      }
    });
  }

  void _prepareQuestionAndMaybeStart() {
    _resetRoundState();

    if (_questionIndex >= _questions.length) {
      // Fallback: highest points wins if we run out.
      final active = _players.where((p) => p.isActive).toList();
      if (active.isEmpty) {
        _gameWinnerId = null;
      } else {
        active.sort((a, b) => b.points.compareTo(a.points));
        _gameWinnerId = active.first.id;
      }
      _setPhase(GamePhase.finished);
      return;
    }

    final q = _questions[_questionIndex];
    final isShield = _shieldQuestionIndex != null && _shieldQuestionIndex == _questionIndex;
    final built = GameQuestion(
      id: q.id,
      category: q.category,
      difficulty: q.difficulty,
      text: q.text,
      options: q.options,
      correctIndex: q.correctIndex,
      isShield: isShield,
    );

    if (isShield) {
      _shieldAsked = true;
    }

    if (isShield) _shieldAnnouncementEvent += 1;

    _recomputeKnockoutAvailability();
    final koJustBecameAvailable = _knockoutJustBecameAvailable;
    _knockoutJustBecameAvailable = false;

    // If KO just became available, show a warning overlay first and DO NOT
    // start the question/timer until the user presses "السؤال التالي".
    if (koJustBecameAvailable && !isShield) {
      _sfx.warning();
      _pendingQuestion = built;
      _currentQuestion = null;
      _setPhase(GamePhase.knockoutWarning);
      // Safety: auto-advance to KO-ready after a fixed duration even if UI dialog fails.
      _knockoutWarningTimer?.cancel();
      _knockoutWarningTimer = Timer(const Duration(seconds: knockoutWarningSeconds), () {
        if (_phase == GamePhase.knockoutWarning) {
          _phase = GamePhase.knockoutReady;
          notifyListeners();
        }
      });
      return;
    }

    if (isShield) {
      // IMPORTANT: Do not show the question, and do not start the timer.
      // UI must show the full-screen intro overlay first.
      _pendingQuestion = built;
      _currentQuestion = null;
      _setPhase(GamePhase.shieldIntro);
      return;
    }

    _pendingQuestion = null;
    _currentQuestion = built;
    _setPhase(GamePhase.showingQuestion);
    _startTimer();
  }

  void startKnockoutPendingQuestion() {
    if (_phase != GamePhase.knockoutReady) return;
    final q = _pendingQuestion;
    if (q == null) {
      _prepareQuestionAndMaybeStart();
      return;
    }
    _pendingQuestion = null;
    _currentQuestion = q;
    _setPhase(GamePhase.showingQuestion);
    _startTimer();
  }

  void acknowledgeKnockoutWarning() {
    if (_phase != GamePhase.knockoutWarning) return;
    _knockoutWarningTimer?.cancel();
    _knockoutWarningTimer = null;
    _setPhase(GamePhase.knockoutReady);
  }

  void _onTimeExpired() {
    if (_roundLocked || _phase != GamePhase.showingQuestion) return;
    _roundLocked = true;
    debugPrint('Time expired - applying no-answer penalty to all active players');
    _applyPenaltyToAllActive(noAnswerPenalty);
    _setPhase(GamePhase.roundEnded);
  }

  void nextQuestion() {
    if (_phase == GamePhase.finished) return;
    if (!(_phase == GamePhase.roundEnded || _phase == GamePhase.showingQuestion)) return;

    // Safety net:
    // If any active player is currently at [shieldTriggerPoints] and the shield hasn't been scheduled yet,
    // force-schedule it as the NEXT question.
    // This prevents missing the shield due to edge cases (e.g., points updated outside
    // the normal delta flow, hot reload, or other unforeseen state transitions).
    if (_shieldQuestionIndex == null && !_shieldAsked) {
      final reached = _players.where((p) => p.isActive && p.points == shieldTriggerPoints).toList();
      if (reached.isNotEmpty) {
        final nextIndex = _questionIndex + 1;
        if (nextIndex < _questions.length) {
          _shieldQuestionIndex = nextIndex;
          _shieldScheduledByPlayerId ??= reached.first.id;
          _shieldScheduledEvent += 1;
          debugPrint('Shield safety-net scheduled for next question (index=$nextIndex) because player at ${shieldTriggerPoints}: ${reached.first.id}');
        }
      }
    }

    _questionIndex += 1;
    _prepareQuestionAndMaybeStart();
  }

  void acknowledgeShieldIntro() {
    if (_phase != GamePhase.shieldIntro) return;
    // User closed the intro overlay. We still don't start the timer until
    // they explicitly press "السؤال التالي".
    _setPhase(GamePhase.shieldReady);
  }

  void startShieldQuestion() {
    if (_phase != GamePhase.shieldReady) return;
    final q = _pendingQuestion;
    if (q == null) {
      // Fallback: if something cleared pending state, just prepare again.
      _prepareQuestionAndMaybeStart();
      return;
    }
    _pendingQuestion = null;
    _currentQuestion = q;
    _setPhase(GamePhase.showingQuestion);
    _startTimer();
  }

  bool hasAnsweredThisRound(int playerId) => _answeredPlayersThisRound.contains(playerId);

  void submitAnswer({required int playerId, required int selectedIndex}) {
    if (_phase != GamePhase.showingQuestion) return;
    if (_roundLocked) return;
    final player = _players.firstWhere((p) => p.id == playerId);
    if (!player.isActive) return;
    if (_answeredPlayersThisRound.contains(playerId)) return;

    // IMPORTANT (per game rules): the question is asked only once.
    // As soon as any player answers (correct or wrong), the round locks and
    // no other player can answer.
    _answeredPlayersThisRound.add(playerId);
    _roundLocked = true;
    _lastAnsweredPlayerId = playerId;
    _lastSelectedIndex = selectedIndex;
    _timer?.cancel();
    _timer = null;

    final q = _currentQuestion;
    if (q == null) return;

    final isCorrect = selectedIndex == q.correctIndex;
    if (!isCorrect) {
      _winnerPlayerId = null;
      _sfx.wrong();
      _updatePlayerPoints(playerId, -wrongPenalty);
      _setPhase(GamePhase.roundEnded);
      return;
    }

    _winnerPlayerId = playerId;
    _sfx.correct();

    // Knockout check: only the right-holder(s) can finish the game.
    if (_knockoutAvailable && _knockoutRightHolders.contains(playerId)) {
      _finishByKnockout(playerId);
      return;
    }

    _setPhase(GamePhase.awaitingWinnerEffect);
  }

  void applyWinnerEffect({required WinnerEffectType type, int? targetPlayerId}) {
    if (_phase != GamePhase.awaitingWinnerEffect) return;
    final winnerId = _winnerPlayerId;
    if (winnerId == null) return;
    final q = _currentQuestion;
    if (q == null) return;

    if (type == WinnerEffectType.deductOther) {
      if (targetPlayerId == null) return;
      if (targetPlayerId == winnerId) return;
      final target = _players.firstWhere((p) => p.id == targetPlayerId);
      if (!target.isActive) return;
      _updatePlayerPoints(targetPlayerId, -10);
      _setPhase(GamePhase.roundEnded);
      return;
    }

    if (type == WinnerEffectType.addSelf) {
      final canAdd = q.isShield ? _canShieldAddSelf(winnerId) : _canSaveYourself(winnerId);
      if (!canAdd) return;
      _updatePlayerPoints(winnerId, 10);
      _setPhase(GamePhase.roundEnded);
      return;
    }
  }

  bool canWinnerAddSelf() {
    final winnerId = _winnerPlayerId;
    final q = _currentQuestion;
    if (winnerId == null || q == null) return false;
    if (q.isShield) return _canShieldAddSelf(winnerId);
    return _canSaveYourself(winnerId);
  }

  bool _canShieldAddSelf(int winnerId) {
    // Shield rules (per user spec):
    // - Add +10 is allowed only if the winner's points are NOT greater than 90.
    // - (Points are clamped to 0..100 anyway.)
    final winner = _players.firstWhere((p) => p.id == winnerId);
    if (!winner.isActive) return false;
    return winner.points <= 90;
  }

  bool _canSaveYourself(int winnerId) {
    // شروط (أنقذ نفسك)
    // 1) رصيد اللاعب = 10
    // 2) لا يوجد لاعب آخر رصيده 10
    // 3) ولا يوجد لاعبان آخران رصيدهما > 10 ومتساويان
    final winner = _players.firstWhere((p) => p.id == winnerId);
    if (!winner.isActive) return false;
    if (winner.points != 10) return false;

    final otherTens = _players.where((p) => p.isActive && p.id != winnerId && p.points == 10).length;
    if (otherTens > 0) return false;

    final activeOver10 = _players.where((p) => p.isActive && p.points > 10).toList();
    for (var i = 0; i < activeOver10.length; i++) {
      for (var j = i + 1; j < activeOver10.length; j++) {
        if (activeOver10[i].points == activeOver10[j].points) return false;
      }
    }
    return true;
  }

  void _finishByKnockout(int winnerId) {
    debugPrint('Knockout! Winner: $winnerId');
    _knockoutEvent += 1;
    _gameWinnerId = winnerId;
    // Eliminate all other players at once.
    final deltas = <int, int>{};
    for (final p in _players) {
      if (p.id == winnerId) continue;
      deltas[p.id] = -999;
    }
    _applyPointChanges(deltas, allowMultiEliminationEvent: true);
    _sfx.win();
    _setPhase(GamePhase.finished);
  }

  void _applyPenaltyToAllActive(int delta) {
    final deltas = <int, int>{};
    for (final p in _players) {
      if (!p.isActive) continue;
      deltas[p.id] = -delta;
    }
    _applyPointChanges(deltas, allowMultiEliminationEvent: true);
  }

  void _updatePlayerPoints(int playerId, int delta) {
    _applyPointChanges({playerId: delta});
  }

  void _applyPointChanges(Map<int, int> deltas, {bool allowMultiEliminationEvent = false}) {
    if (deltas.isEmpty) return;
    final newlyEliminated = <int>[];
    final nextPlayers = <GamePlayer>[];
    int? reachedShieldTriggerPlayerId;
    for (final p in _players) {
      final delta = deltas[p.id];
      if (delta == null || !p.isActive) {
        nextPlayers.add(p);
        continue;
      }

      final nextPoints = (p.points + delta).clamp(minPoints, initialPoints);

      // Detect reaching exactly [shieldTriggerPoints] for the first time (active players only).
      if (p.isActive && p.points != shieldTriggerPoints && nextPoints == shieldTriggerPoints) {
        reachedShieldTriggerPlayerId ??= p.id;
      }

      final eliminatedNow = nextPoints == 0;
      if (!p.isEliminated && eliminatedNow) newlyEliminated.add(p.id);
      nextPlayers.add(p.copyWith(points: nextPoints, isEliminated: eliminatedNow));
    }
    _players = nextPlayers.toList(growable: false);

    // Schedule shield question as the NEXT question when someone reaches [shieldTriggerPoints].
    // Only once per match, and only if we haven't already asked it.
    if (reachedShieldTriggerPlayerId != null && _shieldQuestionIndex == null && !_shieldAsked) {
      final nextIndex = _questionIndex + 1;
      if (nextIndex < _questions.length) {
        _shieldQuestionIndex = nextIndex;
        _shieldScheduledByPlayerId = reachedShieldTriggerPlayerId;
        _shieldScheduledEvent += 1;
        debugPrint('Shield scheduled for next question (index=$nextIndex) by player=$reachedShieldTriggerPlayerId');
      } else {
        debugPrint('Shield could not be scheduled: no next question available.');
      }
    }

    if (newlyEliminated.isNotEmpty) {
      // Only show a goodbye dialog when exactly one player is eliminated in this event.
      // Knockout or mass penalties can eliminate multiple players; UI will ignore multi.
      if (allowMultiEliminationEvent || newlyEliminated.length == 1) {
        _lastEliminatedIds = newlyEliminated;
        _eliminationEvent += 1;
      }
    }

    // KO conditions depend on scores and eliminations; recompute after any change.
    _recomputeKnockoutAvailability();

    notifyListeners();
  }

  void _recomputeKnockoutAvailability() {
    final wasAvailable = _knockoutAvailable;
    final previousRightHolders = _knockoutRightHolders.toSet();
    _knockoutJustBecameAvailable = false;
    _knockoutRightHolders = <int>{};
    _knockoutAvailable = false;

    final active = _players.where((p) => p.isActive).toList();
    if (active.isEmpty) return;

    // Special: all active players at 10 => everyone can knockout.
    final allTen = active.isNotEmpty && active.every((p) => p.points == 10);
    if (allTen) {
      _knockoutAvailable = true;
      _knockoutRightHolders = active.map((p) => p.id).toSet();
      _maybeEmitKnockoutAvailableEvent(wasAvailable: wasAvailable, previousRightHolders: previousRightHolders);
      return;
    }

    final tenOrEliminatedExists = _players.any((p) => p.points == 10 || p.isEliminated);
    if (!tenOrEliminatedExists) {
      _maybeEmitKnockoutAvailableEvent(wasAvailable: wasAvailable, previousRightHolders: previousRightHolders);
      return;
    }

    // Case: two players at 10 AND the other two tied (>10) => right belongs to 10-players.
    final activeTens = active.where((p) => p.points == 10).toList();
    if (activeTens.length == 2) {
      final others = active.where((p) => p.points != 10).toList();
      if (others.length == 2 && others[0].points > 10 && others[0].points == others[1].points) {
        _knockoutAvailable = true;
        _knockoutRightHolders = activeTens.map((p) => p.id).toSet();
        _maybeEmitKnockoutAvailableEvent(wasAvailable: wasAvailable, previousRightHolders: previousRightHolders);
        return;
      }
    }

    // General case:
    // - Two players tied with the same points (>10)
    // - A third player with different points (>10)
    // - A fourth player with 10 or eliminated
    final tiedGroups = <int, List<GamePlayer>>{};
    for (final p in active) {
      tiedGroups.putIfAbsent(p.points, () => []).add(p);
    }
    final tiedOver10 = tiedGroups.entries.where((e) => e.key > 10 && e.value.length >= 2).toList();
    if (tiedOver10.isEmpty) {
      _maybeEmitKnockoutAvailableEvent(wasAvailable: wasAvailable, previousRightHolders: previousRightHolders);
      return;
    }

    // For each tied group, any other active player >10 with different points becomes right-holder.
    final rightHolders = <int>{};
    for (final tie in tiedOver10) {
      final tiedIds = tie.value.map((p) => p.id).toSet();
      for (final p in active) {
        if (p.points > 10 && !tiedIds.contains(p.id) && p.points != tie.key) {
          rightHolders.add(p.id);
        }
      }
    }
    if (rightHolders.isEmpty) {
      _maybeEmitKnockoutAvailableEvent(wasAvailable: wasAvailable, previousRightHolders: previousRightHolders);
      return;
    }

    _knockoutAvailable = true;
    _knockoutRightHolders = rightHolders;

    _maybeEmitKnockoutAvailableEvent(wasAvailable: wasAvailable, previousRightHolders: previousRightHolders);
  }

  static bool _setEquals(Set<int> a, Set<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }

  void _maybeEmitKnockoutAvailableEvent({required bool wasAvailable, required Set<int> previousRightHolders}) {
    // We want the UI to be notified when:
    // 1) KO becomes available (false -> true)
    // 2) KO stays available BUT right-holders change (so the popup should update)
    // This fixes the case where KO was already available in the background,
    // but the owners of the right changed without a false->true transition.
    final rightHoldersChanged = _knockoutAvailable && !_setEquals(previousRightHolders, _knockoutRightHolders);
    final becameAvailable = !wasAvailable && _knockoutAvailable;
    if (becameAvailable || rightHoldersChanged) {
      _knockoutAvailableEvent += 1;
      _lastKnockoutRightHolders = _knockoutRightHolders.toSet();
      _knockoutJustBecameAvailable = becameAvailable;
      debugPrint('Knockout available event fired. available=$_knockoutAvailable holders=$_lastKnockoutRightHolders (becameAvailable=$becameAvailable, changed=$rightHoldersChanged)');
    }
  }

  // UI helpers
  ColorLevel getPlayerLevel(int points) {
    if (points <= 10) return ColorLevel.red3;
    if (points <= 20) return ColorLevel.red2;
    if (points <= 30) return ColorLevel.red1;
    if (points <= 40) return ColorLevel.yellow3;
    if (points <= 50) return ColorLevel.yellow2;
    if (points <= 60) return ColorLevel.yellow1;
    if (points <= 70) return ColorLevel.green3;
    if (points <= 80) return ColorLevel.green2;
    if (points <= 90) return ColorLevel.green1;
    return ColorLevel.none;
  }
}

enum ColorLevel {
  none,
  green1,
  green2,
  green3,
  yellow1,
  yellow2,
  yellow3,
  red1,
  red2,
  red3,
}
