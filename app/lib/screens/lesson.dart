import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../lessons.dart';
import '../progress.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'play.dart' show formatRun;

/// Darsni ochish / открыть урок.
void openLesson(BuildContext context, String id, {bool replace = false}) {
  if (!kAllLessons.containsKey(id)) return;
  FocusManager.instance.primaryFocus?.unfocus();
  final route = AppRoute<void>(builder: (_) => LessonScreen(lessonId: id));
  if (replace) {
    Navigator.of(context).pushReplacement(route);
  } else {
    Navigator.of(context).push(route);
  }
}

const Map<StepType, IconData> _kindIcons = {
  StepType.read: Icons.auto_stories_rounded,
  StepType.quiz: Icons.quiz_rounded,
  StepType.fill: Icons.edit_note_rounded,
  StepType.tryIt: Icons.code_rounded,
};

const Map<String, String> _modeNames = {'html': 'HTML', 'css': 'CSS', 'js': 'JavaScript', 'py': 'Python'};
const Map<String, String> _fileNames = {'html': 'index.html', 'css': 'style.css', 'js': 'script.js', 'py': 'main.py'};

/// Dars o‘yini / игра-урок.
class LessonScreen extends StatefulWidget {
  final String lessonId;
  const LessonScreen({super.key, required this.lessonId});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final Lesson lesson = kAllLessons[widget.lessonId]!.$1;
  late final Course course = kAllLessons[widget.lessonId]!.$2;

  int i = 0; // joriy bosqich / текущий шаг
  int? sel; // tanlangan javob / выбранный вариант
  String? status; // null | ok | no
  String input = '';
  String? code;
  String? out;
  bool wrongOnce = false;
  int combo = 0, best = 0, mistakes = 0;
  String say = '';
  bool running = false;

  // Yakun / итог
  LessonResult? result;
  bool saving = false;
  bool saveFailed = false;
  String _praise = '';

  final _fillCtrl = TextEditingController();

  List<LessonStep> get steps => lesson.steps;
  LessonStep get step => steps[i];

  @override
  void initState() {
    super.initState();
    if (steps.any((s) => s.type == StepType.tryIt && s.mode == 'py')) {
      AppScope.read(context).warmUp();
    }
  }

