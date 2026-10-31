import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config.dart';
import 'screens/auth.dart';
import 'screens/courses.dart';
import 'screens/home.dart';
import 'screens/play.dart';
import 'screens/profile.dart';
import 'screens/ranking.dart';
import 'screens/teacher.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  runApp(KodlaApp(state: state));
  state.init();
}

class KodlaApp extends StatefulWidget {
  final AppState state;
  const KodlaApp({super.key, required this.state});

  @override
  State<KodlaApp> createState() => _KodlaAppState();
}

class _KodlaAppState extends State<KodlaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Telefon mavzusi almashsa / при смене темы телефона
  @override
  void didChangePlatformBrightness() {
    widget.state.setPlatformBrightness(WidgetsBinding.instance.platformDispatcher.platformBrightness);
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      child: Builder(builder: (context) {
        final s = AppScope.of(context);
        return MaterialApp(
          title: kAppName,
          debugShowCheckedModeBanner: false,
          navigatorKey: s.navigatorKey,
          theme: buildTheme(kLight),
          darkTheme: buildTheme(kDark),
          themeMode: switch (s.theme) {
            'light' => ThemeMode.light,
            'dark' => ThemeMode.dark,
            _ => ThemeMode.system,
          },
          themeAnimationDuration: const Duration(milliseconds: 320),
          themeAnimationCurve: Motion.curve,
          home: const RootScreen(),
        );
      }),
    );
  }
}

/// Kirish yoki asosiy ekran / вход или главный экран.
class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final Widget screen;
    if (!s.ready) {
      screen = const SplashScreen(key: ValueKey('splash'));
    } else if (!s.online && s.mode != 'offline') {
      screen = const AuthScreen(key: ValueKey('auth'));
    } else {
      screen = const HomeShell(key: ValueKey('home'));
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (s.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.transparent),
      child: AnimatedSwitcher(
        duration: Motion.of(context, Motion.slow),
        switchInCurve: Motion.curve,
        switchOutCurve: Curves.easeInCubic,
        child: screen,
      ),
    );
  }
}

/// Ochilish ekrani / заставка.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: AppBackground(
        strong: true,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const AppLogo(size: 96),
            const SizedBox(height: S.x5),
            Text(kAppName, style: AppType.title1.copyWith(color: c.text)),
            const SizedBox(height: S.x6),
            CupertinoActivityIndicator(color: c.text2, radius: 11),
          ]),
        ),
      ),
    );
  }
}

/// Ilova logotipi (ikonka rasmi) / логотип приложения.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 88});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.235),
        boxShadow: Shadows.glow(c.accent, c, strength: 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.235),
        child: Image.asset('assets/icon/icon.png', fit: BoxFit.cover, filterQuality: FilterQuality.medium),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Ertasi kuni ochilsa — kunlik vazifalar yangilanadi.
    // Если приложение открыли на следующий день — обновляем задания дня.
    if (state == AppLifecycleState.resumed) AppScope.read(context).refreshDay();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final tabs = s.tabs;
    final tab = tabs.contains(s.tab) || s.tab == 'profile' ? s.tab : 'home';

    final Widget body = switch (tab) {
      'courses' => const CoursesTab(),
      'play' => const PlayTab(),
      'ranking' => const RankingTab(),
      'teacher' => const TeacherTab(),
      'profile' => const ProfileTab(),
      _ => const HomeTab(),
    };

    final meta = <String, (IconData, String)>{
      'home': (Icons.explore_rounded, s.t('adventure')),
      'courses': (Icons.map_rounded, s.t('courses')),
      'play': (Icons.terminal_rounded, s.t('play')),
      'ranking': (Icons.leaderboard_rounded, s.t('ranking')),
      'profile': (Icons.person_rounded, s.t('profile')),
      'teacher': (Icons.school_rounded, s.t('teacher')),
    };
    final sel = tabs.contains(tab) ? tabs.indexOf(tab) : tabs.length - 1;

    return PopScope(
      canPop: tab == 'home',
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) s.go('home');
      },
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          extendBody: true,
          backgroundColor: s.c.bg,
          body: AppBackground(
            child: SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: AnimatedSwitcher(
                    duration: Motion.of(context, Motion.base),
                    switchInCurve: Motion.curve,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0, 0.012), end: Offset.zero).animate(anim),
                        child: child,
                      ),
                    ),
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topCenter,
                      children: [...previous, if (current != null) current],
                    ),
                    child: KeyedSubtree(key: ValueKey('$tab-${s.lang}'), child: body),
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: FloatingNavBar(
            items: [for (final k in tabs) (k, meta[k]!.$1, meta[k]!.$2)],
            index: sel,
            onTap: (i) {
              FocusManager.instance.primaryFocus?.unfocus();
              s.go(tabs[i]);
            },
          ),
        ),
      ),
    );
  }
}
