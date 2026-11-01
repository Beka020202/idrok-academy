// JavaScript kursi — boshlovchilar uchun / курс JavaScript — для начинающих.
import 'model.dart';

const _names = ['Ali', 'Laylo', 'Bekzod', 'Madina', 'Sardor'];

List<LessonStep> js1(Gen g) {
  final name = g.pick(_names);
  final a = g.n(2, 9), b = g.n(2, 9);
  return [
    const LessonStep.read(
      h: Tr('JavaScript: sahifaga jon beramiz', 'JavaScript: оживляем страницу'),
      p: Tr(
          'JavaScript (JS) — buyruqlar tili. console.log(...) — natijani konsolga chiqaradi, xuddi daftarga yozgandek. '
              'Matn qo‘shtirnoq ichida: "Salom". Raqamlar qo‘shtirnoqsiz: 5 + 3 hisoblanadi.',
          'JavaScript (JS) — язык команд. console.log(...) выводит результат в консоль, как запись в тетрадь. '
              'Текст — в кавычках: "Salom". Числа — без кавычек: 5 + 3 вычисляется.'),
      code: 'console.log("Salom!");\nconsole.log(5 + 3); // 8',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Natijani chiqaruvchi buyruq:', 'Команда для вывода результата:'), 'console.log()',
          ['print()', 'echo()', 'show()'])),
      Q(1, (g) => g.quizCode(Tr('console.log($a + $b) nima chiqaradi?', 'Что выведет console.log($a + $b)?'), '${a + b}',
          ['$a$b', '$a + $b', 'Xato'])),
      Q(2, (g) => g.quizCode(Tr('console.log("$a" + "$b") nima chiqaradi?', 'Что выведет console.log("$a" + "$b")?'), '$a$b',
          ['${a + b}', '"$a + $b"', 'Xato'],
          e: const Tr('Qo‘shtirnoqdagi raqamlar — matn. Matnlar yopishtiriladi.', 'Цифры в кавычках — это текст. Тексты склеиваются.'))),
      Q(3, (g) => g.quizCode(const Tr('Qaysi qatorda xato bor?', 'В какой строке ошибка?'), 'console.log("Salom);',
          ['console.log("Salom");', 'console.log(7);', 'console.log(2 * 3);'],
          e: const Tr('Qo‘shtirnoq ochilgan, lekin yopilmagan.', 'Кавычка открыта, но не закрыта.'))),
    ], 2),
    g.fill(Tr('“$name” ni chiqaring:', 'Выведите «$name»:'), 'console.', '("$name");', ['log']),
    g.tryIt(
      mode: 'js',
      task: Tr('console.log bilan “$name” matnini chiqaring.', 'Выведите текст «$name» через console.log.'),
      start: '// kodingiz\n',
      hint: lit('console.log("$name");'),
      check: (c, o) => has('console\\.log\\s*\\(\\s*["\'`]$name["\'`]\\s*\\)', c, ci: false),
      solution: 'console.log("$name");',
    ),
  ];
}

List<LessonStep> js2(Gen g) {
  final age = g.n(10, 17);
  final name = g.pick(_names);
  return [
    const LessonStep.read(
      h: Tr('O‘zgaruvchilar — nomli qutilar', 'Переменные — коробки с именем'),
      p: Tr(
          'O‘zgaruvchi — ichiga qiymat soladigan, ustiga nom yozilgan quti. let — keyin almashtirsa bo‘ladi, '
              'const — o‘zgarmaydi. = belgisi “qutiga sol” degani.',
          'Переменная — коробка с надписью, куда кладут значение. let — можно потом заменить, '
              'const — не меняется. Знак = значит «положи в коробку».'),
      code: 'let ism = "Ali";\nconst yil = 2026;\nconsole.log(ism); // Ali',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Qaysi o‘zgaruvchini qayta o‘zgartirib bo‘lmaydi?', 'Какую переменную нельзя изменить?'), 'const',
          ['let', 'var', 'change'])),
      Q(2, (g) => g.quizCode(const Tr('Natija qanday?', 'Каким будет результат?'), '${age + 1}', ['$age', '${age}1', 'x'],
          code: 'let x = $age;\nx = x + 1;\nconsole.log(x);')),
      Q(2, (g) => g.quizCode(const Tr('Natija qanday?', 'Каким будет результат?'), 'Salom, $name', ['Salom, ism', 'ism', '"Salom, " + ism'],
          code: 'let ism = "$name";\nconsole.log("Salom, " + ism);')),
      Q(3, (g) => g.quiz(const Tr('Nima bo‘ladi?', 'Что произойдёт?'), const Tr('Xato: const ni o‘zgartirib bo‘lmaydi', 'Ошибка: const нельзя изменить'),
          [lit('${age + 1}'), lit('$age'), const Tr('Hech narsa', 'Ничего')], code: 'const yosh = $age;\nyosh = ${age + 1};')),
    ], 2),
    g.fill(const Tr('O‘zgaruvchi e’lon qiling:', 'Объявите переменную:'), '', ' yosh = $age;', ['let', 'const', 'var']),
    g.tryIt(
      mode: 'js',
      task: Tr('yosh nomli o‘zgaruvchiga $age ni soling va uni console.log bilan chiqaring.',
          'Положите $age в переменную yosh и выведите её через console.log.'),
      start: '// kodingiz\n',
      hint: lit('let yosh = $age;\nconsole.log(yosh);'),
      check: (c, o) => has('\\b(let|const|var)\\s+yosh\\s*=\\s*$age\\b', c, ci: false) && has('console\\.log\\s*\\(\\s*yosh\\s*\\)', c, ci: false),
      solution: 'let yosh = $age;\nconsole.log(yosh);',
    ),
  ];
}

