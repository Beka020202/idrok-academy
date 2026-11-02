// Ustoz testlari: ustoz yaratadi, faqat o‘z maktabi o‘quvchilari ko‘radi. XP berilmaydi.
// Тесты учителя: создаёт учитель, видят только ученики его школы. XP не начисляется.
import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator, CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'profile_form.dart' show ErrorBox;
import 'ranking.dart' show asInt, asStr, rowAvatar;

// ============================================================ USTOZ / УЧИТЕЛЬ
class TeacherTestsTab extends StatefulWidget {
  const TeacherTestsTab({super.key});

  @override
  State<TeacherTestsTab> createState() => _TeacherTestsTabState();
}

class _TeacherTestsTabState extends State<TeacherTestsTab> {
  List<Map<String, dynamic>>? _rows;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final rows = await AppScope.read(context).fetchRows('/api/teacher/tests');
    if (!mounted) return;
    setState(() {
      _error = rows == null;
      if (rows != null) _rows = rows;
    });
  }

  Future<void> _open([Map<String, dynamic>? test]) async {
    final saved = await Navigator.of(context).push<bool>(AppRoute(builder: (_) => TestEditorScreen(test: test)));
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final rows = _rows;
    return TabPage(
      title: s.t('tests_tab'),
      subtitle: s.t('tests_sub'),
      onRefresh: _load,
      trailing: AppIconButton(Icons.add_rounded, key: const ValueKey('test-new'), tooltip: s.t('test_new'), onPressed: _open),
      children: [
        AppCard(
          kind: CardKind.tinted,
          padding: const EdgeInsets.all(S.x4),
          child: Row(children: [
            Icon(Icons.info_rounded, color: c.accentText),
            const SizedBox(width: S.x3),
            Expanded(child: Text(s.t('tests_rule'), style: AppType.footnote.copyWith(color: c.text))),
          ]),
        ),
        if (_error && rows == null)
          EmptyState(icon: Icons.cloud_off_rounded, title: s.t('err_conn'), error: true, actionLabel: s.t('retry'), onAction: _load)
        else if (rows == null)
          const SkeletonRows(count: 3)
        else if (rows.isEmpty)
          EmptyState(
              icon: Icons.assignment_add,
              title: s.t('tests_empty'),
              actionLabel: s.t('test_new'),
              onAction: () => _open())
        else
          for (final t in rows)
            AppCard(
              key: ValueKey('test-${t['id']}'),
              padding: const EdgeInsets.all(S.x4),
              onTap: () => Navigator.of(context).push(AppRoute<void>(builder: (_) => TestResultsScreen(test: t))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const IconTile(Icons.assignment_rounded, size: 40),
                  const SizedBox(width: S.x3),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(asStr(t['title']), style: AppType.headline.copyWith(color: c.text)),
                      Text('${(t['questions'] as List?)?.length ?? 0} ${s.t('questions')}',
                          style: AppType.caption.copyWith(color: c.text2)),
                    ]),
                  ),
                  if (t['active'] != true) AppPill(s.t('test_hidden'), small: true),
                  if (t['mine'] == true)
                    AppIconButton(Icons.edit_rounded, tooltip: s.t('edit'), onPressed: () => _open(t)),
                ]),
                const SizedBox(height: S.x3),
                Row(children: [
                  AppPill('${asInt(t['submitted'])} ${s.t('test_done_n')}', icon: Icons.people_alt_rounded, small: true),
                  const SizedBox(width: S.x2),
                  AppPill('${asInt(t['avg'])}% ${s.t('test_avg')}',
                      icon: Icons.insights_rounded, tone: Tone.accent, small: true),
                ]),
              ]),
            ),
      ],
    );
  }
}

class _QEdit {
  String type;
  final q = TextEditingController();
  final opts = <TextEditingController>[];
  final answers = TextEditingController();
  int answer = 0;
  _QEdit(this.type) {
    if (type == 'quiz') {
      opts.addAll([TextEditingController(), TextEditingController()]);
    }
  }

