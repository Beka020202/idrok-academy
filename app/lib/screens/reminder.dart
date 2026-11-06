// Eslatma vaqtini tanlash: osmon tanlangan soatga qarab o‘zgaradi.
// Выбор времени напоминания: небо меняется вместе с выбранным часом.
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../reminders.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

String fmtTime(int minutes) => '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

// Osmon ranglari (soat, yuqori, past) / цвета неба (час, верх, низ)
const List<(double, Color, Color)> _sky = [
  (0, Color(0xFF050B24), Color(0xFF14214F)),
  (5, Color(0xFF0B1A4A), Color(0xFF2E4A9A)),
  (7, Color(0xFF4A7BD8), Color(0xFFF7B7A3)),
  (10, Color(0xFF2E9BFF), Color(0xFFBDE6FF)),
  (14, Color(0xFF1E8CFF), Color(0xFF9FD8FF)),
  (18, Color(0xFF2B4FB5), Color(0xFFF59E7B)),
  (20, Color(0xFF0E1B55), Color(0xFF3B3F8F)),
  (24, Color(0xFF050B24), Color(0xFF14214F)),
];

(Color, Color) skyAt(double hour) {
  for (var k = 0; k < _sky.length - 1; k++) {
    final (h0, a0, b0) = _sky[k];
    final (h1, a1, b1) = _sky[k + 1];
    if (hour >= h0 && hour <= h1) {
      final t = Curves.easeInOut.transform((hour - h0) / (h1 - h0));
      return (Color.lerp(a0, a1, t)!, Color.lerp(b0, b1, t)!);
    }
  }
  return (_sky.first.$2, _sky.first.$3);
}

/// Osmon foni: quyosh yoki oy yoy bo‘ylab harakatlanadi / небо: солнце или луна движутся по дуге.
class SkyBackground extends StatelessWidget {
  final double hour;
  final Widget child;
  const SkyBackground({super.key, required this.hour, required this.child});

  @override
  Widget build(BuildContext context) {
    final (top, bottom) = skyAt(hour);
    final day = hour >= 6 && hour <= 18.5;
    // Kunduzi 6→18, kechasi 18→30 (ertasi 6) / днём 6→18, ночью 18→30
    final p = day ? (hour - 6) / 12.5 : ((hour < 6 ? hour + 24 : hour) - 18.5) / 11.5;
    final x = -0.85 + 1.7 * p.clamp(0.0, 1.0);
    final y = -0.78 - 0.17 * math.sin(math.pi * p.clamp(0.0, 1.0));
    final dur = Motion.of(context, const Duration(milliseconds: 500));
    return AnimatedContainer(
      duration: dur,
      curve: Motion.curve,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]),
      ),
      child: Stack(children: [
        // Yulduzlar kechasi / звёзды ночью
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              duration: dur,
              opacity: day ? 0 : 1,
              child: const CustomPaint(painter: _StarsPainter()),
            ),
          ),
        ),
        AnimatedAlign(
          duration: dur,
          curve: Motion.curve,
          alignment: Alignment(x, y),
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: dur,
              width: day ? 76 : 58,
              height: day ? 76 : 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: day ? const [Color(0xFFFFF6C9), Color(0xFFFFD45E)] : const [Color(0xFFF4F7FF), Color(0xFFC9D6F2)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (day ? const Color(0xFFFFD45E) : const Color(0xFFBFD0FF)).withAlpha(0x8C),
                    blurRadius: day ? 60 : 36,
                    spreadRadius: day ? 12 : 4,
                  ),
                ],
              ),
            ),
          ),
        ),
        child,
      ]),
    );
  }
}

