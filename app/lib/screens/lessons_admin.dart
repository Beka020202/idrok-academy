// Darslar boshqaruvi: admin (hamma uchun) va ustoz (o‘z maktabi uchun, XP yo‘q).
// AI yordamchi, kitoblar (PDF) va dars muharriri.
// Управление уроками: админ (для всех) и учитель (для своей школы, без XP).
// AI-помощник, книги (PDF) и редактор уроков.
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api.dart' show ApiError;
import '../content/data_lesson.dart';
import '../lessons.dart';
import '../progress.dart' show kLeagueNames;
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'anim_player.dart';
import 'lesson.dart';
import 'profile_form.dart' show ErrorBox;
import 'ranking.dart' show asInt, asStr, RankingTab;
import 'teacher.dart' show TeacherTab;
import 'teacher_tests.dart' show TestEditorScreen;

const String kAdminTelegram = '@behruz_sk';
const String kAdminTelegramUrl = 'https://t.me/behruz_sk';

Map<String, dynamic> _copy(Map<String, dynamic> m) => Map<String, dynamic>.from(jsonDecode(jsonEncode(m)) as Map);

Course _courseOf(String id) => kCourses.firstWhere((c) => c.id == id, orElse: () => kCourses.first);

Future<void> _push(BuildContext context, Widget page) =>
    Navigator.of(context).push(AppRoute<void>(builder: (_) => PageShell(child: page)));

// ============================================================ admin bosh sahifasi / главная админа
class AdminDashTab extends StatefulWidget {
  const AdminDashTab({super.key});

  @override
  State<AdminDashTab> createState() => _AdminDashTabState();
}

class _AdminDashTabState extends State<AdminDashTab> {
  Map<String, dynamic>? _st;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final s = AppScope.read(context);
    try {
      final r = await s.staffCall('/api/admin/stats');
      s.loadContent();
      if (mounted) {
        setState(() {
          _st = r;
          _error = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final st = _st;
    Widget tile(IconData i, String k, String label) =>
        StatTile(icon: i, value: st == null ? '—' : '${asInt(st[k])}', label: s.t(label));
    return TabPage(
      title: s.t('dash_tab'),
      subtitle: s.t('dash_sub'),
      onRefresh: _load,
      children: [
        _HeroCard(
          icon: Icons.insights_rounded,
          title: st == null ? s.t('loading') : '${asInt(st['students'])} ${s.t('dash_students')}',
          text: st == null ? '' : '${asInt(st['active_today'])} ${s.t('dash_active')} · +${asInt(st['new_week'])} ${s.t('dash_week')}',
        ),
        if (_error && st == null)
          EmptyState(icon: Icons.cloud_off_rounded, title: s.t('err_conn'), error: true, actionLabel: s.t('retry'), onAction: _load)
        else
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: S.x3,
            crossAxisSpacing: S.x3,
            childAspectRatio: 0.78,
            children: [
              tile(Icons.groups_rounded, 'teachers', 'dash_teachers'),
              tile(Icons.apartment_rounded, 'schools', 'dash_schools'),
              tile(Icons.menu_book_rounded, 'lessons', 'dash_lessons'),
              tile(Icons.edit_note_rounded, 'custom', 'dash_custom'),
              tile(Icons.workspace_premium_rounded, 'certs', 'dash_certs'),
              tile(Icons.redeem_rounded, 'orders_new', 'dash_orders'),
            ],
          ),
        _AiStatus(on: st?['ai'] == true || s.aiOn),
        SectionHeader(s.t('dash_manage')),
        GroupList([
          GroupRow(
              icon: Icons.menu_book_rounded,
              color: c.accent,
              title: s.t('les_tab'),
              onTap: () => s.go('lessons')),
          GroupRow(
              icon: Icons.groups_rounded,
              color: const Color(0xFF34C759),
              title: s.t('students_tab'),
              onTap: () => _push(context, const TeacherTab())),
          GroupRow(
              icon: Icons.leaderboard_rounded,
              color: const Color(0xFFFF9500),
              title: s.t('ranking'),
              onTap: () => _push(context, const RankingTab())),
          GroupRow(icon: Icons.key_rounded, color: const Color(0xFF5856D6), title: s.t('codes_tab'), onTap: () => s.go('admin')),
        ]),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final IconData icon;
  final String title, text;
  const _HeroCard({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return AppCard(
      gradient: c.heroGradient,
      padding: const EdgeInsets.all(S.x5),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: kWhite, size: 28),
        ),
        const SizedBox(width: S.x4),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppType.title2.copyWith(color: kWhite)),
            if (text.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(text, style: AppType.footnote.copyWith(color: const Color(0xD9FFFFFF))),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _AiStatus extends StatelessWidget {
  final bool on;
  const _AiStatus({required this.on});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    return AppCard(
      padding: const EdgeInsets.all(S.x4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        IconTile(Icons.auto_awesome_rounded, size: 40, vivid: on, bg: on ? null : c.yellowSoft, color: c.yellowText),
        const SizedBox(width: S.x3),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.t(on ? 'ai_ready' : 'ai_off_title'), style: AppType.headline.copyWith(color: c.text)),
            const SizedBox(height: 2),
            Text(s.t(on ? 'ai_ready_sub' : 'ai_off_sub'), style: AppType.footnote.copyWith(color: c.text2)),
          ]),
        ),
      ]),
    );
  }
}

// ============================================================ admin bilan bog‘lanish / связь с админом
/// Admin Telegrami (parol va kodlar uchun) / Telegram админа (для паролей и кодов).
class ContactAdminCard extends StatelessWidget {
  final String? text;
  const ContactAdminCard({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    return AppCard(
      key: const ValueKey('contact-admin'),
      padding: const EdgeInsets.all(S.x4),
      onTap: () {
        Clipboard.setData(const ClipboardData(text: kAdminTelegram));
        s.toast('${s.t('copied')}: $kAdminTelegram', icon: Icons.copy_rounded);
      },
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [Color(0xFF37BBFE), Color(0xFF007DBB)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
          child: const Icon(Icons.send_rounded, color: kWhite, size: 22),
        ),
        const SizedBox(width: S.x3),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(text ?? s.t('contact_admin'), style: AppType.footnote.copyWith(color: c.text2)),
            const SizedBox(height: 2),
            Text(kAdminTelegram, style: AppType.headline.copyWith(color: c.accentText)),
          ]),
        ),
        Icon(Icons.copy_rounded, size: 18, color: c.text3),
      ]),
    );
  }
}

// ============================================================ darslar ro‘yxati / список уроков
class LessonsTab extends StatefulWidget {
  const LessonsTab({super.key});

  @override
  State<LessonsTab> createState() => _LessonsTabState();
}