  factory _QEdit.from(Map<String, dynamic> m) {
    final e = _QEdit('${m['type']}');
    e.q.text = '${m['q'] ?? ''}';
    if (e.type == 'quiz') {
      e.opts.clear();
      for (final o in (m['options'] as List? ?? const [])) {
        e.opts.add(TextEditingController(text: '$o'));
      }
      e.answer = asInt(m['answer']);
    } else {
      e.answers.text = [for (final a in (m['answers'] as List? ?? const [])) '$a'].join(', ');
    }
    return e;
  }

  Map<String, Object?> toJson() => type == 'quiz'
      ? {'type': 'quiz', 'q': q.text.trim(), 'options': [for (final o in opts) o.text.trim()], 'answer': answer}
      : {
          'type': 'fill',
          'q': q.text.trim(),
          'answers': [for (final a in answers.text.split(',')) if (a.trim().isNotEmpty) a.trim()],
        };

  bool get valid => type == 'quiz'
      ? q.text.trim().isNotEmpty && opts.every((o) => o.text.trim().isNotEmpty) && answer < opts.length
      : q.text.trim().isNotEmpty && answers.text.trim().isNotEmpty;

  void dispose() {
    q.dispose();
    answers.dispose();
    for (final o in opts) {
      o.dispose();
    }
  }
}

/// Test yaratish / tahrirlash / создание и редактирование теста.
class TestEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? test;
  const TestEditorScreen({super.key, this.test});

  @override
  State<TestEditorScreen> createState() => _TestEditorScreenState();
}

