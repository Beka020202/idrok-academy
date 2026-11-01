// Tanishuv mashqi (aslida — darajani aniqlash testi).
// O‘quvchiga bu liga belgilashini AYTMAYMIZ — u “isinish” deb ko‘rsatiladi.
// Разминка (на самом деле — тест для определения уровня).
// Ученику НЕ говорим, что он определяет лигу — показываем как «разминку».
import 'model.dart';

const kLeagues = ['beginner', 'advanced', 'master'];

List<Q> _easy() => [
      Q(1, (g) {
        final a = g.n(3, 9), b = g.n(2, 8);
        return g.quiz(Tr('$a ta olma bor edi, yana $b ta berishdi. Nechta bo‘ldi?', 'Было $a яблок, дали ещё $b. Сколько стало?'),
            lit('${a + b}'), [lit('${a + b + 1}'), lit('${a * b}'), lit('${a - b}')], difficulty: 1);
      }),
      Q(1, (g) => g.quiz(const Tr('Qaysi biri dasturlash tili?', 'Что из этого — язык программирования?'), lit('Python'),
          [lit('Telegram'), lit('Google'), lit('Windows')], difficulty: 1)),
      Q(1, (g) {
        final n = g.n(2, 6);
        return g.quiz(Tr('Ketma-ketlikni davom ettiring: $n, ${n * 2}, ${n * 3}, …', 'Продолжите ряд: $n, ${n * 2}, ${n * 3}, …'),
            lit('${n * 4}'), [lit('${n * 3 + 1}'), lit('${n * 5}'), lit('${n * 2}')], difficulty: 1);
      }),
      Q(1, (g) => g.quiz(const Tr('Veb-sahifa skeleti qaysi tilda yoziladi?', 'На каком языке пишут скелет веб-страницы?'), lit('HTML'),
          [lit('Excel'), lit('PDF'), lit('MP3')], difficulty: 1)),
    ];

List<Q> _medium() => [
      Q(2, (g) {
        final x = g.n(3, 9);
        return g.quizCode(const Tr('Ekranda nima chiqadi?', 'Что появится на экране?'), '${x * 2}', ['$x', '${x}2', 'x * 2'],
            code: 'x = $x\nprint(x * 2)', difficulty: 2);
      }),
      Q(2, (g) => g.quiz(const Tr('Agar barcha mushuklar hayvon bo‘lsa va Tom mushuk bo‘lsa, unda…', 'Если все кошки — животные, и Том — кошка, то…'),
          const Tr('Tom — hayvon', 'Том — животное'),
          const [Tr('Barcha hayvonlar — mushuk', 'Все животные — кошки'), Tr('Tom — it', 'Том — собака'), Tr('Hech narsa deb bo‘lmaydi', 'Ничего нельзя сказать')],
          difficulty: 2)),
      Q(2, (g) {
        final a = g.n(10, 30), b = g.n(2, 5);
        return g.quizCode(Tr('$a ni $b ga bo‘lgandagi qoldiq?', 'Остаток от деления $a на $b?'), '${a % b}', ['${a ~/ b}', '0', '$b'],
            difficulty: 2);
      }),
      Q(2, (g) {
        final t = g.n(10, 30), lim = g.n(15, 25);
        return g.quizCode(const Tr('Nima chiqadi?', 'Что выведется?'), t > lim ? 'issiq' : 'salqin', [t > lim ? 'salqin' : 'issiq', '$t', 'xato'],
            code: 't = $t\nif t > $lim:\n    print("issiq")\nelse:\n    print("salqin")', difficulty: 2);
      }),
    ];

List<Q> _hard() => [
      Q(3, (g) {
        final n = g.n(3, 6);
        final s = n * (n + 1) ~/ 2;
        return g.quizCode(const Tr('Nima chiqadi?', 'Что выведется?'), '$s', ['$n', '${s + n}', '${n * n}'],
            code: 's = 0\nfor i in range(1, ${n + 1}):\n    s = s + i\nprint(s)', difficulty: 3);
      }),
      Q(3, (g) {
        final n = g.n(4, 9);
        return g.quizCode(const Tr('Sikl necha marta ishlaydi?', 'Сколько раз выполнится цикл?'), '${(n + 1) ~/ 2}', ['$n', '${n ~/ 2 + 2}', '${n - 1}'],
            code: 'for i in range(0, $n, 2):\n    print(i)', difficulty: 3);
      }),
      Q(3, (g) {
        final xs = [for (var i = 0; i < 4; i++) g.n(1, 9)];
        final m = xs.reduce((a, b) => a > b ? a : b);
        return g.quizCode(const Tr('Nima chiqadi?', 'Что выведется?'), '$m', ['${xs.first}', '${xs.last}', '${xs.length}'],
            code: 'sonlar = $xs\neng = sonlar[0]\nfor x in sonlar:\n    if x > eng:\n        eng = x\nprint(eng)', difficulty: 3);
      }),
    ];

/// 8 ta savol: 3 oson, 3 o‘rta, 2 qiyin / 8 вопросов: 3 лёгких, 3 средних, 2 сложных.
List<LessonStep> placementTest(int seed) {
  final g = Gen(seed, 3);
  List<LessonStep> take(List<Q> pool, int k) => [for (final q in g.sample(pool, k)) q.make(g)];
  return [...take(_easy(), 3), ...take(_medium(), 3), ...take(_hard(), 2)];
}

/// Natija -> liga. ball: to‘g‘ri javoblar qiyinligi yig‘indisi (maks 15).
/// tezlik: o‘rtacha sarflangan vaqt / berilgan vaqt (0..1).
/// Результат -> лига. ball: сумма сложности верных ответов (макс 15). tezlik: доля использованного времени.
String leagueFor(int points, double timeShare) {
  if (points >= 12 && timeShare < 0.75) return 'master';
  if (points >= 13) return 'master';
  if (points >= 7) return 'advanced';
  return 'beginner';
}
