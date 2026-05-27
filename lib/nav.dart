import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:darbah_qadiyah/game/ui/game_page.dart';
import 'package:darbah_qadiyah/game/ui/game_rules_page.dart';
import 'package:darbah_qadiyah/game/ui/game_setup_page.dart';

/// GoRouter configuration for app navigation
///
/// This uses go_router for declarative routing, which provides:
/// - Type-safe navigation
/// - Deep linking support (web URLs, app links)
/// - Easy route parameters
/// - Navigation guards and redirects
///
/// To add a new route:
/// 1. Add a route constant to AppRoutes below
/// 2. Add a GoRoute to the routes list
/// 3. Navigate using context.go() or context.push()
/// 4. Use context.pop() to go back.
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.setup,
    routes: [
      GoRoute(
        path: AppRoutes.setup,
        name: 'setup',
        pageBuilder: (context, state) => const NoTransitionPage(child: GameSetupPage()),
      ),
      GoRoute(
        path: AppRoutes.rules,
        name: 'rules',
        pageBuilder: (context, state) => const NoTransitionPage(child: GameRulesPage()),
      ),
      GoRoute(
        path: AppRoutes.game,
        name: 'game',
        pageBuilder: (context, state) => const NoTransitionPage(child: GamePage()),
      ),
    ],
  );
}

/// Route path constants
/// Use these instead of hard-coding route strings
class AppRoutes {
  static const String setup = '/';
  static const String rules = '/rules';
  static const String game = '/game';
}
