import 'dart:async';

import 'package:darbah_qadiyah/game/game_controller.dart';
import 'package:darbah_qadiyah/game/game_models.dart';
import 'package:darbah_qadiyah/game/ui/widgets/player_column_board.dart';
import 'package:darbah_qadiyah/nav.dart';
import 'package:darbah_qadiyah/theme.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

String _categoryLabel(QuestionCategory c) => switch (c) {
  QuestionCategory.islamic => 'إسلامية',
  QuestionCategory.history => 'تأريخ',
  QuestionCategory.science => 'علوم',
  QuestionCategory.geography => 'جغرافيا',
  QuestionCategory.literature => 'أدب',
};

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final ConfettiController _confetti;
  GamePhase? _lastPhase;
  int _lastEliminationEvent = 0;
  int _lastShieldAnnouncementEvent = 0;
  int _lastShieldScheduledEvent = 0;
  int _lastKnockoutEvent = 0;
  int _lastKnockoutAvailableEvent = 0;

  static String _formatNumber(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      b.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) b.write(',');
    }
    return b.toString();
  }

  static String _formatPrizeAmount({required int points}) => '${_formatNumber(points * 1000)} ريال';

  @override
  void initState() {
    super.initState();
    // A bit longer to feel like “fireworks” on a knockout win.
    _confetti = ConfettiController(duration: const Duration(seconds: 6));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<GameController>();
    final phase = ctrl.phase;

    if (_lastEliminationEvent != ctrl.eliminationEvent) {
      _lastEliminationEvent = ctrl.eliminationEvent;
      final ids = ctrl.lastEliminatedIds;
      if (ids.length == 1 && phase != GamePhase.finished) {
        final id = ids.first;
        final name = ctrl.players.firstWhere((p) => p.id == id).name;
        WidgetsBinding.instance.addPostFrameCallback((_) => _showGoodbyeDialog(name));
      }
    }
    if (_lastPhase != phase && phase == GamePhase.finished) {
      _confetti.play();
    }
    _lastPhase = phase;

    if (_lastShieldAnnouncementEvent != ctrl.shieldAnnouncementEvent) {
      _lastShieldAnnouncementEvent = ctrl.shieldAnnouncementEvent;
      // Shield intro should appear BEFORE the shield question/timer start.
      if (phase == GamePhase.shieldIntro) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showShieldDialog());
      }
    }

    if (_lastShieldScheduledEvent != ctrl.shieldScheduledEvent) {
      _lastShieldScheduledEvent = ctrl.shieldScheduledEvent;
      final id = ctrl.shieldScheduledByPlayerId;
      if (id != null) {
        final name = ctrl.players.firstWhere((p) => p.id == id).name;
        WidgetsBinding.instance.addPostFrameCallback((_) => _showShieldScheduledDialog(name));
      }
    }

    if (_lastKnockoutEvent != ctrl.knockoutEvent) {
      _lastKnockoutEvent = ctrl.knockoutEvent;
      if (phase == GamePhase.finished && ctrl.gameWinnerId != null) {
        final winner = ctrl.players.firstWhere((p) => p.id == ctrl.gameWinnerId);
        WidgetsBinding.instance.addPostFrameCallback((_) => _showKnockoutDialog(winnerName: winner.name, winnerPoints: winner.points));
      }
    }

    // Explicit KO-availability warning when the conditions become true.
    if (_lastKnockoutAvailableEvent != ctrl.knockoutAvailableEvent) {
      _lastKnockoutAvailableEvent = ctrl.knockoutAvailableEvent;
      if (ctrl.knockoutAvailable && phase != GamePhase.finished && ctrl.players.isNotEmpty) {
        final holders = ctrl.lastKnockoutRightHolders;
        final activeIds = ctrl.players.where((p) => p.isActive).map((p) => p.id).toSet();
        final isEveryone = holders.isNotEmpty && holders.length == activeIds.length && holders.containsAll(activeIds);
        final names = isEveryone
            ? 'جميع اللاعبين'
            : holders.map((id) => ctrl.players.firstWhere((p) => p.id == id).name).join('، ');
        final requiresAcknowledge = phase == GamePhase.knockoutWarning;
        WidgetsBinding.instance.addPostFrameCallback((_) => _showKnockoutAvailableDialog(names, requiresAcknowledge: requiresAcknowledge));
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('الضربة القاضية'),
                  const SizedBox(width: 10),
                  if (ctrl.phase == GamePhase.showingQuestion && ctrl.players.isNotEmpty)
                    _TimerTitlePill(secondsLeft: ctrl.secondsLeft, knockoutAvailable: ctrl.knockoutAvailable),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'إعادة',
                  onPressed: () {
                    context.read<GameController>().disposeMatch();
                    context.go(AppRoutes.setup);
                  },
                  icon: const Icon(Icons.restart_alt),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: const _GameBody(),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 24,
              emissionFrequency: 0.02,
              gravity: 0.22,
              colors: const [Colors.green, Colors.blue, Colors.orange, Colors.pink, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showGoodbyeDialog(String playerName) async {
    if (!mounted) return;
    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.waving_hand_rounded, color: cs.primary, size: 26),
                    const SizedBox(height: 10),
                    Text('مع السلامة', style: context.textStyles.titleLarge?.semiBold, textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                    Text(playerName, style: context.textStyles.titleMedium?.withColor(cs.onSurfaceVariant).semiBold, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          );
        },
      );

      await Future<void>.delayed(const Duration(seconds: 5));
      if (!mounted) return;
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (e) {
      // If the route changed quickly, the dialog may fail.
      debugPrint('Goodbye dialog failed: $e');
    }
  }

  Future<void> _showShieldDialog() async {
    if (!mounted) return;
    try {
      // Small delay prevents the tap that triggered navigation/next from
      // instantly dismissing the dialog (tap-through).
      await Future<void>.delayed(const Duration(milliseconds: 90));

      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'shield',
        barrierColor: Colors.black.withValues(alpha: 0.55),
        transitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (context, _, __) {
          final cs = Theme.of(context).colorScheme;
          return Material(
            color: Colors.transparent,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (Navigator.of(context, rootNavigator: true).canPop()) {
                    Navigator.of(context, rootNavigator: true).pop();
                  }
                },
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                    child: Column(
                      children: [
                        const Spacer(),
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 520),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                          decoration: BoxDecoration(
                            color: cs.tertiaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.shield_rounded, color: cs.onTertiaryContainer, size: 22),
                                  const SizedBox(width: 10),
                                  Text('درع الحماية', style: context.textStyles.titleLarge?.withColor(cs.onTertiaryContainer).semiBold),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'هذه فرصة خاصة في المباراة:',
                                style: context.textStyles.titleSmall?.withColor(cs.onTertiaryContainer).semiBold,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '• إذا أجبت إجابة صحيحة يمكنك إضافة +10 لرصيدك بشرط ألا يكون رصيدك أكبر من 90.\n'
                                '• إذا كان رصيدك أكبر من 90 فلك الحق في خصم 10 نقاط من لاعب آخر.\n\n'
                                'بعد الإجابة الصحيحة ستظهر لك الخيارات حسب رصيدك.',
                                style: context.textStyles.bodyMedium?.withColor(cs.onTertiaryContainer),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: cs.onTertiaryContainer.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.touch_app_rounded, size: 18, color: cs.onTertiaryContainer),
                                    const SizedBox(width: 8),
                                    Text('اضغط على أي مكان للإغلاق', style: context.textStyles.labelLarge?.withColor(cs.onTertiaryContainer).semiBold),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        transitionBuilder: (context, anim, _, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved), child: child),
          );
        },
      );

      if (!mounted) return;
      // User acknowledged shield intro; now show "السؤال التالي" button.
      context.read<GameController>().acknowledgeShieldIntro();
    } catch (e) {
      debugPrint('Shield dialog failed: $e');
      if (!mounted) return;
      // Still advance to ready state so the game doesn't get stuck.
      context.read<GameController>().acknowledgeShieldIntro();
    }
  }

  Future<void> _showShieldScheduledDialog(String playerName) async {
    if (!mounted) return;
    try {
      showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'shield_scheduled',
        barrierColor: Colors.black.withValues(alpha: 0.18),
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, _, __) {
          final cs = Theme.of(context).colorScheme;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (Navigator.of(context, rootNavigator: true).canPop()) {
                Navigator.of(context, rootNavigator: true).pop();
              }
            },
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 380),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: cs.outline.withValues(alpha: 0.16)),
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_rounded, color: cs.onTertiaryContainer, size: 22),
                            const SizedBox(width: 8),
                            Text('تفعيل درع الحماية', style: context.textStyles.titleMedium?.withColor(cs.onTertiaryContainer).semiBold),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'وصل اللاعب "$playerName" إلى رصيد ${GameController.shieldTriggerPoints}.\nالسؤال القادم سيكون سؤال درع الحماية!',
                          style: context.textStyles.bodyMedium?.withColor(cs.onTertiaryContainer),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'إذا أجبت إجابة صحيحة في سؤال الدرع يمكنك إضافة +10 لرصيدك.',
                          style: context.textStyles.bodySmall?.withColor(cs.onTertiaryContainer.withValues(alpha: 0.9)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.schedule_rounded, size: 16, color: cs.onTertiaryContainer.withValues(alpha: 0.92)),
                            const SizedBox(width: 6),
                            Text('تُغلق تلقائيًا بعد 20 ثانية (أو اضغط للإغلاق).', style: context.textStyles.labelMedium?.withColor(cs.onTertiaryContainer.withValues(alpha: 0.92))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        transitionBuilder: (context, anim, _, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(opacity: curved, child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(curved), child: child));
        },
      );

      await Future<void>.delayed(const Duration(seconds: 20));
      if (!mounted) return;
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (e) {
      debugPrint('Shield scheduled dialog failed: $e');
    }
  }

  Future<void> _showKnockoutDialog({required String winnerName, required int winnerPoints}) async {
    if (!mounted) return;
    try {
      // Ensure the global “fireworks” are running while the dialog is visible.
      _confetti.play();

      var dismissed = false;

      final dialogFuture = showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'knockout',
        barrierColor: Colors.black.withValues(alpha: 0.40),
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (context, _, __) {
          final cs = Theme.of(context).colorScheme;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (Navigator.of(context, rootNavigator: true).canPop()) {
                Navigator.of(context, rootNavigator: true).pop();
              }
            },
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  margin: const EdgeInsets.symmetric(horizontal: 22),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [cs.primaryContainer, cs.tertiaryContainer]),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.black.withValues(alpha: 0.10)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.celebration_rounded, color: cs.onPrimaryContainer, size: 22),
                              const SizedBox(width: 8),
                              Text('تهانينا! ضربة قاضية', style: context.textStyles.titleMedium?.withColor(cs.onPrimaryContainer).semiBold),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(winnerName, style: context.textStyles.headlineSmall?.withColor(cs.onPrimaryContainer).semiBold, textAlign: TextAlign.center),
                        const SizedBox(height: 6),
                        Text(
                          _formatPrizeAmount(points: winnerPoints),
                          style: context.textStyles.titleLarge?.withColor(cs.onTertiaryContainer).semiBold,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'تهانينا لقد فزت بالضربة القاضية',
                          style: context.textStyles.bodyMedium?.withColor(cs.onSurfaceVariant).semiBold,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.celebration_rounded, color: cs.primary),
                            const SizedBox(width: 10),
                            Icon(Icons.emoji_events_rounded, color: cs.tertiary),
                            const SizedBox(width: 10),
                            Icon(Icons.celebration_rounded, color: cs.primary),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'اضغط على الشاشة للإغلاق',
                          style: context.textStyles.labelMedium?.withColor(cs.onSurfaceVariant.withValues(alpha: 0.85)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        transitionBuilder: (context, anim, _, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(curved), child: child),
          );
        },
      );

      dialogFuture.whenComplete(() {
        dismissed = true;
        _confetti.stop();
      });

      // Keep the popup visible until the user taps OR 30 seconds pass.
      await Future<void>.delayed(const Duration(seconds: 30));
      if (!mounted) return;
      if (!dismissed && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (e) {
      debugPrint('Knockout dialog failed: $e');
    }
  }

  Future<void> _showKnockoutAvailableDialog(String rightHoldersText, {required bool requiresAcknowledge}) async {
    if (!mounted) return;
    try {
      // Small delay prevents accidental tap-through.
      await Future<void>.delayed(const Duration(milliseconds: 90));

      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'knockout_available',
        barrierColor: Colors.black.withValues(alpha: 0.45),
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, _, __) {
          final cs = Theme.of(context).colorScheme;
          return Center(
            child: Material(
              color: Colors.transparent,
              child: _KnockoutWarningDialogContent(
                rightHoldersText: rightHoldersText,
                colorScheme: cs,
                onDismissRequested: () {
                  if (Navigator.of(context, rootNavigator: true).canPop()) {
                    Navigator.of(context, rootNavigator: true).pop();
                  }
                },
              ),
            ),
          );
        },
        transitionBuilder: (context, anim, _, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved), child: child),
          );
        },
      );

      // Dialog closes either automatically after the warning duration or by user tapping the header.
      if (!mounted) return;
      if (requiresAcknowledge) context.read<GameController>().acknowledgeKnockoutWarning();
    } catch (e) {
      debugPrint('Knockout-available dialog failed: $e');
      if (!mounted) return;
      if (requiresAcknowledge) context.read<GameController>().acknowledgeKnockoutWarning();
    }
  }
}

