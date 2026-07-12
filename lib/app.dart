import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:stash/data/database.dart';
import 'package:stash/features/home/home_page.dart';
import 'package:stash/features/goals/goals_page.dart';
import 'package:stash/features/insights/insights_page.dart';
import 'package:stash/features/settings/settings_page.dart';
import 'package:stash/features/settings/theme_page.dart';
import 'package:stash/features/goals/goal_detail_page.dart';
import 'package:stash/features/goals/goal_form_page.dart';
import 'package:stash/features/onboarding/splash_screen.dart';
import 'package:stash/features/onboarding/onboarding_screen.dart';
import 'package:stash/features/settings/about_page.dart';
import 'package:stash/features/settings/update_page.dart';
import 'package:stash/features/achievements/achievements_page.dart';
import 'package:stash/providers/settings_provider.dart';
import 'package:stash/services/app_prefs.dart';
import 'package:stash/widgets/ui.dart';
import 'package:stash/widgets/whats_new_dialog.dart';
import 'package:stash/widgets/update_available_dialog.dart';
import 'package:stash/services/update_service.dart';

CustomTransitionPage _fadeSlidePage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
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
      GoRoute(
        path: '/achievements',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AchievementsPage(),
      ),
      GoRoute(
        path: '/update',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const UpdatePage(),
      ),
      GoRoute(
        path: '/theme',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ThemePage(),
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
    _NavDestination(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    _NavDestination(icon: Icons.savings_outlined, activeIcon: Icons.savings_rounded, label: 'Goals'),
    _NavDestination(icon: Icons.insights_outlined, activeIcon: Icons.insights_rounded, label: 'Insights'),
    _NavDestination(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WhatsNewDialog.showIfNeeded(context);
      _checkForUpdate();
    });
  }

  Future<void> _checkForUpdate() async {
    try {
      final info = await UpdateService.fetchLatestRelease();
      if (info == null || !mounted) return;
      final isNewer = await UpdateService.isNewerVersion(info.version);
      if (isNewer && mounted) {
        UpdateAvailableDialog.show(context);
      }
    } catch (_) {}
  }

  void _onTap(int index) {
    AppPrefs.setLastTab(index);
    widget.navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = ref.watch(settingsProvider).reduceMotion;
    final cs = Theme.of(context).colorScheme;
    final selectedIndex = widget.navigationShell.currentIndex;

    return Scaffold(
      body: widget.navigationShell,
      floatingActionButton: selectedIndex < 2
          ? GradientFAB(
              tooltip: 'New goal',
              onPressed: () => context.push('/goal/new'),
            ).animate(autoPlay: !reduceMotion).scale(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                begin: const Offset(0.0, 0.0),
                end: const Offset(1.0, 1.0),
              ).fade(duration: const Duration(milliseconds: 200))
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _CurvedNavBar(
        destinations: _destinations,
        selectedIndex: selectedIndex,
        onTap: _onTap,
        selectedColor: cs.primary,
        surfaceColor: cs.surface,
        unselectedColor: cs.onSurfaceVariant,
      ),
    );
  }
}

class _NavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavDestination({required this.icon, required this.activeIcon, required this.label});
}

// ── Custom curved bottom nav ────────────────────────────────────────────

class _CurvedNavBar extends StatefulWidget {
  final List<_NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final Color selectedColor;
  final Color surfaceColor;
  final Color unselectedColor;

  const _CurvedNavBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onTap,
    required this.selectedColor,
    required this.surfaceColor,
    required this.unselectedColor,
  });

  @override
  State<_CurvedNavBar> createState() => _CurvedNavBarState();
}

class _CurvedNavBarState extends State<_CurvedNavBar> {
  final _itemKeys = <GlobalKey<State>>[];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.destinations.length; i++) {
      _itemKeys.add(GlobalKey());
    }
  }

  @override
  void didUpdateWidget(covariant _CurvedNavBar old) {
    super.didUpdateWidget(old);
    if (old.destinations.length != widget.destinations.length) {
      _itemKeys.clear();
      for (var i = 0; i < widget.destinations.length; i++) {
        _itemKeys.add(GlobalKey());
      }
    }
  }

  Rect _getRect(int index) {
    final key = _itemKeys[index];
    final ctx = key.currentContext;
    if (ctx == null) return Rect.zero;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return Rect.zero;
    final pos = box.localToGlobal(Offset.zero);
    return pos & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final curveH = 30.0;

    return SizedBox(
      height: 80 + curveH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Shadow under curve
          Positioned(
            top: curveH - 4,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: widget.selectedColor.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
            ),
          ),
          // Curved background
          Positioned.fill(
            top: curveH,
            child: CustomPaint(
              painter: _NavBarPainter(
                curveHeight: curveH,
                backgroundColor: widget.surfaceColor,
              ),
            ),
          ),

          // Content row
          Positioned(
            top: curveH + 6,
            left: 0,
            right: 0,
            bottom: 0,
            child: Row(
              children: List.generate(widget.destinations.length, (index) {
                final dest = widget.destinations[index];
                final isSelected = index == widget.selectedIndex;
                return Expanded(
                  key: _itemKeys[index],
                  child: GestureDetector(
                    onTap: () => widget.onTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: _NavTile(
                      destination: dest,
                      isSelected: isSelected,
                      selectedColor: widget.selectedColor,
                      unselectedColor: widget.unselectedColor,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Curved background painter ───────────────────────────────────────────

class _NavBarPainter extends CustomPainter {
  final double curveHeight;
  final Color backgroundColor;

  _NavBarPainter({required this.curveHeight, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, curveHeight)
      ..quadraticBezierTo(
        size.width / 2,
        -curveHeight * 0.8,
        size.width,
        curveHeight,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _NavBarPainter old) =>
      old.curveHeight != curveHeight || old.backgroundColor != backgroundColor;
}

// ── Individual tile with animations ─────────────────────────────────────

class _NavTile extends StatelessWidget {
  final _NavDestination destination;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;

  const _NavTile({
    required this.destination,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with animated scale + color
          AnimatedScale(
            scale: isSelected ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: Icon(
                isSelected ? destination.activeIcon : destination.icon,
                key: ValueKey('$isSelected'),
                size: 24,
                color: isSelected ? selectedColor : unselectedColor,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Label with animated opacity + slide
          AnimatedSlide(
            offset: isSelected ? Offset.zero : const Offset(0, 0.3),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? selectedColor : unselectedColor,
                letterSpacing: isSelected ? 0.3 : 0,
              ),
              child: Opacity(
                opacity: isSelected ? 1.0 : 0.0,
                child: Text(destination.label),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
