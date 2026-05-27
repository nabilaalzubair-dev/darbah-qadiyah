import 'package:darbah_qadiyah/game/game_controller.dart';
import 'package:darbah_qadiyah/nav.dart';
import 'package:darbah_qadiyah/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class GameSetupPage extends StatefulWidget {
  const GameSetupPage({super.key});

  @override
  State<GameSetupPage> createState() => _GameSetupPageState();
}

class _GameSetupPageState extends State<GameSetupPage> {
  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    const defaultNames = ['الدافور', 'المفكر', 'مصطفى', 'القادح'];
    _controllers = List.generate(4, (i) => TextEditingController(text: defaultNames[i]));
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _start() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final names = _controllers.map((c) => c.text.trim()).toList();
    context.read<GameController>().startNewMatch(playerNames: names);
    context.go(AppRoutes.rules);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerGradient = isDark ? AppGameColors.setupHeaderGradientDark : AppGameColors.setupHeaderGradientLight;
    final headerIconChip = isDark ? AppGameColors.setupHeaderIconChipDark : AppGameColors.setupHeaderIconChipLight;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: AppSpacing.paddingLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    const SizedBox(height: AppSpacing.xl),
                    SetupHeader(gradient: headerGradient, iconChipColor: headerIconChip),
                    const SizedBox(height: AppSpacing.md),
                    const SetupSetupHeroTextSection(),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: constraints.maxHeight),
                              child: IntrinsicHeight(
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const Spacer(),
                                      for (var i = 0; i < 4; i++) ...[
                                        PlayerNameField(index: i, controller: _controllers[i]),
                                        const SizedBox(height: AppSpacing.md),
                                      ],
                                      const SizedBox(height: AppSpacing.sm),
                                      FilledButton(
                                        onPressed: () {
                                          FocusManager.instance.primaryFocus?.unfocus();
                                          _start();
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('اقرأ الشروط', style: context.textStyles.titleMedium?.withColor(Colors.white)),
                                            const SizedBox(width: AppSpacing.sm),
                                            const Icon(Icons.menu_book_rounded, color: Colors.white),
                                          ],
                                        ),
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          backgroundColor: AppGameColors.boxingGloveRed,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xl),
                                    ],
                                  ),
                                ),
                              ),
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
        ),
      ),
    );
  }
}

class SetupSetupHeroTextSection extends StatelessWidget {
  const SetupSetupHeroTextSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    final blackPanel = isDark ? Colors.black.withValues(alpha: 0.62) : Colors.black.withValues(alpha: 0.80);

    // Keep the bullets readable in both light/dark modes by using the theme's
    // on-surface color (instead of hard-coded black).
    final bulletsBase = (context.textStyles.titleMedium ?? const TextStyle(fontSize: 16))
        .bold
        .withSize(((context.textStyles.titleMedium?.fontSize) ?? 16) * 1.12)
        .withColor(cs.onSurface);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Transform.translate(offset: Offset(0, (1 - t) * 10), child: Opacity(opacity: t, child: child)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: blackPanel,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Text(
                'الإثارة • السرعة • التحدي',
                textAlign: TextAlign.center,
                style: (context.textStyles.titleMedium ?? const TextStyle()).semiBold.withColor(AppGameColors.setupTaglineYellow),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? cs.surfaceContainerHighest.withValues(alpha: 0.38) : cs.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• هل أنت مستعد للتحدي ؟', style: bulletsBase),
                const SizedBox(height: 10),
                Text('• هل تمتلك الشجاعة ؟', style: bulletsBase),
                const SizedBox(height: 10),
                Text('• الضربة القاضية بانتظارك ..', style: bulletsBase),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SetupHeader extends StatelessWidget {
  const SetupHeader({super.key, required this.gradient, required this.iconChipColor});

  final List<Color> gradient;
  final Color iconChipColor;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    final baseTitleStyle = (text.headlineSmall ?? const TextStyle());

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Transform.translate(offset: Offset(0, (1 - t) * 10), child: Opacity(opacity: t, child: child)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.centerRight, end: Alignment.centerLeft),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'الضربة القاضية',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: baseTitleStyle.withSize((baseTitleStyle.fontSize ?? 24) * 1.6).semiBold.withColor(Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _HeaderIconChip(icon: Icons.sports_mma_rounded, bg: iconChipColor, iconColor: AppGameColors.boxingGloveRed),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconChip extends StatelessWidget {
  const _HeaderIconChip({required this.icon, required this.bg, required this.iconColor});

  final IconData icon;
  final Color bg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 53,
      height: 53,
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, color: iconColor, size: 31),
    );
  }
}

class PlayerNameField extends StatelessWidget {
  const PlayerNameField({super.key, required this.index, required this.controller});

  final int index;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final playerNo = index + 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final numberBg = isDark ? AppGameColors.setupPlayerNumberBgDark : AppGameColors.setupPlayerNumberBgLight;
    final numberFg = isDark ? cs.onSurface : cs.onSurface;
    final accentBorder = isDark ? cs.onSurface : cs.primary;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + (index * 70)),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Transform.translate(offset: Offset(0, (1 - t) * 8), child: Opacity(opacity: t, child: child)),
      child: TextFormField(
        controller: controller,
        textInputAction: playerNo == 4 ? TextInputAction.done : TextInputAction.next,
        decoration: InputDecoration(
          labelText: 'اسم اللاعب $playerNo',
          prefixIcon: Padding(
            padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: numberBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: accentBorder.withValues(alpha: 0.22))),
              child: Text('$playerNo', style: context.textStyles.labelLarge?.semiBold.withColor(numberFg)),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.28),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.xl), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
        validator: (v) {
          final t = (v ?? '').trim();
          if (t.isEmpty) return 'الاسم مطلوب';
          return null;
        },
        onFieldSubmitted: (_) {
          if (playerNo == 4) {
            FocusManager.instance.primaryFocus?.unfocus();
            // ignore: avoid_print
            if (kDebugMode) debugPrint('Setup: submitted last player name');
          }
        },
      ),
    );
  }
}