List<LessonStep> js3(Gen g) {
  final a = g.n(6, 20), b = g.n(2, 5);
  return [
    const LessonStep.read(
      h: Tr('Hisob-kitob', 'Вычисления'),
      p: Tr(
          'JS kalkulyator kabi ishlaydi: + qo‘shish, - ayirish, * ko‘paytirish, / bo‘lish, % — bo‘lgandagi qoldiq. '
              'Qavslar ichidagisi birinchi hisoblanadi, xuddi matematikadagidek.',
          'JS работает как калькулятор: + плюс, - минус, * умножить, / разделить, % — остаток от деления. '
              'Сначала считается то, что в скобках, как в математике.'),
      code: 'console.log(10 * 2);  // 20\nconsole.log(10 % 3);  // 1\nconsole.log((2 + 3) * 4); // 20',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Ko‘paytirish belgisi qaysi?', 'Какой знак умножения?'), '*', ['x', '×', '^'])),
      Q(2, (g) => g.quizCode(Tr('$a % $b nechaga teng?', 'Чему равно $a % $b?'), '${a % b}', ['${a ~/ b}', '${a * b}', '0'],
          e: Tr('$a ni $b ga bo‘lsak, qoldiq ${a % b} qoladi.', 'При делении $a на $b остаток ${a % b}.'))),
      Q(2, (g) => g.quizCode(Tr('($a + $b) * 2 nechaga teng?', 'Чему равно ($a + $b) * 2?'), '${(a + b) * 2}',
          ['${a + b * 2}', '${a + b}', '${a * b}'])),
      Q(3, (g) => g.quizCode(Tr('$a + $b * 2 nechaga teng?', 'Чему равно $a + $b * 2?'), '${a + b * 2}',
          ['${(a + b) * 2}', '${a + b}', '${a * 2 + b}'],
          e: const Tr('Avval ko‘paytirish, keyin qo‘shish.', 'Сначала умножение, потом сложение.'))),
    ], 2),
    g.fill(Tr('$a ning $b ga bo‘lgandagi qoldig‘i:', 'Остаток от деления $a на $b:'), 'console.log($a ', ' $b);', ['%']),
    g.tryIt(
      mode: 'js',
      task: Tr('$a va $b ning ko‘paytmasini console.log bilan chiqaring.', 'Выведите произведение $a и $b через console.log.'),
      start: '// kodingiz\n',
      hint: lit('console.log($a * $b);'),
      check: (c, o) => has('console\\.log\\s*\\(\\s*($a\\s*\\*\\s*$b|$b\\s*\\*\\s*$a|${a * b})\\s*\\)', c, ci: false),
      solution: 'console.log($a * $b);',
    ),
  ];
}