class _LessonsTabState extends State<LessonsTab> {
  String _course = 'html';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.read(context).loadContent();
    });
  }

  Future<void> _ai() async {
    final s = AppScope.read(context);
    final draft = await Navigator.of(context)
        .push<Map<String, dynamic>>(AppRoute(builder: (_) => PageShell(child: AiLessonScreen(course: _course))));
    if (draft == null || !mounted) return;
    _push(context, LessonEditorScreen(draft: draft, isNew: true));
    s.toast(s.t('ai_review'), icon: Icons.auto_awesome_rounded);
  }

  void _blank() {
    _push(
        context,
        LessonEditorScreen(isNew: true, draft: {
          'title': {'uz': '', 'ru': ''},
          'course': _course,
          'xp': 20,
          'leagues': null,
          'steps': [
            {
              't': 'read',
              'h': {'uz': '', 'ru': ''},
              'p': {'uz': '', 'ru': ''}
            },
          ],
        }));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final admin = s.isAdmin;
    final course = _courseOf(_course);
    final rows = admin
        ? adminLessonsOf(course)
        : [for (final co in kCourses) ...(kSchoolLessons[co.id] ?? const <Lesson>[])];
    return TabPage(
      title: s.t('les_tab'),
      subtitle: s.t(admin ? 'les_sub_admin' : 'les_sub_teacher'),
      onRefresh: s.loadContent,
      children: [
        Row(children: [
          Expanded(
            child: AppButton(s.t('ai_make'),
                key: const ValueKey('ai-make'), icon: Icons.auto_awesome_rounded, height: 48, onPressed: _ai),
          ),
          const SizedBox(width: S.x3),
          Expanded(
            child: AppButton(s.t('les_new'),
                key: const ValueKey('les-new'), kind: BtnKind.secondary, icon: Icons.add_rounded, height: 48, onPressed: _blank),
          ),
        ]),
        if (!admin)
          GroupList([
            GroupRow(
                icon: Icons.picture_as_pdf_rounded,
                color: const Color(0xFFFF3B30),
                title: s.t('books_tab'),
                onTap: () => _push(context, const BooksScreen())),
          ]),
        if (admin)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(children: [
              for (final co in kCourses) ...[
                _CourseChip(co: co, on: co.id == _course, onTap: () => setState(() => _course = co.id)),
                const SizedBox(width: S.x2),
              ],
            ]),
          ),
        SectionHeader(admin ? s.tr(course.name) : s.t('les_mine'), trailing: AppPill('${rows.length}', small: true)),
        if (rows.isEmpty)
          EmptyState(icon: Icons.menu_book_rounded, title: s.t('les_empty'), message: s.t('les_empty_sub'))
        else
          GroupList([for (var k = 0; k < rows.length; k++) _LessonRow(lesson: rows[k], n: k + 1)]),
        if (!admin) const ContactAdminCard(),
      ],
    );
  }
}

class _CourseChip extends StatelessWidget {
  final Course co;
  final bool on;
  final VoidCallback onTap;
  const _CourseChip({required this.co, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final col = courseColor(co, c);
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.base),
        curve: Motion.curve,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: on ? col : c.surface,
          borderRadius: R.all(R.pill),
          border: Border.all(color: on ? col : c.hairlineStrong),
          boxShadow: on ? Shadows.glow(col, c, strength: 0.35) : null,
        ),
        child: Text(s.tr(co.name), style: AppType.subhead.copyWith(color: on ? kWhite : c.text, fontWeight: w7)),
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  final Lesson lesson;
  final int n;
  const _LessonRow({required this.lesson, required this.n});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final item = kContent[lesson.id];
    final builtin = kBuiltinLessons.containsKey(lesson.id);
    final hidden = item?.hidden == true;
    final (badge, tone) = hidden
        ? ('les_hidden', Tone.danger)
        : !builtin
            ? ('les_badge_new', Tone.yellow)
            : item?.data != null
                ? ('les_badge_edit', Tone.accent)
                : ('les_badge_app', Tone.neutral);
    final co = _courseOf(lesson.courseId);
    return Material(
      color: const Color(0x00000000),
      child: InkWell(
        key: ValueKey('les-row-${lesson.id}'),
        onTap: () {
          HapticFeedback.selectionClick();
          final draft = item?.data != null ? _copy(item!.data!) : Map<String, dynamic>.from(lessonToJson(lesson));
          _push(context, LessonEditorScreen(id: lesson.id, draft: draft, builtin: builtin, hidden: hidden));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: S.x4, vertical: 12),
          child: Row(children: [
            Opacity(opacity: hidden ? 0.45 : 1, child: CourseTag(co, size: 34, fontSize: 11)),
            const SizedBox(width: S.x3),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$n. ${s.tr(lesson.title)}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.bodyStrong.copyWith(color: c.text)),
                const SizedBox(height: 3),
                Row(children: [
                  AppPill(s.t(badge), tone: tone, small: true),
                  const SizedBox(width: 6),
                  if (lesson.xp > 0) Text('+${lesson.xp} XP', style: AppType.caption.copyWith(color: c.text2)),
                  if (lesson.leagues != null)
                    Flexible(
                      child: Text('  ·  ${lesson.leagues!.map((x) => s.tr(kLeagueNames[x] ?? Tr.same(x))).join(', ')}',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.caption.copyWith(color: c.text3)),
                    ),
                ]),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: c.text3),
          ]),
        ),
      ),
    );
  }
}

// ============================================================ AI bilan dars / урок с AI
class AiLessonScreen extends StatefulWidget {
  final String course;
  const AiLessonScreen({super.key, required this.course});

  @override
  State<AiLessonScreen> createState() => _AiLessonScreenState();
}

class _AiLessonScreenState extends State<AiLessonScreen> {
  final _topic = TextEditingController();
  late String _course = widget.course;
  String _level = 'beginner';
  bool _busy = false;
  String _error = '';

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final s = AppScope.read(context);
    FocusManager.instance.primaryFocus?.unfocus();
    if (_topic.text.trim().length < 5) {
      setState(() => _error = s.t('ai_topic'));
      return;
    }
    setState(() {
      _busy = true;
      _error = '';
    });
    final (l, err) = await s.aiLesson({'topic': _topic.text.trim(), 'course': _course, 'level': _level});
    if (!mounted) return;
    setState(() => _busy = false);
    if (l == null) {
      setState(() => _error = err);
      return;
    }
    Navigator.of(context).pop(l);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    return TabPage(
      title: s.t('ai_make'),
      subtitle: s.t('ai_make_sub'),
      children: [
        _CoursePickRow(value: _course, onChanged: (v) => setState(() => _course = v)),
        Segmented<String>(
          values: const ['beginner', 'advanced', 'master'],
          labels: [for (final l in const ['beginner', 'advanced', 'master']) s.tr(kLeagueNames[l]!)],
          value: _level,
          onChanged: (v) => setState(() => _level = v),
        ),
        AppTextField(
          key: const ValueKey('ai-topic'),
          controller: _topic,
          label: s.t('ai_topic_label'),
          hint: s.t('ai_topic_hint'),
          minLines: 6,
          maxLines: 14,
          maxLength: 4000,
          autocorrect: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        if (_error.isNotEmpty) ErrorBox(_error),
        AppButton(_busy ? s.t('ai_thinking') : s.t('ai_go'),
            key: const ValueKey('ai-go'), icon: Icons.auto_awesome_rounded, expand: true, loading: _busy, onPressed: _go),
        if (_busy) _AiWait(c: c),
        Text(s.t('ai_note'), style: AppType.footnote.copyWith(color: c.text2)),
      ],
    );
  }
}

class _AiWait extends StatelessWidget {
  final AppColors c;
  const _AiWait({required this.c});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return AppCard(
      padding: const EdgeInsets.all(S.x4),
      child: Row(children: [
        CupertinoActivityIndicator(color: c.accent),
        const SizedBox(width: S.x3),
        Expanded(child: Text(s.t('ai_wait'), style: AppType.footnote.copyWith(color: c.text2))),
      ]),
    );
  }
}

class _CoursePickRow extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _CoursePickRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(children: [
          for (final co in kCourses) ...[
            _CourseChip(co: co, on: co.id == value, onTap: () => onChanged(co.id)),
            const SizedBox(width: S.x2),
          ],
        ]),
      );
}

// ============================================================ dars muharriri / редактор урока
class LessonEditorScreen extends StatefulWidget {
  final String? id;
  final Map<String, dynamic> draft;
  final bool builtin, hidden, isNew;
  const LessonEditorScreen(
      {super.key, this.id, required this.draft, this.builtin = false, this.hidden = false, this.isNew = false});

  @override
  State<LessonEditorScreen> createState() => _LessonEditorScreenState();
}

