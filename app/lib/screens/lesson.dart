import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/services.dart';

import '../api.dart' show pingRunner;
import '../focus.dart';
import '../lessons.dart';
import '../progress.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'anim_player.dart';
import 'cards.dart';
import 'certificate.dart';
import 'helper.dart';
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
  StepType.order: Icons.reorder_rounded,
  StepType.tryIt: Icons.code_rounded,
};

const Map<String, String> kModeNames = {
  'html': 'HTML',
  'css': 'CSS',
  'js': 'JavaScript',
  'py': 'Python',
  'text': 'Prompt',
  'ai': 'AI',
};
const Map<String, String> _fileNames = {
  'html': 'index.html',
  'css': 'style.css',
  'js': 'script.js',
  'py': 'main.py',
  'text': 'prompt.txt',
};

/// Savol uchun vaqt (soniya). Qiyinroq — ko‘proq vaqt; boshlang‘ich ligaga qo‘shimcha vaqt.
/// Время на вопрос (сек). Сложнее — больше времени; начальной лиге — дополнительное время.
int timeLimitFor(LessonStep st, String league) {
  final d = st.difficulty.clamp(1, 3).toInt() - 1;
  final base = switch (st.type) {
    StepType.quiz => const [20, 30, 40][d],
    StepType.fill => const [25, 35, 45][d],
    StepType.order => const [35, 50, 65][d],
    StepType.tryIt => const [240, 300, 360][d],
    StepType.read => 0,
  };
  final extra = league.isEmpty || league == 'beginner';
  return extra ? (base * 1.5).round() : base;
}

/// Dars yoki isinish testi / урок или разминка.
///
/// Himoya: test boshlangach ilovadan chiqilsa — test darhol bekor qilinadi.
/// Защита: если выйти из приложения во время теста — тест сразу отменяется.
class LessonScreen extends StatefulWidget {
  final String? lessonId;
  final bool placement;
  final String? examCourse; // yakuniy imtihon / итоговый экзамен
  const LessonScreen({super.key, required String this.lessonId})
      : placement = false,
        examCourse = null;
  const LessonScreen.placement({super.key})
      : lessonId = null,
        examCourse = null,
        placement = true;
  const LessonScreen.exam({super.key, required String this.examCourse})
      : lessonId = null,
        placement = false;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

enum _Phase { gate, test, done }

class _LessonScreenState extends State<LessonScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Lesson? lesson;
  Course? course;
  List<LessonStep> steps = const [];
  int seed = 0;
  bool? runnerOk; // Python serveri / сервер Python: null — noma’lum / неизвестно

  _Phase phase = _Phase.gate;
  bool cancelledBefore = false; // isinish qayta boshlandi / разминку начали заново
  bool dndAccess = false;
  bool dndOn = false;

  int i = 0; // joriy bosqich / текущий шаг
  int? sel; // tanlangan javob / выбранный вариант
  String? status; // null | ok | no
  String input = '';
  String? code;
  String? out;
  bool wrongOnce = false;
  bool timedOut = false;
  bool firstTry = true;
  List<int> picked = []; // tartiblash / порядок
  List<int> pool = [];
  int combo = 0, best = 0, mistakes = 0;
  String say = '';
  bool running = false;
  final Set<int> helperPaid = {};

  // Hisob / подсчёт
  int timedTotal = 0, correctFirst = 0, points = 0;
  double shareSum = 0;
  final Set<int> scored = {};

  // Vaqt / время
  Ticker? _ticker;
  Duration _elapsed = Duration.zero;
  Duration _stepStart = Duration.zero;
  final ValueNotifier<double> _left = ValueNotifier(1); // 0..1
  final ValueNotifier<int> _secs = ValueNotifier(0);

  // Yakun / итог
  LessonResult? result;
  bool saving = false;
  bool saveFailed = false;
  String _praise = '';

  final _fillCtrl = TextEditingController();

  // Imtihon natijasi / результат экзамена
  (int, Cert?)? examResult;