class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(7);
    final p = Paint()..color = const Color(0xCCFFFFFF);
    for (var k = 0; k < 60; k++) {
      final o = Offset(r.nextDouble() * size.width, r.nextDouble() * size.height * 0.55);
      canvas.drawCircle(o, r.nextDouble() * 1.4 + 0.3, p..color = Color.fromARGB(80 + r.nextInt(150), 255, 255, 255));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Soat va daqiqa g‘ildiraklari (iOS uslubida) / колёса часов и минут (в стиле iOS).
class TimeWheel extends StatefulWidget {
  final int minutes;
  final ValueChanged<int> onChanged;
  const TimeWheel({super.key, required this.minutes, required this.onChanged});

  @override
  State<TimeWheel> createState() => _TimeWheelState();
}

class _TimeWheelState extends State<TimeWheel> {
  late int h = widget.minutes ~/ 60, m = (widget.minutes % 60) ~/ 5;
  late final _hc = FixedExtentScrollController(initialItem: h);
  late final _mc = FixedExtentScrollController(initialItem: m);

  @override
  void didUpdateWidget(TimeWheel old) {
    super.didUpdateWidget(old);
    final nh = widget.minutes ~/ 60, nm = (widget.minutes % 60) ~/ 5;
    if (nh != h && _hc.hasClients) {
      h = nh;
      _hc.animateToItem(nh, duration: const Duration(milliseconds: 420), curve: Motion.curve);
    }
    if (nm != m && _mc.hasClients) {
      m = nm;
      _mc.animateToItem(nm, duration: const Duration(milliseconds: 420), curve: Motion.curve);
    }
  }

  @override
  void dispose() {
    _hc.dispose();
    _mc.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(h * 60 + m * 5);

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontFamily: kBody, fontSize: 34, fontWeight: w7, color: kWhite, letterSpacing: -0.5);
    Widget wheel(FixedExtentScrollController ctl, int count, String Function(int) label, ValueChanged<int> on, Key key) =>
        SizedBox(
          width: 92,
          child: CupertinoPicker(
            key: key,
            scrollController: ctl,
            itemExtent: 48,
            diameterRatio: 1.25,
            squeeze: 1.1,
            useMagnifier: true,
            magnification: 1.12,
            looping: true,
            selectionOverlay: const SizedBox.shrink(),
            onSelectedItemChanged: (v) {
              HapticFeedback.selectionClick();
              on(v);
              _emit();
            },
            children: [for (var k = 0; k < count; k++) Center(child: Text(label(k), style: style))],
          ),
        );
    return SizedBox(
      height: 200,
      child: Stack(alignment: Alignment.center, children: [
        Container(
          height: 54,
          margin: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: const Color(0x26FFFFFF),
            borderRadius: R.all(R.md),
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          wheel(_hc, 24, (k) => k.toString().padLeft(2, '0'), (v) => h = v, const ValueKey('wheel-hour')),
          const Text(':', style: style),
          wheel(_mc, 12, (k) => (k * 5).toString().padLeft(2, '0'), (v) => m = v, const ValueKey('wheel-minute')),
        ]),
      ]),
    );
  }
}