class _LessonEditorScreenState extends State<LessonEditorScreen> {
  late Map<String, dynamic> d = _copy(widget.draft);
  Map<String, dynamic>? _undo;
  late final _tUz = TextEditingController(text: '${(d['title'] as Map?)?['uz'] ?? ''}');
  late final _tRu = TextEditingController(text: '${(d['title'] as Map?)?['ru'] ?? ''}');
  late final _xp = TextEditingController(text: '${d['xp'] ?? 20}');
  late final _pos = TextEditingController(text: d['pos'] is int ? '${(d['pos'] as int) + 1}' : '');
  final _ai = TextEditingController();
  bool _aiBusy = false, _saving = false;
  String _error = '';
  late String? _id = widget.id;
  late bool _hidden = widget.hidden;

  List<Map<String, dynamic>> get steps => [
        for (final x in (d['steps'] as List? ?? const []))
          if (x is Map) Map<String, dynamic>.from(x)
      ];
  set steps(List<Map<String, dynamic>> v) => d['steps'] = v;

  @override
  void dispose() {
    for (final x in [_tUz, _tRu, _xp, _pos, _ai]) {
      x.dispose();
    }
    super.dispose();
  }

  void _syncHead() {
    d['title'] = {'uz': _tUz.text.trim(), 'ru': _tRu.text.trim()};
    d['xp'] = (int.tryParse(_xp.text.trim()) ?? 20).clamp(5, 50).toInt();
    final p = int.tryParse(_pos.text.trim());
    d['pos'] = p == null || p < 1 ? null : p - 1;
  }

  void _loadHead() {
    _tUz.text = '${(d['title'] as Map?)?['uz'] ?? ''}';
    _tRu.text = '${(d['title'] as Map?)?['ru'] ?? ''}';
    _xp.text = '${d['xp'] ?? 20}';
  }

  Lesson? _asLesson() {
    _syncHead();
    return lessonFromJson('__preview', d, source: 'preview');
  }

  void _preview() {
    final s = AppScope.read(context);
    final l = _asLesson();
    if (l == null) {
      setState(() => _error = s.t('les_bad'));
      return;
    }
    Navigator.of(context)
        .push(AppRoute<void>(builder: (_) => LessonScreen.preview(custom: l, customCourse: _courseOf(l.courseId))));
  }

  Future<void> _save() async {
    final s = AppScope.read(context);
    FocusManager.instance.primaryFocus?.unfocus();
    final l = _asLesson();
    if (l == null || _tUz.text.trim().isEmpty) {
      setState(() => _error = s.t('les_bad'));
      return;
    }
    setState(() {
      _saving = true;
      _error = '';
    });
    final id = await s.saveLesson(_id, d);
    if (!mounted) return;
    setState(() => _saving = false);
    if (id != null) {
      _id = id;
      s.toast(s.t('saved'), icon: Icons.check_circle_rounded);
      Navigator.of(context).pop();
    }
  }

  Future<void> _aiRevise() async {
    final s = AppScope.read(context);
    FocusManager.instance.primaryFocus?.unfocus();
    if (_ai.text.trim().length < 3) return;
    _syncHead();
    setState(() => _aiBusy = true);
    final (l, err) = await s.aiLesson({'draft': d, 'instruction': _ai.text.trim(), 'course': d['course']});
    if (!mounted) return;
    setState(() => _aiBusy = false);
    if (l == null) {
      s.toast(err, icon: Icons.error_outline_rounded);
      return;
    }
    setState(() {
      _undo = _copy(d);
      final keep = {'course': d['course'], 'xp': d['xp'], 'leagues': d['leagues'], 'pos': d['pos']};
      d = {...l, ...keep};
      _loadHead();
      _ai.clear();
    });
    s.toast(s.t('ai_done'), icon: Icons.auto_awesome_rounded);
  }

  Future<void> _action(String a) async {
    final s = AppScope.read(context);
    if (_id == null) return;
    final ok = await _confirm(context, s.t(a == 'delete' ? (widget.builtin ? 'les_restore_q' : 'les_delete_q') : 'les_hide_q'));
    if (!ok || !mounted) return;
    final done = await s.lessonAction(a, _id!, hidden: !_hidden);
    if (!done || !mounted) return;
    if (a == 'hide') {
      setState(() => _hidden = !_hidden);
      s.toast(s.t(_hidden ? 'les_hidden' : 'les_shown'), icon: Icons.check_circle_rounded);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _editStep(int? k, {String? type}) async {
    final src = k == null ? _blankStep(type!) : steps[k];
    final res = await Navigator.of(context).push<Map<String, dynamic>>(
        AppRoute(builder: (_) => PageShell(child: StepEditorScreen(step: _copy(src), course: '${d['course']}'))));
    if (res == null || !mounted) return;
    setState(() {
      final list = steps;
      if (k == null) {
        list.add(res);
      } else {
        list[k] = res;
      }
      steps = list;
    });
  }

  Future<void> _addStep() async {
    final s = AppScope.read(context);
    final t = await showAppSheet<String>(context, builder: (ctx) {
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(s.t('step_add'), style: AppType.title3.copyWith(color: AppScope.of(ctx).c.text)),
        const SizedBox(height: S.x4),
        GroupList([
          for (final (k, i) in const [
            ('read', Icons.auto_stories_rounded),
            ('quiz', Icons.quiz_rounded),
            ('fill', Icons.edit_note_rounded),
            ('order', Icons.reorder_rounded),
            ('try', Icons.code_rounded),
          ])
            GroupRow(
                icon: i, color: _stepColor(k), title: s.t('step_$k'), onTap: () => Navigator.of(ctx).pop(k)),
        ]),
      ]);
    });
    if (t != null) _editStep(null, type: t);
  }

  void _move(int k, int dir) {
    final list = steps;
    final j = k + dir;
    if (j < 0 || j >= list.length) return;
    HapticFeedback.selectionClick();
    setState(() {
      final x = list.removeAt(k);
      list.insert(j, x);
      steps = list;
    });
  }

