import 'package:flutter/material.dart';

import '../lessons.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'lesson.dart';

/// 2. Kurs xaritasi / карта курса.
class CoursesTab extends StatelessWidget {
  const CoursesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final course = s.course;
    return TabPage(
      title: s.t('courses'),
      children: [
        const _CoursePicker(),
        _CourseHero(course: course),
        SectionHeader(s.t('course_path')),
        _Path(course: course),
        _Chest(course: course),
      ],
    );
  }
}

// ------------------------------------------------------------ kurs tanlash / выбор курса
class _CoursePicker extends StatelessWidget {
  const _CoursePicker();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      physics: const BouncingScrollPhysics(),
      child: Row(children: [
        for (final x in kCourses) ...[
          Pressable(
            onTap: () => s.pickCourse(x.id),
            scale: 0.95,
            child: AnimatedContainer(
              duration: Motion.of(context, Motion.base),
              curve: Motion.curve,
              padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
              decoration: BoxDecoration(
                color: x.id == s.courseId ? (c.isDark ? c.elevated : c.surface) : Colors.transparent,
                borderRadius: R.all(R.pill),
                border: Border.all(color: x.id == s.courseId ? c.hairlineStrong : c.hairline),
                boxShadow: x.id == s.courseId ? Shadows.soft(c) : null,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                CourseTag(x, size: 30, fontSize: 10.5),
                const SizedBox(width: S.x2),
                Text(s.tr(x.name),
                    style: AppType.subhead.copyWith(
                        color: x.id == s.courseId ? c.text : c.text2, fontWeight: x.id == s.courseId ? w8 : w6)),
              ]),
            ),
          ),
          const SizedBox(width: S.x2),
        ],
      ]),
    );
  }
}

// ------------------------------------------------------------ kurs kartasi / карточка курса
class _CourseHero extends StatelessWidget {
  final Course course;
  const _CourseHero({required this.course});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final col = courseColor(course, c);
    final on = onColor(col);
    final soft = on == kWhite ? const Color(0xDDFFFFFF) : const Color(0xB3111111);
    final d = s.progressOf(course), n = course.lessons.length;
    return AnimatedContainer(
      duration: Motion.of(context, Motion.slow),
      curve: Motion.curve,
      padding: const EdgeInsets.all(S.x5),
      decoration: BoxDecoration(
        borderRadius: R.all(R.xxl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(col, kWhite, 0.16)!, col],
        ),
        border: Border.all(color: on == kWhite ? const Color(0x33FFFFFF) : const Color(0x14000000)),
        boxShadow: Shadows.glow(col, c, strength: 0.6),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on == kWhite ? const Color(0x2EFFFFFF) : const Color(0x14000000),
              borderRadius: R.all(R.md + 2),
              border: Border.all(color: on == kWhite ? const Color(0x40FFFFFF) : const Color(0x1A000000)),
            ),
            child: Text(course.tag, style: AppType.monoStrong.copyWith(fontSize: 16, color: on)),
          ),
          const SizedBox(width: S.x4),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${s.t('boss').toUpperCase()} ${kCourses.indexOf(course) + 1}',
                  style: AppType.overline.copyWith(color: soft)),
              const SizedBox(height: 3),
              Text(s.tr(course.name),
                  style: AppType.title1.copyWith(color: on, shadows: on == kWhite ? kTextShadow : null)),
              Text(s.tr(course.sub), style: AppType.subhead.copyWith(color: soft)),
            ]),
          ),
        ]),
        const SizedBox(height: S.x5),
        Row(children: [
          Expanded(
            child: AppProgress(d / n,
                height: 8,
                color: on,
                track: on == kWhite ? const Color(0x38FFFFFF) : const Color(0x1F000000)),
          ),
          const SizedBox(width: S.x3),
          Text('$d/$n', style: AppType.footnote.copyWith(color: on, fontWeight: w8)),
        ]),
      ]),
    );
  }
}