  AppState get s => AppScope.read(context);
  bool get _exam => widget.examCourse != null;
  bool get _oneShot => widget.placement || _exam;
  LessonStep get step => steps[i];
  bool get _testMode => AppScope.read(context).testMode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_exam) {
      course = kCourses.firstWhere((x) => x.id == widget.examCourse);
    } else if (!widget.placement) {
      final e = kAllLessons[widget.lessonId]!;
      lesson = e.$1;
      course = e.$2;
    }
    _prepare();
    _checkDnd();
  }

  void _prepare() {
    final st = AppScope.read(context);
    seed = st.testMode ? 7 : math.Random().nextInt(1 << 30);
    steps = widget.placement
        ? placementTest(seed)
        : _exam
            ? examQuestions(st.lessonsOf(course!), seed)
            : [...lesson!.build(seed, st.st.difficultyFor(lesson!.id))];
    if (!_oneShot && steps.any(_needsRunner)) {
      if (st.testMode) {
        runnerOk = true;
      } else {
        pingRunner(st.server).then((ok) {
          if (!mounted) return;
          runnerOk = ok;
          if (!ok) _swapCurrent();
        });
      }
    }
  }

  static bool _needsRunner(LessonStep x) => x.type == StepType.tryIt && x.mode == 'py';

  /// Server bo‘lmasa — kod savolini oddiy savolga almashtirish.
  /// Нет сервера — заменить вопрос с кодом обычным вопросом.
  void _swapCurrent({bool notify = true}) {
    if (phase != _Phase.test || i >= steps.length || !_needsRunner(step) || status == 'ok' || timedOut) return;
    setState(() {
      steps[i] = offlineFallback(step, seed + i);
      sel = null;
      status = null;
      code = null;
      out = null;
      running = false;
      wrongOnce = false;
      picked = [];
      _enterStep();
    });
    if (notify) s.toast(s.t('offline_swap'), icon: Icons.wifi_off_rounded);
  }

  Future<void> _checkDnd() async {
    if (!FocusMode.isAndroid) return;
    final a = await FocusMode.hasAccess();
    if (mounted && a != dndAccess) setState(() => dndAccess = a);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.dispose();
    _left.dispose();
    _secs.dispose();
    _fillCtrl.dispose();
    FocusMode.restore();
    super.dispose();
  }

  // ---------------------------------------------------------------- himoya / защита
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && phase == _Phase.gate) _checkDnd();
    if (phase != _Phase.test) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden || state == AppLifecycleState.detached) {
      _cancelTest();
    }
  }

  /// Ilovadan chiqildi — test bekor / вышли из приложения — тест отменён.
  void _cancelTest({bool byUser = false}) {
    if (phase != _Phase.test) return;
    _ticker?.stop();
    FocusMode.restore();
    dndOn = false;
    if (widget.placement) {
      // Isinish yangi savollar bilan qaytadan / разминка заново с новыми вопросами.
      setState(() {
        _resetRun();
        phase = _Phase.gate;
        cancelledBefore = true;
        _prepare();
      });
      return;
    }
    phase = _Phase.done; // qayta chaqirilmasin / чтобы не вызвать повторно
    final app = s;
    if (_exam) {
      app.pendingNotice = byUser ? '' : app.t('exam_cancelled');
      if (byUser) app.toast(app.t('exam_cancelled'), icon: Icons.block_rounded);
      Navigator.of(context).pop();
      return;
    }
    app.cancelLessonTest(lesson!);
    if (byUser) {
      app.pendingNotice = '';
      app.toast(app.t('test_cancelled'), icon: Icons.block_rounded);
    }
    Navigator.of(context).pop();
  }

  void _resetRun() {
    i = 0;
    sel = null;
    status = null;
    input = '';
    code = null;
    out = null;
    wrongOnce = false;
    timedOut = false;
    firstTry = true;
    picked = [];
    pool = [];
    combo = best = mistakes = 0;
    say = '';
    helperPaid.clear();
    timedTotal = correctFirst = points = 0;
    shareSum = 0;
    scored.clear();
    _fillCtrl.clear();
  }

  bool _starting = false;

  Future<void> _start() async {
    if (_starting) return;
    HapticFeedback.mediumImpact();
    if (_exam) {
      setState(() => _starting = true);
      final err = await s.startExam(course!);
      if (!mounted) return;
      setState(() => _starting = false);
      if (err != null) {
        s.toast(s.t(err), icon: Icons.info_rounded);
        return;
      }
    }
    if (FocusMode.isAndroid && dndAccess) dndOn = await FocusMode.enable();
    if (!mounted) return;
    setState(() {
      _resetRun();
      phase = _Phase.test;
      _enterStep();
    });
    if (!_testMode) {
      _ticker ??= createTicker(_onTick);
      _elapsed = Duration.zero;
      _stepStart = Duration.zero;
      if (!_ticker!.isActive) _ticker!.start();
    }
  }

  /// X tugmasi / кнопка X.
  Future<void> _close() async {
    if (phase != _Phase.test) {
      if (!widget.placement) Navigator.of(context).maybePop();
      return;
    }
    final c = s.c;
    final yes = await showAppSheet<bool>(context, builder: (ctx) {
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: IconTile(Icons.warning_amber_rounded, size: 56, circle: true, bg: c.dangerSoft, color: c.danger)),
        const SizedBox(height: S.x4),
        Text(s.t('quit_q'), textAlign: TextAlign.center, style: AppType.title3.copyWith(color: c.text)),
        const SizedBox(height: S.x2),
        Text(s.t(widget.placement ? 'quit_warm' : 'quit_text'),
            textAlign: TextAlign.center, style: AppType.subhead.copyWith(color: c.text2)),
        const SizedBox(height: S.x5),
        AppButton(s.t('quit_yes'),
            key: const ValueKey('quit-yes'), kind: BtnKind.danger, expand: true, onPressed: () => Navigator.of(ctx).pop(true)),
        const SizedBox(height: S.x2),
        AppButton(s.t('quit_no'), kind: BtnKind.secondary, expand: true, onPressed: () => Navigator.of(ctx).pop(false)),
      ]);
    });
    if (yes == true && mounted) _cancelTest(byUser: true);
  }

  // ---------------------------------------------------------------- vaqt / время
  int get _limit => timeLimitFor(step, widget.placement ? '' : s.st.league);

  bool get _timerRunning => phase == _Phase.test && i < steps.length && step.timed && status != 'ok' && !timedOut && !(_oneShot && status != null);

  void _enterStep() {
    if (runnerOk == false && i < steps.length && _needsRunner(steps[i])) steps[i] = offlineFallback(steps[i], seed + i);
    _stepStart = _elapsed;
    if (i < steps.length && step.timed) {
      _left.value = 1;
      _secs.value = _limit;
      if (step.type == StepType.order) {
        final r = math.Random(seed + i * 31);
        pool = List.generate(step.lines.length, (k) => k)..shuffle(r);
        var guard = 0;
        while (pool.length > 1 && _inOrder(pool) && guard++ < 5) {
          pool.shuffle(r);
        }
      }
    }
  }

  bool _inOrder(List<int> xs) {
    for (var k = 0; k < xs.length; k++) {
      if (step.lines[xs[k]] != step.lines[k]) return false;
    }
    return true;
  }

  double get _usedShare {
    if (_testMode) return 0.3;
    final used = (_elapsed - _stepStart).inMilliseconds / 1000;
    return (used / _limit).clamp(0.0, 1.0).toDouble();
  }

  void _onTick(Duration e) {
    _elapsed = e;
    if (!_timerRunning) return;
    final share = _usedShare;
    _left.value = 1 - share;
    _secs.value = math.max(0, (_limit * (1 - share)).ceil());
    if (share >= 1) _timeout();
  }

  void _timeout() {
    HapticFeedback.heavyImpact();
    _score(false, 1);
    setState(() {
      timedOut = true;
      wrongOnce = true;
      status = 'no';
      combo = 0;
      mistakes += 1;
      say = s.t('time_up');
    });
  }

  /// Savol natijasini bir marta hisoblash / учесть результат вопроса один раз.
  void _score(bool ok, double share) {
    if (scored.contains(i) || !step.timed) return;
    scored.add(i);
    timedTotal += 1;
    shareSum += share;
    if (ok) {
      correctFirst += 1;
      points += step.difficulty;
    }
  }

  // ---------------------------------------------------------------- amallar / действия
  void _pick(int k) {
    if (status == 'ok' || timedOut || (_oneShot && status != null)) return;
    HapticFeedback.selectionClick();
    setState(() {
      sel = k;
      if (status == 'no') status = null;
    });
  }

  bool get _locked => status == 'ok' || timedOut || (_oneShot && status != null);

  bool get _canCheck => !_locked && switch (step.type) {
        StepType.quiz => sel != null,
        StepType.fill => input.trim().isNotEmpty,
        StepType.order => picked.length == step.lines.length,
        StepType.tryIt => !running,
        StepType.read => false,
      };

  Future<void> _check() async {
    if (!_canCheck) return;
    final st = step;
    FocusManager.instance.primaryFocus?.unfocus();
    bool ok = false;
    switch (st.type) {
      case StepType.quiz:
        ok = sel == st.answer;
      case StepType.fill:
        final v = input.trim().toLowerCase();
        ok = st.answers.any((a) => a.toLowerCase() == v);
      case StepType.order:
        ok = _inOrder(picked);
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
            // Server yo‘q — savol almashadi, xato hisoblanmaydi.
            // Сервера нет — вопрос заменяется, ошибкой не считается.
            runnerOk = false;
            _swapCurrent();
            return;
          }
          output = r.err == null ? r.out : '';
        }
        ok = st.check!(src, output);
      case StepType.read:
        return;
    }
    if (phase != _Phase.test || timedOut) return;
    _score(ok && firstTry, _usedShare);
    firstTry = false;
    setState(() {
      if (ok) {
        status = 'ok';
        combo += 1;
        if (combo > best) best = combo;
        say = s.pick('praise');
        HapticFeedback.lightImpact();
      } else {
        if (status == 'no' || st.type == StepType.quiz || st.type == StepType.order) wrongOnce = true;
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
    if (step.type == StepType.read) HapticFeedback.selectionClick();
    setState(() {
      i += 1;
      sel = null;
      status = null;
      input = '';
      code = null;
      out = null;
      wrongOnce = false;
      timedOut = false;
      firstTry = true;
      picked = [];
      pool = [];
      say = '';
      _fillCtrl.clear();
      if (i < steps.length) _enterStep();
    });
    if (i >= steps.length) _finish();
  }

  Future<void> _finish() async {
    _ticker?.stop();
    FocusMode.restore();
    dndOn = false;
    setState(() => phase = _Phase.done);
    if (widget.placement) {
      HapticFeedback.heavyImpact();
      _praise = s.pick('praise');
      return;
    }
    if (_exam) {
      await _saveExam();
      return;
    }
    await _save();
  }

  Future<void> _save() async {
    if (saving) return;
    setState(() {
      saving = true;
      saveFailed = false;
    });
    final r = await s.finishLesson(lesson!,
        perfect: mistakes == 0,
        bestCombo: best,
        correct: correctFirst,
        total: timedTotal,
        timeShare: timedTotal == 0 ? 0.5 : shareSum / timedTotal);
    if (!mounted) return;
    setState(() {
      saving = false;
      result = r;
      saveFailed = r == null;
      _praise = s.pick('praise');
    });
    if (r != null) HapticFeedback.heavyImpact();
  }

  Future<void> _saveExam() async {
    if (saving) return;
    setState(() {
      saving = true;
      saveFailed = false;
    });
    final r = await s.finishExam(course!, correctFirst, timedTotal);
    if (!mounted) return;
    setState(() {
      saving = false;
      examResult = r;
      saveFailed = r == null;
    });
    if (r != null) HapticFeedback.heavyImpact();
  }

  Future<void> _finishPlacement() async {
    if (saving) return;
    setState(() => saving = true);
    await s.submitPlacement(points, timedTotal == 0 ? 1 : shareSum / timedTotal);
    if (mounted) setState(() => saving = false);
  }

  Future<void> _runOnly() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => running = true);
    final r = await s.run(code ?? step.start ?? '');
    if (!mounted) return;
    setState(() {
      running = false;
      out = formatRun(s, r);
    });
    if (r.err == 'conn' || r.err == 'busy') {
      runnerOk = false;
      _swapCurrent();
    }
  }

  Future<void> _helper() async {
    final st = step;
    if (!helperPaid.contains(i)) {
      final ok = await s.payForHelper();
      if (!ok || !mounted) return;
      helperPaid.add(i);
      setState(() {});
    }
    if (!mounted) return;
    await showHelperSheet(
      context,
      explainMistake(
        s,
        st,
        courseId: course?.id ?? 'py',
        selected: sel,
        input: input,
        picked: picked,
        code: code ?? st.start ?? '',
        output: out ?? '',
        timedOut: timedOut,
      ),
    );
  }

  // ---------------------------------------------------------------- chizish / отрисовка
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;

    final Widget content = switch (phase) {
      _Phase.gate => _gate(s),
      _Phase.test => _stepView(s),
      _Phase.done => widget.placement ? _placementDone(s) : (_exam ? _examDone(s) : _done(s)),
    };

    final top = phase == _Phase.test ? _topBar(s) : _gateBar(s);

    final scaffold = GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: c.bg,
        body: AppBackground(
          strong: phase != _Phase.test,
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(S.page, S.x3, S.page, S.x3),
                  child: Column(children: [
                    if (top != null) ...[top, const SizedBox(height: S.x4)],
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
                          key: ValueKey('${phase.name}-$i-$seed'),
                          child: content,
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

    return PopScope(
      canPop: phase != _Phase.test && !widget.placement,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && phase == _Phase.test) _close();
      },
      child: scaffold,
    );
  }

  Widget? _gateBar(AppState s) {
    if (widget.placement) {
      if (phase == _Phase.done) return null;
      return Row(children: [
        const Spacer(),
        Pressable(
          onTap: s.toggleLang,
          child: AppPill(s.lang == 'uz' ? 'RU' : 'UZ', icon: Icons.translate_rounded),
        ),
      ]);
    }
    if (phase == _Phase.done) return null;
    return Row(children: [
      AppIconButton(Icons.close_rounded, tooltip: s.t('back'), onPressed: _close),
      const Spacer(),
    ]);
  }

  Widget _topBar(AppState s) {
    final c = s.c;
    return Column(children: [
      Row(children: [
        AppIconButton(Icons.close_rounded, key: const ValueKey('lesson-close'), tooltip: s.t('back'), onPressed: _close),
        const SizedBox(width: S.x3),
        Expanded(
          child: AppProgress(i / steps.length, height: 10, gradient: c.accentGradient),
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
        if (i < steps.length && step.timed) ...[
          const SizedBox(width: S.x2),
          _TimerPill(left: _left, secs: _secs, active: _timerRunning),
        ] else if (lesson != null) ...[
          const SizedBox(width: S.x2),
          AppPill('${lesson!.xp}', icon: Icons.bolt_rounded, iconColor: c.yellow, small: true),
        ],
      ]),
    ]);
  }

  // ---------------------------------------------------------------- boshlashdan oldin / перед началом
  Widget _gate(AppState s) {
    final c = s.c;
    final timed = steps.where((x) => x.timed).length;
    final title = widget.placement ? s.t('warm_title') : (_exam ? s.t('exam_title') : s.tr(lesson!.title));
    final sub = widget.placement ? s.t('warm_sub') : s.tr(course!.name);

    Widget rule(IconData icon, String text, {bool danger = false}) => Padding(
          padding: const EdgeInsets.only(bottom: S.x3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconTile(icon,
                size: 34, bg: danger ? c.dangerSoft : c.accentSoft, color: danger ? c.danger : c.accentText),
            const SizedBox(width: S.x3),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(text, style: AppType.subhead.copyWith(color: c.text)),
              ),
            ),
          ]),
        );

    final head = Column(children: [
      if (widget.placement)
        const _Logo(size: 84)
      else
        CourseTag(course!, size: 72, fontSize: 22),
      const SizedBox(height: S.x4),
      Text(title, textAlign: TextAlign.center, style: AppType.title1.copyWith(color: c.text)),
      const SizedBox(height: S.x2),
      Text(sub, textAlign: TextAlign.center, style: AppType.callout.copyWith(color: c.text2)),
      const SizedBox(height: S.x4),
      Wrap(alignment: WrapAlignment.center, spacing: S.x2, runSpacing: S.x2, children: [
        AppPill('$timed ${s.t('questions')}', icon: Icons.quiz_rounded),
        if (lesson != null) AppPill('+${lesson!.xp} XP', icon: Icons.bolt_rounded, iconColor: c.yellow),
        if (_exam) AppPill('$kExamPass% ${s.t('exam_to_pass')}', icon: Icons.workspace_premium_rounded, tone: Tone.yellow),
        if (lesson != null && (s.st.retries[lesson!.id] ?? 0) > 0)
          AppPill(s.t('harder'), icon: Icons.trending_up_rounded, tone: Tone.danger),
      ]),
    ]);

    final rules = AppCard(
      padding: const EdgeInsets.fromLTRB(S.x4, S.x4, S.x4, S.x2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s.t('rules'), style: AppType.headline.copyWith(color: c.text)),
        const SizedBox(height: S.x3),
        rule(Icons.timer_rounded, s.t('rule_time')),
        if (_exam) ...[
          rule(Icons.looks_one_rounded, s.t('rule_exam_once')),
          rule(Icons.workspace_premium_rounded, s.t('rule_exam_pass').replaceAll('{n}', '$kExamPass')),
          rule(Icons.exit_to_app_rounded, s.t('rule_exam_leave'), danger: true),
        ] else ...[
          rule(Icons.exit_to_app_rounded, s.t(widget.placement ? 'rule_leave_warm' : 'rule_leave'), danger: true),
          if (!widget.placement) rule(Icons.autorenew_rounded, s.t('rule_retry')),
          if (!widget.placement) rule(Icons.smart_toy_rounded, s.t('rule_helper').replaceAll('{n}', '$kHelperCost')),
        ],
      ]),
    );

    Widget? focus;
    if (FocusMode.isAndroid) {
      focus = AppCard(
        kind: CardKind.tinted,
        padding: const EdgeInsets.all(S.x4),
        child: Row(children: [
          IconTile(dndAccess ? Icons.notifications_off_rounded : Icons.notifications_active_rounded, size: 40),
          const SizedBox(width: S.x3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.t('dnd_title'), style: AppType.headline.copyWith(color: c.text)),
              const SizedBox(height: 2),
              Text(s.t(dndAccess ? 'dnd_ready' : 'dnd_text'), style: AppType.footnote.copyWith(color: c.text2)),
            ]),
          ),
          if (!dndAccess) ...[
            const SizedBox(width: S.x2),
            AppButton(s.t('dnd_allow'), kind: BtnKind.secondary, height: 40, onPressed: FocusMode.requestAccess),
          ],
        ]),
      );
    } else if (FocusMode.isIOS) {
      focus = AppCard(
        kind: CardKind.tinted,
        padding: const EdgeInsets.all(S.x4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const IconTile(Icons.lock_rounded, size: 40),
            const SizedBox(width: S.x3),
            Expanded(child: Text(s.t('ga_title'), style: AppType.headline.copyWith(color: c.text))),
          ]),
          const SizedBox(height: S.x3),
          for (final (k, key) in const [(1, 'ga_1'), (2, 'ga_2'), (3, 'ga_3')])
            Padding(
              padding: const EdgeInsets.only(bottom: S.x2),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                  child: Text('$k', style: AppType.caption.copyWith(color: kWhite)),
                ),
                const SizedBox(width: S.x2),
                Expanded(child: Text(s.t(key), style: AppType.footnote.copyWith(color: c.text))),
              ]),
            ),
        ]),
      );
    }

    return Column(children: [
      Expanded(
        child: ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.only(bottom: S.x4),
          children: [
            Appear(index: 0, child: head),
            if (cancelledBefore) ...[
              const SizedBox(height: S.x5),
              Appear(
                index: 1,
                child: AppCard(
                  kind: CardKind.tinted,
                  tint: c.dangerSoft,
                  borderColor: c.danger.withAlpha(0x55),
                  padding: const EdgeInsets.all(S.x4),
                  child: Row(children: [
                    Icon(Icons.info_rounded, color: c.danger),
                    const SizedBox(width: S.x3),
                    Expanded(child: Text(s.t('warm_restarted'), style: AppType.subhead.copyWith(color: c.text))),
                  ]),
                ),
              ),
            ],
            const SizedBox(height: S.x6),
            Appear(index: 2, child: rules),
            if (focus != null) ...[const SizedBox(height: S.x4), Appear(index: 3, child: focus)],
          ],
        ),
      ),
      AppButton(s.t(widget.placement ? 'warm_go' : (_exam ? 'exam_start' : 'test_start')),
          key: const ValueKey('test-start'),
          onPressed: _starting ? null : _start,
          loading: _starting,
          expand: true,
          height: 56,
          icon: Icons.play_arrow_rounded),
    ]);
  }

  // ---------------------------------------------------------------- bosqich / шаг
  Widget _stepView(AppState s) {
    final c = s.c, st = step;
    final body = <Widget>[];
    final label = kModeNames[course?.id] ?? '';

    var kindLabel = s.t(st.kindKey);
    if (st.type == StepType.tryIt) kindLabel = '$kindLabel · ${kModeNames[st.mode] ?? ''}';
    body.add(Row(children: [
      IconTile(_kindIcons[st.type]!, size: 28),
      const SizedBox(width: S.x2),
      Flexible(child: Text(kindLabel.toUpperCase(), style: AppType.overline.copyWith(color: c.accentText))),
      const Spacer(),
      Text('${i + 1} / ${steps.length}', style: AppType.caption.copyWith(color: c.text3)),
    ]));

    switch (st.type) {
      case StepType.read:
        body
          ..add(Text(s.tr(st.h!), style: AppType.title1.copyWith(color: c.text)))
          ..add(Text(s.tr(st.p!), style: AppType.body.copyWith(color: c.text, fontSize: 17)));
        if (st.code != null) body.add(CodeBlock(st.code!, label: label));
        if (st.anim != null) body.add(AnimPlayer(key: ValueKey('anim-$i'), scene: st.anim!));

      case StepType.quiz:
        body.add(Text(s.tr(st.q!), style: AppType.title2.copyWith(color: c.text)));
        if (st.code != null) body.add(CodeBlock(st.code!, label: label));
        for (var k = 0; k < st.options.length; k++) {
          body.add(_Option(
            key: ValueKey('opt-$k'),
            index: k,
            text: s.tr(st.options[k]),
            mono: st.mono,
            state: _optionState(k, st),
            shakeTrigger: k == sel && status == 'no' ? mistakes : 0,
            onTap: _locked ? null : () => _pick(k),
          ));
        }

      case StepType.fill:
        body.add(Text(s.tr(st.q!), style: AppType.title2.copyWith(color: c.text)));
        final field = SizedBox(
          width: 150,
          child: TextField(
            key: const ValueKey('fill-input'),
            controller: _fillCtrl,
            autofocus: true,
            enabled: !_locked,
            onChanged: (v) => setState(() => input = v),
            onSubmitted: (_) => _check(),
            textAlign: TextAlign.center,
            autocorrect: false,
            enableSuggestions: false,
            smartQuotesType: SmartQuotesType.disabled,
            smartDashesType: SmartDashesType.disabled,
            textCapitalization: TextCapitalization.none,
            cursorColor: kSky,
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
                  borderRadius: R.all(R.sm - 2), borderSide: const BorderSide(color: kSky, width: 1.5)),
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
              CodeBar(label),
              Padding(
                padding: const EdgeInsets.all(S.x4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (st.pre!.isNotEmpty) Text(st.pre!, style: AppType.monoStrong.copyWith(color: c.codeFg)),
                    field,
                    if (st.post!.isNotEmpty) Text(st.post!, style: AppType.monoStrong.copyWith(color: c.codeFg)),
                  ],
                ),
              ),
            ]),
          ),
        ));

      case StepType.order:
        body
          ..add(Text(s.tr(st.q!), style: AppType.title2.copyWith(color: c.text)))
          ..add(Shake(trigger: status == 'no' ? mistakes : 0, child: _orderAnswer(s, st)))
          ..add(Text(s.t('order_tap'), style: AppType.footnote.copyWith(color: c.text2)))
          ..add(_orderPool(s, st));

      case StepType.tryIt:
        code ??= st.start;
        body
          ..add(Text(s.tr(st.task!), style: AppType.title2.copyWith(color: c.text)))
          ..add(Shake(
            trigger: status == 'no' ? mistakes : 0,
            child: CodeEditor(
              key: const ValueKey('code-editor'),
              initial: code ?? '',
              onChanged: (v) => code = v,
              enabled: !_locked,
              label: _fileNames[st.mode] ?? '',
            ),
          ));
        if (st.mode == 'py') {
          body
            ..add(Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                running ? s.t('running') : s.t('run'),
                onPressed: running || _locked ? null : _runOnly,
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

    // Avtomatik testlar uchun yashirin javob / скрытый ответ для автотестов.
    if (s.testMode && st.timed) {
      final sol = switch (st.type) {
        StepType.quiz => 'opt:${st.answer}',
        StepType.fill => 'fill:${st.answers.first}',
        StepType.order => 'order:${st.lines.length}',
        _ => 'try:${st.solution ?? ''}',
      };
      body.add(Opacity(opacity: 0, child: Text(sol, key: const ValueKey('test-solution'))));
    }

    // ---- fikr / отклик
    final hasFeedback = status == 'ok' || status == 'no';
    final ok = status == 'ok';
    Widget? feedback;
    if (hasFeedback) {
      final extra = <String>[];
      var extraMono = false;
      if (!ok) {
        if (timedOut) {
          extra.add(s.t('time_up_text'));
        } else if (!_oneShot) {
          extra.add(s.t('try_again'));
        }
        if (wrongOnce || _oneShot) {
          if (st.type == StepType.fill) {
            extra.add('${s.t('answer')}: ${st.answers.first}');
            extraMono = true;
          } else if (st.type == StepType.order && timedOut) {
            extra.add(st.lines.join('\n'));
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

    final showHelper = !ok && hasFeedback && !_oneShot;
    final Widget action;
    if (st.type == StepType.read || ok || timedOut || (_oneShot && hasFeedback)) {
      action = AppButton(s.t('next'),
          key: const ValueKey('step-next'),
          onPressed: _next,
          kind: ok ? BtnKind.success : BtnKind.primary,
          expand: true,
          height: 56,
          icon: Icons.arrow_forward_rounded);
    } else {
      action = AppButton(running ? s.t('running') : s.t('check'),
          key: const ValueKey('step-check'), onPressed: _canCheck ? _check : null, expand: true, height: 56, loading: running);
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
      if (showHelper) ...[
        _HelperButton(
          paid: helperPaid.contains(i),
          cost: kHelperCost,
          label: s.t('helper_btn'),
          onTap: _helper,
        ),
        const SizedBox(height: S.x2),
      ],
      action,
    ]);
  }

  Widget _orderAnswer(AppState s, LessonStep st) {
    final c = s.c;
    final okColor = status == 'ok' ? c.yellow : (status == 'no' ? c.danger : c.hairlineStrong);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(S.x3),
      decoration: BoxDecoration(
        color: c.codeBg,
        borderRadius: R.all(R.lg),
        border: Border.all(color: okColor, width: status == null ? 1 : 2),
        boxShadow: Shadows.card(c),
      ),
      child: picked.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: S.x8),
              child: Center(child: Text(s.t('order_empty'), style: AppType.mono.copyWith(color: c.codeMuted))),
            )
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var k = 0; k < picked.length; k++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Pressable(
                    key: ValueKey('order-picked-$k'),
                    onTap: _locked
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              picked.removeAt(k);
                              if (status == 'no') status = null;
                            });
                          },
                    scale: 0.98,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: S.x3, vertical: S.x2 + 2),
                      decoration: BoxDecoration(
                        color: const Color(0x14FFFFFF),
                        borderRadius: R.all(R.sm),
                        border: Border.all(color: const Color(0x26FFFFFF)),
                      ),
                      child: Row(children: [
                        Text('${k + 1}', style: AppType.caption.copyWith(color: c.codeMuted)),
                        const SizedBox(width: S.x3),
                        Expanded(
                          child: Text(st.lines[picked[k]], style: AppType.mono.copyWith(color: c.codeFg)),
                        ),
                        if (!_locked) Icon(Icons.close_rounded, size: 16, color: c.codeMuted),
                      ]),
                    ),
                  ),
                ),
            ]),
    );
  }

  Widget _orderPool(AppState s, LessonStep st) {
    final c = s.c;
    final left = [for (final k in pool) if (!picked.contains(k)) k];
    if (left.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: S.x2, runSpacing: S.x2, children: [
      for (final k in left)
        Pressable(
          key: ValueKey('order-line-$k'),
          onTap: _locked
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    picked.add(k);
                    if (status == 'no') status = null;
                  });
                },
          scale: 0.96,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: S.x3, vertical: S.x2 + 2),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: R.all(R.sm),
              border: Border.all(color: c.hairlineStrong),
              boxShadow: Shadows.soft(c),
            ),
            child: Text(st.lines[k], style: AppType.monoStrong.copyWith(color: c.text, fontSize: 14)),
          ),
        ),
    ]);
  }

  _OptState _optionState(int k, LessonStep st) {
    if (status != null) {
      final reveal = status == 'ok' || wrongOnce || timedOut || _oneShot;
      if (k == st.answer && reveal) return _OptState.correct;
      if (k == sel && status == 'no') return _OptState.wrong;
      return _OptState.idle;
    }
    return k == sel ? _OptState.selected : _OptState.idle;
  }

  // ---------------------------------------------------------------- isinish yakuni / итог разминки
  Widget _placementDone(AppState s) {
    final c = s.c;
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: _Trophy(icon: Icons.rocket_launch_rounded, gold: false)),
          const SizedBox(height: S.x6),
          Appear(
            index: 1,
            child: Column(children: [
              Text(s.t('warm_done'), textAlign: TextAlign.center, style: AppType.largeTitle.copyWith(color: c.text)),
              const SizedBox(height: S.x2),
              Text('$_praise ${s.t('warm_done_text')}',
                  textAlign: TextAlign.center, style: AppType.callout.copyWith(color: c.text2)),
            ]),
          ),
          const SizedBox(height: S.x6),
          Appear(
            index: 2,
            child: Row(children: [
              _Reward(icon: Icons.bolt_rounded, value: kPlacementXp, prefix: '+', label: 'XP', yellow: true),
              const SizedBox(width: S.x3),
              _Reward(
                  icon: Icons.check_circle_rounded,
                  value: correctFirst,
                  prefix: '',
                  label: '${s.t('correct')} / $timedTotal',
                  yellow: false),
            ]),
          ),
          const SizedBox(height: S.x7),
          AppButton(s.t('start_learning'),
              key: const ValueKey('placement-finish'),
              onPressed: saving ? null : _finishPlacement,
              loading: saving,
              expand: true,
              height: 56,
              icon: Icons.arrow_forward_rounded),
        ]),
      ),
    );
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
            EmptyState(icon: Icons.cloud_off_rounded, title: s.t('save_failed'), error: true),
            const SizedBox(height: S.x5),
            AppButton(s.t('retry'), onPressed: _save, expand: true, height: 56, icon: Icons.refresh_rounded),
            const SizedBox(height: S.x3),
            AppButton(s.t('back'), onPressed: () => Navigator.of(context).maybePop(), kind: BtnKind.secondary, expand: true),
          ]),
        ),
      );
    }

    final r = result!;
    final nx = s.nextLesson(course!);
    final acc = timedTotal == 0 ? 100 : (correctFirst * 100 / timedTotal).round();

    final extras = <Widget>[
      if (r.perfect) AppPill(s.t('perfect'), icon: Icons.verified_rounded, tone: Tone.yellow),
      if (r.levelUp) AppPill('${s.t('level_up')} ${r.level}', icon: Icons.workspace_premium_rounded, tone: Tone.accent),
      if (!r.first) AppPill(s.t('review'), icon: Icons.replay_rounded),
    ];

    return Stack(children: [
      Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: _Trophy(
                icon: r.perfect ? Icons.emoji_events_rounded : Icons.celebration_rounded, gold: r.perfect),
          ),
          const SizedBox(height: S.x6),
          Appear(
            index: 1,
            child: Column(children: [
              Text(s.t('lesson_done'), textAlign: TextAlign.center, style: AppType.largeTitle.copyWith(color: c.text)),
              const SizedBox(height: S.x2),
              Text('$_praise ${s.tr(lesson!.title)}',
                  textAlign: TextAlign.center, style: AppType.callout.copyWith(color: c.text2)),
            ]),
          ),
          if (r.promoted.isNotEmpty) ...[
            const SizedBox(height: S.x5),
            Appear(
              index: 2,
              child: AppCard(
                key: const ValueKey('promoted'),
                gradient: c.heroGradient,
                padding: const EdgeInsets.all(S.x4),
                child: Row(children: [
                  const Icon(Icons.military_tech_rounded, color: kWhite, size: 40, shadows: kTextShadow),
                  const SizedBox(width: S.x3),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.t('promoted'), style: AppType.headline.copyWith(color: kWhite)),
                      const SizedBox(height: 2),
                      Text(s.tr(kLeagueNames[r.promoted] ?? kLeagueNames['advanced']!),
                          style: AppType.title3.copyWith(color: kWhite)),
                    ]),
                  ),
                ]),
              ),
            ),
          ],
          const SizedBox(height: S.x6),
          Appear(
            index: 3,
            child: Row(children: [
              _Reward(icon: Icons.bolt_rounded, value: r.xp, prefix: '+', label: 'XP', yellow: true),
              const SizedBox(width: S.x3),
              _Reward(icon: Icons.track_changes_rounded, value: acc, prefix: '', label: '% ${s.t('accuracy')}', yellow: false),
              const SizedBox(width: S.x3),
              _Reward(icon: Icons.local_fire_department_rounded, value: best, prefix: 'x', label: s.t('combo'), yellow: false),
            ]),
          ),
          if (extras.isNotEmpty) ...[
            const SizedBox(height: S.x4),
            Appear(
              index: 4,
              child: Wrap(alignment: WrapAlignment.center, spacing: S.x2, runSpacing: S.x2, children: extras),
            ),
          ],
          if (keyPoints(lesson!).isNotEmpty) ...[
            const SizedBox(height: S.x5),
            Appear(
              index: 5,
              child: Pressable(
                key: const ValueKey('summary-open'),
                onTap: () => showSummary(context, lesson!, course!),
                scale: 0.98,
                child: SummaryCard(lesson: lesson!, course: course!, compact: true),
              ),
            ),
          ],
          const SizedBox(height: S.x7),
          if (nx != null) ...[
            AppButton(s.tr(nx.title),
                key: const ValueKey('next-lesson'),
                onPressed: () => openLesson(context, nx.id, replace: true),
                expand: true,
                height: 56,
                icon: Icons.play_arrow_rounded),
            const SizedBox(height: S.x3),
          ],
          AppButton(s.t('back'),
              key: const ValueKey('lesson-back'),
              onPressed: () => Navigator.of(context).maybePop(),
              kind: nx == null ? BtnKind.primary : BtnKind.secondary,
              expand: true),
        ]),
      ),
    ),
      Positioned.fill(child: Confetti(count: r.perfect ? 110 : 70)),
    ]);
  }

  // ---------------------------------------------------------------- imtihon yakuni / итог экзамена
  Widget _examDone(AppState s) {
    final c = s.c;
    if (saving || (examResult == null && !saveFailed)) {
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
            EmptyState(icon: Icons.cloud_off_rounded, title: s.t('save_failed'), error: true),
            const SizedBox(height: S.x5),
            AppButton(s.t('retry'), onPressed: _saveExam, expand: true, height: 56, icon: Icons.refresh_rounded),
          ]),
        ),
      );
    }
    final (score, cert) = examResult!;
    final passed = cert != null && score >= kExamPass;
    final body = Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: _Trophy(
                icon: passed ? Icons.workspace_premium_rounded : Icons.replay_rounded, gold: passed),
          ),
          const SizedBox(height: S.x6),
          Appear(
            index: 1,
            child: Column(children: [
              Text(s.t(passed ? 'exam_passed_title' : 'exam_failed_title'),
                  key: ValueKey(passed ? 'exam-passed' : 'exam-failed'),
                  textAlign: TextAlign.center,
                  style: AppType.largeTitle.copyWith(color: c.text)),
              const SizedBox(height: S.x2),
              Text(
                  passed
                      ? s.t('exam_passed_text')
                      : s.t('exam_failed_text').replaceAll('{n}', '$kExamPass'),
                  textAlign: TextAlign.center,
                  style: AppType.callout.copyWith(color: c.text2)),
            ]),
          ),
          const SizedBox(height: S.x6),
          Appear(
            index: 2,
            child: Row(children: [
              _Reward(icon: Icons.percent_rounded, value: score, prefix: '', label: s.t('exam_score'), yellow: passed),
              const SizedBox(width: S.x3),
              _Reward(
                  icon: Icons.check_circle_rounded,
                  value: correctFirst,
                  prefix: '',
                  label: '${s.t('correct')} / $timedTotal',
                  yellow: false),
            ]),
          ),
          if (passed) ...[
            const SizedBox(height: S.x5),
            Appear(
              index: 3,
              child: Pressable(
                key: const ValueKey('exam-cert'),
                onTap: () => openCertificate(context, cert!),
                scale: 0.98,
                child: CertificateView(CertText.of(cert!, s.certLink(cert!))),
              ),
            ),
          ],
          const SizedBox(height: S.x7),
          if (passed) ...[
            AppButton(s.t('cert_open'),
                key: const ValueKey('cert-open'),
                onPressed: () => openCertificate(context, cert!),
                expand: true,
                height: 56,
                icon: Icons.workspace_premium_rounded),
            const SizedBox(height: S.x3),
          ],
          AppButton(s.t('back'),
              key: const ValueKey('lesson-back'),
              onPressed: () => Navigator.of(context).maybePop(),
              kind: passed ? BtnKind.secondary : BtnKind.primary,
              expand: true),
        ]),
      ),
    );
    if (!passed) return body;
    return Stack(children: [body, const Positioned.fill(child: Confetti(count: 130))]);
  }
}

