// Darslar JSON ko‘rinishida (admin va ustozlar yaratadi, AI yordam beradi).
// Уроки в виде JSON (создают админ и учителя, помогает AI).
//
// Format:
// {"title":{"uz","ru"},"course":"html","xp":20,"leagues":null,"pos":null,"steps":[
//   {"t":"read","h":Tr,"p":Tr,"code":"...","anim":Scene},
//   {"t":"quiz","q":Tr,"o":[Tr],"a":0,"code":"...","mono":false,"e":Tr,"d":1},
//   {"t":"fill","q":Tr,"pre":"","post":"","answers":["..."],"e":Tr,"d":1},
//   {"t":"order","q":Tr,"lines":["..."],"e":Tr,"d":1},
//   {"t":"try","mode":"html","task":Tr,"start":"","hint":Tr,"solution":"","must":["<h1>"],"out":["Salom"],"d":1}]}
import 'model.dart';

Tr? trOf(Object? v) {
  if (v is Map) {
    final uz = '${v['uz'] ?? ''}'.trim(), ru = '${v['ru'] ?? ''}'.trim();
    if (uz.isEmpty && ru.isEmpty) return null;
    return Tr(uz.isEmpty ? ru : uz, ru.isEmpty ? uz : ru);
  }
  if (v is String && v.trim().isNotEmpty) return Tr.same(v.trim());
  return null;
}

Map<String, String> trJson(Tr t) => {'uz': t.uz, 'ru': t.ru};

int _int(Object? v, int d) => v is int ? v : v is num ? v.toInt() : int.tryParse('$v') ?? d;
List<String> _strs(Object? v) => v is List ? [for (final x in v) '$x'] : v is String ? v.split('\n') : const [];

// ---------------------------------------------------------------- animatsiya / анимация
AnimScene? sceneFromJson(Object? raw) {
  if (raw is! Map) return null;
  final kind = '${raw['kind'] ?? ''}';
  if (!const ['trace', 'render', 'box', 'flex', 'learn', 'chat', 'grid'].contains(kind)) return null;
  final frames = <AnimFrame>[];
  for (final f in raw['frames'] is List ? raw['frames'] as List : const []) {
    if (f is! Map) continue;
    final vars = f['vars'] is Map ? {for (final e in (f['vars'] as Map).entries) '${e.key}': '${e.value}'} : <String, String>{};
    final extra = f['extra'] is Map ? {for (final e in (f['extra'] as Map).entries) if (e.value != null) '${e.key}': e.value as Object} : <String, Object>{};
    frames.add(AnimFrame(
      say: trOf(f['say']) ?? const Tr('', ''),
      line: _int(f['line'], -1),
      vars: vars,
      hot: f['hot'] == null ? null : '${f['hot']}',
      out: _strs(f['out']),
      arr: f['arr'] is List ? _strs(f['arr']) : null,
      arrName: '${f['arrName'] ?? ''}',
      arrHot: _int(f['arrHot'], -1),
      reveal: _int(f['reveal'], 0),
      extra: extra,
    ));
  }
  if (frames.isEmpty) return null;
  final els = <RenderEl>[
    for (final e in raw['els'] is List ? raw['els'] as List : const [])
      if (e is Map)
        RenderEl('${e['tag'] ?? 'p'}', '${e['text'] ?? ''}', _int(e['line'], 0),
            style: e['style'] is Map ? {for (final s in (e['style'] as Map).entries) '${s.key}': '${s.value}'} : const {}),
  ];
  final chat = <(bool, Tr)>[
    for (final m in raw['chat'] is List ? raw['chat'] as List : const [])
      if (m is Map && trOf(m['text']) != null) (m['me'] == true, trOf(m['text'])!),
  ];
  final points = <(double, double, int)>[
    for (final p in raw['points'] is List ? raw['points'] as List : const [])
      if (p is List && p.length >= 3) ((p[0] as num).toDouble(), (p[1] as num).toDouble(), (p[2] as num).toInt()),
  ];
  final grids = <List<int>>[
    for (final g in raw['grids'] is List ? raw['grids'] as List : const [])
      if (g is List) [for (final x in g) _int(x, 0)],
  ];
  return AnimScene(
      kind: kind,
      lang: '${raw['lang'] ?? ''}',
      code: _strs(raw['code']),
      frames: frames,
      els: els,
      chat: chat,
      points: points,
      grids: grids);
}

