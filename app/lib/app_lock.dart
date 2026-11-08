// Fokus rejimi: bugungi dars belgilangan vaqtgacha o‘tilmasa, tanlangan ilovalar (o‘yinlar,
// ijtimoiy tarmoqlar) bitta dars tugaguncha qulflanadi. Faqat Android (Maxsus imkoniyatlar xizmati).
// Режим фокуса: если урок не пройден к выбранному времени, выбранные приложения (игры, соцсети)
// блокируются до окончания одного урока. Только Android (служба специальных возможностей).
//
// Sozlamalar SharedPreferences’da — Android xizmati ularni "FlutterSharedPreferences" dan o‘qiydi.
// Настройки в SharedPreferences — служба Android читает их из "FlutterSharedPreferences".
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

class LockApp {
  final String pkg, label;
  final Uint8List? icon;
  const LockApp(this.pkg, this.label, this.icon);
}

class AppLock {
  static const _ch = MethodChannel('idrok/applock');
  static const passMinutes = 10, passPerDay = 2;

  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static String _day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------- sozlamalar / настройки
  static Future<SharedPreferences> get _sp => SharedPreferences.getInstance();

  static Future<bool> isOn() async => (await _sp).getBool('lock_on') ?? false;
  static Future<Set<String>> apps() async =>
      {for (final x in ((await _sp).getString('lock_apps') ?? '').split(',')) if (x.isNotEmpty) x};
  static Future<int> minutes() async {
    final sp = await _sp;
    return (sp.getInt('lock_hour') ?? 18) * 60 + (sp.getInt('lock_min') ?? 0);
  }

  static Future<void> save({required bool on, required Set<String> apps, required int minutes}) async {
    final sp = await _sp;
    await sp.setBool('lock_on', on);
    await sp.setString('lock_apps', apps.join(','));
    await sp.setInt('lock_hour', minutes ~/ 60);
    await sp.setInt('lock_min', minutes % 60);
  }

  /// Dars tugadi — bugun qulf yo‘q / урок пройден — сегодня блокировки нет.
  static Future<void> lessonDone() async {
    if (!supported) return;
    try {
      await (await _sp).setString('lock_done', _day(DateTime.now()));
    } catch (_) {}
  }

  /// Hozir qulflanganmi (Android xizmatidagi bilan bir xil qoida).
  /// Заблокировано ли сейчас (то же правило, что в службе Android).
  static Future<bool> lockedNow() async {
    if (!supported) return false;
    final sp = await _sp;
    if (!(sp.getBool('lock_on') ?? false)) return false;
    if ((sp.getString('lock_apps') ?? '').isEmpty) return false;
    final now = DateTime.now();
    if (sp.getString('lock_done') == _day(now)) return false;
    if ((sp.getInt('lock_pass_until') ?? 0) > now.millisecondsSinceEpoch) return false;
    final m = (sp.getInt('lock_hour') ?? 18) * 60 + (sp.getInt('lock_min') ?? 0);
    return now.hour * 60 + now.minute >= m;
  }

  static Future<int> passesLeft() async {
    final sp = await _sp;
    if (sp.getString('lock_pass_day') != _day(DateTime.now())) return passPerDay;
    return passPerDay - (sp.getInt('lock_pass_count') ?? 0);
  }

  /// Favqulodda ochish (10 daqiqa, kuniga 2 marta) / экстренная разблокировка (10 минут, 2 раза в день).
  static Future<bool> usePass() async {
    final left = await passesLeft();
    if (left <= 0) return false;
    final sp = await _sp;
    final today = _day(DateTime.now());
    await sp.setInt('lock_pass_count', passPerDay - left + 1);
    await sp.setString('lock_pass_day', today);
    await sp.setInt('lock_pass_until', DateTime.now().add(const Duration(minutes: passMinutes)).millisecondsSinceEpoch);
    return true;
  }