/// Isinishdan keyin bir marta ko‘rsatiladi / показывается один раз после разминки.
class ReminderScreen extends StatefulWidget {
  final bool asSheet;
  const ReminderScreen({super.key, this.asSheet = false});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  late int minutes;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final s = AppScope.read(context);
    minutes = s.reminderMinutes >= 0 ? s.reminderMinutes : 19 * 60;
  }

  Future<void> _save() async {
    final s = AppScope.read(context);
    setState(() => saving = true);
    HapticFeedback.mediumImpact();
    if (!s.testMode) {
      await Reminders.askPermission();
      await Reminders.schedule(minutes, title: s.t('reminder_title'), body: s.pick('reminder_bodies'));
    }
    await s.setReminder(minutes);
    if (!mounted) return;
    setState(() => saving = false);
    s.toast('${s.t('reminder_set')} ${fmtTime(minutes)}', icon: Icons.notifications_active_rounded);
    if (widget.asSheet) Navigator.of(context).pop();
  }

  Future<void> _skip() async {
    final s = AppScope.read(context);
    if (!s.testMode) await Reminders.cancel();
    await s.setReminder(-1);
    if (mounted && widget.asSheet) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final hour = minutes / 60;
    final presets = [(7 * 60 + 30, 'preset_morning'), (15 * 60, 'preset_day'), (19 * 60, 'preset_evening')];
    final white70 = kWhite.withAlpha(0xD9);

    final body = SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(S.page, S.x4, S.page, S.x4),
            child: Column(children: [
              if (widget.asSheet)
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppIconButton(Icons.close_rounded,
                      key: const ValueKey('reminder-close'),
                      tooltip: s.t('back'),
                      onPressed: () => Navigator.of(context).maybePop()),
                ),
              const Spacer(flex: 3),
              Appear(
                child: Column(children: [
                  Text(s.t('reminder_q'),
                      textAlign: TextAlign.center, style: AppType.largeTitle.copyWith(color: kWhite, shadows: kTextShadow)),
                  const SizedBox(height: S.x2),
                  Text(s.t('reminder_sub'), textAlign: TextAlign.center, style: AppType.callout.copyWith(color: white70)),
                ]),
              ),
              const SizedBox(height: S.x5),
              Appear(
                index: 1,
                child: Glass(
                  radius: R.xxl,
                  color: const Color(0x1FFFFFFF),
                  padding: const EdgeInsets.symmetric(vertical: S.x3),
                  child: Column(children: [
                    TimeWheel(minutes: minutes, onChanged: (v) => setState(() => minutes = v)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(S.x4, 0, S.x4, S.x2),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.notifications_active_rounded, size: 18, color: kWhite),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(s.t('reminder_line').replaceAll('{t}', fmtTime(minutes)),
                              key: const ValueKey('reminder-line'),
                              textAlign: TextAlign.center,
                              style: AppType.subhead.copyWith(color: kWhite, fontWeight: w7)),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: S.x4),
              Appear(
                index: 2,
                child: Wrap(alignment: WrapAlignment.center, spacing: S.x2, runSpacing: S.x2, children: [
                  for (final (v, key) in presets)
                    Pressable(
                      key: ValueKey('preset-$v'),
                      onTap: () => setState(() => minutes = v),
                      scale: 0.95,
                      child: AnimatedContainer(
                        duration: Motion.of(context, Motion.fast),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          borderRadius: R.all(R.pill),
                          color: minutes == v ? kWhite : const Color(0x26FFFFFF),
                          border: Border.all(color: const Color(0x40FFFFFF)),
                        ),
                        child: Text('${s.t(key)} · ${fmtTime(v)}',
                            style: AppType.footnote.copyWith(
                                color: minutes == v ? const Color(0xFF0A1226) : kWhite, fontWeight: w8)),
                      ),
                    ),
                ]),
              ),
              const Spacer(flex: 2),
              AppButton(s.t('reminder_on'),
                  key: const ValueKey('reminder-save'),
                  kind: BtnKind.dark,
                  onPressed: saving ? null : _save,
                  loading: saving,
                  expand: true,
                  height: 56,
                  icon: Icons.notifications_rounded),
              const SizedBox(height: S.x2),
              TextButton(
                key: const ValueKey('reminder-skip'),
                onPressed: saving ? null : _skip,
                child: Text(s.t(widget.asSheet ? 'reminder_off' : 'reminder_later'),
                    style: AppType.callout.copyWith(color: white70, fontWeight: w7)),
              ),
            ]),
          ),
        ),
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF050B24),
        body: SkyBackground(hour: hour, child: body),
      ),
    );
  }
}

/// Profildagi eslatma qatori / строка напоминания в профиле.
class ReminderTile extends StatelessWidget {
  const ReminderTile({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final on = s.reminderMinutes >= 0;
    final (top, bottom) = skyAt(on ? s.reminderMinutes / 60 : 21);
    return AppCard(
      key: const ValueKey('reminder-tile'),
      onTap: () => Navigator.of(context).push(AppRoute<void>(builder: (_) => const ReminderScreen(asSheet: true))),
      padding: const EdgeInsets.all(S.x4),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]),
          ),
          child: Icon(on ? Icons.notifications_active_rounded : Icons.notifications_off_rounded, color: kWhite, size: 22),
        ),
        const SizedBox(width: S.x3),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.t('reminder_title_short'), style: AppType.headline.copyWith(color: c.text)),
            Text(on ? s.t('reminder_line').replaceAll('{t}', fmtTime(s.reminderMinutes)) : s.t('reminder_none'),
                style: AppType.footnote.copyWith(color: c.text2)),
          ]),
        ),
        Icon(Icons.chevron_right_rounded, color: c.text3),
      ]),
    );
  }
}