List<LessonStep> js4(Gen g) {
  final limit = g.n(50, 90);
  final score = g.n(30, 100);
  return [
    const LessonStep.read(
      h: Tr('Shartlar: agar… aks holda', 'Условия: если… иначе'),
      p: Tr(
          'Hayotda: “agar yomg‘ir yog‘sa — soyabon ol, aks holda — ko‘zoynak”. Kodda: if (shart) { … } else { … }. '
              'Taqqoslash: > katta, < kichik, >= katta yoki teng, === teng.',
          'В жизни: «если идёт дождь — возьми зонт, иначе — очки». В коде: if (условие) { … } else { … }. '
              'Сравнение: > больше, < меньше, >= больше или равно, === равно.'),
      code: 'let ball = 85;\nif (ball >= 80) {\n  console.log("A’lo");\n} else {\n  console.log("Yaxshi");\n}',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('“Teng” qanday tekshiriladi?', 'Как проверить «равно»?'), '===', ['=', '=>', '!='])),
      Q(2, (g) => g.quizCode(const Tr('Bu kod nima chiqaradi?', 'Что выведет этот код?'), score >= limit ? 'Ha' : 'Yo‘q',
          [score >= limit ? 'Yo‘q' : 'Ha', '$score', 'Xato'],
          code: 'let ball = $score;\nif (ball >= $limit) {\n  console.log("Ha");\n} else {\n  console.log("Yo‘q");\n}')),
      Q(3, (g) => g.quizCode(const Tr('Bu kod nima chiqaradi?', 'Что выведет этот код?'),
          score > 90 ? 'A' : (score > 70 ? 'B' : 'C'), ['A', 'B', 'C', 'D'].where((x) => x != (score > 90 ? 'A' : (score > 70 ? 'B' : 'C'))).toList(),
          code: 'let b = $score;\nif (b > 90) {\n  console.log("A");\n} else if (b > 70) {\n  console.log("B");\n} else {\n  console.log("C");\n}')),
    ], 2),
    g.order(const Tr('Shartni yig‘ing:', 'Соберите условие:'),
        ['if (ball >= $limit) {', '  console.log("O‘tdi");', '} else {', '  console.log("Yana urin");', '}']),
    g.tryIt(
      mode: 'js',
      task: Tr('ball $limit dan katta yoki teng bo‘lsa “Ha”, aks holda “Yo‘q” chiqaring.',
          'Если ball больше или равен $limit — выведите «Ha», иначе «Yo‘q».'),
      start: 'let ball = $score;\n',
      hint: lit('if (ball >= $limit) {\n  console.log("Ha");\n} else {\n  console.log("Yo‘q");\n}'),
      check: (c, o) => has('if\\s*\\(\\s*ball\\s*>=\\s*$limit\\s*\\)', c, ci: false) && has('\\belse\\b', c, ci: false) &&
          count('console\\.log', c, ci: false) >= 2,
      solution: 'let ball = $score;\nif (ball >= $limit) {\n  console.log("Ha");\n} else {\n  console.log("Yo‘q");\n}',
    ),
  ];
}

List<LessonStep> js5(Gen g) {
  final n = g.n(3, 7);
  return [
    const LessonStep.read(
      h: Tr('Sikllar: takrorlash', 'Циклы: повторение'),
      p: Tr(
          'Bir ishni 100 marta yozish o‘rniga sikl ishlatamiz. for (let i = 1; i <= 5; i++) — '
              'i 1 dan boshlanadi, 5 gacha boradi, har safar 1 ga oshadi (i++).',
          'Вместо того чтобы писать одно и то же 100 раз, используем цикл. for (let i = 1; i <= 5; i++) — '
              'i начинается с 1, идёт до 5 и каждый раз растёт на 1 (i++).'),
      code: 'for (let i = 1; i <= 3; i++) {\n  console.log(i);\n}\n// 1 2 3',
    ),
    ...g.from([
      Q(1, (g) => g.quiz(const Tr('i++ nima qiladi?', 'Что делает i++?'), const Tr('i ni 1 ga oshiradi', 'Увеличивает i на 1'),
          const [Tr('i ni 2 ga oshiradi', 'Увеличивает i на 2'), Tr('i ni o‘chiradi', 'Удаляет i'), Tr('i ni nolga tenglaydi', 'Обнуляет i')])),
      Q(2, (g) => g.quizCode(const Tr('Sikl necha marta ishlaydi?', 'Сколько раз выполнится цикл?'), '$n', ['${n + 1}', '${n - 1}', '1'],
          code: 'for (let i = 1; i <= $n; i++) {\n  console.log("Salom");\n}')),
      Q(3, (g) => g.quizCode(const Tr('Sikl necha marta ishlaydi?', 'Сколько раз выполнится цикл?'), '$n', ['${n + 1}', '${n - 1}', '0'],
          code: 'for (let i = 0; i < $n; i++) {\n  console.log(i);\n}',
          e: Tr('i: 0 dan ${n - 1} gacha — jami $n marta.', 'i: от 0 до ${n - 1} — всего $n раз.'))),
    ], 2),
    g.fill(const Tr('Har safar 1 ga oshiring:', 'Увеличивайте на 1 каждый раз:'), 'for (let i = 1; i <= $n; ', ') { … }', ['i++', 'i += 1', 'i = i + 1']),
    g.tryIt(
      mode: 'js',
      task: Tr('for sikli bilan 1 dan $n gacha sonlarni chiqaring.', 'Выведите числа от 1 до $n циклом for.'),
      start: '// kodingiz\n',
      hint: lit('for (let i = 1; i <= $n; i++) {\n  console.log(i);\n}'),
      check: (c, o) =>
          has('for\\s*\\(\\s*let\\s+\\w+\\s*=\\s*1\\s*;\\s*\\w+\\s*<=\\s*$n\\s*;', c, ci: false) ||
          has('for\\s*\\(\\s*let\\s+\\w+\\s*=\\s*1\\s*;\\s*\\w+\\s*<\\s*${n + 1}\\s*;', c, ci: false),
      solution: 'for (let i = 1; i <= $n; i++) {\n  console.log(i);\n}',
    ),
  ];
}