// ------------------------------------------------------------ kichik qismlar / мелкие части
class _Logo extends StatelessWidget {
  final double size;
  const _Logo({required this.size});

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
        child: Image.asset('assets/icon/icon.png', fit: BoxFit.cover),
      ),
    );
  }
}

class _Trophy extends StatelessWidget {
  final IconData icon;
  final bool gold;
  const _Trophy({required this.icon, required this.gold});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return TweenAnimationBuilder<double>(
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
          gradient: gold ? c.yellowGradient : c.accentGradient,
          border: Border.all(color: const Color(0x4DFFFFFF), width: 3),
          boxShadow: Shadows.glow(gold ? c.yellow : c.accent, c, strength: 1.2),
        ),
        child: Icon(icon, size: 58, color: kWhite, shadows: kTextShadow),
      ),
    );
  }
}

class _Reward extends StatelessWidget {
  final IconData icon;
  final int value;
  final String prefix, label;
  final bool yellow;
  const _Reward({required this.icon, required this.value, required this.prefix, required this.label, required this.yellow});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: S.x4, horizontal: S.x2),
        radius: R.lg,
        child: Column(children: [
          IconTile(icon, size: 36, bg: yellow ? c.yellowSoft : c.accentSoft, color: yellow ? c.yellowText : c.accentText),
          const SizedBox(height: S.x2 + 2),
          CountUp(value, prefix: prefix, style: AppType.title2.copyWith(color: c.text)),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.caption.copyWith(color: c.text2)),
        ]),
      ),
    );
  }
}