class _KnockoutWarningDialogContent extends StatefulWidget {
  const _KnockoutWarningDialogContent({required this.rightHoldersText, required this.colorScheme, required this.onDismissRequested});

  final String rightHoldersText;
  final ColorScheme colorScheme;
  final VoidCallback onDismissRequested;

  @override
  State<_KnockoutWarningDialogContent> createState() => _KnockoutWarningDialogContentState();
}

class _KnockoutWarningDialogContentState extends State<_KnockoutWarningDialogContent> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  int _seconds = GameController.knockoutWarningSeconds;
  Timer? _countdown;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _seconds = (_seconds - 1).clamp(0, GameController.knockoutWarningSeconds));
      if (_seconds <= 0) {
        t.cancel();
        _requestDismiss();
      }
    });
  }

  void _requestDismiss() {
    if (_dismissed) return;
    _dismissed = true;
    widget.onDismissRequested();
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 460),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            final a = _pulse.value;
            final ring = cs.onErrorContainer.withValues(alpha: 0.08 + (0.12 * a));
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  button: true,
                  label: 'تجاوز تنبيه الضربة القاضية',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _requestDismiss,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: ring, borderRadius: BorderRadius.circular(999)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: cs.onErrorContainer, size: 22 + (2 * a)),
                          const SizedBox(width: 8),
                          Text('تنبيه قوي: الضربة القاضية متاحة', style: context.textStyles.titleMedium?.withColor(cs.onErrorContainer).semiBold),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'أصحاب الحق الآن: ${widget.rightHoldersText}',
                  style: context.textStyles.titleSmall?.withColor(cs.onErrorContainer).semiBold,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'خلال هذا التنبيه المؤقّت متوقف — وسيبدأ فقط بعد الضغط على زر (السؤال التالي).',
                  style: context.textStyles.bodySmall?.withColor(cs.onErrorContainer.withValues(alpha: 0.92)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer, size: 18, color: cs.onErrorContainer),
                    const SizedBox(width: 8),
                    Text('متبقّي: $_seconds ثوانٍ', style: context.textStyles.titleSmall?.withColor(cs.onErrorContainer).semiBold),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GameBody extends StatelessWidget {
  const _GameBody();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<GameController>();
    final isAwaitingEffect = ctrl.phase == GamePhase.awaitingWinnerEffect;
    if (ctrl.phase == GamePhase.setup || ctrl.players.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go(AppRoutes.setup));
      return const SizedBox.shrink();
    }

    return SafeArea(
      bottom: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cs = Theme.of(context).colorScheme;
          final h = constraints.maxHeight;

          // Reduce scoreboard background panel size by ~15% (user request),
          // while keeping clamps to avoid overflows on short screens.
          final scoreboardHeight = (h * 0.3825).clamp(180.0, 360.0);

          return Stack(
            children: [
              Padding(
                // Restore the previous overall scoreboard width (user requested: don't widen columns panel).
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                child: Column(
                  children: [
                    SizedBox(height: scoreboardHeight, child: _ScoreboardPanel(gameWinnerId: ctrl.gameWinnerId)),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            // Keep the question visually attached to the answers panel by
                            // anchoring it to the bottom of its slot.
                            flex: 3,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: _QuestionCard(
                                question: ctrl.currentQuestion,
                                questionNumber: ctrl.questionNumber,
                                totalQuestions: ctrl.totalQuestions,
                                phase: ctrl.phase,
                                lastSelectedIndex: ctrl.lastSelectedIndex,
                              ),
                            ),
                          ),
                          // Keep Q and answers visually connected (user request: reduce the gap).
                          const SizedBox(height: 1),
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                Expanded(
                                  child: _AnswersGrid(
                                    phase: ctrl.phase,
                                    players: ctrl.players,
                                    onSelect: (playerId, index) => context.read<GameController>().submitAnswer(playerId: playerId, selectedIndex: index),
                                    hasAnswered: (playerId) => ctrl.hasAnsweredThisRound(playerId),
                                  ),
                                ),
                                if (isAwaitingEffect) ...[
                                  const SizedBox(height: 8),
                                  SafeArea(
                                    top: false,
                                    minimum: const EdgeInsets.only(bottom: 6),
                                    child: ConstrainedBox(
                                      // Raise the popup and ensure all its content is visible.
                                      // If content grows, allow scrolling within a capped height.
                                      constraints: BoxConstraints(maxHeight: constraints.maxHeight * 0.30),
                                      child: SingleChildScrollView(
                                        padding: EdgeInsets.zero,
                                        child: _WinnerEffectBar(winnerId: ctrl.winnerPlayerId),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  _BottomActionBar(colorScheme: cs),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TimerTitlePill extends StatelessWidget {
  const _TimerTitlePill({required this.secondsLeft, required this.knockoutAvailable});

  final int secondsLeft;
  final bool knockoutAvailable;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWarning = secondsLeft <= 5;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppGameColors.timerPillBgDark : AppGameColors.timerPillBgLight;
    final fg = isWarning ? cs.error : AppGameColors.timerPillFgNormal;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, size: 16, color: fg),
          const SizedBox(width: 6),
          Text('$secondsLeft ث', style: context.textStyles.labelMedium?.withColor(fg).semiBold),
          if (knockoutAvailable) ...[
            const SizedBox(width: 8),
            Icon(Icons.warning_amber_rounded, size: 16, color: cs.error),
          ],
        ],
      ),
    );
  }
}

class _ScoreboardPanel extends StatelessWidget {
  const _ScoreboardPanel({required this.gameWinnerId});

  final int? gameWinnerId;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<GameController>();
    final cs = Theme.of(context).colorScheme;
    return Container(
      // Widen the inner rectangles inside each player column by reducing
      // horizontal padding and gaps (without changing the outer panel width).
      // IMPORTANT (user request): do NOT increase the scoreboard background size.
      // To make the *columns* look ~5% taller within the same background,
      // reduce the vertical padding so the children can occupy more height.
      // Keep the scoreboard background height EXACTLY the same,
      // but reduce inner padding so columns can extend further downward.
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: cs.outline.withValues(alpha: 0.12))),
      child: Row(
        children: [
          for (final p in ctrl.players) ...[
            Expanded(
              child: PlayerColumnBoard(player: p, level: ctrl.getPlayerLevel(p.points), isWinner: gameWinnerId != null && p.id == gameWinnerId),
            ),
            if (p.id != ctrl.players.last.id) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

class _TimerAndStatusBar extends StatelessWidget {
  const _TimerAndStatusBar({required this.secondsLeft, required this.knockoutAvailable, required this.knockoutRightHolders});

  final int secondsLeft;
  final bool knockoutAvailable;
  final Set<int> knockoutRightHolders;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWarning = secondsLeft <= 5;
    final barColor = isWarning ? cs.errorContainer : cs.surfaceContainerHighest;
    final fg = isWarning ? cs.onErrorContainer : cs.onSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: barColor.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: cs.outline.withValues(alpha: 0.12))),
      child: Row(
        children: [
          Icon(Icons.timer, color: fg),
          const SizedBox(width: 8),
          Text('الوقت: $secondsLeft ث', style: context.textStyles.titleSmall?.withColor(fg).semiBold),
          const Spacer(),
          if (knockoutAvailable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: cs.error.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999), border: Border.all(color: cs.error.withValues(alpha: 0.35))),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: cs.error),
                  const SizedBox(width: 6),
                  Text('قريبة: الضربة القاضية', style: context.textStyles.labelLarge?.withColor(cs.error).semiBold),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question, required this.questionNumber, required this.totalQuestions, required this.phase, required this.lastSelectedIndex});

  final GameQuestion? question;
  final int questionNumber;
  final int totalQuestions;
  final GamePhase phase;
  final int? lastSelectedIndex;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final q = question;
    final categoryLabel = q == null ? '' : _categoryLabel(q.category);
    final shouldReveal = q != null && phase != GamePhase.showingQuestion;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      // Slightly tighter padding to match the 15% area reduction request.
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? AppGameColors.questionCardBgDark : AppGameColors.questionCardBgLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _QuestionHeaderRow(
            questionNumber: questionNumber,
            totalQuestions: totalQuestions,
            categoryLabel: categoryLabel,
            isShield: q?.isShield ?? false,
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Center(
                    child: Text(
                      q?.text ?? '...',
                      textAlign: TextAlign.center,
                      style: context.textStyles.titleMedium?.withColor(cs.onSurface).semiBold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (q != null)
            _OptionsTwoColumns(
              options: q.options,
              correctIndex: q.correctIndex,
              reveal: shouldReveal,
              selectedIndex: lastSelectedIndex,
            ),
        ],
      ),
    );
  }

  String _optLabel(int i) => switch (i) { 0 => 'A', 1 => 'B', 2 => 'C', _ => 'D' };
}

class _QuestionHeaderRow extends StatelessWidget {
  const _QuestionHeaderRow({required this.questionNumber, required this.totalQuestions, required this.categoryLabel, required this.isShield});

  final int questionNumber;
  final int totalQuestions;
  final String categoryLabel;
  final bool isShield;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(999)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('سؤال $questionNumber / $totalQuestions', style: context.textStyles.labelLarge?.withColor(cs.onPrimaryContainer).semiBold),
              if (categoryLabel.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(categoryLabel, style: context.textStyles.labelLarge?.withColor(cs.error).semiBold),
              ],
            ],
          ),
        ),
        const Spacer(),
        if (isShield)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: cs.tertiary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999), border: Border.all(color: cs.tertiary.withValues(alpha: 0.35))),
            child: Row(
              children: [
                Icon(Icons.shield, size: 18, color: cs.tertiary),
                const SizedBox(width: 6),
                Text('درع الحماية', style: context.textStyles.labelLarge?.withColor(cs.tertiary).semiBold),
              ],
            ),
          ),
      ],
    );
  }
}

