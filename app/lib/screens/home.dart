import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../lessons.dart';
import '../progress.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'lesson.dart';

const Map<String, IconData> kQuestIcons = {
  'xp': Icons.bolt_rounded,
  'lessons': Icons.menu_book_rounded,
  'combo': Icons.local_fire_department_rounded,
};

/// O‘qish — bosh sahifa (minimal) / Учёба — главная (минимально).
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final st = s.st;
    Lesson? nl = s.nextLesson(s.course);
    if (nl == null) {
      for (final co in kCourses) {
        nl = s.nextLesson(co);
        if (nl != null) break;
      }
    }
    final next = nl;
    final name = s.displayName.split(' ').first;

    final h = DateTime.now().hour;
    final greet = h < 5
        ? const Tr('Xayrli tun', 'Доброй ночи')
        : h < 12
            ? const Tr('Xayrli tong', 'Доброе утро')
            : h < 18
                ? const Tr('Xayrli kun', 'Добрый день')
                : const Tr('Xayrli kech', 'Добрый вечер');
    return TabPage(
      title: '${s.tr(greet)}${name.isNotEmpty ? ', $name' : ''} 👋',
      subtitle: s.leagueName,
      children: [
        const _TodayCard(),
        _Continue(next: next),
        const _QuestStrip(),
        SectionHeader(s.t('courses')),
        const _CourseGrid(),
        const _TipCard(),
      ],
    );
  }
}

// ------------------------------------------------------------ bugun: maqsad va seriya / сегодня: цель и серия
class _TodayCard extends StatelessWidget {
  const _TodayCard();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c, st = s.st;
    final goal = (st.todayXp / kGoal).clamp(0.0, 1.0);
    // haftalik chiziq / недельная полоска
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final last = DateTime.tryParse(st.lastDay);
    bool lit(DateTime d) {
      if (last == null || st.streak <= 0) return false;
      final ld = DateTime(last.year, last.month, last.day);
      final first = ld.subtract(Duration(days: st.streak - 1));
      return !d.isBefore(first) && !d.isAfter(ld);
    }
    const days = [Tr('Du', 'Пн'), Tr('Se', 'Вт'), Tr('Ch', 'Ср'), Tr('Pa', 'Чт'), Tr('Ju', 'Пт'), Tr('Sh', 'Сб'), Tr('Ya', 'Вс')];
    return Container(
      key: const ValueKey('today-card'),
      padding: const EdgeInsets.all(S.x5),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: R.all(R.xl),
        border: Border.all(color: c.hairline),
      ),
      child: Column(children: [
        Row(children: [
          // kunlik maqsad halqasi / кольцо дневной цели
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: goal),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => SizedBox(
              width: 92,
              height: 92,
              child: CustomPaint(
                painter: _RingPainter(v, c.surfaceAlt, const [Color(0xFF2EA6FF), Color(0xFF0A6CFF), Color(0xFF7A5CFF)]),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.bolt_rounded, color: Color(0xFFFFB800), size: 22),
                    Text('${st.todayXp.clamp(0, 999)}', style: AppType.title3.copyWith(color: c.text, height: 1.0)),
                    Text('/$kGoal XP', style: AppType.caption.copyWith(color: c.text2)),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(width: S.x4),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.tr(goal >= 1 ? const Tr('Maqsad bajarildi!', 'Цель выполнена!') : const Tr('Bugungi maqsad', 'Цель на сегодня')),
                  style: AppType.headline.copyWith(color: c.text)),
              const SizedBox(height: 4),
              Text(
                  goal >= 1
                      ? s.tr(const Tr('Ertaga ham kel — seriya o‘sadi', 'Приходи завтра — серия вырастет'))
                      : s.tr(Tr('Yana ${kGoal - st.todayXp} XP — va maqsad bajariladi', 'Ещё ${kGoal - st.todayXp} XP — и цель выполнена')),
                  style: AppType.footnote.copyWith(color: c.text2)),
            ]),
          ),
          const SizedBox(width: S.x3),
          Column(children: [
            _Pulse(
              active: st.streak > 0,
              child: st.streak > 0
                  ? ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (r) => const LinearGradient(
                          begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFFFF3B30), Color(0xFFFF9500), Color(0xFFFFD60A)]).createShader(r),
                      child: const Icon(Icons.local_fire_department_rounded, size: 46, color: kWhite),
                    )
                  : Icon(Icons.local_fire_department_rounded, size: 46, color: c.text3),
            ),
            Text('${st.streak}', style: AppType.title3.copyWith(color: st.streak > 0 ? const Color(0xFFFF8A00) : c.text3, height: 1.0)),
          ]),
        ]),
        const SizedBox(height: S.x4),
        Row(children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Builder(builder: (_) {
                final d = monday.add(Duration(days: i));
                final on = lit(d), isToday = d == today;
                return Column(children: [
                  Text(s.tr(days[i]), style: AppType.caption.copyWith(color: isToday ? c.accentText : c.text3, fontWeight: isToday ? w8 : null)),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: on ? const LinearGradient(colors: [Color(0xFFFFB347), Color(0xFFFF6A00)]) : null,
                      color: on ? null : c.surfaceAlt,
                      border: isToday ? Border.all(color: c.accent, width: 2) : null,
                      boxShadow: on ? const [BoxShadow(color: Color(0x55FF8A00), blurRadius: 10)] : null,
                    ),
                    child: on
                        ? const Icon(Icons.local_fire_department_rounded, color: kWhite, size: 18)
                        : Text('${d.day}', style: AppType.caption.copyWith(color: c.text3)),
                  ),
                ]);
              }),
            ),
        ]),
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double v;
  final Color track;
  final List<Color> colors;
  _RingPainter(this.v, this.track, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    const w = 9.0;
    final r = Rect.fromLTWH(w / 2, w / 2, size.width - w, size.height - w);
    canvas.drawArc(r, 0, math.pi * 2, false, Paint()..style = PaintingStyle.stroke..strokeWidth = w..color = track);
    if (v <= 0) return;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(colors: colors, startAngle: -math.pi / 2, endAngle: math.pi * 1.5, transform: const GradientRotation(-math.pi / 2)).createShader(r);
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * v, false, p);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.v != v || o.track != track;
}

