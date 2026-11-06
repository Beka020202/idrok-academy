// Dars konspekti va portfolio loyihalari.
// Конспект урока и портфолио-проекты.
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../lessons.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'lesson.dart' show kModeNames;

// ============================================================ KONSPEKT / КОНСПЕКТ
class KeyPoint {
  final Tr title, text;
  final String? code;
  const KeyPoint(this.title, this.text, this.code);
}

String _firstSentences(String p, {int max = 170}) {
  final parts = p.split(RegExp(r'(?<=[.!?])\s+'));
  var out = '';
  for (final x in parts) {
    if (out.isNotEmpty && (out.length + x.length) > max) break;
    out = out.isEmpty ? x : '$out $x';
  }
  return out.length > max + 60 ? '${out.substring(0, max)}…' : out;
}

/// Darsning asosiy fikrlari (nazariya qadamlaridan) / главные мысли урока (из шагов теории).
List<KeyPoint> keyPoints(Lesson l) {
  final steps = l.build(1, 1);
  return [
    for (final st in steps)
      if (st.type == StepType.read && st.anim == null && st.h != null && st.p != null)
        KeyPoint(st.h!, Tr(_firstSentences(st.p!.uz), _firstSentences(st.p!.ru)), st.code),
  ];
}

/// Konspekt kartasi (iOS uslubida) / карточка-конспект (в стиле iOS).
class SummaryCard extends StatelessWidget {
  final Lesson lesson;
  final Course course;
  final bool compact;
  const SummaryCard({super.key, required this.lesson, required this.course, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final points = keyPoints(lesson);
    final saved = s.isCardSaved(lesson.id);
    final col = courseColor(course, c);
    return ClipRRect(
      borderRadius: R.all(R.xxl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: R.all(R.xxl),
            color: c.isDark ? const Color(0xCC111827) : const Color(0xE6FFFFFF),
            border: Border.all(color: c.isDark ? const Color(0x1FFFFFFF) : const Color(0x14000000)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.fromLTRB(S.x4, S.x4, S.x2, S.x4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color.lerp(col, kWhite, 0.15)!, col],
                ),
              ),
              child: Row(children: [
                CourseTag(course, size: 40, fontSize: 12, onColorBg: true),
                const SizedBox(width: S.x3),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.t('summary').toUpperCase(),
                        style: AppType.overline.copyWith(color: kWhite.withAlpha(0xD9), letterSpacing: 1.4)),
                    const SizedBox(height: 2),
                    Text(s.tr(lesson.title),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.title3.copyWith(color: onColor(col), shadows: kTextShadow)),
                  ]),
                ),
                IconButton(
                  key: ValueKey('card-save-${lesson.id}'),
                  tooltip: s.t(saved ? 'card_saved' : 'card_save'),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    s.toggleCard(lesson.id);
                    if (!saved) s.toast(s.t('card_saved'), icon: Icons.bookmark_rounded);
                  },
                  icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: kWhite, size: 26),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(S.x4, S.x4, S.x4, S.x2),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (var k = 0; k < points.length; k++) ...[
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.accentSoft, shape: BoxShape.circle),
                      child: Text('${k + 1}', style: AppType.caption.copyWith(color: c.accentText, fontWeight: w8)),
                    ),
                    const SizedBox(width: S.x3),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.tr(points[k].title), style: AppType.headline.copyWith(color: c.text)),
                        if (!compact) ...[
                          const SizedBox(height: 3),
                          Text(s.tr(points[k].text), style: AppType.subhead.copyWith(color: c.text2, fontWeight: w4)),
                        ],
                        if (points[k].code != null && !compact) ...[
                          const SizedBox(height: S.x2),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(S.x3),
                            decoration: BoxDecoration(color: c.codeBg, borderRadius: R.all(R.sm)),
                            child: Text(points[k].code!, style: AppType.mono.copyWith(color: c.codeFg, fontSize: 13)),
                          ),
                        ],
                      ]),
                    ),
                  ]),
                  const SizedBox(height: S.x4),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

Future<void> showSummary(BuildContext context, Lesson lesson, Course course) {
  return showAppSheet<void>(context, builder: (ctx) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.85),
      child: SingleChildScrollView(child: SummaryCard(lesson: lesson, course: course)),
    );
  });
}