class _TestEditorScreenState extends State<TestEditorScreen> {
  final _title = TextEditingController();
  final _text = TextEditingController();
  final _qs = <_QEdit>[];
  bool _active = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    final t = widget.test;
    if (t != null) {
      _title.text = asStr(t['title']);
      _text.text = asStr(t['text']);
      _active = t['active'] != false;
      for (final q in (t['questions'] as List? ?? const [])) {
        if (q is Map) _qs.add(_QEdit.from(Map<String, dynamic>.from(q)));
      }
    }
    if (_qs.isEmpty) _qs.add(_QEdit('quiz'));
  }

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    for (final q in _qs) {
      q.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final s = AppScope.read(context);
    FocusManager.instance.primaryFocus?.unfocus();
    if (_title.text.trim().isEmpty || _qs.isEmpty || !_qs.every((q) => q.valid)) {
      setState(() => _error = s.t('test_invalid'));
      return;
    }
    setState(() => _error = '');
    final res = await s.post('/api/teacher/tests/save', {
      if (widget.test != null) 'id': widget.test!['id'],
      'title': _title.text.trim(),
      'text': _text.text.trim(),
      'active': _active,
      'questions': [for (final q in _qs) q.toJson()],
    });
    if (res != null && mounted) {
      s.toast(s.t('test_saved'), icon: Icons.check_circle_rounded);
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _delete() async {
    final s = AppScope.read(context);
    final res = await s.post('/api/teacher/tests/delete', {'id': widget.test!['id']});
    if (res != null && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
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
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(S.page, S.x3, S.page, S.x8),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    Row(children: [
                      AppIconButton(Icons.close_rounded, tooltip: s.t('back'), onPressed: () => Navigator.of(context).maybePop()),
                      const Spacer(),
                      if (widget.test != null)
                        AppIconButton(Icons.delete_outline_rounded, tooltip: s.t('delete'), color: c.danger, onPressed: _delete),
                    ]),
                    const SizedBox(height: S.x4),
                    LargeTitle(widget.test == null ? s.t('test_new') : s.t('test_edit')),
                    const SizedBox(height: S.x5),
                    AppCard(
                      padding: const EdgeInsets.all(S.x4),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        AppTextField(
                          key: const ValueKey('test-title'),
                          controller: _title,
                          label: s.t('test_title'),
                          icon: Icons.title_rounded,
                          maxLength: 80,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: S.x4),
                        AppTextField(
                          key: const ValueKey('test-text'),
                          controller: _text,
                          label: s.t('test_text'),
                          hint: s.t('test_text_hint'),
                          minLines: 3,
                          maxLines: 8,
                          maxLength: 3000,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: S.x3),
                        Row(children: [
                          Expanded(child: Text(s.t('test_visible'), style: AppType.subhead.copyWith(color: c.text))),
                          CupertinoSwitch(
                            value: _active,
                            activeTrackColor: c.accent,
                            onChanged: (v) => setState(() => _active = v),
                          ),
                        ]),
                      ]),
                    ),
                    for (var k = 0; k < _qs.length; k++) ...[
                      const SizedBox(height: S.x4),
                      _QuestionCard(
                        key: ObjectKey(_qs[k]),
                        index: k,
                        q: _qs[k],
                        onRemove: _qs.length > 1
                            ? () => setState(() {
                                  _qs.removeAt(k).dispose();
                                })
                            : null,
                        onChanged: () => setState(() {}),
                      ),
                    ],
                    const SizedBox(height: S.x4),
                    Row(children: [
                      Expanded(
                        child: AppButton(s.t('q_add_quiz'),
                            key: const ValueKey('q-add-quiz'),
                            kind: BtnKind.secondary,
                            icon: Icons.list_rounded,
                            height: 46,
                            onPressed: _qs.length >= 30 ? null : () => setState(() => _qs.add(_QEdit('quiz')))),
                      ),
                      const SizedBox(width: S.x2),
                      Expanded(
                        child: AppButton(s.t('q_add_fill'),
                            key: const ValueKey('q-add-fill'),
                            kind: BtnKind.secondary,
                            icon: Icons.edit_note_rounded,
                            height: 46,
                            onPressed: _qs.length >= 30 ? null : () => setState(() => _qs.add(_QEdit('fill')))),
                      ),
                    ]),
                    if (_error.isNotEmpty) ...[const SizedBox(height: S.x4), ErrorBox(_error)],
                    const SizedBox(height: S.x5),
                    AppButton(s.t('save'),
                        key: const ValueKey('test-save'),
                        onPressed: s.busy ? null : _save,
                        loading: s.busy,
                        expand: true,
                        height: 56,
                        icon: Icons.check_rounded),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final _QEdit q;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;
  const _QuestionCard({super.key, required this.index, required this.q, required this.onRemove, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    return AppCard(
      padding: const EdgeInsets.all(S.x4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          AppPill('${index + 1}', tone: Tone.accent, small: true),
          const SizedBox(width: S.x2),
          Expanded(
            child: Text(s.t(q.type == 'quiz' ? 'q_quiz' : 'q_fill').toUpperCase(),
                style: AppType.overline.copyWith(color: c.accentText)),
          ),
          if (onRemove != null) AppIconButton(Icons.close_rounded, size: 34, tooltip: s.t('delete'), onPressed: onRemove),
        ]),
        const SizedBox(height: S.x3),
        AppTextField(
          key: ValueKey('q-text-$index'),
          controller: q.q,
          hint: s.t('q_text'),
          minLines: 1,
          maxLines: 4,
          maxLength: 400,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: S.x3),
        if (q.type == 'quiz') ...[
          for (var k = 0; k < q.opts.length; k++)
            Padding(
              padding: const EdgeInsets.only(bottom: S.x2),
              child: Row(children: [
                Pressable(
                  key: ValueKey('q-$index-correct-$k'),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    q.answer = k;
                    onChanged();
                  },
                  child: AnimatedContainer(
                    duration: Motion.of(context, Motion.fast),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: q.answer == k ? c.yellow : const Color(0x00000000),
                      border: Border.all(color: q.answer == k ? c.yellow : c.hairlineStrong, width: 2),
                    ),
                    child: q.answer == k ? const Icon(Icons.check_rounded, size: 18, color: kWhite) : null,
                  ),
                ),
                const SizedBox(width: S.x2),
                Expanded(
                  child: AppTextField(
                    key: ValueKey('q-$index-opt-$k'),
                    controller: q.opts[k],
                    hint: '${s.t('q_option')} ${k + 1}',
                    maxLength: 200,
                  ),
                ),
                if (q.opts.length > 2)
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline_rounded, color: c.text3),
                    onPressed: () {
                      q.opts.removeAt(k).dispose();
                      if (q.answer >= q.opts.length) q.answer = 0;
                      onChanged();
                    },
                  ),
              ]),
            ),
          if (q.opts.length < 4)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  q.opts.add(TextEditingController());
                  onChanged();
                },
                icon: Icon(Icons.add_rounded, color: c.accentText),
                label: Text(s.t('q_option_add'), style: AppType.subhead.copyWith(color: c.accentText)),
              ),
            ),
          Text(s.t('q_mark_correct'), style: AppType.caption.copyWith(color: c.text3)),
        ] else
          AppTextField(
            key: ValueKey('q-$index-answers'),
            controller: q.answers,
            label: s.t('q_answers'),
            hint: s.t('q_answers_hint'),
            maxLength: 300,
          ),
      ]),
    );
  }
}

