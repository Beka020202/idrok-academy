// ============================================================================
//  Dars dvigateli / движок уроков
//  Har bir urinishda savollar yangidan yaratiladi (tasodifiy variantlar).
//  При каждой попытке вопросы генерируются заново (случайные варианты).
// ============================================================================

import 'dart:math';

/// Ikki tildagi matn / текст на двух языках.
class Tr {
  final String uz;
  final String ru;
  const Tr(this.uz, this.ru);
  const Tr.same(String s)
      : uz = s,
        ru = s;
  String of(String lang) => lang == 'ru' ? ru : uz;
}

/// Bir xil matn (kod, raqam) / одинаковый текст (код, число).
Tr lit(String v) => Tr.same(v);

enum StepType { read, quiz, fill, order, tryIt }

/// (kod, natija) -> to‘g‘rimi / (код, вывод) -> верно ли.
typedef CodeCheck = bool Function(String code, String output);

class LessonStep {
  final StepType type;
  final int difficulty; // 1 oson / лёгкий … 3 qiyin / сложный

  // nazariya / теория
  final Tr? h, p;
  final String? code;

  // savol / вопрос
  final Tr? q;
  final List<Tr> options;
  final int answer;
  final bool mono;
  final Tr? e; // tushuntirish / объяснение

  // bo‘sh joy / пропуск
  final String? pre, post;
  final List<String> answers;

  // tartiblash / порядок строк (to‘g‘ri tartibda / в правильном порядке)
  final List<String> lines;

  // amaliyot / практика
  final String? mode;
  final Tr? task;
  final String? start;
  final Tr? hint;
  final CodeCheck? check;
  final String? solution;

  const LessonStep._({
    required this.type,
    this.difficulty = 1,
    this.h,
    this.p,
    this.code,
    this.q,
    this.options = const [],
    this.answer = 0,
    this.mono = false,
    this.e,
    this.pre,
    this.post,
    this.answers = const [],
    this.lines = const [],
    this.mode,
    this.task,
    this.start,
    this.hint,
    this.check,
    this.solution,
  });

  const LessonStep.read({required Tr h, required Tr p, String? code})
      : this._(type: StepType.read, h: h, p: p, code: code);

  const LessonStep.quiz(
      {required Tr q, required List<Tr> o, required int answer, String? code, bool mono = false, Tr? e, int difficulty = 1})
      : this._(type: StepType.quiz, q: q, options: o, answer: answer, code: code, mono: mono, e: e, difficulty: difficulty);

  const LessonStep.fill(
      {required Tr q, required String pre, required String post, required List<String> answers, Tr? e, int difficulty = 1})
      : this._(type: StepType.fill, q: q, pre: pre, post: post, answers: answers, e: e, difficulty: difficulty);

  const LessonStep.order({required Tr q, required List<String> lines, Tr? e, int difficulty = 1})
      : this._(type: StepType.order, q: q, lines: lines, e: e, difficulty: difficulty, mono: true);

  const LessonStep.tryIt(
      {required String mode,
      required Tr task,
      required String start,
      required Tr hint,
      required CodeCheck check,
      required String solution,
      int difficulty = 1})
      : this._(
            type: StepType.tryIt,
            mode: mode,
            task: task,
            start: start,
            hint: hint,
            check: check,
            solution: solution,
            difficulty: difficulty);

  /// Bosqich turi kaliti (tarjima uchun) / ключ типа шага (для перевода).
  String get kindKey => switch (type) {
        StepType.read => 'read',
        StepType.quiz => 'quiz',
        StepType.fill => 'fill',
        StepType.order => 'order',
        StepType.tryIt => 'try',
      };

  /// Test bosqichimi (vaqt hisoblanadi) / тестовый ли шаг (с таймером).
  bool get timed => type != StepType.read;

  /// Avtomatik testlar uchun to‘g‘ri javob / правильный ответ для автотестов.
  String get testSolution => switch (type) {
        StepType.quiz => options[answer].uz,
        StepType.fill => answers.first,
        StepType.order => lines.join('\n'),
        StepType.tryIt => solution ?? '',
        StepType.read => '',
      };
}

/// Savol yaratuvchi (qiyinlik darajasi bilan) / генератор вопроса (с уровнем сложности).
class Q {
  final int d;
  final LessonStep Function(Gen g) make;
  const Q(this.d, this.make);
}

/// Tasodifiy variantlar generatori / генератор случайных вариантов.
class Gen {
  final Random r;
  final int d; // 1..3
  Gen(int seed, int difficulty)
      : r = Random(seed),
        d = difficulty.clamp(1, 3).toInt();

