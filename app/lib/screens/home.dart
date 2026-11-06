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
        const _CourseGrid(),
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