  @override
  void dispose() {
    _fillCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- amallar / действия
  void _pick(int k) {
    if (status == 'ok') return;
    HapticFeedback.selectionClick();
    setState(() {
      sel = k;
      status = null;
    });
  }

  bool get _canCheck => switch (step.type) {
        StepType.quiz => sel != null,
        StepType.fill => input.trim().isNotEmpty,
        StepType.tryIt => !running,
        StepType.read => false,
      };

  Future<void> _check() async {
    if (!_canCheck) return;
    final s = AppScope.read(context);
    final st = step;
    FocusManager.instance.primaryFocus?.unfocus();
    bool ok = false;
    switch (st.type) {
      case StepType.quiz:
        ok = sel == st.answer;
      case StepType.fill:
        final v = input.trim().toLowerCase();
        ok = st.answers.any((a) => a.toLowerCase() == v);
      case StepType.tryIt:
        var output = '';
        final src = code ?? st.start ?? '';
        if (st.mode == 'py') {
          setState(() => running = true);
          final r = await s.run(src);
          if (!mounted) return;
          running = false;
          out = formatRun(s, r);
          if (r.err == 'conn' || r.err == 'busy') {
            // Internet muammosi — xato hisoblanmaydi / проблема сети — не считается ошибкой.
            setState(() {});
            return;
          }
          output = r.err == null ? r.out : '';
        }
        ok = st.check!(src, output);
      case StepType.read:
        return;
    }
    setState(() {
      if (ok) {
        status = 'ok';
        combo += 1;
        if (combo > best) best = combo;
        say = s.pick('praise');
        HapticFeedback.lightImpact();
      } else {
        if (status == 'no' || st.type == StepType.quiz) wrongOnce = true;
        status = 'no';
        combo = 0;
        mistakes += 1;
        say = s.pick('cheer');
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _next() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      i += 1;
      sel = null;
      status = null;
      input = '';
      code = null;
      out = null;
      wrongOnce = false;
      say = '';
      _fillCtrl.clear();
    });
    if (i >= steps.length) _finish();
  }

  Future<void> _finish() async {
    if (saving || result != null) return;
    final s = AppScope.read(context);
    setState(() {
      saving = true;
      saveFailed = false;
    });
    final r = await s.finishLesson(lesson, mistakes == 0, best);
    if (!mounted) return;
    setState(() {
      saving = false;
      result = r;
      saveFailed = r == null;
      _praise = s.pick('praise');
    });
    if (r != null) HapticFeedback.heavyImpact();
  }

  Future<void> _runOnly() async {
    final s = AppScope.read(context);
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => running = true);
    final r = await s.run(code ?? step.start ?? '');
    if (!mounted) return;
    setState(() {
      running = false;
      out = formatRun(s, r);
    });
  }

  // ---------------------------------------------------------------- chizish / отрисовка
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final finished = i >= steps.length;

    final top = Row(children: [
      AppIconButton(Icons.close_rounded, tooltip: s.t('back'), onPressed: () => Navigator.of(context).maybePop()),
      const SizedBox(width: S.x3),
      Expanded(
        child: AppProgress(finished ? 1 : i / steps.length, height: 10, gradient: c.accentGradient),
      ),
      AnimatedSize(
        duration: Motion.of(context, Motion.base),
        curve: Motion.curve,
        child: combo >= 2
            ? Padding(
                padding: const EdgeInsets.only(left: S.x2),
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(combo),
                  tween: Tween(begin: 0.6, end: 1),
                  duration: Motion.of(context, Motion.base),
                  curve: Motion.pop,
                  builder: (_, v, child) => Transform.scale(scale: v, child: child),
                  child: AppPill('x$combo', icon: Icons.local_fire_department_rounded, tone: Tone.accent, small: true),
                ),
              )
            : const SizedBox.shrink(),
      ),
      const SizedBox(width: S.x2),
      AppPill('${lesson.xp}', icon: Icons.bolt_rounded, iconColor: c.yellow, small: true),
    ]);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: c.bg,
        body: AppBackground(
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(S.page, S.x3, S.page, S.x3),
                  child: Column(children: [
                    top,
                    const SizedBox(height: S.x4),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: Motion.of(context, Motion.base),
                        switchInCurve: Motion.curve,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween(begin: const Offset(0.04, 0), end: Offset.zero).animate(anim),
                            child: child,
                          ),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(finished ? 'done' : 'step-$i'),
                          child: finished ? _done(s) : _stepView(s),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepView(AppState s) {
    final c = s.c, st = step;
    final body = <Widget>[];

    var kindLabel = s.t(st.kindKey);
    if (st.type == StepType.tryIt) kindLabel = '$kindLabel · ${_modeNames[st.mode] ?? ''}';
    body.add(Row(children: [
      IconTile(_kindIcons[st.type]!, size: 28),
      const SizedBox(width: S.x2),
      Text(kindLabel.toUpperCase(), style: AppType.overline.copyWith(color: c.accentText)),
      const Spacer(),
      Text('${i + 1} / ${steps.length}', style: AppType.caption.copyWith(color: c.text3)),
    ]));

    switch (st.type) {
      case StepType.read:
        body
          ..add(Text(s.tr(st.h!), style: AppType.title1.copyWith(color: c.text)))
          ..add(Text(s.tr(st.p!), style: AppType.body.copyWith(color: c.text, fontSize: 17)));
        if (st.code != null) body.add(CodeBlock(st.code!, label: _modeNames[course.id] ?? ''));

      case StepType.quiz:
        body.add(Text(s.tr(st.q!), style: AppType.title2.copyWith(color: c.text)));
        if (st.code != null) body.add(CodeBlock(st.code!, label: _modeNames[course.id] ?? ''));
        for (var k = 0; k < st.options.length; k++) {
          body.add(_Option(
            index: k,
            text: s.tr(st.options[k]),
            mono: st.mono,
            state: _optionState(k, st),
            shakeTrigger: k == sel && status == 'no' ? mistakes : 0,
            onTap: status == 'ok' ? null : () => _pick(k),
          ));
        }

      case StepType.fill:
        body.add(Text(s.tr(st.q!), style: AppType.title2.copyWith(color: c.text)));
        final field = SizedBox(
          width: 150,
          child: TextField(
            key: ValueKey('fill-$i'),
            controller: _fillCtrl,
            autofocus: true,
            enabled: status != 'ok',
            onChanged: (v) => setState(() => input = v),
            onSubmitted: (_) => _check(),
            textAlign: TextAlign.center,
            autocorrect: false,
            enableSuggestions: false,
            smartQuotesType: SmartQuotesType.disabled,
            smartDashesType: SmartDashesType.disabled,
            textCapitalization: TextCapitalization.none,
            cursorColor: kOrange,
            style: AppType.monoStrong.copyWith(color: c.codeFg),
            decoration: InputDecoration(
              isDense: true,
              hintText: s.t('type_here'),
              hintStyle: AppType.mono.copyWith(color: c.codeMuted),
              filled: true,
              fillColor: const Color(0x14FFFFFF),
              contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
              border: OutlineInputBorder(
                  borderRadius: R.all(R.sm - 2), borderSide: const BorderSide(color: Color(0x40FFFFFF))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: R.all(R.sm - 2), borderSide: const BorderSide(color: Color(0x40FFFFFF))),
              disabledBorder: OutlineInputBorder(
                  borderRadius: R.all(R.sm - 2), borderSide: BorderSide(color: c.yellow, width: 1.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: R.all(R.sm - 2), borderSide: const BorderSide(color: kOrange, width: 1.5)),
            ),
          ),
        );
        body.add(Shake(
          trigger: status == 'no' ? mistakes : 0,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: c.codeBg,
              borderRadius: R.all(R.lg),
              border: Border.all(color: c.isDark ? c.hairline : const Color(0x1F000000)),
              boxShadow: Shadows.card(c),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              CodeBar(_modeNames[course.id] ?? ''),
              Padding(
                padding: const EdgeInsets.all(S.x4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (st.pre!.isNotEmpty) Text(st.pre!, style: AppType.monoStrong.copyWith(color: c.codeFg)),
                    field,
                    Text(st.post!, style: AppType.monoStrong.copyWith(color: c.codeFg)),
                  ],
                ),
              ),
            ]),
          ),
        ));

      case StepType.tryIt:
        code ??= st.start;
        body
          ..add(Text(s.tr(st.task!), style: AppType.title2.copyWith(color: c.text)))
          ..add(Shake(
            trigger: status == 'no' ? mistakes : 0,
            child: CodeEditor(
              key: ValueKey('code-$i'),
              initial: code ?? '',
              onChanged: (v) => code = v,
              enabled: status != 'ok',
              label: _fileNames[st.mode] ?? '',
            ),
          ));
        if (st.mode == 'py') {
          body
            ..add(Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                running ? s.t('running') : s.t('run'),
                onPressed: running ? null : _runOnly,
                loading: running,
                kind: BtnKind.secondary,
                icon: Icons.play_arrow_rounded,
                height: 44,
              ),
            ))
            ..add(Console((out ?? '').isEmpty ? s.t('empty_out') : out!,
                label: s.t('output'), placeholder: (out ?? '').isEmpty));
        }
    }

    // ---- Kodi gapiradi / Коди говорит
    final hasFeedback = status == 'ok' || status == 'no';
    final ok = status == 'ok';
    Widget? feedback;
    if (hasFeedback) {
      final extra = <String>[];
      var extraMono = false;
      if (!ok) {
        extra.add(s.t('try_again'));
        if (wrongOnce) {
          if (st.type == StepType.fill) {
            extra.add('${s.t('answer')}: ${st.answers.first}');
            extraMono = true;
          } else if (st.type == StepType.tryIt) {
            extra.add(s.tr(st.hint!));
            extraMono = true;
          } else if (st.e != null) {
            extra.add(s.tr(st.e!));
          }
        }
      } else if (st.e != null) {
        extra.add(s.tr(st.e!));
      }
      feedback = _Feedback(
        key: ValueKey('fb-$i-$status-$mistakes'),
        ok: ok,
        title: say + (ok && combo >= 2 ? '  ·  x$combo' : ''),
        lines: extra,
        lastMono: extraMono,
        hintIcon: !ok && wrongOnce && st.type == StepType.tryIt,
      );
    }

    final Widget action;
    if (st.type == StepType.read || ok) {
      action = AppButton(s.t('next'), onPressed: _next, kind: ok ? BtnKind.success : BtnKind.primary,
          expand: true, height: 56, icon: Icons.arrow_forward_rounded);
    } else {
      action = AppButton(running ? s.t('running') : s.t('check'),
          onPressed: _canCheck ? _check : null, expand: true, height: 56, loading: running);
    }

    return Column(children: [
      Expanded(
        child: ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(bottom: S.x4),
          children: [
            for (var k = 0; k < body.length; k++)
              Padding(
                padding: EdgeInsets.only(bottom: k == 0 ? S.x4 : S.x4 + 2),
                child: Appear(index: k, child: body[k]),
              ),
          ],
        ),
      ),
      AnimatedSize(
        duration: Motion.of(context, Motion.base),
        curve: Motion.curve,
        alignment: Alignment.bottomCenter,
        child: feedback == null
            ? const SizedBox(width: double.infinity)
            : Padding(padding: const EdgeInsets.only(bottom: S.x3), child: feedback),
      ),
      action,
    ]);
  }

  _OptState _optionState(int k, LessonStep st) {
    if (status != null) {
      if (k == st.answer && (status == 'ok' || wrongOnce)) return _OptState.correct;
      if (k == sel && status == 'no') return _OptState.wrong;
      return _OptState.idle;
    }
    return k == sel ? _OptState.selected : _OptState.idle;
  }

  // ---------------------------------------------------------------- yakun / итог
  Widget _done(AppState s) {
    final c = s.c;

    if (saving || (result == null && !saveFailed)) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CupertinoActivityIndicator(color: c.text2, radius: 13),
          const SizedBox(height: S.x4),
          Text(s.t('saving'), style: AppType.callout.copyWith(color: c.text2)),
        ]),
      );
    }

    if (saveFailed) {
      return Center(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            EmptyState(
              icon: Icons.cloud_off_rounded,
              title: s.t('save_failed'),
              error: true,
            ),
            const SizedBox(height: S.x5),
            AppButton(s.t('retry'), onPressed: _finish, expand: true, height: 56, icon: Icons.refresh_rounded),
            const SizedBox(height: S.x3),
            AppButton(s.t('back'), onPressed: () => Navigator.of(context).maybePop(), kind: BtnKind.secondary, expand: true),
          ]),
        ),
      );
    }

    final r = result!;
    final nx = s.nextLesson(course);

    Widget reward(IconData icon, int value, String prefix, String label, bool yellow) => Expanded(
          child: AppCard(
            padding: const EdgeInsets.symmetric(vertical: S.x4, horizontal: S.x2),
            radius: R.lg,
            child: Column(children: [
              IconTile(icon,
                  size: 36,
                  bg: yellow ? c.yellowSoft : c.accentSoft,
                  color: yellow ? c.yellowText : c.accentText),
              const SizedBox(height: S.x2 + 2),
              CountUp(value, prefix: prefix, style: AppType.title2.copyWith(color: c.text)),
              const SizedBox(height: 2),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.caption.copyWith(color: c.text2)),
            ]),
          ),
        );

    final extras = <Widget>[
      if (r.perfect) AppPill(s.t('perfect'), icon: Icons.verified_rounded, tone: Tone.yellow),
      if (r.levelUp) AppPill('${s.t('level_up')} ${r.level}', icon: Icons.workspace_premium_rounded, tone: Tone.accent),
      if (!r.first) AppPill(s.t('review'), icon: Icons.replay_rounded),
    ];

    final trophy = TweenAnimationBuilder<double>(
      tween: Tween(begin: Motion.reduced(context) ? 1 : 0.4, end: 1),
      duration: Motion.of(context, const Duration(milliseconds: 900)),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        width: 124,
        height: 124,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: r.perfect ? c.yellowGradient : c.accentGradient,
          border: Border.all(color: const Color(0x4DFFFFFF), width: 3),
          boxShadow: Shadows.glow(r.perfect ? c.yellow : c.accent, c, strength: 1.2),
        ),
        child: Icon(r.perfect ? Icons.emoji_events_rounded : Icons.celebration_rounded,
            size: 58, color: kWhite, shadows: kTextShadow),
      ),
    );

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: trophy),
          const SizedBox(height: S.x6),
          Appear(
            index: 1,
            child: Column(children: [
              Text(s.t('lesson_done'), textAlign: TextAlign.center, style: AppType.largeTitle.copyWith(color: c.text)),
              const SizedBox(height: S.x2),
              Text('$_praise ${s.tr(lesson.title)}',
                  textAlign: TextAlign.center, style: AppType.callout.copyWith(color: c.text2)),
            ]),
          ),
          const SizedBox(height: S.x6),
          Appear(
            index: 2,
            child: Row(children: [
              reward(Icons.bolt_rounded, r.xp, '+', 'XP', true),
              const SizedBox(width: S.x3),
              reward(Icons.diamond_rounded, r.gems, '+', s.t('gems'), true),
              const SizedBox(width: S.x3),
              reward(Icons.local_fire_department_rounded, best, 'x', s.t('combo'), false),
            ]),
          ),
          if (extras.isNotEmpty) ...[
            const SizedBox(height: S.x4),
            Appear(
              index: 3,
              child: Wrap(alignment: WrapAlignment.center, spacing: S.x2, runSpacing: S.x2, children: extras),
            ),
          ],
          const SizedBox(height: S.x7),
          if (nx != null) ...[
            AppButton(s.tr(nx.title),
                onPressed: () => openLesson(context, nx.id, replace: true),
                expand: true,
                height: 56,
                icon: Icons.play_arrow_rounded),
            const SizedBox(height: S.x3),
          ],
          AppButton(s.t('back'),
              onPressed: () => Navigator.of(context).maybePop(),
              kind: nx == null ? BtnKind.primary : BtnKind.secondary,
              expand: true),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------ javob varianti / вариант ответа
