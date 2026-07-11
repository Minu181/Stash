import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:stash/data/database.dart';
import 'package:stash/features/home/home_page.dart';
import 'package:stash/features/goals/goals_page.dart';
import 'package:stash/features/insights/insights_page.dart';
import 'package:stash/features/settings/settings_page.dart';
import 'package:stash/features/goals/goal_detail_page.dart';
import 'package:stash/features/goals/goal_form_page.dart';
import 'package:stash/features/onboarding/splash_screen.dart';
import 'package:stash/features/onboarding/onboarding_screen.dart';
import 'package:stash/features/settings/about_page.dart';
import 'package:stash/providers/settings_provider.dart';
import 'package:stash/services/app_prefs.dart';
import 'package:stash/widgets/ui.dart';

CustomTransitionPage _fadeSlidePage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
    },
  );
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

Widget _animatedContainerBuilder(
  BuildContext context,
  StatefulNavigationShell shell,
  List<Widget> children,
) {
  return children[shell.currentIndex];
}

final routerProvider = Provider<GoRouter>((ref) {
  final settings = ref.watch(settingsProvider);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        navigatorContainerBuilder: _animatedContainerBuilder,
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (context, state) => const HomePage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/goals', builder: (context, state) => const GoalsPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/insights', builder: (context, state) => const InsightsPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
          ]),
        ],
      ),
      GoRoute(
        path: '/goal/new',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(state, const GoalFormPage()),
      ),
      GoRoute(
        path: '/goal/edit',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final goal = state.extra as Goal;
          return _fadeSlidePage(state, GoalFormPage(goal: goal));
        },
      ),
      GoRoute(
        path: '/goal/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _fadeSlidePage(state, GoalDetailPage(goalId: id));
        },
      ),
      GoRoute(
        path: '/about',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AboutPage(),
      ),
    ],
    redirect: (context, state) {
      final isOnSplash = state.matchedLocation == '/splash';
      final isOnOnboarding = state.matchedLocation == '/onboarding';
      final onboarded = settings.hasOnboarded;

      if (isOnSplash) return null;

      if (!onboarded && !isOnOnboarding) return '/onboarding';
      if (onboarded && isOnOnboarding) return '/';

      return null;
    },
  );
  return router;
});

class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.savings_rounded), label: 'Goals'),
    NavigationDestination(icon: Icon(Icons.insights_rounded), label: 'Insights'),
    NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Settings'),
  ];

  void _onTap(int index) {
    AppPrefs.setLastTab(index);
    widget.navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = ref.watch(settingsProvider).reduceMotion;
    return Scaffold(
      body: widget.navigationShell,
      floatingActionButton: GradientFAB(
        tooltip: 'New goal',
        onPressed: () => context.push('/goal/new'),
      ).animate(autoPlay: !reduceMotion).scale(duration: const Duration(milliseconds: 250), curve: Curves.easeOutBack),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: _destinations,
      ),
    );
  }
}