List<LessonStep> js6(Gen g) {
  final a = g.n(2, 9), b = g.n(2, 9);
  final fn = g.pick(['kvadrat', 'ikkilang', 'uchlang']);
  final mult = {'kvadrat': 0, 'ikkilang': 2, 'uchlang': 3}[fn]!;
  final arg = g.n(3, 9);
  final res = mult == 0 ? arg * arg : arg * mult;
  final body = mult == 0 ? 'n * n' : 'n * $mult';
  return [
    const LessonStep.read(
      h: Tr('Funksiyalar — o‘z buyrug‘ingiz', 'Функции — ваша собственная команда'),
      p: Tr(
          'Funksiya — retsept: bir marta yozasiz, xohlagancha ishlatasiz. function nom(parametr) { return natija; }. '
              'return — natijani qaytaradi.',
          'Функция — как рецепт: пишете один раз, используете сколько угодно. function имя(параметр) { return результат; }. '
              'return возвращает результат.'),
      code: 'function qoshish(a, b) {\n  return a + b;\n}\nconsole.log(qoshish(2, 3)); // 5',
    ),
    ...g.from([
      Q(1, (g) => g.quiz(const Tr('return nima qiladi?', 'Что делает return?'), const Tr('Natijani qaytaradi', 'Возвращает результат'),
          const [Tr('Sahifani yangilaydi', 'Обновляет страницу'), Tr('Xato chiqaradi', 'Выдаёт ошибку'), Tr('Funksiyani o‘chiradi', 'Удаляет функцию')])),
      Q(2, (g) => g.quizCode(Tr('qoshish($a, $b) nechaga teng?', 'Чему равно qoshish($a, $b)?'), '${a + b}', ['$a$b', '${a * b}', 'undefined'],
          code: 'function qoshish(a, b) {\n  return a + b;\n}')),
      Q(3, (g) => g.quizCode(Tr('$fn($arg) nechaga teng?', 'Чему равно $fn($arg)?'), '$res', ['$arg', '${res + 1}', '${arg + (mult == 0 ? arg : mult)}'],
          code: 'function $fn(n) {\n  return $body;\n}')),
    ], 2),
    g.order(const Tr('Funksiyani yig‘ing:', 'Соберите функцию:'), ['function $fn(n) {', '  return $body;', '}', 'console.log($fn($arg));']),
    g.tryIt(
      mode: 'js',
      task: Tr('$fn(n) funksiyasini yozing ($body ni qaytarsin) va $fn($arg) ni chiqaring.',
          'Напишите функцию $fn(n), возвращающую $body, и выведите $fn($arg).'),
      start: 'function $fn(n) {\n  \n}\n',
      hint: lit('return $body;\nconsole.log($fn($arg));'),
      check: (c, o) =>
          has('return\\s+${RegExp.escape(body).replaceAll(' ', '\\s*')}', c, ci: false) &&
          has('console\\.log\\s*\\(\\s*$fn\\s*\\(\\s*$arg\\s*\\)\\s*\\)', c, ci: false),
      solution: 'function $fn(n) {\n  return $body;\n}\nconsole.log($fn($arg));',
    ),
  ];
}
