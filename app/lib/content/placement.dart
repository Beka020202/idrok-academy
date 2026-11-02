// Tanishuv mashqi (aslida — darajani aniqlash testi).
// O‘quvchiga bu liga belgilashini AYTMAYMIZ — u “isinish” deb ko‘rsatiladi.
// Разминка (на самом деле — тест для определения уровня).
// Ученику НЕ говорим, что он определяет лигу — показываем как «разминку».
import 'model.dart';

const kLeagues = ['beginner', 'advanced', 'master'];

// Savollar hech qaysi tilga bog‘liq emas — oddiy psevdokod (har qanday dasturchi o‘qiy oladi).
// Вопросы не привязаны к языку — простой псевдокод (его прочтёт любой программист).

const _q = Tr('Bu kod nima chiqaradi?', 'Что выведет этот код?');

/// Sonli javobli savol: noto‘g‘ri variantlar har doim 3 ta va har xil.
/// Вопрос с числовым ответом: всегда 3 разных неверных варианта.
LessonStep _num(Gen g, int correct, List<int> wrong, String code, int d, {Tr q = _q, Tr? e}) {
  final seen = <int>{correct};
  final w = <int>[for (final x in wrong) if (seen.add(x)) x];
  for (var k = 1; w.length < 3; k++) {
    for (final x in [correct + k, correct - k]) {
      if (w.length < 3 && x >= 0 && seen.add(x)) w.add(x);
    }
  }
  return g.quizCode(q, '$correct', [for (final x in w.take(3)) '$x'], code: code, e: e, difficulty: d);
}

/// Matnli savol: 3 ta noto‘g‘ri variant bilan / текстовый вопрос с 3 неверными вариантами.
LessonStep _txt(Gen g, Tr q, Tr correct, List<Tr> wrong, int d, {String? code, Tr? e}) =>
    g.quiz(q, correct, wrong, code: code, e: e, difficulty: d);

const _note = Tr('Psevdokod: “=” qiymat beradi, “print” ekranga chiqaradi, ro‘yxat raqamlari 0 dan boshlanadi.',
    'Псевдокод: «=» присваивает значение, «print» выводит на экран, нумерация списка с 0.');

List<Q> _easy() => [
      Q(1, (g) {
        final a = g.n(2, 9), b = g.n(2, 9);
        return _num(g, a + b, [a, b, a * b], 'x = $a\nx = x + $b\nprint(x)', 1, e: _note);
      }),
      Q(1, (g) {
        final a = g.n(2, 9), b = g.n(10, 19);
        return _num(g, b, [a, a + b, 0], 'a = $a\nb = $b\na = b\nprint(a)', 1,
            e: const Tr('a = b — a ga b ning qiymati yoziladi.', 'a = b — в a записывается значение b.'));
      }),
      Q(1, (g) {
        final x = g.n(2, 5);
        final y = x * 3;
        return _num(g, y, [30, x, 10], 'x = $x\ny = x * 3\nx = 10\nprint(y)', 1,
            e: const Tr('y bir marta hisoblangan; x keyin o‘zgarishi y ga ta’sir qilmaydi.',
                'y вычислен один раз; последующее изменение x на y не влияет.'));
      }),
      Q(1, (g) {
        final x = g.n(3, 17);
        return _txt(g, _q, lit(x > 10 ? 'katta' : 'kichik'), [lit(x > 10 ? 'kichik' : 'katta'), lit('$x'), lit('10')], 1,
            code: 'x = $x\nif x > 10:\n    print("katta")\nelse:\n    print("kichik")');
      }),
      Q(1, (g) {
        final n = g.n(3, 5), k = g.n(2, 4);
        return _num(g, n * k, [n + k, k, n], 'c = 0\nrepeat $n times:\n    c = c + $k\nprint(c)', 1);
      }),
      Q(1, (g) => _txt(g, const Tr('O‘zgaruvchi (variable) nima?', 'Что такое переменная?'),
          const Tr('Qiymatni saqlaydigan nomlangan “quti”', 'Именованная «коробка» для хранения значения'),
          const [
            Tr('Ekranga chiqaradigan buyruq', 'Команда вывода на экран'),
            Tr('Kodning xatosi', 'Ошибка в коде'),
            Tr('Dasturning nomi', 'Название программы'),
          ],
          1)),
      Q(1, (g) => _txt(g, const Tr('Sikl (loop) nima uchun kerak?', 'Зачем нужен цикл?'),
          const Tr('Bir xil ishni ko‘p marta takrorlash uchun', 'Чтобы повторять одно действие много раз'),
          const [
            Tr('Dasturni to‘xtatish uchun', 'Чтобы остановить программу'),
            Tr('Ma’lumotni o‘chirish uchun', 'Чтобы удалять данные'),
            Tr('Rangni o‘zgartirish uchun', 'Чтобы менять цвет'),
          ],
          1)),
    ];