/// Qolgan vaqt / оставшееся время.
class _TimerPill extends StatelessWidget {
  final ValueNotifier<double> left;
  final ValueNotifier<int> secs;
  final bool active;
  const _TimerPill({required this.left, required this.secs, required this.active});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return ValueListenableBuilder<int>(
      valueListenable: secs,
      builder: (_, sec, __) {
        final low = active && left.value < 0.25;
        final col = low ? c.danger : c.accentText;
        final txt = '${sec ~/ 60}:${(sec % 60).toString().padLeft(2, '0')}';
        return Container(
          key: const ValueKey('timer'),
          padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
          decoration: BoxDecoration(
            color: low ? c.dangerSoft : c.accentSoft,
            borderRadius: R.all(R.pill),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 18,
              height: 18,
              child: ValueListenableBuilder<double>(
                valueListenable: left,
                builder: (_, v, __) => CircularProgressIndicator(
                  value: v.clamp(0.0, 1.0).toDouble(),
                  strokeWidth: 2.6,
                  color: col,
                  backgroundColor: col.withAlpha(0x33),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(txt, style: AppType.caption.copyWith(color: col, fontFeatures: const [FontFeature.tabularFigures()])),
          ]),
        );
      },
    );
  }
}

class _HelperButton extends StatelessWidget {
  final bool paid;
  final int cost;
  final String label;
  final VoidCallback onTap;
  const _HelperButton({required this.paid, required this.cost, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Pressable(
      key: const ValueKey('helper-btn'),
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: S.x4),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: R.all(R.pill),
          border: Border.all(color: c.accent.withAlpha(0x66), width: 1.5),
          boxShadow: Shadows.soft(c),
        ),
        child: Row(children: [
          Icon(Icons.smart_toy_rounded, color: c.accentText, size: 22),
          const SizedBox(width: S.x2),
          Expanded(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: AppType.callout.copyWith(color: c.accentText, fontWeight: w8)),
          ),
          if (!paid) AppPill('-$cost XP', icon: Icons.bolt_rounded, iconColor: c.yellow, small: true)
          else Icon(Icons.chevron_right_rounded, color: c.text3),
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
      {super.key,
      required this.index,
      required this.text,
      required this.mono,
      required this.state,
      required this.shakeTrigger,
      this.onTap});

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
        constraints: const BoxConstraints(maxHeight: 220),
        padding: const EdgeInsets.all(S.x4),
        decoration: BoxDecoration(
          color: ok ? c.yellowSoft : c.dangerSoft,
          borderRadius: R.all(R.lg),
          border: Border.all(color: tint.withAlpha(0x59)),
        ),
        child: SingleChildScrollView(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconTile(ok ? Icons.sentiment_very_satisfied_rounded : Icons.psychology_alt_rounded,
                size: 40, circle: true, bg: tint, color: kWhite),
            const SizedBox(width: S.x3),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: AppType.headline.copyWith(color: ok ? c.yellowText : c.danger, fontWeight: w8)),
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
      ),
    );
  }
}