  void _remove(int k) {
    final list = steps..removeAt(k);
    setState(() => steps = list);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final admin = s.isAdmin;
    final list = steps;
    final leagues = d['leagues'] is List ? {for (final x in d['leagues'] as List) '$x'} : <String>{};
    return TabPage(
      title: s.t(widget.isNew ? 'les_new' : 'les_edit'),
      subtitle: widget.builtin ? s.t('les_builtin_note') : (admin ? s.t('les_global_note') : s.t('les_school_note')),
      children: [
        AppCard(
          padding: const EdgeInsets.all(S.x4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AppTextField(key: const ValueKey('les-title-uz'), controller: _tUz, label: '${s.t('les_title')} · UZ', maxLength: 120),
            const SizedBox(height: S.x3),
            AppTextField(key: const ValueKey('les-title-ru'), controller: _tRu, label: '${s.t('les_title')} · RU', maxLength: 120),
            if (!widget.builtin && _id == null) ...[
              const SizedBox(height: S.x3),
              _CoursePickRow(value: '${d['course']}', onChanged: (v) => setState(() => d['course'] = v)),
            ],
            if (admin) ...[
              const SizedBox(height: S.x3),
              Row(children: [
                Expanded(
                    child: AppTextField(
                        controller: _xp,
                        label: 'XP',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                if (!widget.builtin) ...[
                  const SizedBox(width: S.x3),
                  Expanded(
                      child: AppTextField(
                          controller: _pos,
                          label: s.t('les_pos'),
                          hint: s.t('les_pos_hint'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                ],
              ]),
              const SizedBox(height: S.x3),
              Text(s.t('les_leagues'), style: AppType.footnote.copyWith(color: c.text2, fontWeight: w7)),
              const SizedBox(height: 6),
              Wrap(spacing: S.x2, runSpacing: S.x2, children: [
                for (final lg in const ['beginner', 'advanced', 'master'])
                  _Toggle(
                    label: s.tr(kLeagueNames[lg]!),
                    on: leagues.contains(lg),
                    onTap: () => setState(() {
                      leagues.contains(lg) ? leagues.remove(lg) : leagues.add(lg);
                      d['leagues'] = leagues.isEmpty ? null : leagues.toList();
                    }),
                  ),
              ]),
              const SizedBox(height: 4),
              Text(s.t('les_leagues_hint'), style: AppType.caption.copyWith(color: c.text3)),
            ],
          ]),
        ),
        // AI yordamchi
        AppCard(
          padding: const EdgeInsets.all(S.x4),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: c.isDark ? const [Color(0xFF1C2140), Color(0xFF14182C)] : const [Color(0xFFF1F4FF), Color(0xFFFFFFFF)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const IconTile(Icons.auto_awesome_rounded, size: 34, vivid: true),
              const SizedBox(width: S.x3),
              Expanded(child: Text(s.t('ai_helper'), style: AppType.headline.copyWith(color: c.text))),
              if (_undo != null)
                AppIconButton(Icons.undo_rounded, tooltip: s.t('undo'), size: 36, onPressed: () {
                  setState(() {
                    d = _undo!;
                    _undo = null;
                    _loadHead();
                  });
                }),
            ]),
            const SizedBox(height: S.x3),
            AppTextField(
              key: const ValueKey('ai-revise'),
              controller: _ai,
              hint: s.t('ai_revise_hint'),
              minLines: 2,
              maxLines: 6,
              autocorrect: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: S.x3),
            AppButton(_aiBusy ? s.t('ai_thinking') : s.t('ai_revise'),
                icon: Icons.auto_fix_high_rounded, height: 46, loading: _aiBusy, expand: true, onPressed: _aiRevise),
          ]),
        ),
        SectionHeader(s.t('les_steps'), trailing: AppPill('${list.length}', small: true)),
        for (var k = 0; k < list.length; k++)
          _StepCard(
            step: list[k],
            n: k + 1,
            onTap: () => _editStep(k),
            onUp: k > 0 ? () => _move(k, -1) : null,
            onDown: k < list.length - 1 ? () => _move(k, 1) : null,
            onDelete: list.length > 1 ? () => _remove(k) : null,
          ),
        AppButton(s.t('step_add'), kind: BtnKind.secondary, icon: Icons.add_rounded, height: 46, expand: true, onPressed: _addStep),
        if (_error.isNotEmpty) ErrorBox(_error),
        Row(children: [
          Expanded(
            child: AppButton(s.t('preview'),
                key: const ValueKey('les-preview'), kind: BtnKind.secondary, icon: Icons.play_arrow_rounded, onPressed: _preview),
          ),
          const SizedBox(width: S.x3),
          Expanded(
            child: AppButton(s.t('save'),
                key: const ValueKey('les-save'), icon: Icons.check_rounded, loading: _saving, onPressed: _save),
          ),
        ]),
        if (_id != null)
          GroupList([
            if (admin)
              GroupRow(
                  icon: _hidden ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: const Color(0xFF8E8E93),
                  title: s.t(_hidden ? 'les_show' : 'les_hide'),
                  onTap: () => _action('hide')),
            if (!widget.builtin || kContent[_id]?.data != null)
              GroupRow(
                  icon: widget.builtin ? Icons.restore_rounded : Icons.delete_outline_rounded,
                  color: const Color(0xFFFF3B30),
                  title: s.t(widget.builtin ? 'les_restore' : 'les_delete'),
                  onTap: () => _action('delete')),
          ]),
      ],
    );
  }
}

Future<bool> _confirm(BuildContext context, String text) async {
  final s = AppScope.read(context);
  final r = await showAppSheet<bool>(context, builder: (ctx) {
    final c = AppScope.of(ctx).c;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(text, textAlign: TextAlign.center, style: AppType.headline.copyWith(color: c.text)),
      const SizedBox(height: S.x5),
      AppButton(s.t('ok_yes'), kind: BtnKind.danger, expand: true, onPressed: () => Navigator.of(ctx).pop(true)),
      const SizedBox(height: S.x2),
      AppButton(s.t('cancel'), kind: BtnKind.secondary, expand: true, onPressed: () => Navigator.of(ctx).pop(false)),
    ]);
  });
  return r == true;
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _Toggle({required this.label, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.fast),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: on ? c.accentSoft : c.surfaceAlt,
          borderRadius: R.all(R.pill),
          border: Border.all(color: on ? c.accent : c.hairline),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(on ? Icons.check_circle_rounded : Icons.circle_outlined, size: 16, color: on ? c.accentText : c.text3),
          const SizedBox(width: 6),
          Text(label, style: AppType.footnote.copyWith(color: on ? c.accentText : c.text2, fontWeight: w7)),
        ]),
      ),
    );
  }
}

Color _stepColor(String t) => switch (t) {
      'read' => const Color(0xFF007AFF),
      'quiz' => const Color(0xFF5856D6),
      'fill' => const Color(0xFFFF9500),
      'order' => const Color(0xFF34C759),
      _ => const Color(0xFFFF2D55),
    };

IconData _stepIcon(String t) => switch (t) {
      'read' => Icons.auto_stories_rounded,
      'quiz' => Icons.quiz_rounded,
      'fill' => Icons.edit_note_rounded,
      'order' => Icons.reorder_rounded,
      _ => Icons.code_rounded,
    };

String _trText(Object? v, String lang) {
  final t = trOf(v);
  return t == null ? '' : t.of(lang);
}

Map<String, dynamic> _blankStep(String t) => switch (t) {
      'read' => {
          't': 'read',
          'h': {'uz': '', 'ru': ''},
          'p': {'uz': '', 'ru': ''}
        },
      'quiz' => {
          't': 'quiz',
          'q': {'uz': '', 'ru': ''},
          'o': [
            {'uz': '', 'ru': ''},
            {'uz': '', 'ru': ''},
            {'uz': '', 'ru': ''}
          ],
          'a': 0,
          'd': 1
        },
      'fill' => {
          't': 'fill',
          'q': {'uz': '', 'ru': ''},
          'pre': '',
          'post': '',
          'answers': <String>[],
          'd': 1
        },
      'order' => {
          't': 'order',
          'q': {'uz': '', 'ru': ''},
          'lines': <String>[],
          'd': 1
        },
      _ => {
          't': 'try',
          'mode': 'html',
          'task': {'uz': '', 'ru': ''},
          'start': '',
          'hint': {'uz': '', 'ru': ''},
          'solution': '',
          'must': <String>[],
          'out': <String>[],
          'd': 1
        },
    };

class _StepCard extends StatelessWidget {
  final Map<String, dynamic> step;
  final int n;
  final VoidCallback onTap;
  final VoidCallback? onUp, onDown, onDelete;
  const _StepCard({required this.step, required this.n, required this.onTap, this.onUp, this.onDown, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final t = '${step['t']}';
    final title = _trText(step['h'] ?? step['q'] ?? step['task'], s.lang);
    final anim = step['anim'] is Map ? '${(step['anim'] as Map)['kind']}' : '';
    return AppCard(
      padding: const EdgeInsets.fromLTRB(S.x4, S.x3, S.x2, S.x3),
      onTap: onTap,
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: _stepColor(t), borderRadius: BorderRadius.circular(10)),
          child: Icon(_stepIcon(t), size: 19, color: kWhite),
        ),
        const SizedBox(width: S.x3),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$n · ${s.t('step_$t')}', style: AppType.caption.copyWith(color: c.text2)),
            const SizedBox(height: 2),
            Text(title.isEmpty ? '—' : title,
                maxLines: 2, overflow: TextOverflow.ellipsis, style: AppType.subhead.copyWith(color: c.text)),
            if (anim.isNotEmpty) ...[
              const SizedBox(height: 4),
              AppPill('${s.t('anim')}: $anim', icon: Icons.animation_rounded, tone: Tone.accent, small: true),
            ],
          ]),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          _Mini(Icons.keyboard_arrow_up_rounded, onUp),
          _Mini(Icons.keyboard_arrow_down_rounded, onDown),
        ]),
        _Mini(Icons.close_rounded, onDelete, danger: true),
      ]),
    );
  }
}

