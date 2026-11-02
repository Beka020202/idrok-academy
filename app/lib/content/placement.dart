// Tanishuv mashqi (aslida — darajani aniqlash testi).
// O‘quvchiga bu liga belgilashini AYTMAYMIZ — u “isinish” deb ko‘rsatiladi.
// Разминка (на самом деле — тест для определения уровня).
// Ученику НЕ говорим, что он определяет лигу — показываем как «разминку».
import 'model.dart';

const kLeagues = ['beginner', 'advanced', 'master'];

// Savollar faqat dasturlash haqida: HTML, CSS, JavaScript, Python.
// Вопросы только о программировании: HTML, CSS, JavaScript, Python.
const _words = ['olma', 'kitob', 'maktab', 'Idrok', 'kod', 'robot'];

List<Q> _easy() => [
      Q(1, (g) => g.quizCode(const Tr('Eng katta sarlavha qaysi HTML teg bilan yoziladi?', 'Каким HTML-тегом пишут самый крупный заголовок?'),
          '<h1>', ['<p>', '<head>', '<h6>'], difficulty: 1)),
      Q(1, (g) => g.quizCode(const Tr('Havola (link) qaysi HTML teg bilan yaratiladi?', 'Каким HTML-тегом создают ссылку?'),
          '<a>', ['<link>', '<href>', '<img>'], difficulty: 1)),
      Q(1, (g) => g.quizCode(const Tr('Rasm qo‘yish uchun qaysi HTML teg ishlatiladi?', 'Какой HTML-тег вставляет картинку?'),
          '<img>', ['<pic>', '<image>', '<src>'], difficulty: 1)),
      Q(1, (g) => g.quizCode(const Tr('CSS’da matn rangini qaysi xususiyat o‘zgartiradi?', 'Какое свойство CSS меняет цвет текста?'),
          'color', ['background', 'font-size', 'text'], difficulty: 1)),
      Q(1, (g) => g.quizCode(const Tr('Python’da izoh (comment) qaysi belgi bilan boshlanadi?', 'С какого символа начинается комментарий в Python?'),
          '#', ['//', '<!--', '--'], difficulty: 1)),
      Q(1, (g) => g.quizCode(const Tr('JavaScript’da bir qatorli izoh qanday yoziladi?', 'Как пишут однострочный комментарий в JavaScript?'),
          '// izoh', ['# izoh', '<!-- izoh -->', '** izoh'], difficulty: 1)),
      Q(1, (g) {
        final w = g.pick(_words);
        return g.quizCode(const Tr('Ekranda nima chiqadi?', 'Что появится на экране?'), w, ['"$w"', 'print', '$w()'],
            code: 'print("$w")', difficulty: 1);
      }),
      Q(1, (g) {
        final a = g.n(2, 9), b = g.n(2, 9);
        return g.quizCode(const Tr('Ekranda nima chiqadi?', 'Что появится на экране?'), '${a + b}', ['x + $b', '$a$b', '$a'],
            code: 'x = $a\nprint(x + $b)', difficulty: 1);
      }),
    ];

List<Q> _medium() => [
      Q(2, (g) {
        final a = g.n(10, 30), b = g.n(3, 5);
        return g.quizCode(const Tr('Ekranda nima chiqadi?', 'Что появится на экране?'), '${a ~/ b}', ['${a % b}', '${a ~/ b + 1}', '${a * b}'],
            code: 'print($a // $b)', difficulty: 2);
      }),
      Q(2, (g) {
        final a = g.n(10, 30), b = g.n(3, 5);
        return g.quizCode(const Tr('Ekranda nima chiqadi?', 'Что появится на экране?'), '${a % b}', ['${a ~/ b}', '$b', '${a - b}'],
            code: 'print($a % $b)', difficulty: 2);
      }),
      Q(2, (g) {
        final t = g.n(10, 30), lim = g.n(15, 25);
        return g.quizCode(const Tr('Ekranda nima chiqadi?', 'Что появится на экране?'), t > lim ? 'issiq' : 'salqin',
            [t > lim ? 'salqin' : 'issiq', '$t', 'Xato'],
            code: 't = $t\nif t > $lim:\n    print("issiq")\nelse:\n    print("salqin")', difficulty: 2);
      }),
      Q(2, (g) {
        final n = g.n(2, 4);
        return g.quizCode(const Tr('Ekranda nima chiqadi?', 'Что появится на экране?'), 'ha' * n, ['ha$n', '$n', List.filled(n, 'ha').join(' ')],
            code: 'print("ha" * $n)', difficulty: 2);
      }),
      Q(2, (g) {
        final a = g.n(2, 9), b = g.n(2, 9);
        return g.quizCode(const Tr('Konsolda nima chiqadi?', 'Что выведется в консоль?'), '${a + b}', ['$a', '$b', '$a$b'],
            code: 'let x = $a;\nx = x + $b;\nconsole.log(x);', difficulty: 2);
      }),
      Q(2, (g) {
        final a = g.n(2, 9), b = g.n(2, 9);
        return g.quizCode(const Tr('Konsolda nima chiqadi?', 'Что выведется в консоль?'), '$a$b', ['${a + b}', 'Xato', '"$a" + $b'],
            code: 'console.log("$a" + $b);', difficulty: 2);
      }),
      Q(2, (g) {
        final xs = g.sample(_words, 3);
        return g.quizCode(const Tr('Ekranda nima chiqadi?', 'Что появится на экране?'), xs[1], [xs[0], xs[2], '1'],
            code: 'narsalar = ["${xs[0]}", "${xs[1]}", "${xs[2]}"]\nprint(narsalar[1])', difficulty: 2);
      }),
      Q(2, (g) => g.quizCode(const Tr('“card” klassli elementlarni qaysi CSS selektor tanlaydi?', 'Какой CSS-селектор выбирает элементы с классом «card»?'),
          '.card', ['#card', 'card', '*card'], difficulty: 2)),
      Q(2, (g) {
        final w = g.pick(_words);
        return g.quizCode(const Tr('Ekranda nima chiqadi?', 'Что появится на экране?'), '${w.length}', ['${w.length - 1}', '${w.length + 1}', w],
            code: 'print(len("$w"))', difficulty: 2);
      }),
    ];

