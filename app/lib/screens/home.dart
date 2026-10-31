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

/// 1. Sarguzasht / Приключение.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final st = s.st;
    final course = s.course;
    Lesson? nl = s.nextLesson(course);
    if (nl == null) {
      for (final co in kCourses) {
        nl = s.nextLesson(co);
        if (nl != null) break;
      }
    }
    final next = nl;
    final nlCourse = next != null ? kAllLessons[next.id]!.$2 : course;
    final tips = s.tl('tips');
    final now = DateTime.now();
    final tip = tips[DateTime(now.year, now.month, now.day).difference(DateTime(2024)).inDays % tips.length];
    final name = s.displayName;

    return TabPage(
      title: '${s.t('hello')}${name.isNotEmpty ? ', $name' : ''}',
      children: [
        _Hero(next: next, course: nlCourse),
        _Mascot(tip: tip),
        _Quests(st: st),
        _Week(st: st),
        SectionHeader(s.t('courses')),
        gridOf([for (final co in kCourses) _CourseCard(co)], 2),
      ],
    );
  }
}

// ------------------------------------------------------------ qahramon kartasi / карточка-герой
class _Hero extends StatelessWidget {
  final Lesson? next;
  final Course course;
  const _Hero({required this.next, required this.course});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c, st = s.st;
    final lvl = levelOf(st.xp);
    final goal = st.todayXp < kGoal ? st.todayXp : kGoal;
    final nx = next;
    final white70 = kWhite.withAlpha(0xD9);

    return Container(
      decoration: BoxDecoration(
        borderRadius: R.all(R.xxl + 2),
        gradient: c.heroGradient,
        boxShadow: Shadows.glow(c.accent, c, strength: 0.9),
      ),
      child: ClipRRect(
        borderRadius: R.all(R.xxl + 2),
        child: Stack(children: [
          // Yumshoq yorug‘lik va aks / мягкий свет и отражение
          Positioned(
            right: -60,
            top: -80,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Color(0x47FFE08A), Color(0x00FFE08A)]),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: R.all(R.xxl + 2),
                  border: Border.all(color: const Color(0x33FFFFFF)),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [Color(0x26FFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(S.x5 + 2),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                AppRing(
                  (st.xp % 100) / 100,
                  size: 84,
                  stroke: 8,
                  color: kWhite,
                  track: const Color(0x38FFFFFF),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('$lvl', style: AppType.title1.copyWith(color: kWhite, height: 1, shadows: kTextShadow)),
                    const SizedBox(height: 2),
                    Text(s.t('level').toUpperCase(),
                        style: AppType.overline.copyWith(color: white70, fontSize: 9.5, letterSpacing: 0.8)),
                  ]),
                ),
                const SizedBox(width: S.x4 + 2),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${100 - st.xp % 100} XP',
                        style: AppType.title2.copyWith(color: kWhite, shadows: kTextShadow)),
                    Text(s.t('next_level'), style: AppType.subhead.copyWith(color: white70)),
                    const SizedBox(height: S.x3),
                    AppPill('${course.tag}  ${s.tr(course.name)}', tone: Tone.onColor, small: true),
                  ]),
                ),
              ]),
              const SizedBox(height: S.x5),
              Row(children: [
                const Icon(Icons.track_changes_rounded, size: 16, color: kWhite),
                const SizedBox(width: 6),
                Expanded(child: Text(s.t('goal'), style: AppType.footnote.copyWith(color: kWhite, fontWeight: w7))),
                Text('$goal / $kGoal XP', style: AppType.footnote.copyWith(color: kWhite, fontWeight: w8)),
              ]),
              const SizedBox(height: S.x2 + 2),
              AppProgress(st.todayXp / kGoal, height: 10, color: kWhite, track: const Color(0x38FFFFFF)),
              const SizedBox(height: S.x5),
              nx != null
                  ? AppButton('${s.t('play_now')}: ${s.tr(nx.title)}',
                      onPressed: () => openLesson(context, nx.id),
                      kind: BtnKind.dark,
                      icon: Icons.play_arrow_rounded,
                      expand: true)
                  : AppButton(s.t('courses'),
                      onPressed: () => s.go('courses'),
                      kind: BtnKind.dark,
                      icon: Icons.emoji_events_rounded,
                      expand: true),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------ Kodi maslahati / совет Коди