Map<String, Object?> sceneToJson(AnimScene s) => {
      'kind': s.kind,
      'lang': s.lang,
      'code': s.code,
      'frames': [
        for (final f in s.frames)
          {
            'say': trJson(f.say),
            'line': f.line,
            if (f.vars.isNotEmpty) 'vars': f.vars,
            if (f.hot != null) 'hot': f.hot,
            'out': f.out,
            if (f.arr != null) ...{'arr': f.arr, 'arrName': f.arrName, 'arrHot': f.arrHot},
            'reveal': f.reveal,
            if (f.extra.isNotEmpty) 'extra': f.extra,
          }
      ],
      if (s.els.isNotEmpty)
        'els': [
          for (final e in s.els) {'tag': e.tag, 'text': e.text, 'line': e.line, if (e.style.isNotEmpty) 'style': e.style}
        ],
      if (s.chat.isNotEmpty) 'chat': [for (final m in s.chat) {'me': m.$1, 'text': trJson(m.$2)}],
      if (s.points.isNotEmpty) 'points': [for (final p in s.points) [p.$1, p.$2, p.$3]],
      if (s.grids.isNotEmpty) 'grids': s.grids,
    };

// ---------------------------------------------------------------- tekshiruv / проверка
/// Amaliyot tekshiruvi: kodda kerakli qismlar bor va natijada kerakli matn chiqdi.
/// Проверка практики: в коде есть нужные части и в выводе есть нужный текст.
CodeCheck makeCheck(List<String> must, List<String> out) {
  final m = [for (final x in must) if (x.trim().isNotEmpty) _norm(x)];
  final o = [for (final x in out) if (x.trim().isNotEmpty) _norm(x)];
  return (code, output) {
    final c = _norm(code), r = _norm(output);
    if (c.trim().isEmpty) return false;
    return m.every(c.contains) && o.every(r.contains);
  };
}

String _norm(String v) => v.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').replaceAll("'", '"').trim();

/// Asl dars yechimidan majburiy qismlarni chiqaradi (tahrirlash uchun boshlang‘ich qiymat).
/// Достаёт обязательные части из решения встроенного урока (начальное значение для редактора).
List<String> guessMust(String mode, String solution) {
  final out = <String>{};
  if (mode == 'html') {
    for (final m in RegExp(r'<([a-zA-Z][a-zA-Z0-9]*)').allMatches(solution)) {
      out.add('<${m.group(1)!.toLowerCase()}');
    }
  } else if (mode == 'css') {
    for (final m in RegExp(r'([a-z-]+)\s*:').allMatches(solution)) {
      out.add('${m.group(1)}:');
    }
  } else {
    for (final m in RegExp(r'\b(print|input|console\.log|for|while|if|def|function|return|range|let|const|len|append)\b')
        .allMatches(solution)) {
      out.add(m.group(1)!);
    }
  }
  return out.take(6).toList();
}

// ---------------------------------------------------------------- bosqich / шаг
LessonStep? stepFromJson(Object? raw) {
  if (raw is! Map) return null;
  final d = _int(raw['d'], 1).clamp(1, 3).toInt();
  switch ('${raw['t']}') {
    case 'read':
      final h = trOf(raw['h']), p = trOf(raw['p']);
      if (h == null || p == null) return null;
      final code = '${raw['code'] ?? ''}';
      return LessonStep.read(h: h, p: p, code: code.isEmpty ? null : code, anim: sceneFromJson(raw['anim']));
    case 'quiz':
      final q = trOf(raw['q']);
      final o = <Tr>[for (final x in raw['o'] is List ? raw['o'] as List : const []) if (trOf(x) != null) trOf(x)!];
      final a = _int(raw['a'], -1);
      if (q == null || o.length < 2 || a < 0 || a >= o.length) return null;
      final code = '${raw['code'] ?? ''}';
      return LessonStep.quiz(
          q: q, o: o, answer: a, code: code.isEmpty ? null : code, mono: raw['mono'] == true, e: trOf(raw['e']), difficulty: d);
    case 'fill':
      final q = trOf(raw['q']);
      final ans = [for (final x in _strs(raw['answers'])) if (x.trim().isNotEmpty) x.trim()];
      if (q == null || ans.isEmpty) return null;
      return LessonStep.fill(
          q: q, pre: '${raw['pre'] ?? ''}', post: '${raw['post'] ?? ''}', answers: ans, e: trOf(raw['e']), difficulty: d);
    case 'order':
      final q = trOf(raw['q']);
      final lines = [for (final x in _strs(raw['lines'])) if (x.trim().isNotEmpty) x];
      if (q == null || lines.length < 2) return null;
      return LessonStep.order(q: q, lines: lines, e: trOf(raw['e']), difficulty: d);
    case 'try':
      final task = trOf(raw['task']);
      final mode = '${raw['mode'] ?? 'html'}';
      if (task == null || !const ['html', 'css', 'js', 'py', 'text'].contains(mode)) return null;
      final sol = '${raw['solution'] ?? ''}';
      var must = _strs(raw['must']);
      if (must.isEmpty && raw['out'] == null) must = guessMust(mode, sol);
      return LessonStep.tryIt(
          mode: mode,
          task: task,
          start: '${raw['start'] ?? ''}',
          hint: trOf(raw['hint']) ?? const Tr('', ''),
          check: makeCheck(must, _strs(raw['out'])),
          solution: sol,
          difficulty: d);
  }
  return null;
}