class _Mini extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool danger;
  const _Mini(this.icon, this.onTap, {this.danger = false});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Pressable(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.25 : 1,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 22, color: danger ? c.danger : c.text2),
        ),
      ),
    );
  }
}

// ============================================================ bosqich muharriri / редактор шага
/// Ikki tildagi maydon / поле на двух языках.
class _TrCtrl {
  final TextEditingController uz, ru;
  _TrCtrl(Object? v)
      : uz = TextEditingController(text: v is Map ? '${v['uz'] ?? ''}' : (v is String ? v : '')),
        ru = TextEditingController(text: v is Map ? '${v['ru'] ?? ''}' : (v is String ? v : ''));
  Map<String, String> get json => {'uz': uz.text.trim(), 'ru': ru.text.trim()};
  bool get empty => uz.text.trim().isEmpty && ru.text.trim().isEmpty;
  void dispose() {
    uz.dispose();
    ru.dispose();
  }
}

class StepEditorScreen extends StatefulWidget {
  final Map<String, dynamic> step;
  final String course;
  const StepEditorScreen({super.key, required this.step, required this.course});

  @override
  State<StepEditorScreen> createState() => _StepEditorScreenState();
}

class _StepEditorScreenState extends State<StepEditorScreen> {
  late final Map<String, dynamic> st = widget.step;
  late final String t = '${st['t']}';
  late final _main = _TrCtrl(st['h'] ?? st['q'] ?? st['task']);
  late final _body = _TrCtrl(st['p']);
  late final _e = _TrCtrl(st['e'] ?? st['hint']);
  late final _code = TextEditingController(text: '${st['code'] ?? st['start'] ?? ''}');
  late final _pre = TextEditingController(text: '${st['pre'] ?? ''}');
  late final _post = TextEditingController(text: '${st['post'] ?? ''}');
  late final _answers = TextEditingController(text: [for (final a in (st['answers'] as List? ?? const [])) '$a'].join(', '));
  late final _lines = TextEditingController(text: [for (final a in (st['lines'] as List? ?? const [])) '$a'].join('\n'));
  late final _solution = TextEditingController(text: '${st['solution'] ?? ''}');
  late final _must = TextEditingController(text: [for (final a in (st['must'] as List? ?? const [])) '$a'].join('\n'));
  late final _out = TextEditingController(text: [for (final a in (st['out'] as List? ?? const [])) '$a'].join('\n'));
  late final List<_TrCtrl> _opts = [for (final o in (st['o'] as List? ?? const [])) _TrCtrl(o)];
  late int _answer = asInt(st['a']);
  late bool _mono = st['mono'] == true;
  late int _d = asInt(st['d']).clamp(1, 3).toInt();
  late String _mode = '${st['mode'] ?? (widget.course == 'ai' ? 'py' : widget.course)}';
  late Map<String, dynamic>? _anim = st['anim'] is Map ? Map<String, dynamic>.from(st['anim'] as Map) : null;
  String _error = '';

  @override
  void dispose() {
    for (final x in [_main, _body, _e, ..._opts]) {
      x.dispose();
    }
    for (final x in [_code, _pre, _post, _answers, _lines, _solution, _must, _out]) {
      x.dispose();
    }
    super.dispose();
  }

  List<String> _split(String v, {String by = '\n'}) => [for (final x in v.split(by)) if (x.trim().isNotEmpty) x.trimRight()];

  void _done() {
    final s = AppScope.read(context);
    final Map<String, dynamic> out = switch (t) {
      'read' => {
          't': 'read',
          'h': _main.json,
          'p': _body.json,
          if (_code.text.trim().isNotEmpty) 'code': _code.text.trimRight(),
          if (_anim != null) 'anim': _anim,
        },
      'quiz' => {
          't': 'quiz',
          'q': _main.json,
          'o': [for (final o in _opts) o.json],
          'a': _answer,
          if (_code.text.trim().isNotEmpty) 'code': _code.text.trimRight(),
          'mono': _mono,
          if (!_e.empty) 'e': _e.json,
          'd': _d,
        },
      'fill' => {
          't': 'fill',
          'q': _main.json,
          'pre': _pre.text,
          'post': _post.text,
          'answers': _split(_answers.text, by: ',').map((x) => x.trim()).toList(),
          if (!_e.empty) 'e': _e.json,
          'd': _d,
        },
      'order' => {'t': 'order', 'q': _main.json, 'lines': _split(_lines.text), if (!_e.empty) 'e': _e.json, 'd': _d},
      _ => {
          't': 'try',
          'mode': _mode,
          'task': _main.json,
          'start': _code.text,
          'hint': _e.json,
          'solution': _solution.text.trimRight(),
          'must': _split(_must.text).map((x) => x.trim()).toList(),
          'out': _split(_out.text).map((x) => x.trim()).toList(),
          'd': _d,
        },
    };
    if (stepFromJson(out) == null) {
      setState(() => _error = s.t('step_bad'));
      return;
    }
    if (t == 'try') {
      final check = makeCheck([for (final x in out['must'] as List) '$x'], const []);
      if ((out['must'] as List).isNotEmpty && !check(_solution.text, '')) {
        setState(() => _error = s.t('step_must_bad'));
        return;
      }
    }
    Navigator.of(context).pop(out);
  }