/// Yengil "nafas olish" / лёгкое «дыхание».
class _Pulse extends StatefulWidget {
  final Widget child;
  final bool active;
  const _Pulse({required this.child, this.active = true});
  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  @override
  void initState() {
    super.initState();
    _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active || Motion.reduced(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, ch) {
        final k = Curves.easeInOut.transform(_c.value);
        return Transform.rotate(angle: (k - .5) * .12, child: Transform.scale(scale: 1 + .1 * k, child: ch));
      },
    );
  }
}

// ------------------------------------------------------------ kunlik vazifalar chizig‘i / полоска заданий
class _QuestStrip extends StatelessWidget {
  const _QuestStrip();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c, st = s.st;
    const colors = [Color(0xFFFFB800), Color(0xFF2EA6FF), Color(0xFFFF6A00)];
    const labels = [Tr('XP', 'XP'), Tr('dars', 'урока'), Tr('ketma-ket', 'подряд')];
    return Pressable(
      key: const ValueKey('quests-row'),
      onTap: () => showAppSheet<void>(context, builder: (_) => const _Quests()),
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.fromLTRB(S.x4, S.x4, S.x4, S.x4),
        decoration: BoxDecoration(color: c.surface, borderRadius: R.all(R.xl), border: Border.all(color: c.hairline)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(s.t('quests'), style: AppType.headline.copyWith(color: c.text)),
            const Spacer(),
            Text('${st.quests.claimed.length}/${kQuests.length}', style: AppType.footnote.copyWith(color: c.text2, fontWeight: w7)),
            Icon(Icons.chevron_right_rounded, color: c.text3),
          ]),
          const SizedBox(height: S.x3),
          Row(children: [
            for (var i = 0; i < kQuests.length; i++) ...[
              if (i > 0) const SizedBox(width: S.x3),
              Expanded(
                child: Builder(builder: (_) {
                  final q = kQuests[i];
                  final prog = questProgress(st, q).clamp(0, q.target);
                  final done = prog >= q.target;
                  final col = colors[i % colors.length];
                  return Container(
                    padding: const EdgeInsets.all(S.x3),
                    decoration: BoxDecoration(
                      color: done ? col.withAlpha(0x26) : c.surfaceAlt,
                      borderRadius: R.all(R.lg),
                      border: Border.all(color: done ? col.withAlpha(0x99) : Colors.transparent, width: 1.5),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(done ? Icons.check_circle_rounded : (kQuestIcons[q.id] ?? Icons.star_rounded), color: col, size: 22),
                        const Spacer(),
                        Text('+${q.reward}', style: AppType.caption.copyWith(color: c.text2, fontWeight: w7)),
                      ]),
                      const SizedBox(height: S.x2),
                      Text('$prog/${q.target}', style: AppType.headline.copyWith(color: c.text)),
                      Text(s.tr(labels[i % labels.length]), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.caption.copyWith(color: c.text2)),
                      const SizedBox(height: S.x2),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: prog / q.target),
                        duration: Duration(milliseconds: 700 + i * 200),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => AppProgress(v, height: 5, color: col, track: c.hairline),
                      ),
                    ]),
                  );
                }),
              ),
            ],
          ]),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------ kun maslahati / совет дня