List<Q> _hard() => [
      Q(3, (g) {
        final n = g.n(3, 6);
        final s = n * (n + 1) ~/ 2;
        return g.quizCode(const Tr('Ekranda nima chiqadi?', 'Что появится на экране?'), '$s', ['$n', '${s + n}', '${n * n}'],
            code: 's = 0\nfor i in range(1, ${n + 1}):\n    s = s + i\nprint(s)', difficulty: 3);
      }),
      Q(3, (g) {
        final n = g.n(4, 9);
        return g.quizCode(const Tr('Sikl necha marta ishlaydi?', 'Сколько раз выполнится цикл?'), '${(n + 1) ~/ 2}',
            ['$n', '${n ~/ 2 + 2}', '${n - 1}'],
            code: 'for i in range(0, $n, 2):\n    print(i)', difficulty: 3);
      }),
      Q(3, (g) {
        final xs = [for (var i = 0; i < 4; i++) g.n(1, 9)];
        final m = xs.reduce((a, b) => a > b ? a : b);
        return g.quizCode(const Tr('Ekranda nima chiqadi?', 'Что появится на экране?'), '$m', ['${xs.first}', '${xs.last}', '${xs.length}'],
            code: 'sonlar = $xs\neng = sonlar[0]\nfor x in sonlar:\n    if x > eng:\n        eng = x\nprint(eng)', difficulty: 3);
      }),
      Q(3, (g) {
        final a = g.n(2, 6);
        final r = 2 * (2 * a + 1) + 1;
        return g.quizCode(const Tr('Ekranda nima chiqadi?', 'Что появится на экране?'), '$r', ['${2 * a + 1}', '${4 * a + 1}', '${r + 1}'],
            code: 'def f(x):\n    return x * 2 + 1\n\nprint(f(f($a)))', difficulty: 3);
      }),
      Q(3, (g) {
        final a = g.n(2, 5), b = g.n(2, 5);
        return g.quizCode(const Tr('Ekranda nima chiqadi?', 'Что появится на экране?'), '${a * b}', ['${a + b}', '$a', '${a * b + 1}'],
            code: 'c = 0\nfor i in range($a):\n    for j in range($b):\n        c += 1\nprint(c)', difficulty: 3);
      }),
      Q(3, (g) {
        final n = g.pick([8, 16, 20, 32, 40, 64]);
        var k = 0, m = n;
        while (m > 1) {
          m ~/= 2;
          k++;
        }
        return g.quizCode(const Tr('Ekranda nima chiqadi?', 'Что появится на экране?'), '$k', ['${k + 1}', '${k - 1}', '${n ~/ 2}'],
            code: 'n = $n\nk = 0\nwhile n > 1:\n    n = n // 2\n    k += 1\nprint(k)', difficulty: 3);
      }),
      Q(3, (g) {
        final n = g.n(5, 9);
        var even = 0, all = 0;
        for (var i = 1; i <= n; i++) {
          all += i;
          if (i % 2 == 0) even += i;
        }
        return g.quizCode(const Tr('Konsolda nima chiqadi?', 'Что выведется в консоль?'), '$even', ['$all', '${all - even}', '$n'],
            code: 'let s = 0;\nfor (let i = 1; i <= $n; i++) {\n  if (i % 2 === 0) s += i;\n}\nconsole.log(s);', difficulty: 3);
      }),
      Q(3, (g) {
        final xs = [for (var i = 0; i < 5; i++) g.n(1, 9)];
        String lst(List<int> v) => '[${v.join(', ')}]';
        return g.quizCode(const Tr('Ekranda nima chiqadi?', 'Что появится на экране?'), lst(xs.sublist(1, 3)),
            [lst(xs.sublist(1, 4)), lst(xs.sublist(0, 2)), lst(xs.sublist(2, 4))],
            code: 'xs = ${lst(xs)}\nprint(xs[1:3])', difficulty: 3);
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