  Widget _tr(String label, _TrCtrl ctl, {int lines = 1, String? key}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppTextField(
          key: key == null ? null : ValueKey('$key-uz'),
          controller: ctl.uz,
          label: '$label · UZ',
          minLines: lines,
          maxLines: lines == 1 ? 3 : 12,
          autocorrect: true,
          textCapitalization: TextCapitalization.sentences),
      const SizedBox(height: S.x3),
      AppTextField(
          key: key == null ? null : ValueKey('$key-ru'),
          controller: ctl.ru,
          label: '$label · RU',
          minLines: lines,
          maxLines: lines == 1 ? 3 : 12,
          autocorrect: true,
          textCapitalization: TextCapitalization.sentences),
    ]);
  }

  Widget _codeField(String label, TextEditingController ctl, {int lines = 4, String? hint}) => _CodeField(label: label, ctl: ctl, lines: lines, hint: hint);

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final diff = Segmented<int>(
      values: const [1, 2, 3],
      labels: [s.t('d_easy'), s.t('d_mid'), s.t('d_hard')],
      value: _d,
      onChanged: (v) => setState(() => _d = v),
    );
    return TabPage(
      title: s.t('step_$t'),
      children: [
        if (t == 'read') ...[
          _tr(s.t('f_head'), _main, key: 'st-h'),
          _tr(s.t('f_text'), _body, lines: 4, key: 'st-p'),
          _codeField(s.t('f_code_opt'), _code),
          _AnimBlock(
            anim: _anim,
            lang: widget.course == 'ai' ? 'py' : widget.course,
            onChanged: (a) => setState(() => _anim = a),
          ),
        ],
        if (t == 'quiz') ...[
          _tr(s.t('f_question'), _main, lines: 2, key: 'st-q'),
          _codeField(s.t('f_code_opt'), _code, lines: 3),
          SectionHeader(s.t('f_options')),
          for (var k = 0; k < _opts.length; k++)
            AppCard(
              padding: const EdgeInsets.all(S.x3),
              borderColor: k == _answer ? c.accent : null,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Pressable(
                    onTap: () => setState(() => _answer = k),
                    child: Row(children: [
                      Icon(k == _answer ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: k == _answer ? c.accent : c.text3),
                      const SizedBox(width: 6),
                      Text(k == _answer ? s.t('f_correct') : '${s.t('f_option')} ${k + 1}',
                          style: AppType.footnote.copyWith(color: k == _answer ? c.accentText : c.text2, fontWeight: w7)),
                    ]),
                  ),
                  const Spacer(),
                  if (_opts.length > 2)
                    _Mini(Icons.close_rounded, () {
                      setState(() {
                        _opts.removeAt(k).dispose();
                        if (_answer >= _opts.length) _answer = 0;
                      });
                    }, danger: true),
                ]),
                const SizedBox(height: S.x2),
                AppTextField(controller: _opts[k].uz, hint: 'UZ', autocorrect: true),
                const SizedBox(height: S.x2),
                AppTextField(controller: _opts[k].ru, hint: 'RU', autocorrect: true),
              ]),
            ),
          if (_opts.length < 4)
            AppButton(s.t('f_option_add'),
                kind: BtnKind.secondary, icon: Icons.add_rounded, height: 44, onPressed: () => setState(() => _opts.add(_TrCtrl(null)))),
          _Toggle(label: s.t('f_mono'), on: _mono, onTap: () => setState(() => _mono = !_mono)),
          _tr(s.t('f_explain'), _e, lines: 2),
          diff,
        ],
        if (t == 'fill') ...[
          _tr(s.t('f_question'), _main, lines: 2, key: 'st-q'),
          _codeField(s.t('f_pre'), _pre, lines: 2),
          _codeField(s.t('f_post'), _post, lines: 2),
          AppTextField(controller: _answers, label: s.t('f_answers'), hint: s.t('f_answers_hint')),
          _tr(s.t('f_explain'), _e, lines: 2),
          diff,
        ],
        if (t == 'order') ...[
          _tr(s.t('f_question'), _main, lines: 2, key: 'st-q'),
          _codeField(s.t('f_lines'), _lines, lines: 5, hint: s.t('f_lines_hint')),
          _tr(s.t('f_explain'), _e, lines: 2),
          diff,
        ],
        if (t == 'try') ...[
          Segmented<String>(
            values: const ['html', 'css', 'js', 'py'],
            labels: const ['HTML', 'CSS', 'JS', 'Python'],
            value: const ['html', 'css', 'js', 'py'].contains(_mode) ? _mode : 'html',
            onChanged: (v) => setState(() => _mode = v),
          ),
          _tr(s.t('f_task'), _main, lines: 2, key: 'st-task'),
          _codeField(s.t('f_start'), _code),
          _codeField(s.t('f_solution'), _solution, lines: 5),
          _codeField(s.t('f_must'), _must, lines: 3, hint: s.t('f_must_hint')),
          if (_mode == 'py' || _mode == 'js') _codeField(s.t('f_out'), _out, lines: 2, hint: s.t('f_out_hint')),
          _tr(s.t('f_hint'), _e, lines: 2),
          diff,
        ],
        if (_error.isNotEmpty) ErrorBox(_error),
        AppButton(s.t('done'), key: const ValueKey('step-done'), icon: Icons.check_rounded, expand: true, onPressed: _done),
      ],
    );
  }
}

class _CodeField extends StatelessWidget {
  final String label;
  final TextEditingController ctl;
  final int lines;
  final String? hint;
  const _CodeField({required this.label, required this.ctl, this.lines = 4, this.hint});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(label, style: AppType.footnote.copyWith(color: c.text2, fontWeight: w7)),
      ),
      Container(
        decoration: BoxDecoration(color: c.codeBg, borderRadius: R.all(R.md - 2)),
        padding: const EdgeInsets.symmetric(horizontal: S.x3, vertical: 4),
        child: TextField(
          controller: ctl,
          minLines: lines,
          maxLines: 20,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.multiline,
          style: AppType.mono.copyWith(color: c.codeFg, fontSize: 13),
          cursorColor: c.accent,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle: AppType.mono.copyWith(color: c.codeMuted, fontSize: 13),
          ),
        ),
      ),
    ]);
  }
}

// ============================================================ animatsiya muharriri / редактор анимации
class _AnimBlock extends StatelessWidget {
  final Map<String, dynamic>? anim;
  final String lang;
  final ValueChanged<Map<String, dynamic>?> onChanged;
  const _AnimBlock({required this.anim, required this.lang, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final scene = sceneFromJson(anim);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(s.t('anim')),
      if (scene != null) ...[
        AnimPlayer(key: ValueKey(jsonEncode(anim).hashCode), scene: scene),
        const SizedBox(height: S.x3),
      ] else
        Text(s.t('anim_none'), style: AppType.footnote.copyWith(color: c.text2)),
      const SizedBox(height: S.x2),
      Row(children: [
        Expanded(
          child: AppButton(s.t(scene == null ? 'anim_add' : 'anim_edit'),
              kind: BtnKind.secondary,
              icon: Icons.animation_rounded,
              height: 44,
              onPressed: () async {
                final r = await Navigator.of(context).push<Map<String, dynamic>>(AppRoute(
                    builder: (_) => PageShell(child: AnimEditorScreen(anim: anim == null ? null : _copy(anim!), lang: lang))));
                if (r != null) onChanged(r);
              }),
        ),
        if (scene != null) ...[
          const SizedBox(width: S.x3),
          AppButton(s.t('remove'), kind: BtnKind.danger, height: 44, onPressed: () => onChanged(null)),
        ],
      ]),
    ]);
  }
}

/// Animatsiya qadami (muharrirda) / кадр анимации (в редакторе).
class _FrameCtrl {
  final say = _TrCtrl(null);
  final line = TextEditingController();
  final vars = TextEditingController();
  final out = TextEditingController();
  // render: element / chat: xabar
  final tag = TextEditingController(text: 'p');
  final text = _TrCtrl(null);
  final color = TextEditingController();
  bool me = false;

  void dispose() {
    say.dispose();
    text.dispose();
    for (final x in [line, vars, out, tag, color]) {
      x.dispose();
    }
  }
}

class AnimEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? anim;
  final String lang;
  const AnimEditorScreen({super.key, this.anim, required this.lang});

  @override
  State<AnimEditorScreen> createState() => _AnimEditorScreenState();
}

class _AnimEditorScreenState extends State<AnimEditorScreen> {
  late String kind = _initKind();
  final _code = TextEditingController();
  final _frames = <_FrameCtrl>[];
  Map<String, dynamic>? _keep; // murakkab turlar o‘zgarmaydi / сложные типы не меняются
  int _tick = 0;

  String _initKind() {
    final k = '${widget.anim?['kind'] ?? ''}';
    if (const ['trace', 'render', 'chat'].contains(k)) return k;
    if (k.isNotEmpty) return k;
    return widget.lang == 'html' || widget.lang == 'css' ? 'render' : widget.lang == 'ai' ? 'chat' : 'trace';
  }