const _kTips = [
  Tr('HTML’da har bir ochilgan teg yopilishi kerak: <p> … </p>.', 'В HTML каждый открытый тег нужно закрыть: <p> … </p>.'),
  Tr('CSS’da rang uchun #2EA6FF kabi kodlardan foydalanish mumkin.', 'В CSS цвет можно задать кодом, например #2EA6FF.'),
  Tr('Python’da probellar muhim: if ichidagi qatorlar 4 ta probel bilan yoziladi.', 'В Python важны отступы: строки внутри if пишутся с 4 пробелами.'),
  Tr('JavaScript’da console.log() — kod nima qilayotganini ko‘rishning eng oson yo‘li.', 'В JavaScript console.log() — самый простой способ увидеть, что делает код.'),
  Tr('Xato — bu yomon emas. Har bir xato yangi narsani o‘rgatadi.', 'Ошибка — это не плохо. Каждая ошибка чему-то учит.'),
  Tr('Har kuni 1 ta dars — bir oyda 30 ta dars. Seriyani uzmang!', 'Один урок в день — 30 уроков за месяц. Не прерывайте серию!'),
  Tr('O‘zgaruvchiga tushunarli nom bering: x emas, yosh yoki narx.', 'Давайте переменным понятные имена: не x, а age или price.'),
];

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final now = DateTime.now();
    final idx = DateTime(now.year, now.month, now.day).difference(DateTime(now.year)).inDays % _kTips.length;
    return Container(
      padding: const EdgeInsets.all(S.x4),
      decoration: BoxDecoration(
        borderRadius: R.all(R.xl),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c.accentSoft, c.surface]),
        border: Border.all(color: c.hairline),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Floaty(
          amount: 3,
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFFE27A), Color(0xFFFFB800)])),
            child: const Icon(Icons.lightbulb_rounded, color: kWhite, size: 26),
          ),
        ),
        const SizedBox(width: S.x3),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.tr(const Tr('Kun maslahati', 'Совет дня')), style: AppType.overline.copyWith(color: c.accentText, letterSpacing: 1.2)),
            const SizedBox(height: 4),
            Text(s.tr(_kTips[idx]), style: AppType.callout.copyWith(color: c.text)),
          ]),
        ),
      ]),
    );
  }
}