/// Saqlangan konspektlar / сохранённые конспекты.
class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final ids = [for (final id in s.savedCards) if (kAllLessons.containsKey(id)) id];
    return Scaffold(
      backgroundColor: c.bg,
      body: AppBackground(
        child: SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(S.page, S.x3, S.page, S.x8), children: [
            Row(children: [
              AppIconButton(Icons.arrow_back_rounded, tooltip: s.t('back'), onPressed: () => Navigator.of(context).maybePop()),
            ]),
            const SizedBox(height: S.x4),
            LargeTitle(s.t('my_cards'), subtitle: s.t('my_cards_sub')),
            const SizedBox(height: S.x5),
            if (ids.isEmpty)
              EmptyState(icon: Icons.bookmark_border_rounded, title: s.t('cards_empty'))
            else
              for (final id in ids) ...[
                SummaryCard(lesson: kAllLessons[id]!.$1, course: kAllLessons[id]!.$2),
                const SizedBox(height: S.x4),
              ],
          ]),
        ),
      ),
    );
  }
}

/// Profildagi “Konspektlarim” qatori / строка «Мои конспекты» в профиле.
class CardsTile extends StatelessWidget {
  const CardsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    return AppCard(
      key: const ValueKey('cards-tile'),
      onTap: () => Navigator.of(context).push(AppRoute<void>(builder: (_) => const CardsScreen())),
      padding: const EdgeInsets.all(S.x4),
      child: Row(children: [
        const IconTile(Icons.bookmarks_rounded, size: 44),
        const SizedBox(width: S.x3),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.t('my_cards'), style: AppType.headline.copyWith(color: c.text)),
            Text('${s.savedCards.length} ${s.t('cards_n')}', style: AppType.footnote.copyWith(color: c.text2)),
          ]),
        ),
        Icon(Icons.chevron_right_rounded, color: c.text3),
      ]),
    );
  }
}

// ============================================================ PORTFOLIO
/// Kurs sahifasidagi loyiha kartasi / карточка проекта на странице курса.
class ProjectCard extends StatelessWidget {
  final Course course;
  const ProjectCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final p = kProjects[course.id];
    if (p == null) return const SizedBox.shrink();
    final ls = s.lessonsOf(course);
    final open = ls.isNotEmpty && ls.every((l) => s.st.isDone(l.id));
    final done = s.projectLinks.containsKey(course.id) ||
        (s.projects[course.id] != null && p.passes(s.projects[course.id]!));
    return AppCard(
      key: ValueKey('project-${course.id}'),
      onTap: open ? () => Navigator.of(context).push(AppRoute<void>(builder: (_) => ProjectScreen(project: p))) : null,
      kind: open ? CardKind.tinted : CardKind.solid,
      padding: const EdgeInsets.all(S.x4),
      child: Row(children: [
        IconTile(done ? Icons.workspace_premium_rounded : (open ? Icons.rocket_launch_rounded : Icons.lock_rounded),
            size: 56, vivid: open),
        const SizedBox(width: S.x4),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.t('portfolio').toUpperCase(), style: AppType.overline.copyWith(color: c.accentText)),
            const SizedBox(height: 2),
            Text(s.tr(p.title), style: AppType.headline.copyWith(color: c.text)),
            const SizedBox(height: 2),
            Text(open ? (done ? s.t('project_done') : s.t('project_open')) : s.t('project_locked'),
                style: AppType.footnote.copyWith(color: c.text2)),
          ]),
        ),
        if (open) Icon(Icons.chevron_right_rounded, color: c.text3),
      ]),
    );
  }
}

/// Loyihani yozish, tekshirish va ulashish / написать, проверить и поделиться проектом.
class ProjectScreen extends StatefulWidget {
  final Project project;
  const ProjectScreen({super.key, required this.project});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  late String code;
  bool checked = false;

  @override
  void initState() {
    super.initState();
    code = AppScope.read(context).projects[widget.project.course] ?? widget.project.starter;
  }