  @override
  void initState() {
    super.initState();
    final a = widget.anim;
    if (a != null && !const ['trace', 'render', 'chat'].contains(a['kind'])) {
      _keep = a;
      return;
    }
    _code.text = [for (final x in (a?['code'] as List? ?? const [])) '$x'].join('\n');
    final frames = [for (final f in (a?['frames'] as List? ?? const [])) if (f is Map) f];
    if (kind == 'trace') {
      for (final f in frames) {
        final fc = _FrameCtrl();
        fc.say.uz.text = _trText(f['say'], 'uz');
        fc.say.ru.text = _trText(f['say'], 'ru');
        fc.line.text = '${(asInt(f['line'])) + 1}';
        fc.vars.text = f['vars'] is Map ? [for (final e in (f['vars'] as Map).entries) '${e.key}=${e.value}'].join('; ') : '';
        fc.out.text = [for (final x in (f['out'] as List? ?? const [])) '$x'].join('\n');
        _frames.add(fc);
      }
    } else {
      final items = kind == 'render' ? (a?['els'] as List? ?? const []) : (a?['chat'] as List? ?? const []);
      for (var i = 0; i < items.length; i++) {
        final it = items[i];
        if (it is! Map) continue;
        final fc = _FrameCtrl();
        final f = frames.where((x) => asInt(x['reveal']) == i + 1).firstOrNull;
        if (f != null) {
          fc.say.uz.text = _trText(f['say'], 'uz');
          fc.say.ru.text = _trText(f['say'], 'ru');
        }
        if (kind == 'render') {
          fc.tag.text = '${it['tag'] ?? 'p'}';
          fc.text.uz.text = '${it['text'] ?? ''}';
          fc.line.text = '${asInt(it['line']) + 1}';
          fc.color.text = '${(it['style'] as Map?)?['color'] ?? ''}';
        } else {
          fc.me = it['me'] == true;
          fc.text.uz.text = _trText(it['text'], 'uz');
          fc.text.ru.text = _trText(it['text'], 'ru');
        }
        _frames.add(fc);
      }
    }
    if (_frames.isEmpty) _frames.add(_FrameCtrl());
  }