/// Bosqichni JSON ga (o‘rnatilgan darsni tahrirlash uchun) / шаг в JSON (для правки встроенного урока).
Map<String, Object?> stepToJson(LessonStep s, {List<String>? must, List<String>? out}) {
  Map<String, String>? e(Tr? t) => t == null ? null : trJson(t);
  return switch (s.type) {
    StepType.read => {
        't': 'read',
        'h': e(s.h),
        'p': e(s.p),
        if (s.code != null) 'code': s.code,
        if (s.anim != null) 'anim': sceneToJson(s.anim!),
      },
    StepType.quiz => {
        't': 'quiz',
        'q': e(s.q),
        'o': [for (final o in s.options) trJson(o)],
        'a': s.answer,
        if (s.code != null) 'code': s.code,
        'mono': s.mono,
        if (s.e != null) 'e': e(s.e),
        'd': s.difficulty,
      },
    StepType.fill => {
        't': 'fill',
        'q': e(s.q),
        'pre': s.pre ?? '',
        'post': s.post ?? '',
        'answers': s.answers,
        if (s.e != null) 'e': e(s.e),
        'd': s.difficulty,
      },
    StepType.order => {'t': 'order', 'q': e(s.q), 'lines': s.lines, if (s.e != null) 'e': e(s.e), 'd': s.difficulty},
    StepType.tryIt => {
        't': 'try',
        'mode': s.mode,
        'task': e(s.task),
        'start': s.start ?? '',
        'hint': e(s.hint),
        'solution': s.solution ?? '',
        'must': must ?? guessMust(s.mode ?? 'html', s.solution ?? ''),
        'out': out ?? const <String>[],
        'd': s.difficulty,
      },
  };
}

// ---------------------------------------------------------------- dars / урок
/// Ma’lumotdan dars. Variantlar har urinishda aralashtiriladi.
/// Урок из данных. Варианты перемешиваются при каждой попытке.
Lesson? lessonFromJson(String id, Object? raw, {String source = 'global', int? xp, String? course}) {
  if (raw is! Map) return null;
  final title = trOf(raw['title']);
  final steps = <LessonStep>[
    for (final x in raw['steps'] is List ? raw['steps'] as List : const [])
      if (stepFromJson(x) != null) stepFromJson(x)!
  ];
  final co = course ?? '${raw['course'] ?? ''}';
  if (title == null || steps.isEmpty || co.isEmpty) return null;
  final lg = raw['leagues'] is List ? {for (final x in raw['leagues'] as List) '$x'} : null;
  return Lesson(
    id: id,
    courseId: co,
    xp: source == 'school' || source == 'preview' ? 0 : (xp ?? _int(raw['xp'], 20)),
    title: title,
    leagues: lg == null || lg.isEmpty ? null : lg,
    source: source,
    builder: (g) => [
      for (final s in steps)
        if (s.type == StepType.quiz) _shuffleQuiz(g, s) else s
    ],
  );
}

LessonStep _shuffleQuiz(Gen g, LessonStep s) {
  final right = s.options[s.answer];
  final opts = g.shuffled(s.options);
  return LessonStep.quiz(
      q: s.q!, o: opts, answer: opts.indexOf(right), code: s.code, mono: s.mono, e: s.e, difficulty: s.difficulty);
}

/// Darsni JSON ga (bitta urinish nusxasi) / урок в JSON (снимок одной попытки).
Map<String, Object?> lessonToJson(Lesson l, {int seed = 1, int difficulty = 2}) => {
      'title': trJson(l.title),
      'course': l.courseId,
      'xp': l.xp,
      'leagues': l.leagues?.toList(),
      'steps': [for (final s in l.build(seed, difficulty)) stepToJson(s)],
    };