class _Mascot extends StatelessWidget {
  final String tip;
  const _Mascot({required this.tip});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    return AppCard(
      padding: const EdgeInsets.all(S.x4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const AppAvatar('🤖', size: 46),
        const SizedBox(width: S.x3),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.t('mascot_name'), style: AppType.caption.copyWith(color: c.accentText, fontWeight: w8)),
            const SizedBox(height: 3),
            Text(tip, style: AppType.callout.copyWith(color: c.text, fontWeight: w6)),
          ]),
        ),
      ]),
    );
  }
}

// ------------------------------------------------------------ kunlik vazifalar / задания дня
class _Quests extends StatelessWidget {
  final GameState st;
  const _Quests({required this.st});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
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
        action = AppButton('${s.t('claim')} ${q.gems}',
            onPressed: () => s.claim(q.id), kind: BtnKind.success, height: 38, icon: Icons.diamond_rounded);
      } else {
        action = AppPill('${q.gems}', icon: Icons.diamond_rounded, iconColor: c.yellow, small: true);
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
      SectionHeader(s.t('quests'), trailing: AppPill('$claimedN/${kQuests.length}', small: true)),
      const SizedBox(height: S.x3),
      AppCard(child: Column(children: rows)),
    ]);
  }
}

// ------------------------------------------------------------ hafta / неделя
class _Week extends StatelessWidget {
  final GameState st;
  const _Week({required this.st});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final days = s.tl('days_short');
    final today = todayStr();
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(s.t('week'), style: AppType.title3.copyWith(color: c.text))),
          AppPill('${st.streak} ${s.t('streak').toLowerCase()}',
              icon: Icons.local_fire_department_rounded, iconColor: c.accent, tone: Tone.accent, small: true),
        ]),
        const SizedBox(height: S.x4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (final (d, on) in lastWeek(st))
            Column(children: [
              AnimatedContainer(
                duration: Motion.of(context, Motion.base),
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: on ? c.accentGradient : null,
                  color: on ? null : c.surfaceAlt,
                  border: d == today ? Border.all(color: c.accent, width: 2) : null,
                  boxShadow: on ? Shadows.glow(c.accent, c, strength: 0.35) : null,
                ),
                child: on
                    ? const Icon(Icons.local_fire_department_rounded, size: 19, color: kWhite)
                    : Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(color: c.text3, shape: BoxShape.circle),
                      ),
              ),
              const SizedBox(height: 6),
              Text(days[parseIso(d).weekday - 1],
                  style: AppType.caption.copyWith(
                      color: d == today ? c.accentText : c.text2, fontWeight: d == today ? w8 : w7)),
            ]),
        ]),
      ]),
    );
  }
}

// ------------------------------------------------------------ kurs kartasi / карточка курса
class _CourseCard extends StatelessWidget {
  final Course co;
  const _CourseCard(this.co);

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final d = s.progressOf(co), n = co.lessons.length;
    final opened = s.st.chests.contains(co.id);
    return AppCard(
      onTap: () => s.pickCourse(co.id, open: true),
      padding: const EdgeInsets.all(S.x4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CourseTag(co, size: 44),
          const Spacer(),
          Icon(opened ? Icons.auto_awesome_rounded : Icons.redeem_rounded,
              size: 20, color: opened ? c.yellow : c.text3),
        ]),
        const SizedBox(height: S.x4),
        Text(s.tr(co.name), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.headline.copyWith(color: c.text)),
        const SizedBox(height: 2),
        Text(s.tr(co.sub), maxLines: 2, overflow: TextOverflow.ellipsis, style: AppType.caption.copyWith(color: c.text2)),
        const Spacer(),
        const SizedBox(height: S.x3),
        AppProgress(d / n, height: 6, color: courseColor(co, c)),
        const SizedBox(height: S.x2),
        Text('$d/$n ${s.t('lessons')}', style: AppType.caption.copyWith(color: c.text2)),
      ]),
    );
  }
}
