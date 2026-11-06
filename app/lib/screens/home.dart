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
    final questsDone = kQuests.where((q) => st.quests.claimed.contains(q.id)).length;

    return TabPage(
      title: '${s.t('hello')}${name.isNotEmpty ? ', $name' : ''}',
      subtitle: s.leagueName,
      children: [
        _Continue(next: next),
        GroupList([
          GroupRow(
            key: const ValueKey('quests-row'),
            icon: Icons.task_alt_rounded,
            color: const Color(0xFF34C759),
            title: s.t('quests'),
            value: '$questsDone/${kQuests.length}',
            onTap: () => showAppSheet<void>(context, builder: (_) => const _Quests()),
          ),
        ]),
        SectionHeader(s.t('courses')),
        GroupList([for (final co in kCourses) _CourseRow(co)]),
      ],
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
    return Container(
      key: const ValueKey('continue-card'),
      padding: const EdgeInsets.all(S.x5),
      decoration: BoxDecoration(borderRadius: R.all(R.xl), gradient: c.heroGradient),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('${co.tag}  ${s.tr(co.name)}'.toUpperCase(),
              style: AppType.overline.copyWith(color: white70, letterSpacing: 1.2)),
          const Spacer(),
          Text('$goal/$kGoal XP', style: AppType.footnote.copyWith(color: kWhite, fontWeight: w7)),
        ]),
        const SizedBox(height: S.x3),
        Text(nx != null ? s.tr(nx.title) : s.t('all_done'),
            maxLines: 2, overflow: TextOverflow.ellipsis, style: AppType.title1.copyWith(color: kWhite)),
        const SizedBox(height: S.x3),
        AppProgress(st.todayXp / kGoal, height: 6, color: kWhite, track: const Color(0x38FFFFFF)),
        const SizedBox(height: S.x5),
        SizedBox(
          width: double.infinity,
          child: Pressable(
            key: const ValueKey('continue-btn'),
            onTap: () => nx != null ? openLesson(context, nx.id) : s.go('courses'),
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: kWhite, borderRadius: R.all(R.pill)),
              child: Text(nx != null ? s.t('continue') : s.t('courses'),
                  style: AppType.headline.copyWith(color: const Color(0xFF0058E6))),
            ),
          ),
        ),
      ]),
    );
  }
}

// ------------------------------------------------------------ kurs qatori / строка курса
class _CourseRow extends StatelessWidget {
  final Course co;
  const _CourseRow(this.co);

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final d = s.progressOf(co), n = s.lessonsOf(co).length;
    return Material(
      color: const Color(0x00000000),
      child: InkWell(
        key: ValueKey('course-row-${co.id}'),
        onTap: () {
          s.pickCourse(co.id);
          s.go('courses');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: S.x4, vertical: 12),
          child: Row(children: [
            CourseTag(co, size: 30, fontSize: 10),
            const SizedBox(width: S.x3),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.tr(co.name), style: AppType.body.copyWith(color: c.text)),
                const SizedBox(height: 5),
                AppProgress(n == 0 ? 0 : d / n, height: 4, color: courseColor(co, c)),
              ]),
            ),
            const SizedBox(width: S.x4),
            Text('$d/$n', style: AppType.callout.copyWith(color: c.text2)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 22, color: c.text3),
          ]),
        ),
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