  @override
  void dispose() {
    _code.dispose();
    for (final f in _frames) {
      f.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _build() {
    if (_keep != null) return _keep!;
    final code = [for (final x in _code.text.split('\n')) x.trimRight()];
    while (code.isNotEmpty && code.last.isEmpty) {
      code.removeLast();
    }
    int ln(TextEditingController t) => ((int.tryParse(t.text.trim()) ?? 1) - 1).clamp(0, code.isEmpty ? 0 : code.length - 1).toInt();
    if (kind == 'trace') {
      return {
        'kind': 'trace',
        'lang': widget.lang == 'js' ? 'js' : 'py',
        'code': code,
        'frames': [
          for (final f in _frames)
            {
              'say': f.say.json,
              'line': ln(f.line),
              'vars': {
                for (final p in f.vars.text.split(';'))
                  if (p.contains('=')) p.split('=').first.trim(): p.split('=').sublist(1).join('=').trim()
              },
              'out': [for (final x in f.out.text.split('\n')) if (x.trim().isNotEmpty) x],
            }
        ],
      };
    }
    if (kind == 'render') {
      return {
        'kind': 'render',
        'lang': 'html',
        'code': code,
        'els': [
          for (final f in _frames)
            {
              'tag': f.tag.text.trim().isEmpty ? 'p' : f.tag.text.trim(),
              'text': f.text.uz.text.trim(),
              'line': ln(f.line),
              if (f.color.text.trim().isNotEmpty) 'style': {'color': f.color.text.trim()},
            }
        ],
        'frames': [
          for (var i = 0; i < _frames.length; i++)
            {'say': _frames[i].say.json, 'line': ln(_frames[i].line), 'reveal': i + 1}
        ],
      };
    }
    return {
      'kind': 'chat',
      'chat': [
        for (final f in _frames) {'me': f.me, 'text': f.text.json}
      ],
      'frames': [
        for (var i = 0; i < _frames.length; i++) {'say': _frames[i].say.json, 'reveal': i + 1}
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final built = _build();
    final scene = sceneFromJson(built);
    return TabPage(
      title: s.t('anim'),
      subtitle: s.t('anim_sub'),
      children: [
        if (scene != null)
          AnimPlayer(key: ValueKey('anim-prev-$_tick-${jsonEncode(built).hashCode}'), scene: scene)
        else
          Text(s.t('anim_none'), style: AppType.footnote.copyWith(color: c.text2)),
        if (_keep != null)
          AppCard(
            padding: const EdgeInsets.all(S.x4),
            child: Text(s.t('anim_keep'), style: AppType.footnote.copyWith(color: c.text2)),
          )
        else ...[
          Segmented<String>(
            values: const ['trace', 'render', 'chat'],
            labels: [s.t('anim_trace'), s.t('anim_render'), s.t('anim_chat')],
            value: kind,
            onChanged: (v) => setState(() => kind = v),
          ),
          if (kind != 'chat') _CodeField(label: s.t('anim_code'), ctl: _code, lines: 4),
          for (var k = 0; k < _frames.length; k++) _frameCard(s, c, k),
          AppButton(s.t('anim_frame_add'),
              kind: BtnKind.secondary, icon: Icons.add_rounded, height: 44, onPressed: () => setState(() => _frames.add(_FrameCtrl()))),
          AppButton(s.t('anim_refresh'),
              kind: BtnKind.ghost, icon: Icons.refresh_rounded, height: 40, onPressed: () => setState(() => _tick++)),
        ],
        AppButton(s.t('done'), icon: Icons.check_rounded, expand: true, onPressed: () {
          if (scene == null) {
            s.toast(s.t('step_bad'), icon: Icons.error_outline_rounded);
            return;
          }
          Navigator.of(context).pop(built);
        }),
      ],
    );
  }

  Widget _frameCard(AppState s, AppColors c, int k) {
    final f = _frames[k];
    return AppCard(
      padding: const EdgeInsets.all(S.x3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          AppPill('${s.t('anim_frame')} ${k + 1}', tone: Tone.accent, small: true),
          const Spacer(),
          if (_frames.length > 1)
            _Mini(Icons.close_rounded, () => setState(() => _frames.removeAt(k).dispose()), danger: true),
        ]),
        const SizedBox(height: S.x2),
        if (kind == 'trace') ...[
          Row(children: [
            SizedBox(
              width: 90,
              child: AppTextField(
                  controller: f.line,
                  label: s.t('anim_line'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
            const SizedBox(width: S.x2),
            Expanded(child: AppTextField(controller: f.vars, label: s.t('anim_vars'), hint: 'x=3; y=5')),
          ]),
          const SizedBox(height: S.x2),
          AppTextField(controller: f.out, label: s.t('anim_out'), minLines: 1, maxLines: 4),
        ],
        if (kind == 'render') ...[
          Row(children: [
            SizedBox(width: 80, child: AppTextField(controller: f.tag, label: 'tag')),
            const SizedBox(width: S.x2),
            SizedBox(
              width: 80,
              child: AppTextField(
                  controller: f.line,
                  label: s.t('anim_line'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
            const SizedBox(width: S.x2),
            Expanded(child: AppTextField(controller: f.color, label: s.t('anim_color'), hint: '#0A6CFF')),
          ]),
          const SizedBox(height: S.x2),
          AppTextField(controller: f.text.uz, label: s.t('anim_el_text')),
        ],
        if (kind == 'chat') ...[
          _Toggle(label: s.t('anim_me'), on: f.me, onTap: () => setState(() => f.me = !f.me)),
          const SizedBox(height: S.x2),
          AppTextField(controller: f.text.uz, label: '${s.t('anim_msg')} · UZ', minLines: 1, maxLines: 4),
          const SizedBox(height: S.x2),
          AppTextField(controller: f.text.ru, label: '${s.t('anim_msg')} · RU', minLines: 1, maxLines: 4),
        ],
        const SizedBox(height: S.x2),
        AppTextField(controller: f.say.uz, label: '${s.t('anim_say')} · UZ', minLines: 1, maxLines: 4),
        const SizedBox(height: S.x2),
        AppTextField(controller: f.say.ru, label: '${s.t('anim_say')} · RU', minLines: 1, maxLines: 4),
      ]),
    );
  }
}

// ============================================================ kitoblar / книги
class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  List<Map<String, dynamic>>? _rows;
  bool _error = false, _uploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final s = AppScope.read(context);
    try {
      final r = await s.staffCall('/api/teacher/books');
      if (mounted) {
        setState(() {
          _rows = [for (final b in (r['books'] as List? ?? const [])) if (b is Map) Map<String, dynamic>.from(b)];
          _error = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  Future<void> _upload() async {
    final s = AppScope.read(context);
    FilePickerResult? pick;
    try {
      pick = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['pdf'], withData: true);
    } catch (_) {
      pick = null;
    }
    final f = pick?.files.firstOrNull;
    final bytes = f?.bytes;
    if (f == null || bytes == null) return;
    if (!mounted) return;
    if (bytes.length > 16 * 1024 * 1024) {
      s.toast(s.t('pdf_big'), icon: Icons.error_outline_rounded);
      return;
    }
    setState(() => _uploading = true);
    try {
      final r = await s.staffCall('/api/teacher/books/upload',
          {'title': f.name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), ''), 'pdf': base64Encode(bytes)},
          const Duration(seconds: 150));
      s.toast('${s.t('pdf_ok')} · ${asInt(r['pages'])} ${s.t('pages')}', icon: Icons.check_circle_rounded);
      await _load();
    } on ApiError catch (e) {
      s.toast(s.aiError(e.code), icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final rows = _rows;
    return TabPage(
      title: s.t('books_tab'),
      subtitle: s.t('books_sub'),
      onRefresh: _load,
      children: [
        AppButton(_uploading ? s.t('pdf_reading') : s.t('pdf_upload'),
            key: const ValueKey('pdf-upload'),
            icon: Icons.upload_file_rounded,
            expand: true,
            loading: _uploading,
            onPressed: _upload),
        Text(s.t('pdf_note'), style: AppType.footnote.copyWith(color: c.text2)),
        if (_error && rows == null)
          EmptyState(icon: Icons.cloud_off_rounded, title: s.t('err_conn'), error: true, actionLabel: s.t('retry'), onAction: _load)
        else if (rows == null)
          const SkeletonRows(count: 2)
        else if (rows.isEmpty)
          EmptyState(icon: Icons.picture_as_pdf_rounded, title: s.t('books_empty'))
        else
          GroupList([
            for (final b in rows)
              GroupRow(
                icon: Icons.picture_as_pdf_rounded,
                color: const Color(0xFFFF3B30),
                title: asStr(b['title']),
                value: '${asInt(b['pages'])} ${s.t('pages')}',
                onTap: () => _push(context, BookScreen(book: b)).then((_) => _load()),
              ),
          ]),
      ],
    );
  }
}

class BookScreen extends StatefulWidget {
  final Map<String, dynamic> book;
  const BookScreen({super.key, required this.book});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  final _from = TextEditingController(text: '1');
  late final _to = TextEditingController(text: '${asInt(widget.book['pages']).clamp(1, 5)}');
  final _wish = TextEditingController();
  String _course = 'html';
  String _busy = '';

  @override
  void dispose() {
    for (final x in [_from, _to, _wish]) {
      x.dispose();
    }
    super.dispose();
  }

  Map<String, Object?> get _body => {
        'id': widget.book['id'],
        'from': int.tryParse(_from.text) ?? 1,
        'to': int.tryParse(_to.text) ?? 1,
        'topic': _wish.text.trim(),
        'course': _course,
      };

  Future<void> _lesson() async {
    final s = AppScope.read(context);
    setState(() => _busy = 'lesson');
    final (l, err) = await s.aiLesson(_body, path: '/api/teacher/books/lesson');
    if (!mounted) return;
    setState(() => _busy = '');
    if (l == null) {
      s.toast(err, icon: Icons.error_outline_rounded);
      return;
    }
    _push(context, LessonEditorScreen(draft: l, isNew: true));
    s.toast(s.t('ai_review'), icon: Icons.auto_awesome_rounded);
  }

  Future<void> _test() async {
    final s = AppScope.read(context);
    setState(() => _busy = 'test');
    try {
      final r = await s.staffCall('/api/teacher/books/test', _body, const Duration(seconds: 150));
      if (!mounted) return;
      final t = r['test'] is Map ? Map<String, dynamic>.from(r['test'] as Map) : <String, dynamic>{};
      final test = <String, dynamic>{
        'title': asStr(t['title']).isEmpty ? asStr(widget.book['title']) : asStr(t['title']),
        'text': '',
        'active': true,
        'questions': [
          for (final q in (t['questions'] as List? ?? const []))
            if (q is Map && (q['type'] == 'quiz' || q['type'] == 'fill')) Map<String, dynamic>.from(q)
        ].take(30).toList(),
      };
      setState(() => _busy = '');
      await Navigator.of(context).push<bool>(AppRoute(builder: (_) => TestEditorScreen(test: test)));
      s.toast(s.t('ai_review'), icon: Icons.auto_awesome_rounded);
    } on ApiError catch (e) {
      if (mounted) setState(() => _busy = '');
      s.toast(s.aiError(e.code), icon: Icons.error_outline_rounded);
    }
  }

  Future<void> _delete() async {
    final s = AppScope.read(context);
    if (!await _confirm(context, s.t('book_delete_q')) || !mounted) return;
    try {
      await s.staffCall('/api/teacher/books/delete', {'id': widget.book['id']});
      if (mounted) Navigator.of(context).pop();
    } on ApiError {
      s.toast(s.t('err_conn'), icon: Icons.cloud_off_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final n = asInt(widget.book['pages']);
    final digits = [FilteringTextInputFormatter.digitsOnly];
    return TabPage(
      title: asStr(widget.book['title']),
      subtitle: '$n ${s.t('pages')}',
      children: [
        _HeroCard(icon: Icons.auto_awesome_rounded, title: s.t('book_ai'), text: s.t('book_ai_sub')),
        Row(children: [
          Expanded(child: AppTextField(controller: _from, label: s.t('page_from'), keyboardType: TextInputType.number, inputFormatters: digits)),
          const SizedBox(width: S.x3),
          Expanded(child: AppTextField(controller: _to, label: s.t('page_to'), keyboardType: TextInputType.number, inputFormatters: digits)),
        ]),
        Text(s.t('page_max'), style: AppType.caption.copyWith(color: c.text3)),
        _CoursePickRow(value: _course, onChanged: (v) => setState(() => _course = v)),
        AppTextField(controller: _wish, label: s.t('book_wish'), hint: s.t('book_wish_hint'), minLines: 2, maxLines: 5, autocorrect: true),
        AppButton(_busy == 'lesson' ? s.t('ai_thinking') : s.t('book_lesson'),
            icon: Icons.menu_book_rounded, expand: true, loading: _busy == 'lesson', onPressed: _busy.isEmpty ? _lesson : null),
        AppButton(_busy == 'test' ? s.t('ai_thinking') : s.t('book_test'),
            kind: BtnKind.secondary,
            icon: Icons.assignment_rounded,
            expand: true,
            loading: _busy == 'test',
            onPressed: _busy.isEmpty ? _test : null),
        if (_busy.isNotEmpty) _AiWait(c: c),
        GroupList([
          GroupRow(icon: Icons.delete_outline_rounded, color: const Color(0xFFFF3B30), title: s.t('book_delete'), onTap: _delete),
        ]),
      ],
    );
  }
}

// ============================================================ o‘quvchi: maktab darslari / ученик: уроки школы
class SchoolLessonsSection extends StatelessWidget {
  final Course course;
  const SchoolLessonsSection({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final list = kSchoolLessons[course.id] ?? const <Lesson>[];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(s.t('school_lessons'), trailing: AppPill(s.t('no_xp'), small: true)),
      const SizedBox(height: S.x3),
      GroupList([
        for (final l in list)
          GroupRow(
            icon: s.schoolDone.contains(l.id) ? Icons.check_rounded : Icons.school_rounded,
            color: s.schoolDone.contains(l.id) ? const Color(0xFF34C759) : courseColor(course, c),
            title: s.tr(l.title),
            onTap: () => openLesson(context, l.id),
          ),
      ]),
    ]);
  }
}
