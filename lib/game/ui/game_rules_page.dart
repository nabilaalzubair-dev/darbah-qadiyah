import 'package:darbah_qadiyah/nav.dart';
import 'package:darbah_qadiyah/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GameRulesPage extends StatelessWidget {
  const GameRulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = context.textStyles;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerGradient = isDark ? AppGameColors.setupHeaderGradientDark : AppGameColors.setupHeaderGradientLight;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: false,
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Padding(
                  padding: AppSpacing.paddingLg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _RulesHeader(gradient: headerGradient),
                      const SizedBox(height: AppSpacing.lg),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _RulesCard(
                                title: 'الفكرة العامة',
                                icon: Icons.flash_on_rounded,
                                items: const [
                                  'لعبة معلومات سريعة تعتمد على سرعة الإجابة وإدارة النقاط.',
                                  'كل لاعب يبدأ بـ 100 نقطة (تمثل 100 ألف ريال).',
                                  'النقاط تزيد أو تنقص بحسب الإجابات والأحداث الخاصة.',
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _RulesCard(
                                title: 'نظام اللعب',
                                icon: Icons.sports_mma_rounded,
                                items: const [
                                  'عدد اللاعبين ثابت: 4 ولا تبدأ اللعبة بدونهم.',
                                  'لكل سؤال مؤقت (25 ثانية) – آخر 5 ثوانٍ تحذير.',
                                  'عند اختيار إجابة: الخاطئة تُلوَّن أحمر، والصحيحة أخضر.',
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _RulesCard(
                                title: 'درع الحماية',
                                icon: Icons.shield_rounded,
                                tone: _RulesTone.warning,
                                items: const [
                                      'عندما يصل أي لاعب إلى رصيد 30 نقطة: يتم جدولة سؤال “درع الحماية” ليكون السؤال التالي مباشرة.',
                                  'عند جدولة الدرع ستظهر نافذة منبثقة توضح ذلك.',
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _RulesCard(
                                title: 'الخروج من اللعبة',
                                icon: Icons.exit_to_app_rounded,
                                tone: _RulesTone.danger,
                                items: const [
                                  'عند خروج لاعب ستظهر نافذة “مع السلامة” وتبقى 5 ثوانٍ.',
                                  'استمر حتى يتبقى لاعب واحد لإعلان الفائز.',
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.32 : 0.24),
                                  borderRadius: BorderRadius.circular(AppRadius.xl),
                                  border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text('جاهز؟', style: text.titleLarge?.semiBold, textAlign: TextAlign.center),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      'لن يمكنك تجاوز هذه الصفحة إلا بعد تأكيد فهم الشروط.',
                                      style: text.bodyMedium?.withColor(cs.onSurfaceVariant),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    FilledButton.icon(
                                      onPressed: () => context.go(AppRoutes.game),
                                      icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                                      label: Text('فهمت الشروط', style: text.titleMedium?.semiBold.withColor(Colors.white)),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppGameColors.boxingGloveRed,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RulesHeader extends StatelessWidget {
  const _RulesHeader({required this.gradient});

  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
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
            const Icon(Icons.rule_rounded, color: Colors.white),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                'شرح اللعبة وشروطها',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (text.headlineSmall ?? const TextStyle()).semiBold.withColor(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _RulesTone { normal, warning, danger }

class _RulesCard extends StatelessWidget {
  const _RulesCard({required this.title, required this.icon, required this.items, this.tone = _RulesTone.normal});

  final String title;
  final IconData icon;
  final List<String> items;
  final _RulesTone tone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = context.textStyles;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accent = switch (tone) {
      _RulesTone.normal => cs.primary,
      _RulesTone.warning => AppGameColors.levelYellow,
      _RulesTone.danger => AppGameColors.boxingGloveRed,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.30 : 0.22),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(title, style: text.titleLarge?.semiBold)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final it in items) ...[
            _RulesBullet(text: it, accent: accent),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _RulesBullet extends StatelessWidget {
  const _RulesBullet({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = context.textStyles;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 6),
          child: Container(width: 8, height: 8, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(99))),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(text, style: t.bodyMedium?.withColor(cs.onSurface.withValues(alpha: 0.90)), textAlign: TextAlign.right)),
      ],
    );
  }
}