class _OptionsTwoColumns extends StatelessWidget {
  const _OptionsTwoColumns({required this.options, required this.correctIndex, required this.reveal, required this.selectedIndex});
  final List<String> options;
  final int correctIndex;
  final bool reveal;
  final int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    // Desired layout:
    // A فوق B
    // C فوق D
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _OptionChip(
                label: 'A',
                value: options[0],
                state: _optionRevealStateFor(index: 0, reveal: reveal, correctIndex: correctIndex, selectedIndex: selectedIndex),
              ),
              const SizedBox(height: 10),
              _OptionChip(
                label: 'B',
                value: options[1],
                state: _optionRevealStateFor(index: 1, reveal: reveal, correctIndex: correctIndex, selectedIndex: selectedIndex),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _OptionChip(
                label: 'C',
                value: options[2],
                state: _optionRevealStateFor(index: 2, reveal: reveal, correctIndex: correctIndex, selectedIndex: selectedIndex),
              ),
              const SizedBox(height: 10),
              _OptionChip(
                label: 'D',
                value: options[3],
                state: _optionRevealStateFor(index: 3, reveal: reveal, correctIndex: correctIndex, selectedIndex: selectedIndex),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _OptionRevealState { none, correct, wrong }

_OptionRevealState _optionRevealStateFor({required int index, required bool reveal, required int correctIndex, required int? selectedIndex}) {
  if (!reveal) return _OptionRevealState.none;
  if (index == correctIndex) return _OptionRevealState.correct;
  if (selectedIndex != null && index == selectedIndex && selectedIndex != correctIndex) return _OptionRevealState.wrong;
  return _OptionRevealState.none;
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({required this.label, required this.value, required this.state});

  final String label;
  final String value;
  final _OptionRevealState state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final correctBg = isDark ? AppGameColors.correctGreenContainerDark : AppGameColors.correctGreenContainerLight;
    final correctBorder = AppGameColors.correctGreen.withValues(alpha: 0.75);
    final correctBadgeBg = AppGameColors.correctGreen;
    const correctBadgeFg = Colors.white;

    final (bg, border, badgeBg, badgeFg) = switch (state) {
      _OptionRevealState.correct => (correctBg.withValues(alpha: isDark ? 0.8 : 0.95), correctBorder, correctBadgeBg, correctBadgeFg),
      _OptionRevealState.wrong => (cs.errorContainer.withValues(alpha: isDark ? 0.75 : 0.9), cs.error.withValues(alpha: 0.55), cs.error, cs.onError),
      _OptionRevealState.none => (cs.surfaceContainerHighest.withValues(alpha: 0.55), cs.outline.withValues(alpha: 0.12), cs.primary, cs.onPrimary),
    };

    return SizedBox(
      height: 40,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(label, style: context.textStyles.labelLarge?.withColor(badgeFg).semiBold)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodyMedium?.withColor(cs.onSurface).medium)),
          ],
        ),
      ),
    );
  }
}