List<Q> _medium() => [
      Q(2, (g) {
        final n = g.n(3, 7);
        return _num(g, n, [n + 1, n - 1, 1],
            'for i = 1 to $n:\n    print("*")', 2,
            q: const Tr('Necha marta “*” chiqadi?', 'Сколько раз выведется «*»?'));
      }),
      Q(2, (g) {
        final xs = g.sample([3, 5, 7, 8, 11, 12, 14, 20], 4);
        return _num(g, xs[2], [xs[1], xs[3], 2], 'a = $xs\nprint(a[2])', 2, e: _note);
      }),
      Q(2, (g) {
        final xs = g.sample([2, 4, 6, 9, 13, 15, 21, 30], g.n(3, 6));
        return _num(g, xs.length, [xs.length - 1, xs.last, xs.length + 1], 'a = $xs\nprint(length(a))', 2);
      }),
      Q(2, (g) {
        final a = g.n(13, 29), b = g.n(3, 5);
        return _num(g, a % b, [a ~/ b, b, a - b], 'print($a % $b)', 2,
            e: const Tr('% — bo‘lishdan qolgan qoldiq.', '% — остаток от деления.'));
      }),
      Q(2, (g) {
        final lim = g.pick([20, 30, 50, 100]);
        var x = 1;
        while (x < lim) {
          x *= 2;
        }
        return _num(g, x, [x ~/ 2, lim, x * 2], 'x = 1\nwhile x < $lim:\n    x = x * 2\nprint(x)', 2);
      }),
      Q(2, (g) {
        final a = g.n(2, 9);
        return _num(g, a * 2 + 1, [a * 2, a + 1, a], 'function f(x):\n    return x * 2\n\nprint(f($a) + 1)', 2);
      }),
      Q(2, (g) {
        final x = g.n(1, 15);
        final ok = x > 5 && x < 10;
        return _txt(g, _q, lit(ok ? 'ha' : 'yo‘q'), [lit(ok ? 'yo‘q' : 'ha'), lit('$x'), const Tr('Xato', 'Ошибка')], 2,
            code: 'x = $x\nif x > 5 and x < 10:\n    print("ha")\nelse:\n    print("yo‘q")');
      }),
      Q(2, (g) => _txt(
          g,
          const Tr('Kod 1 dan 5 gacha sonlar yig‘indisini chiqarishi kerak, lekin javob 5. Xato qayerda?',
              'Код должен вывести сумму чисел от 1 до 5, но выводит 5. Где ошибка?'),
          const Tr('“s = i” o‘rniga “s = s + i” bo‘lishi kerak', 'Вместо «s = i» должно быть «s = s + i»'),
          const [
            Tr('Sikl 0 dan boshlanishi kerak', 'Цикл должен начинаться с 0'),
            Tr('print sikl ichida bo‘lishi kerak', 'print должен быть внутри цикла'),
            Tr('s = 0 qatori ortiqcha', 'Строка s = 0 лишняя'),
          ],
          2,
          code: 's = 0\nfor i = 1 to 5:\n    s = i\nprint(s)')),
    ];

List<Q> _hard() => [
      Q(3, (g) {
        final n = g.n(4, 7);
        final s = n * (n + 1) ~/ 2;
        return _num(g, s, [n, s + n, n * n], 's = 0\nfor i = 1 to $n:\n    s = s + i\nprint(s)', 3);
      }),
      Q(3, (g) {
        final xs = [for (var i = 0; i < 5; i++) g.n(1, 9)];
        final m = xs.reduce((a, b) => a > b ? a : b);
        return _num(g, m, [xs.first, xs.last, xs.length],
            'a = $xs\nm = a[0]\nfor x in a:\n    if x > m:\n        m = x\nprint(m)', 3);
      }),
      Q(3, (g) {
        final a = g.n(2, 6);
        final r = 2 * (2 * a + 1) + 1;
        return _num(g, r, [2 * a + 1, 4 * a + 1, r + 1], 'function f(x):\n    return x * 2 + 1\n\nprint(f(f($a)))', 3);
      }),
      Q(3, (g) {
        final a = g.n(2, 5), b = g.n(2, 5);
        return _num(g, a * b, [a + b, a, b],
            'c = 0\nfor i = 1 to $a:\n    for j = 1 to $b:\n        c = c + 1\nprint(c)', 3);
      }),
      Q(3, (g) {
        final n = g.pick([8, 16, 20, 32, 40, 64]);
        var k = 0, m = n;
        while (m > 1) {
          m ~/= 2;
          k++;
        }
        return _num(g, k, [n ~/ 2, k + 2, 1], 'n = $n\nk = 0\nwhile n > 1:\n    n = n div 2\n    k = k + 1\nprint(k)', 3,
            e: const Tr('div — butun bo‘lish (qoldiqsiz).', 'div — целочисленное деление.'));
      }),
      Q(3, (g) {
        final n = g.n(4, 6);
        return _num(g, n * (n + 1) ~/ 2, [n, n * n, n + 1],
            'function f(n):\n    if n == 0:\n        return 0\n    return n + f(n - 1)\n\nprint(f($n))', 3);
      }),
      Q(3, (g) {
        final xs = [for (var i = 0; i < 6; i++) g.n(1, 9)];
        final k = g.n(3, 6);
        final c = xs.where((x) => x > k).length;
        return _num(g, c, [6 - c, k, xs.where((x) => x >= k).length],
            'a = $xs\nc = 0\nfor x in a:\n    if x > $k:\n        c = c + 1\nprint(c)', 3);
      }),
      Q(3, (g) => _txt(
          g,
          const Tr('Alifbo tartibidagi 1000 ta ism ichidan bittasini eng tez qanday topish mumkin?',
              'Как быстрее всего найти одно имя среди 1000 имён, отсортированных по алфавиту?'),
          const Tr('O‘rtasidan boshlab, har safar yarmini tashlab yuborish', 'Начать с середины и каждый раз отбрасывать половину'),
          const [
            Tr('Boshidan bittalab tekshirish', 'Проверять по одному с начала'),
            Tr('Tasodifiy ismlarni tanlash', 'Выбирать случайные имена'),
            Tr('Oxiridan bittalab tekshirish', 'Проверять по одному с конца'),
          ],
          3,
          e: const Tr('Bu “ikkilik qidiruv”: 1000 ta ism uchun 10 ta qadam yetadi.',
              'Это «двоичный поиск»: для 1000 имён хватит 10 шагов.'))),
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