  T pick<T>(List<T> xs) => xs[r.nextInt(xs.length)];
  int n(int a, int b) => a + r.nextInt(b - a + 1);
  List<T> shuffled<T>(List<T> xs) => List<T>.of(xs)..shuffle(r);
  List<T> sample<T>(List<T> xs, int k) => shuffled(xs).take(k).toList();

  /// Hovuzdan k ta savol: joriy darajadagilar birinchi.
  /// k вопросов из пула: сначала текущего уровня.
  List<LessonStep> from(List<Q> pool, int k) {
    var ok = pool.where((q) => q.d <= d).toList();
    if (ok.isEmpty) ok = List.of(pool);
    final same = shuffled(ok.where((q) => q.d == d).toList());
    final rest = shuffled(ok.where((q) => q.d != d).toList());
    return [...same, ...rest].take(k).map((q) => q.make(this)).toList();
  }

  /// Variantlari aralashtirilgan savol / вопрос с перемешанными вариантами.
  LessonStep quiz(Tr q, Tr correct, List<Tr> wrong, {String? code, Tr? e, bool mono = false, int? difficulty}) {
    // Takroriy va to‘g‘ri javobga teng variantlarni olib tashlaymiz.
    // Убираем повторы и варианты, совпадающие с правильным ответом.
    final seen = <String>{correct.uz};
    final uniq = <Tr>[for (final x in wrong) if (seen.add(x.uz)) x];
    final w = sample(uniq, min(3, uniq.length));
    final opts = shuffled([correct, ...w]);
    return LessonStep.quiz(
        q: q, o: opts, answer: opts.indexOf(correct), code: code, e: e, mono: mono, difficulty: difficulty ?? d);
  }

  /// Faqat kod variantlari / варианты только из кода.
  LessonStep quizCode(Tr q, String correct, List<String> wrong, {String? code, Tr? e, int? difficulty}) =>
      quiz(q, lit(correct), [for (final w in wrong) lit(w)], code: code, e: e, mono: true, difficulty: difficulty);

  LessonStep fill(Tr q, String pre, String post, List<String> answers, {Tr? e}) =>
      LessonStep.fill(q: q, pre: pre, post: post, answers: answers, e: e, difficulty: d);

  LessonStep order(Tr q, List<String> lines, {Tr? e}) => LessonStep.order(q: q, lines: lines, e: e, difficulty: d);

  LessonStep tryIt(
          {required String mode,
          required Tr task,
          required String start,
          required Tr hint,
          required CodeCheck check,
          required String solution}) =>
      LessonStep.tryIt(
          mode: mode, task: task, start: start, hint: hint, check: check, solution: solution, difficulty: d);
}

typedef StepBuilder = List<LessonStep> Function(Gen g);

class Lesson {
  final String id;
  final String courseId;
  final int xp;
  final Tr title;
  final Set<String>? leagues; // null = hamma uchun / для всех
  final StepBuilder builder;
  const Lesson({
    required this.id,
    required this.courseId,
    required this.xp,
    required this.title,
    required this.builder,
    this.leagues,
  });

  /// Yangi urinish uchun bosqichlar / шаги для новой попытки.
  List<LessonStep> build(int seed, int difficulty) => builder(Gen(seed, difficulty));

  bool forLeague(String league) => leagues == null || leagues!.contains(league);
}

class Course {
  final String id, tag, color;
  final Tr name, sub;
  final List<Lesson> lessons;
  const Course(
      {required this.id, required this.tag, required this.color, required this.name, required this.sub, required this.lessons});

  /// O‘quvchi ligasi uchun darslar / уроки для лиги ученика.
  List<Lesson> lessonsFor(String league) =>
      [for (final l in lessons) if (l.forLeague(league.isEmpty ? 'beginner' : league)) l];

  List<String> idsFor(String league) => [for (final l in lessonsFor(league)) l.id];
}

// ---------------------------------------------------------------- tekshirish yordamchilari / помощники проверки
bool has(String pattern, String text, {bool ci = true}) => RegExp(pattern, caseSensitive: !ci).hasMatch(text);

int count(String pattern, String text, {bool ci = true}) =>
    RegExp(pattern, caseSensitive: !ci).allMatches(text).length;

List<String> words(String v) {
  final t = v.trim();
  return t.isEmpty ? <String>[] : t.split(RegExp(r'\s+'));
}

/// Natija qatorlari (bo‘sh joylarsiz) / строки вывода (без пробелов по краям).
List<String> outLines(String v) => [for (final l in v.trim().split('\n')) if (l.trim().isNotEmpty) l.trim()];