// ------------------------------------------------------------ davom etish / продолжить
class _Continue extends StatelessWidget {
  final Lesson? next;
  const _Continue({required this.next});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c, st = s.st;
    final nx = next;
    final co = nx != null ? kAllLessons[nx.id]!.$2 : s.course;
    final goal = st.todayXp < kGoal ? st.todayXp : kGoal;
    final white70 = kWhite.withAlpha(0xD9);
    final lessons = s.lessonsOf(co);
    final idx = nx != null ? lessons.indexWhere((l) => l.id == nx.id) : -1;
    return Container(
      key: const ValueKey('continue-card'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: R.all(R.xl),
        gradient: c.heroGradient,
        boxShadow: const [BoxShadow(color: Color(0x400A6CFF), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Stack(children: [
        // suzuvchi kod belgilari / плавающие символы кода
        for (final (i, sym, x, y, sz) in const [
          (0, '</>', .70, .05, 34.0),
          (1, '{ }', .86, .42, 26.0),
          (2, '( )', .58, .62, 22.0),
          (3, ';', .93, .08, 28.0),
          (4, '#', .48, .18, 20.0),
        ])
          Positioned.fill(
            child: Align(
              alignment: Alignment(x * 2 - 1, y * 2 - 1),
              child: Floaty(
                amount: 8,
                phase: i * .19,
                period: Duration(milliseconds: 3000 + i * 500),
                child: Text(sym, style: AppType.monoStrong.copyWith(fontSize: sz, color: kWhite.withAlpha(0x2E))),
              ),
            ),
          ),
        Padding(
      padding: const EdgeInsets.all(S.x5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('${co.tag}  ${s.tr(co.name)}'.toUpperCase(),
              style: AppType.overline.copyWith(color: white70, letterSpacing: 1.2)),
          const Spacer(),
          Text('$goal/$kGoal XP', style: AppType.footnote.copyWith(color: kWhite, fontWeight: w7)),
        ]),
        const SizedBox(height: S.x3),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
            child: Text(nx != null ? s.tr(nx.title) : s.t('all_done'),
                maxLines: 2, overflow: TextOverflow.ellipsis, style: AppType.title1.copyWith(color: kWhite)),
          ),
          const SizedBox(width: S.x3),
          Floaty(child: CourseTag(co, size: 52, fontSize: 16, onColorBg: true)),
        ]),
        const SizedBox(height: S.x3),
        AppProgress(st.todayXp / kGoal, height: 6, color: kWhite, track: const Color(0x38FFFFFF)),
        const SizedBox(height: S.x5),
        SizedBox(
          width: double.infinity,
          child: Pressable(
            key: const ValueKey('continue-btn'),
            onTap: () => nx != null ? openLesson(context, nx.id) : s.go('courses'),
            child: _Shine(
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: kWhite, borderRadius: R.all(R.pill)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(nx != null ? s.t('continue') : s.t('courses'),
                      style: AppType.headline.copyWith(color: const Color(0xFF0058E6))),
                  const SizedBox(width: 6),
                  const Icon(Icons.play_arrow_rounded, color: Color(0xFF0058E6)),
                ]),
              ),
            ),
          ),
        ),
        if (idx >= 0) ...[
          const SizedBox(height: S.x3),
          Center(
            child: Text(s.tr(Tr('${idx + 1}-dars · ${lessons.length} tadan', 'Урок ${idx + 1} из ${lessons.length}')),
                style: AppType.caption.copyWith(color: white70)),
          ),
        ],
      ]),
        ),
      ]),
    );
  }
}

/// Tugma ustidan o‘tuvchi yaltirash / блик, пробегающий по кнопке.
class _Shine extends StatefulWidget {
  final Widget child;
  const _Shine({required this.child});
  @override
  State<_Shine> createState() => _ShineState();
}

class _ShineState extends State<_Shine> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
  @override
  void initState() {
    super.initState();
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, ch) {
        final t = (_c.value * 1.6 - .3);
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (r) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [Color(0x00FFFFFF), Color(0x66BFE3FF), Color(0x00FFFFFF)],
            stops: [(t - .12).clamp(0.0, 1.0), t.clamp(0.0, 1.0), (t + .12).clamp(0.0, 1.0)],
          ).createShader(r),
          child: ch,
        );
      },
    );
  }
}

// ------------------------------------------------------------ rangli kurs kartalari / цветные карточки курсов
const Map<String, List<Color>> kTileColors = {
  'html': [Color(0xFF4DB0FF), Color(0xFF0A6CFF)],
  'css': [Color(0xFF4656FF), Color(0xFF0A1226)],
  'js': [Color(0xFF2CC4F7), Color(0xFF0A84D6)],
  'py': [Color(0xFF9A8CFF), Color(0xFF5B6CFF)],
  'ai': [Color(0xFFB45CFF), Color(0xFF2D3FE0)],
};

class _CourseGrid extends StatelessWidget {
  const _CourseGrid();

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < kCourses.length; i += 2) {
      final pair = kCourses.skip(i).take(2).toList();
      if (rows.isNotEmpty) rows.add(const SizedBox(height: S.x3));
      rows.add(pair.length == 2
          ? Row(children: [
              Expanded(child: Appear(index: i, child: _CourseTile(pair[0], index: i))),
              const SizedBox(width: S.x3),
              Expanded(child: Appear(index: i + 1, child: _CourseTile(pair[1], index: i + 1))),
            ])
          : Appear(index: i, child: _CourseTile(pair[0], index: i, wide: true)));
    }
    return Column(children: rows);
  }
}