// ------------------------------------------------------------ dars yo‘li / путь уроков
class _Path extends StatelessWidget {
  final Course course;
  const _Path({required this.course});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c, st = s.st;
    final cur = s.nextLesson(course);
    const offsets = [0.0, 56.0, 112.0, 56.0];
    final items = <Widget>[];
    for (var i = 0; i < course.lessons.length; i++) {
      final l = course.lessons[i];
      final done = st.isDone(l.id);
      final open = s.unlocked(course, i);
      final isCur = cur != null && cur.id == l.id;
      final sub = done
          ? s.t('completed')
          : isCur
              ? '${s.t('now')} · +${l.xp} XP'
              : open
                  ? '+${l.xp} XP'
                  : s.t('locked');
      items.add(Padding(
        padding: EdgeInsets.only(left: offsets[i % 4]),
        child: Pressable(
          onTap: open ? () => openLesson(context, l.id) : null,
          scale: 0.97,
          child: Row(children: [
            _Node(index: i, done: done, current: isCur, open: open),
            const SizedBox(width: S.x4),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.tr(l.title),
                    style: AppType.headline.copyWith(color: open ? c.text : c.text3)),
                const SizedBox(height: 2),
                Text(sub,
                    style: AppType.footnote.copyWith(
                        color: isCur ? c.accentText : c.text2, fontWeight: isCur ? w8 : w6)),
              ]),
            ),
            if (open && !done)
              Icon(Icons.chevron_right_rounded, color: isCur ? c.accentText : c.text3),
          ]),
        ),
      ));
      if (i < course.lessons.length - 1) {
        items.add(Padding(
          padding: EdgeInsets.only(left: (offsets[i % 4] + offsets[(i + 1) % 4]) / 2 + 33, top: 6, bottom: 6),
          child: Column(children: [
            for (var k = 0; k < 3; k++)
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? c.accent.withAlpha(0x99) : c.hairlineStrong,
                ),
              ),
          ]),
        ));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: items);
  }
}

/// Dars tugunchasi / узел урока.
class _Node extends StatelessWidget {
  final int index;
  final bool done, current, open;
  const _Node({required this.index, required this.done, required this.current, required this.open});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    const size = 72.0;
    Widget face({required Gradient? gradient, Color? color, required Widget child, Color? lip, bool ring = false}) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient,
          color: color,
          border: Border.all(
            color: ring ? kWhite.withAlpha(c.isDark ? 0x40 : 0xCC) : (lip == null ? c.hairline : const Color(0x26FFFFFF)),
            width: ring ? 3 : 1,
          ),
          boxShadow: [
            if (lip != null) BoxShadow(color: lip, offset: const Offset(0, 5)),
            ...Shadows.soft(c),
          ],
        ),
        child: child,
      );
    }

    if (done) {
      return face(
        gradient: c.accentGradient,
        lip: Color.lerp(c.accent, kBlack, 0.35),
        child: const Icon(Icons.check_rounded, size: 32, color: kWhite),
      );
    }
    if (current) {
      return Breathing(
        builder: (t) => Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: c.yellow.withAlpha((0x40 + 0x50 * t).round()), blurRadius: 18 + 14 * t)],
          ),
          child: face(
            gradient: c.yellowGradient,
            lip: Color.lerp(c.yellow, kBlack, 0.3),
            ring: true,
            child: const Icon(Icons.play_arrow_rounded, size: 36, color: kWhite, shadows: kTextShadow),
          ),
        ),
      );
    }
    if (open) {
      return face(
        gradient: null,
        color: c.isDark ? c.elevated : c.surface,
        lip: c.isDark ? const Color(0xFF0E0E10) : const Color(0xFFE3DED6),
        child: Text('${index + 1}', style: AppType.title2.copyWith(color: c.text)),
      );
    }
    return face(
      gradient: null,
      color: c.surfaceAlt,
      child: Icon(Icons.lock_rounded, size: 24, color: c.text3),
    );
  }
}

// ------------------------------------------------------------ xazina / сундук
class _Chest extends StatelessWidget {
  final Course course;
  const _Chest({required this.course});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final d = s.progressOf(course), n = course.lessons.length;
    final allDone = d == n;
    final opened = s.st.chests.contains(course.id);
    final ready = allDone && !opened;
    return AppCard(
      kind: ready ? CardKind.tinted : CardKind.solid,
      tint: ready ? c.yellowSoft : null,
      borderColor: ready ? c.yellow.withAlpha(0x66) : null,
      padding: const EdgeInsets.all(S.x4),
      child: Row(children: [
        IconTile(
          opened ? Icons.auto_awesome_rounded : Icons.redeem_rounded,
          size: 56,
          bg: ready || opened ? c.yellowSoft : c.surfaceAlt,
          color: ready || opened ? c.yellowText : c.text3,
        ),
        const SizedBox(width: S.x4),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.t('chest'), style: AppType.headline.copyWith(color: c.text)),
            const SizedBox(height: 2),
            Text(
              opened ? s.t('chest_done') : (allDone ? '+50' : s.t('chest_locked')),
              style: AppType.footnote.copyWith(color: c.text2),
            ),
          ]),
        ),
        if (ready)
          AppButton(s.t('chest_open'),
              onPressed: () => s.chest(course), kind: BtnKind.success, height: 42, icon: Icons.diamond_rounded),
      ]),
    );
  }
}