  // ---------------------------------------------------------------- Android
  static Future<bool> serviceOn() async {
    if (!supported) return false;
    try {
      return await _ch.invokeMethod<bool>('enabled') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openSettings() async {
    try {
      await _ch.invokeMethod<void>('openSettings');
    } catch (_) {}
  }

  static Future<List<LockApp>> installed() async {
    try {
      final r = await _ch.invokeMethod<List<Object?>>('apps') ?? const [];
      final out = <LockApp>[
        for (final x in r)
          if (x is Map) LockApp('${x['pkg']}', '${x['label']}', x['icon'] is Uint8List ? x['icon'] as Uint8List : null)
      ]..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
      return out;
    } catch (_) {
      return const [];
    }
  }

  // ---------------------------------------------------------------- qulf oynasi / экран блокировки
  static bool _showing = false;

  /// Ilova ochilganda: qulf bo‘lsa — qulf oynasi / при открытии: если блокировка — экран блокировки.
  static Future<void> check(BuildContext context) async {
    final s = AppScope.read(context);
    if (_showing || s.isStaff || !await lockedNow() || !context.mounted) return;
    _showing = true;
    await Navigator.of(context).push(AppRoute<void>(builder: (_) => const LockScreen()));
    _showing = false;
  }
}

// ======================================================== qulf oynasi / экран блокировки
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  int _left = AppLock.passPerDay;

  @override
  void initState() {
    super.initState();
    AppLock.passesLeft().then((v) {
      if (mounted) setState(() => _left = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(S.x5),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(34),
                    gradient: c.accentGradient,
                    boxShadow: Shadows.glow(c.accent, c, strength: .6),
                  ),
                  child: const Icon(Icons.lock_rounded, color: kWhite, size: 56),
                ),
              ),
              const SizedBox(height: S.x6),
              Text(s.t('lock_title'), textAlign: TextAlign.center, style: AppType.title1.copyWith(color: c.text)),
              const SizedBox(height: S.x3),
              Text(s.t('lock_text'), textAlign: TextAlign.center, style: AppType.body.copyWith(color: c.text2)),
              const SizedBox(height: S.x6),
              AppButton(s.t('lock_go'), key: const ValueKey('lock-go'), icon: Icons.play_arrow_rounded, expand: true, onPressed: () {
                s.go('home');
                Navigator.of(context).pop();
              }),
              const SizedBox(height: S.x3),
              AppButton('${s.t('lock_pass')} · $_left',
                  kind: BtnKind.secondary,
                  icon: Icons.emergency_rounded,
                  expand: true,
                  onPressed: _left <= 0
                      ? null
                      : () async {
                          final ok = await AppLock.usePass();
                          if (!context.mounted) return;
                          if (ok) {
                            s.toast(s.t('lock_pass_ok'), icon: Icons.timer_rounded);
                            Navigator.of(context).pop();
                          }
                        }),
              const Spacer(),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.call_rounded, size: 16, color: c.text3),
                const SizedBox(width: 6),
                Flexible(child: Text(s.t('lock_calls'), style: AppType.footnote.copyWith(color: c.text3))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

// ======================================================== sozlamalar / настройки
class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> with WidgetsBindingObserver {
  bool _on = false, _service = false, _loaded = false;
  Set<String> _apps = {};
  int _min = 18 * 60;
  List<LockApp>? _list;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppLock.serviceOn().then((v) {
        if (mounted) setState(() => _service = v);
      });
    }
  }

  Future<void> _load() async {
    final on = await AppLock.isOn(), apps = await AppLock.apps(), m = await AppLock.minutes();
    final sv = await AppLock.serviceOn();
    if (!mounted) return;
    setState(() {
      _on = on;
      _apps = apps;
      _min = m;
      _service = sv;
      _loaded = true;
    });
    final l = await AppLock.installed();
    if (mounted) setState(() => _list = l);
  }

  Future<void> _save() => AppLock.save(on: _on, apps: _apps, minutes: _min);

  Future<void> _time() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: _min ~/ 60, minute: _min % 60));
    if (t == null) return;
    setState(() => _min = t.hour * 60 + t.minute);
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final hh = '${(_min ~/ 60).toString().padLeft(2, '0')}:${(_min % 60).toString().padLeft(2, '0')}';
    if (!AppLock.supported) {
      return TabPage(title: s.t('lock_name'), children: [
        EmptyState(icon: Icons.phone_android_rounded, title: s.t('lock_android'), message: s.t('lock_android_sub')),
      ]);
    }
    return TabPage(
      title: s.t('lock_name'),
      subtitle: s.t('lock_sub'),
      children: [
        AppCard(
          padding: const EdgeInsets.all(S.x4),
          child: Row(children: [
            IconTile(Icons.shield_moon_rounded, size: 44, vivid: _on),
            const SizedBox(width: S.x3),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.t('lock_name'), style: AppType.headline.copyWith(color: c.text)),
                Text(s.t(_on ? 'lock_is_on' : 'lock_is_off'), style: AppType.footnote.copyWith(color: c.text2)),
              ]),
            ),
            Switch.adaptive(
              key: const ValueKey('lock-switch'),
              value: _on,
              onChanged: !_loaded
                  ? null
                  : (v) {
                      setState(() => _on = v);
                      _save();
                      if (v && !_service) AppLock.openSettings();
                    },
            ),
          ]),
        ),
        if (!_service)
          AppCard(
            padding: const EdgeInsets.all(S.x4),
            kind: CardKind.tinted,
            tint: c.yellowSoft,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(s.t('lock_perm'), style: AppType.headline.copyWith(color: c.yellowText)),
              const SizedBox(height: S.x2),
              Text(s.t('lock_perm_sub'), style: AppType.footnote.copyWith(color: c.text)),
              const SizedBox(height: S.x3),
              AppButton(s.t('lock_perm_btn'), icon: Icons.settings_rounded, height: 44, onPressed: AppLock.openSettings),
            ]),
          ),
        GroupList([
          GroupRow(icon: Icons.schedule_rounded, color: const Color(0xFF5856D6), title: s.t('lock_time'), value: hh, onTap: _time),
        ]),
        Text(s.t('lock_time_sub'), style: AppType.footnote.copyWith(color: c.text2)),
        SectionHeader(s.t('lock_apps'), trailing: AppPill('${_apps.length}', small: true)),
        if (_list == null)
          const SkeletonRows(count: 4)
        else if (_list!.isEmpty)
          EmptyState(icon: Icons.apps_rounded, title: s.t('lock_no_apps'))
        else
          GroupList([
            for (final a in _list!)
              _AppRow(
                app: a,
                on: _apps.contains(a.pkg),
                onChanged: (v) {
                  setState(() => v ? _apps.add(a.pkg) : _apps.remove(a.pkg));
                  _save();
                },
              ),
          ]),
        AppCard(
          padding: const EdgeInsets.all(S.x4),
          child: Text(s.t('lock_rules'), style: AppType.footnote.copyWith(color: c.text2, height: 1.5)),
        ),
      ],
    );
  }
}

class _AppRow extends StatelessWidget {
  final LockApp app;
  final bool on;
  final ValueChanged<bool> onChanged;
  const _AppRow({required this.app, required this.on, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return InkWell(
      onTap: () => onChanged(!on),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: S.x4, vertical: 10),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: app.icon == null
                ? Container(width: 34, height: 34, color: c.surfaceAlt, child: Icon(Icons.apps_rounded, color: c.text3, size: 20))
                : Image.memory(app.icon!, width: 34, height: 34, gaplessPlayback: true),
          ),
          const SizedBox(width: S.x3),
          Expanded(child: Text(app.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.body.copyWith(color: c.text))),
          Icon(on ? Icons.lock_rounded : Icons.lock_open_rounded, color: on ? c.accent : c.text3, size: 22),
        ]),
      ),
    );
  }
}