class _CourseTile extends StatelessWidget {
  final Course co;
  final int index;
  final bool wide;
  const _CourseTile(this.co, {required this.index, this.wide = false});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final d = s.progressOf(co), n = s.lessonsOf(co).length;
    final colors = kTileColors[co.id] ?? [hexColor(co.color), hexColor(co.color)];
    final cert = s.certs[co.id];
    final examReady = !s.isStaff && cert == null && s.courseComplete(co) && s.examWait(co) == Duration.zero;
    final white80 = kWhite.withAlpha(0xCC);

    Widget? badge;
    if (cert != null) {
      badge = const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD54A), size: 22, shadows: kTextShadow);
    } else if (examReady) {
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xFFFFC21A), borderRadius: R.all(R.pill)),
        child: Text(s.t('exam_short'), style: AppType.caption.copyWith(color: const Color(0xFF5A3A00))),
      );
    }

    return Pressable(
      key: ValueKey('course-row-${co.id}'),
      scale: 0.96,
      onTap: () {
        s.pickCourse(co.id);
        s.go('courses');
      },
      child: Container(
        height: wide ? 150 : 172,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: R.all(R.xl),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          boxShadow: [BoxShadow(color: colors.last.withAlpha(0x40), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Stack(children: [
          // katta belgi / большой значок
          Positioned(
            right: -10,
            bottom: wide ? -18 : -8,
            child: Floaty(
              amount: 5,
              phase: index * 0.21,
              period: Duration(milliseconds: 3600 + index * 300),
              child: Text(co.tag,
                  style: AppType.monoStrong.copyWith(
                      fontSize: wide ? 84 : 64, color: kWhite.withAlpha(0x2E), letterSpacing: -2, height: 1)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(S.x4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CourseTag(co, size: 34, fontSize: 11, onColorBg: true),
                const Spacer(),
                if (badge != null) badge,
              ]),
              const Spacer(),
              Text(s.tr(co.name),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.headline.copyWith(color: kWhite, fontSize: 17)),
              const SizedBox(height: 1),
              Text(s.tr(co.sub), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.caption.copyWith(color: white80)),
              const SizedBox(height: S.x3),
              Row(children: [
                Expanded(child: AppProgress(n == 0 ? 0 : d / n, height: 5, color: kWhite, track: const Color(0x33FFFFFF))),
                const SizedBox(width: S.x2),
                Text('$d/$n', style: AppType.caption.copyWith(color: kWhite)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------ kunlik vazifalar / задания дня
class _Quests extends StatelessWidget {
  const _Quests();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c, st = s.st;
    final claimedN = st.quests.claimed.length;
    final rows = <Widget>[];
    for (var i = 0; i < kQuests.length; i++) {
      final q = kQuests[i];
      final prog = questProgress(st, q);
      final done = prog >= q.target;
      final claimed = st.quests.claimed.contains(q.id);
      final Widget action;
      if (claimed) {
        action = AppPill(s.t('claimed'), icon: Icons.check_rounded, tone: Tone.yellow, small: true);
      } else if (done) {
        action = AppButton('+${q.reward}',
            key: ValueKey('claim-${q.id}'),
            onPressed: () => s.claim(q.id),
            kind: BtnKind.success,
            height: 38,
            icon: Icons.bolt_rounded);
      } else {
        action = AppPill('+${q.reward} XP', icon: Icons.bolt_rounded, iconColor: c.yellow, small: true);
      }
      if (i > 0) rows.add(Divider(height: S.x6, thickness: 1, color: c.hairline));
      rows.add(Row(children: [
        IconTile(kQuestIcons[q.id] ?? Icons.star_rounded,
            size: 42, bg: done ? c.yellowSoft : c.accentSoft, color: done ? c.yellowText : c.accentText),
        const SizedBox(width: S.x3),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.tr(q.title), style: AppType.subhead.copyWith(color: c.text, fontWeight: w7)),
            const SizedBox(height: S.x2),
            Row(children: [
              Expanded(
                child: AppProgress(prog / q.target,
                    height: 6, gradient: done ? c.yellowGradient : c.accentGradient),
              ),
              const SizedBox(width: S.x2),
              Text('$prog/${q.target}', style: AppType.caption.copyWith(color: c.text2)),
            ]),
          ]),
        ),
        const SizedBox(width: S.x3),
        action,
      ]));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: Text(s.t('quests'), style: AppType.title3.copyWith(color: c.text))),
        AppPill('$claimedN/${kQuests.length}', small: true),
      ]),
      const SizedBox(height: S.x4),
      ...rows,
    ]);
  }
}