/// Test natijalari / результаты теста.
class TestResultsScreen extends StatefulWidget {
  final Map<String, dynamic> test;
  const TestResultsScreen({super.key, required this.test});

  @override
  State<TestResultsScreen> createState() => _TestResultsScreenState();
}

class _TestResultsScreenState extends State<TestResultsScreen> {
  List<Map<String, dynamic>>? _rows;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final rows = await AppScope.read(context).fetchRows('/api/teacher/results?id=${widget.test['id']}');
      if (!mounted) return;
      setState(() {
        _error = rows == null;
        _rows = rows;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final rows = _rows;
    return Scaffold(
      backgroundColor: c.bg,
      body: AppBackground(
        child: SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(S.page, S.x3, S.page, S.x8), children: [
            Row(children: [
              AppIconButton(Icons.arrow_back_rounded, tooltip: s.t('back'), onPressed: () => Navigator.of(context).maybePop()),
            ]),
            const SizedBox(height: S.x4),
            LargeTitle(asStr(widget.test['title']), subtitle: s.t('test_results')),
            const SizedBox(height: S.x5),
            if (_error)
              EmptyState(icon: Icons.cloud_off_rounded, title: s.t('err_conn'), error: true)
            else if (rows == null)
              Center(child: CupertinoActivityIndicator(color: c.text2))
            else if (rows.isEmpty)
              EmptyState(icon: Icons.hourglass_empty_rounded, title: s.t('test_no_results'))
            else
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: S.x4, vertical: S.x2),
                child: Column(children: [
                  for (var k = 0; k < rows.length; k++) ...[
                    if (k > 0) Divider(height: 1, color: c.hairline),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: S.x3),
                      child: Row(children: [
                        rowAvatar(s, rows[k], size: 40),
                        const SizedBox(width: S.x3),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(asStr(rows[k]['name']), style: AppType.subhead.copyWith(color: c.text, fontWeight: w8)),
                            Text('${asInt(rows[k]['tries'])} ${s.t('tries')}', style: AppType.caption.copyWith(color: c.text2)),
                          ]),
                        ),
                        AppPill('${asInt(rows[k]['best'])}/${asInt(rows[k]['total'])}',
                            tone: asInt(rows[k]['best']) == asInt(rows[k]['total']) ? Tone.yellow : Tone.accent),
                      ]),
                    ),
                  ],
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}

// ============================================================ O‘QUVCHI / УЧЕНИК
/// Kurslar sahifasidagi “Ustozingiz testlari” bo‘limi / раздел «Тесты учителя» на странице курсов.
class SchoolTestsSection extends StatefulWidget {
  const SchoolTestsSection({super.key});