enum _OptState { idle, selected, correct, wrong }

class _Option extends StatelessWidget {
  final int index;
  final String text;
  final bool mono;
  final _OptState state;
  final int shakeTrigger;
  final VoidCallback? onTap;
  const _Option(
      {required this.index, required this.text, required this.mono, required this.state, required this.shakeTrigger, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final (bg, border, badgeBg, badgeFg) = switch (state) {
      _OptState.idle => (c.surface, c.hairlineStrong, c.surfaceAlt, c.text2),
      _OptState.selected => (c.accentSoft, c.accent, c.accent, kWhite),
      _OptState.correct => (c.yellowSoft, c.yellow, c.yellow, kWhite),
      _OptState.wrong => (c.dangerSoft, c.danger, c.danger, kWhite),
    };
    final IconData? badgeIcon = switch (state) {
      _OptState.correct => Icons.check_rounded,
      _OptState.wrong => Icons.close_rounded,
      _ => null,
    };
    return Shake(
      trigger: shakeTrigger,
      child: Pressable(
        onTap: onTap,
        scale: 0.98,
        child: AnimatedContainer(
          duration: Motion.of(context, Motion.fast),
          curve: Motion.curve,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: R.all(R.lg - 2),
            border: Border.all(color: border, width: state == _OptState.idle ? 1 : 2),
            boxShadow: state == _OptState.idle
                ? Shadows.soft(c)
                : Shadows.glow(border, c, strength: state == _OptState.selected ? 0.35 : 0.25),
          ),
          child: Row(children: [
            AnimatedContainer(
              duration: Motion.of(context, Motion.fast),
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: badgeBg, borderRadius: R.all(R.xs + 1)),
              child: badgeIcon != null
                  ? Icon(badgeIcon, size: 18, color: badgeFg)
                  : Text('${index + 1}', style: AppType.footnote.copyWith(color: badgeFg, fontWeight: w8)),
            ),
            const SizedBox(width: S.x3),
            Expanded(
              child: Text(
                text,
                style: mono
                    ? AppType.monoStrong.copyWith(color: c.text)
                    : AppType.bodyStrong.copyWith(color: c.text, fontWeight: w7),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ fikr paneli / панель отклика
class _Feedback extends StatelessWidget {
  final bool ok;
  final String title;
  final List<String> lines;
  final bool lastMono;
  final bool hintIcon;
  const _Feedback(
      {super.key, required this.ok, required this.title, required this.lines, this.lastMono = false, this.hintIcon = false});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final tint = ok ? c.yellow : c.danger;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.of(context, Motion.base),
      curve: Motion.curve,
      builder: (_, v, child) =>
          Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(S.x4),
        decoration: BoxDecoration(
          color: ok ? c.yellowSoft : c.dangerSoft,
          borderRadius: R.all(R.lg),
          border: Border.all(color: tint.withAlpha(0x59)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppAvatar(ok ? '🤖' : '🤔', size: 44),
          const SizedBox(width: S.x3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(ok ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 18, color: ok ? c.yellowText : c.danger),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(title, style: AppType.headline.copyWith(color: ok ? c.yellowText : c.danger, fontWeight: w8)),
                ),
              ]),
              for (var k = 0; k < lines.length; k++)
                Padding(
                  padding: const EdgeInsets.only(top: S.x1 + 2),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (k == lines.length - 1 && hintIcon) ...[
                      Icon(Icons.lightbulb_rounded, size: 16, color: c.yellowText),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        lines[k],
                        style: (k == lines.length - 1 && lastMono ? AppType.mono : AppType.subhead)
                            .copyWith(color: c.text, fontWeight: w6),
                      ),
                    ),
                  ]),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}