  Future<void> _check() async {
    final s = AppScope.read(context);
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => checked = true);
    await s.saveProject(widget.project.course, code);
    if (widget.project.passes(code)) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      final link = await s.publishProject(widget.project.course, widget.project.mode, s.tr(widget.project.title), code);
      if (!mounted) return;
      await _shareSheet(link);
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _shareSheet(String? link) {
    final s = AppScope.read(context);
    return showAppSheet<void>(context, builder: (ctx) {
      final c = AppScope.of(ctx).c;
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Center(child: IconTile(Icons.workspace_premium_rounded, size: 64, circle: true, vivid: true)),
        const SizedBox(height: S.x4),
        Text(s.t('project_ready'), textAlign: TextAlign.center, style: AppType.title2.copyWith(color: c.text)),
        const SizedBox(height: S.x2),
        Text(link == null ? s.t('project_online') : s.t('project_share'),
            textAlign: TextAlign.center, style: AppType.subhead.copyWith(color: c.text2)),
        if (link != null) ...[
          const SizedBox(height: S.x4),
          Container(
            padding: const EdgeInsets.all(S.x3),
            decoration: BoxDecoration(color: c.accentSoft, borderRadius: R.all(R.md)),
            child: SelectableText(link,
                key: const ValueKey('project-link'),
                textAlign: TextAlign.center,
                style: AppType.mono.copyWith(color: c.accentText, fontSize: 13)),
          ),
          const SizedBox(height: S.x4),
          AppButton(s.t('copy_link'), icon: Icons.link_rounded, expand: true, onPressed: () {
            Clipboard.setData(ClipboardData(text: link));
            s.toast(s.t('copied'), icon: Icons.copy_rounded);
          }),
        ],
        const SizedBox(height: S.x2),
        AppButton(s.t('ok'), kind: BtnKind.secondary, expand: true, onPressed: () => Navigator.of(ctx).pop()),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final p = widget.project;
    final res = p.results(code);
    final link = s.projectLinks[p.course];
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: c.bg,
        body: AppBackground(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(S.page, S.x3, S.page, S.x8),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Row(children: [
                  AppIconButton(Icons.close_rounded, tooltip: s.t('back'), onPressed: () => Navigator.of(context).maybePop()),
                  const Spacer(),
                  AppPill(s.t('portfolio'), icon: Icons.workspace_premium_rounded, tone: Tone.accent),
                ]),
                const SizedBox(height: S.x4),
                LargeTitle(s.tr(p.title), subtitle: s.tr(p.brief)),
                const SizedBox(height: S.x5),
                AppCard(
                  padding: const EdgeInsets.all(S.x4),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.t('project_checklist'), style: AppType.headline.copyWith(color: c.text)),
                    const SizedBox(height: S.x3),
                    for (var k = 0; k < p.checks.length; k++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: S.x2),
                        child: Row(children: [
                          AnimatedSwitcher(
                            duration: Motion.of(context, Motion.fast),
                            child: Icon(
                              res[k] ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              key: ValueKey(res[k]),
                              color: res[k] ? c.yellow : (checked ? c.danger : c.text3),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: S.x2),
                          Expanded(child: Text(s.tr(p.checks[k].$1), style: AppType.subhead.copyWith(color: c.text))),
                        ]),
                      ),
                  ]),
                ),
                const SizedBox(height: S.x4),
                CodeEditor(
                  key: const ValueKey('project-editor'),
                  initial: code,
                  minLines: 12,
                  label: p.mode == 'py' ? 'main.py' : 'index.html',
                  onChanged: (v) => setState(() => code = v),
                ),
                const SizedBox(height: S.x5),
                AppButton(s.t('project_check'),
                    key: const ValueKey('project-check'),
                    onPressed: s.busy ? null : _check,
                    loading: s.busy,
                    expand: true,
                    height: 56,
                    icon: Icons.verified_rounded),
                if (link != null) ...[
                  const SizedBox(height: S.x3),
                  AppButton(s.t('project_my_link'),
                      kind: BtnKind.secondary, expand: true, icon: Icons.link_rounded, onPressed: () => _shareSheet(link)),
                ],
                const SizedBox(height: S.x3),
                Text('${kModeNames[p.mode == 'py' ? 'py' : 'html']} · ${s.t('project_hint')}',
                    textAlign: TextAlign.center, style: AppType.caption.copyWith(color: c.text3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