  @override
  State<SchoolTestsSection> createState() => _SchoolTestsSectionState();
}

class _SchoolTestsSectionState extends State<SchoolTestsSection> {
  List<Map<String, dynamic>>? _rows;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final s = AppScope.read(context);
    if (!s.online || !s.isStudent) return;
    final rows = await s.fetchRows('/api/tests');
    if (mounted && rows != null) setState(() => _rows = rows);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final rows = _rows;
    if (rows == null || rows.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(s.t('school_tests')),
      const SizedBox(height: S.x3),
      for (final t in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: S.x3),
          child: AppCard(
            key: ValueKey('stest-${t['id']}'),
            padding: const EdgeInsets.all(S.x4),
            onTap: () async {
              await Navigator.of(context).push(AppRoute<void>(builder: (_) => StudentTestScreen(test: t)));
              _load();
            },
            child: Row(children: [
              const IconTile(Icons.assignment_ind_rounded, size: 42),
              const SizedBox(width: S.x3),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(asStr(t['title']), style: AppType.headline.copyWith(color: c.text)),
                  Text('${(t['questions'] as List?)?.length ?? 0} ${s.t('questions')} · ${s.t('from_teacher')}',
                      style: AppType.caption.copyWith(color: c.text2)),
                ]),
              ),
              if (t['result'] is Map)
                AppPill('${asInt((t['result'] as Map)['best'])}/${asInt((t['result'] as Map)['total'])}',
                    icon: Icons.check_rounded, tone: Tone.yellow, small: true)
              else
                Icon(Icons.chevron_right_rounded, color: c.text3),
            ]),
          ),
        ),
    ]);
  }
}

/// O‘quvchi ustoz testini yechadi / ученик проходит тест учителя.
class StudentTestScreen extends StatefulWidget {
  final Map<String, dynamic> test;
  const StudentTestScreen({super.key, required this.test});

  @override
  State<StudentTestScreen> createState() => _StudentTestScreenState();
}