class _AnswersGrid extends StatelessWidget {
  const _AnswersGrid({required this.phase, required this.players, required this.onSelect, required this.hasAnswered});

  final GamePhase phase;
  final List<GamePlayer> players;
  final void Function(int playerId, int index) onSelect;
  final bool Function(int playerId) hasAnswered;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = phase != GamePhase.showingQuestion;

    // By default, GridView expands to the available height and keeps its children
    // pinned to the top, leaving an empty space at the bottom on short grids.
    // Here we compute the grid's natural height, then align it to the bottom
    // to eliminate that empty area (and free space visually for the scoreboard).
    return LayoutBuilder(
      builder: (context, c) {
        // Reduce background/padding around answer pads (user request).
        const outerPadding = 5.0;
        const mainAxisSpacing = 10.0;
        const crossAxisSpacing = 10.0;
        const crossAxisCount = 2;
        const childAspectRatio = 2.1;

        final rows = (players.length / crossAxisCount).ceil().clamp(1, 99);
        final usableW = (c.maxWidth - (outerPadding * 2) - crossAxisSpacing).clamp(0.0, double.infinity);
        final tileW = usableW / crossAxisCount;
        final tileH = tileW / childAspectRatio;
        final naturalGridH = (rows * tileH) + ((rows - 1) * mainAxisSpacing);
        final maxH = (c.maxHeight - (outerPadding * 2)).clamp(0.0, double.infinity);
        final gridH = naturalGridH.clamp(0.0, maxH);

        // Make the background panel hug the grid instead of filling the whole slot.
        // This removes the large empty tinted area while keeping the grid positioned low.
        final panelH = (gridH + (outerPadding * 2)).clamp(0.0, c.maxHeight);

        return Align(
          // User request: lift the players' answer pads upward to attach to the question card.
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: panelH,
            child: Container(
              padding: const EdgeInsets.all(outerPadding),
              decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.28), borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: cs.outline.withValues(alpha: 0.10))),
              child: SizedBox(
                height: gridH,
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: mainAxisSpacing,
                  crossAxisSpacing: crossAxisSpacing,
                  childAspectRatio: childAspectRatio,
                  children: [
                    for (final p in players)
                      _PlayerAnswerPad(
                        player: p,
                        disabled: disabled || !p.isActive || hasAnswered(p.id),
                        onSelect: (index) => onSelect(p.id, index),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlayerAnswerPad extends StatelessWidget {
  const _PlayerAnswerPad({required this.player, required this.disabled, required this.onSelect});

  final GamePlayer player;
  final bool disabled;
  final void Function(int index) onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ctrl = context.read<GameController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeId = player.id.clamp(0, AppGameColors.playerPadBgLight.length - 1);
    final padBg = isDark ? AppGameColors.playerPadBgDark[safeId] : AppGameColors.playerPadBgLight[safeId];

    final level = ctrl.getPlayerLevel(player.points);
    final pointsColor = _levelColor(level);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: player.isActive ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: padBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(player.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.titleSmall?.semiBold),
                ),
                const SizedBox(width: 8),
                Text('${player.points}', style: context.textStyles.labelLarge?.withColor(pointsColor).semiBold),
              ],
            ),
            const SizedBox(height: 6),
            // Avoid Expanded here to prevent small-height overflows within GridView tiles.
            SizedBox(
              height: 32,
              child: Row(
                children: [
                  Expanded(child: _AnswerButton(playerId: player.id, label: 'A', onPressed: disabled ? null : () => onSelect(0))),
                  const SizedBox(width: 8),
                  Expanded(child: _AnswerButton(playerId: player.id, label: 'B', onPressed: disabled ? null : () => onSelect(1))),
                  const SizedBox(width: 8),
                  Expanded(child: _AnswerButton(playerId: player.id, label: 'C', onPressed: disabled ? null : () => onSelect(2))),
                  const SizedBox(width: 8),
                  Expanded(child: _AnswerButton(playerId: player.id, label: 'D', onPressed: disabled ? null : () => onSelect(3))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _levelColor(ColorLevel level) => switch (level) {
    ColorLevel.green1 || ColorLevel.green2 || ColorLevel.green3 => AppGameColors.levelGreen,
    ColorLevel.yellow1 || ColorLevel.yellow2 || ColorLevel.yellow3 => AppGameColors.levelYellow,
    ColorLevel.red1 || ColorLevel.red2 || ColorLevel.red3 => AppGameColors.levelRed,
    ColorLevel.none => Colors.black,
  };
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({required this.playerId, required this.label, required this.onPressed});

  final int playerId;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeId = playerId.clamp(0, AppGameColors.playerAnswerBgLight.length - 1);
    final bg = isDark ? AppGameColors.playerAnswerBgDark[safeId] : AppGameColors.playerAnswerBgLight[safeId];
    final fg = isDark ? AppGameColors.playerAnswerFgDark[safeId] : AppGameColors.playerAnswerFgLight[safeId];
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 6),
        backgroundColor: bg,
        disabledBackgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label, style: context.textStyles.titleSmall?.withColor(fg).semiBold),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<GameController>();
    Widget child;

    if (ctrl.phase == GamePhase.waitingForBell) {
      child = Align(
        alignment: Alignment.center,
        child: FilledButton.icon(
          onPressed: () => context.read<GameController>().beginGame(),
          icon: Icon(Icons.notifications_active_rounded, color: colorScheme.onPrimary),
          label: Text('اقرع الجرس', style: context.textStyles.titleMedium?.withColor(colorScheme.onPrimary).semiBold),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
        ),
      );
    } else if (ctrl.phase == GamePhase.shieldReady) {
      child = Align(
        alignment: Alignment.center,
        child: FilledButton.icon(
          onPressed: () => context.read<GameController>().startShieldQuestion(),
          icon: Icon(Icons.arrow_forward, color: colorScheme.onPrimary),
          label: Text('السؤال التالي', style: context.textStyles.titleMedium?.withColor(colorScheme.onPrimary).semiBold),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
        ),
      );
    } else if (ctrl.phase == GamePhase.knockoutReady) {
      child = Align(
        alignment: Alignment.center,
        child: FilledButton.icon(
          onPressed: () => context.read<GameController>().startKnockoutPendingQuestion(),
          icon: Icon(Icons.arrow_forward, color: colorScheme.onPrimary),
          label: Text('السؤال التالي', style: context.textStyles.titleMedium?.withColor(colorScheme.onPrimary).semiBold),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
        ),
      );
    } else if (ctrl.phase == GamePhase.awaitingWinnerEffect) {
      child = _WinnerEffectBar(winnerId: ctrl.winnerPlayerId);
    } else if (ctrl.phase == GamePhase.roundEnded) {
      child = Align(
        alignment: Alignment.center,
        child: FilledButton.icon(
          onPressed: () => context.read<GameController>().nextQuestion(),
          icon: Icon(Icons.arrow_forward, color: colorScheme.onPrimary),
          label: Text('السؤال التالي', style: context.textStyles.titleMedium?.withColor(colorScheme.onPrimary).semiBold),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
        ),
      );
    } else if (ctrl.phase == GamePhase.finished) {
      final winnerId = ctrl.gameWinnerId;
      final winnerName = winnerId == null ? '—' : ctrl.players.firstWhere((p) => p.id == winnerId).name;
      child = _FinishedBar(winnerName: winnerName);
    } else {
      child = const SizedBox(height: 52);
    }

    return SafeArea(top: false, minimum: const EdgeInsets.only(bottom: 6), child: child);
  }
}

class _WinnerEffectBar extends StatelessWidget {
  const _WinnerEffectBar({required this.winnerId});

  final int? winnerId;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<GameController>();
    final cs = Theme.of(context).colorScheme;
    final winner = winnerId == null ? null : ctrl.players.firstWhere((p) => p.id == winnerId);
    if (winner == null) return const SizedBox.shrink();

    final isShield = ctrl.currentQuestion?.isShield == true;
    final canAddSelf = ctrl.canWinnerAddSelf();
    final showAddSelf = canAddSelf && winner.points < 100;

    final hintText = isShield
        ? (winner.points > 90
            ? 'درع الحماية: رصيدك أكبر من 90، لذلك لك الحق في خصم 10 نقاط من لاعب آخر.'
            : 'درع الحماية: يمكنك اختيار خصم 10 من لاعب آخر أو إضافة 10 لرصيدك.')
        : '';

    final addLabel = isShield ? 'إضافة 10 لرصيدك' : 'حالة خاصة: إضافة 10 لرصيدك';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: cs.outline.withValues(alpha: 0.12))),
      child: LayoutBuilder(
        builder: (context, c) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: cs.tertiary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('إجابة صحيحة — ${winner.name}', style: context.textStyles.titleSmall?.semiBold)),
                ],
              ),
              const SizedBox(height: 10),
              if (hintText.isNotEmpty) ...[
                Text(hintText, style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant)),
                const SizedBox(height: 12),
              ] else
                const SizedBox(height: 6),
              FilledButton.icon(
                onPressed: () async {
                  final targetId = await showModalBottomSheet<int>(
                    context: context,
                    showDragHandle: true,
                    isScrollControlled: true,
                    builder: (context) => _DeductTargetSheet(excludeId: winner.id),
                  );
                  if (targetId == null) return;
                  context.read<GameController>().applyWinnerEffect(type: WinnerEffectType.deductOther, targetPlayerId: targetId);
                },
                icon: Icon(Icons.remove_circle_outline, color: cs.onPrimary),
                label: Text('خصم 10 من لاعب', style: context.textStyles.titleSmall?.withColor(cs.onPrimary).semiBold),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
              if (showAddSelf) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => context.read<GameController>().applyWinnerEffect(type: WinnerEffectType.addSelf),
                  icon: Icon(Icons.add_circle_outline, color: cs.primary),
                  label: Text(addLabel, style: context.textStyles.labelLarge?.withColor(cs.primary).semiBold),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DeductTargetSheet extends StatelessWidget {
  const _DeductTargetSheet({required this.excludeId});

  final int excludeId;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<GameController>();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final targets = ctrl.players.where((p) => p.id != excludeId && p.isActive).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('اختر اللاعب الذي سيتم خصم 10 نقاط منه', style: context.textStyles.titleMedium?.semiBold),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: ListView.separated(
                    itemCount: targets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final p = targets[i];
                      final level = ctrl.getPlayerLevel(p.points);
                      final levelColor = _levelColor(level);
                      final bg = levelColor.withValues(alpha: isDark ? 0.25 : 0.18);
                      final border = levelColor.withValues(alpha: isDark ? 0.45 : 0.35);
                      return FilledButton(
                        onPressed: () => context.pop(p.id),
                        style: FilledButton.styleFrom(
                          backgroundColor: bg,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg), side: BorderSide(color: border)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(p.name, style: context.textStyles.titleSmall?.withColor(cs.onSurface).semiBold, overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 10),
                            Text('${p.points}', style: context.textStyles.labelLarge?.withColor(Colors.black).semiBold),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _levelColor(ColorLevel level) => switch (level) {
    ColorLevel.green1 || ColorLevel.green2 || ColorLevel.green3 => AppGameColors.levelGreen,
    ColorLevel.yellow1 || ColorLevel.yellow2 || ColorLevel.yellow3 => AppGameColors.levelYellow,
    ColorLevel.red1 || ColorLevel.red2 || ColorLevel.red3 => AppGameColors.levelRed,
    ColorLevel.none => AppGameColors.levelGreen,
  };
}

class _FinishedBar extends StatelessWidget {
  const _FinishedBar({required this.winnerName});

  final String winnerName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: cs.primary.withValues(alpha: 0.2))),
      child: Row(
        children: [
          Icon(Icons.emoji_events, color: cs.onPrimaryContainer),
          const SizedBox(width: 10),
          Expanded(child: Text('الفائز: $winnerName', style: context.textStyles.titleMedium?.withColor(cs.onPrimaryContainer).semiBold)),
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.setup),
            icon: Icon(Icons.home, color: cs.onPrimary),
            label: Text('مباراة جديدة', style: context.textStyles.labelLarge?.withColor(cs.onPrimary).semiBold),
          ),
        ],
      ),
    );
  }
}