class _StudentTestScreenState extends State<StudentTestScreen> {
  late final List<Map<String, dynamic>> qs = [
    for (final q in (widget.test['questions'] as List? ?? const [])) if (q is Map) Map<String, dynamic>.from(q)
  ];
  late int i = asStr(widget.test['text']).isEmpty ? 0 : -1; // -1 — tushuntirish / объяснение
  final answers = <Object?>[];
  final _fill = TextEditingController();
  int? sel;
  Map<String, dynamic>? result;
  bool sending = false;

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (i >= 0) answers.add(qs[i]['type'] == 'quiz' ? sel : _fill.text.trim());
    if (i + 1 < qs.length) {
      setState(() {
        i++;
        sel = null;
        _fill.clear();
      });
      return;
    }
    setState(() => sending = true);
    final s = AppScope.read(context);
    final res = await s.post('/api/tests/submit', {'test_id': widget.test['id'], 'answers': answers});
    if (!mounted) return;
    setState(() {
      sending = false;
      result = res;
      if (res == null) answers.removeLast();
    });
    if (res != null) HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    Widget content;
    Widget? action;
    final r = result;
    if (r != null) {
      final key = r['key'] is List ? r['key'] as List : const [];
      content = ListView(children: [
        const SizedBox(height: S.x6),
        Center(
          child: Container(
            width: 112,
            height: 112,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: c.accentGradient),
            child: Text('${asInt(r['correct'])}/${asInt(r['total'])}',
                style: AppType.title1.copyWith(color: kWhite, shadows: kTextShadow)),
          ),
        ),
        const SizedBox(height: S.x4),
        Text(s.t('test_finished'), textAlign: TextAlign.center, style: AppType.title2.copyWith(color: c.text)),
        const SizedBox(height: S.x2),
        Text(s.t('test_no_xp'), textAlign: TextAlign.center, style: AppType.footnote.copyWith(color: c.text2)),
        const SizedBox(height: S.x5),
        for (var k = 0; k < qs.length; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: S.x2),
            child: AppCard(
              padding: const EdgeInsets.all(S.x3 + 2),
              radius: R.lg,
              child: Builder(builder: (_) {
                final q = qs[k];
                final kk = k < key.length && key[k] is Map ? key[k] as Map : const {};
                final a = k < answers.length ? answers[k] : null;
                final right = q['type'] == 'quiz'
                    ? asStr((q['options'] as List)[asInt(kk['answer'])])
                    : [for (final x in (kk['answers'] as List? ?? const [])) '$x'].join(' / ');
                final ok = q['type'] == 'quiz'
                    ? a == kk['answer']
                    : (kk['answers'] as List? ?? const []).any((x) => '$x'.toLowerCase() == '${a ?? ''}'.toLowerCase());
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(ok ? Icons.check_circle_rounded : Icons.cancel_rounded, color: ok ? c.yellow : c.danger, size: 20),
                  const SizedBox(width: S.x2),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(asStr(q['q']), style: AppType.subhead.copyWith(color: c.text, fontWeight: w7)),
                      if (!ok)
                        Text('${s.t('answer')}: $right', style: AppType.footnote.copyWith(color: c.text2)),
                    ]),
                  ),
                ]);
              }),
            ),
          ),
      ]);
      action = AppButton(s.t('back'),
          key: const ValueKey('stest-back'), expand: true, onPressed: () => Navigator.of(context).maybePop());
    } else if (i < 0) {
      content = ListView(children: [
        Text(asStr(widget.test['title']), style: AppType.title1.copyWith(color: c.text)),
        const SizedBox(height: S.x4),
        Text(asStr(widget.test['text']), style: AppType.body.copyWith(color: c.text, fontSize: 17)),
      ]);
      action = AppButton(s.t('next'), key: const ValueKey('stest-next'), expand: true, onPressed: _next);
    } else {
      final q = qs[i];
      final opts = q['type'] == 'quiz' ? [for (final o in (q['options'] as List)) '$o'] : const <String>[];
      content = ListView(children: [
        Text('${i + 1} / ${qs.length}', style: AppType.caption.copyWith(color: c.text3)),
        const SizedBox(height: S.x2),
        Text(asStr(q['q']), style: AppType.title2.copyWith(color: c.text)),
        const SizedBox(height: S.x5),
        if (q['type'] == 'quiz')
          for (var k = 0; k < opts.length; k++)
            Padding(
              padding: const EdgeInsets.only(bottom: S.x3),
              child: AppCard(
                key: ValueKey('sopt-$k'),
                onTap: () => setState(() => sel = k),
                padding: const EdgeInsets.all(S.x4),
                radius: R.lg,
                kind: sel == k ? CardKind.tinted : CardKind.solid,
                borderColor: sel == k ? c.accent : null,
                child: Text(opts[k], style: AppType.bodyStrong.copyWith(color: c.text)),
              ),
            )
        else
          AppTextField(
            key: const ValueKey('sfill'),
            controller: _fill,
            hint: s.t('type_here'),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _next(),
          ),
      ]);
      final ready = q['type'] == 'quiz' ? sel != null : _fill.text.trim().isNotEmpty;
      action = AppButton(i + 1 < qs.length ? s.t('next') : s.t('test_submit'),
          key: const ValueKey('stest-next'),
          expand: true,
          loading: sending,
          onPressed: ready && !sending ? _next : null);
    }

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: c.bg,
        body: AppBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(S.page, S.x3, S.page, S.x3),
              child: Column(children: [
                Row(children: [
                  AppIconButton(Icons.close_rounded, tooltip: s.t('back'), onPressed: () => Navigator.of(context).maybePop()),
                  const SizedBox(width: S.x3),
                  Expanded(
                    child: AppProgress(result != null ? 1 : (i < 0 ? 0 : i / qs.length), height: 10, gradient: c.accentGradient),
                  ),
                ]),
                const SizedBox(height: S.x5),
                Expanded(child: content),
                const SizedBox(height: S.x3),
                action,
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
