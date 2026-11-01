// Python kursi — boshlovchilar uchun / курс Python — для начинающих.
import 'model.dart';

const _names = ['Ali', 'Laylo', 'Bekzod', 'Madina', 'Sardor'];
const _cities = ['Asaka', 'Andijon', 'Toshkent', 'Samarqand', 'Buxoro'];

List<LessonStep> py1(Gen g) {
  final name = g.pick(_names);
  final a = g.n(2, 12), b = g.n(2, 12);
  return [
    const LessonStep.read(
      h: Tr('Birinchi dastur', 'Первая программа'),
      p: Tr(
          'Python — eng sodda va eng mashhur tillardan biri (olimpiadalarda ham). print(...) — ekranga chiqaradi. '
              'Matn qo‘shtirnoqda: print("Salom"). Raqamlar qo‘shtirnoqsiz va hisoblanadi: print(2 + 3) → 5.',
          'Python — один из самых простых и популярных языков (и на олимпиадах). print(...) выводит на экран. '
              'Текст — в кавычках: print("Salom"). Числа без кавычек вычисляются: print(2 + 3) → 5.'),
      code: 'print("Salom, dunyo!")\nprint(2 + 3)',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(Tr('print($a + $b) nima chiqaradi?', 'Что выведет print($a + $b)?'), '${a + b}', ['$a + $b', '$a$b', 'Xato'])),
      Q(1, (g) => g.quizCode(const Tr('Ekranga chiqarish funksiyasi:', 'Функция вывода на экран:'), 'print', ['input', 'echo', 'show'])),
      Q(2, (g) => g.quizCode(Tr('print("$a + $b") nima chiqaradi?', 'Что выведет print("$a + $b")?'), '$a + $b', ['${a + b}', '$a$b', 'Xato'],
          e: const Tr('Qo‘shtirnoq ichidagisi matn — hisoblanmaydi.', 'Всё в кавычках — текст, он не вычисляется.'))),
      Q(3, (g) => g.quizCode(const Tr('Qaysi qatorda xato bor?', 'В какой строке ошибка?'), 'print(Salom)',
          ['print("Salom")', 'print(5)', "print('Salom')"],
          e: const Tr('Matn qo‘shtirnoqsiz yozilgan — Python uni o‘zgaruvchi deb o‘ylaydi.', 'Текст без кавычек — Python считает его переменной.'))),
    ], 2),
    g.fill(const Tr('Ekranga chiqaring:', 'Выведите на экран:'), '', '("$name")', ['print']),
    g.tryIt(
      mode: 'py',
      task: Tr('“$name” ismini ekranga chiqaring.', 'Выведите на экран имя «$name».'),
      start: 'print()\n',
      hint: lit('print("$name")'),
      check: (c, o) => o.contains(name),
      solution: 'print("$name")',
    ),
  ];
}

List<LessonStep> py2(Gen g) {
  final city = g.pick(_cities);
  final name = g.pick(_names);
  return [
    const LessonStep.read(
      h: Tr('O‘zgaruvchilar va input', 'Переменные и input'),
      p: Tr(
          'O‘zgaruvchi — nomli quti: ism = "Ali". input() — foydalanuvchidan so‘raydi. '
              'f-satr qiymatni matnga qo‘yadi: f"Salom, {ism}!" — {} ichiga o‘zgaruvchi yoziladi.',
          'Переменная — коробка с именем: ism = "Ali". input() спрашивает пользователя. '
              'f-строка вставляет значение в текст: f"Salom, {ism}!" — в {} пишут переменную.'),
      code: 'ism = input("Ismingiz? ")\nprint(f"Salom, {ism}!")',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Foydalanuvchidan so‘rash:', 'Спросить пользователя:'), 'input()', ['print()', 'ask()', 'read()'])),
      Q(2, (g) => g.quizCode(const Tr('Natija qanday?', 'Каким будет результат?'), 'Salom, $name!', ['Salom, {ism}!', 'Salom, ism!', 'Xato'],
          code: 'ism = "$name"\nprint(f"Salom, {ism}!")')),
      Q(3, (g) => g.quizCode(const Tr('Natija qanday?', 'Каким будет результат?'), 'Salom, {ism}!', ['Salom, $name!', 'Salom, ism!', 'Xato'],
          code: 'ism = "$name"\nprint("Salom, {ism}!")',
          e: const Tr('f harfi yo‘q — shuning uchun {ism} almashtirilmaydi.', 'Нет буквы f — поэтому {ism} не подставляется.'))),
    ], 2),
    g.fill(const Tr('f-satr yozing:', 'Напишите f-строку:'), 'print(', '"Men {shahar}da yashayman")', ['f']),
    g.tryIt(
      mode: 'py',
      task: Tr('shahar o‘zgaruvchisini f-satr bilan ishlatib “Men $city da yashayman” deb chiqaring.',
          'Используя переменную shahar и f-строку, выведите «Men $city da yashayman».'),
      start: 'shahar = "$city"\n',
      hint: lit('print(f"Men {shahar} da yashayman")'),
      check: (c, o) => has('f["\']', c, ci: false) && o.contains(city) && o.contains('yashayman') && !o.contains('{'),
      solution: 'shahar = "$city"\nprint(f"Men {shahar} da yashayman")',
    ),
  ];
}

List<LessonStep> py3(Gen g) {
  final a = g.n(10, 40), b = g.n(3, 7);
  return [
    const LessonStep.read(
      h: Tr('Sonlar bilan ishlash', 'Работа с числами'),
      p: Tr(
          '+ - * / — oddiy amallar. // — butun bo‘lish (17 // 5 = 3), % — qoldiq (17 % 5 = 2), ** — daraja (2 ** 3 = 8). '
              'Olimpiada masalalarida % va // juda ko‘p ishlatiladi!',
          '+ - * / — обычные действия. // — целочисленное деление (17 // 5 = 3), % — остаток (17 % 5 = 2), ** — степень (2 ** 3 = 8). '
              'В олимпиадных задачах % и // используются очень часто!'),
      code: 'print(17 // 5)  # 3\nprint(17 % 5)   # 2\nprint(2 ** 3)   # 8',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Darajaga ko‘tarish:', 'Возведение в степень:'), '**', ['^', '*', '//'])),
      Q(2, (g) => g.quizCode(Tr('print($a // $b) nima chiqaradi?', 'Что выведет print($a // $b)?'), '${a ~/ b}',
          ['${a % b}', '${(a / b).toStringAsFixed(1)}', '${a * b}'])),
      Q(2, (g) => g.quizCode(Tr('print($a % $b) nima chiqaradi?', 'Что выведет print($a % $b)?'), '${a % b}', ['${a ~/ b}', '0', '$b'])),
      Q(3, (g) => g.quiz(const Tr('Son juft ekanini qanday tekshiramiz?', 'Как проверить, что число чётное?'), lit('n % 2 == 0'),
          [lit('n // 2 == 0'), lit('n / 2 == 1'), lit('n ** 2 == 0')], mono: true)),
    ], 2),
    g.fill(Tr('$a ning $b ga bo‘lgandagi qoldig‘i:', 'Остаток от деления $a на $b:'), 'print($a ', ' $b)', ['%']),
    g.tryIt(
      mode: 'py',
      task: Tr('$a ni $b ga butun bo‘lish (//) va qoldig‘ini (%) ikki qatorda chiqaring.',
          'Выведите в двух строках $a // $b и $a % $b.'),
      start: 'a = $a\nb = $b\n',
      hint: lit('print(a // b)\nprint(a % b)'),
      check: (c, o) => outLines(o).length >= 2 && outLines(o)[0] == '${a ~/ b}' && outLines(o)[1] == '${a % b}',
      solution: 'a = $a\nb = $b\nprint(a // b)\nprint(a % b)',
    ),
  ];
}

List<LessonStep> py4(Gen g) {
  final t = g.n(-5, 35);
  final limit = g.n(15, 25);
  final word = t > limit ? 'Issiq' : 'Salqin';
  return [
    const LessonStep.read(
      h: Tr('Shartlar: if / elif / else', 'Условия: if / elif / else'),
      p: Tr(
          'if — “agar”, elif — “aks holda, agar”, else — “aks holda”. Shartdan keyin ikki nuqta (:) va ichki kod '
              '4 bo‘sh joy bilan suriladi — Python uchun bu juda muhim!',
          'if — «если», elif — «иначе, если», else — «иначе». После условия ставим двоеточие (:), а внутренний код '
              'сдвигаем на 4 пробела — для Python это очень важно!'),
      code: 'ball = 85\nif ball >= 90:\n    print("A’lo")\nelif ball >= 70:\n    print("Yaxshi")\nelse:\n    print("Harakat qil")',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Shartdan keyin nima qo‘yiladi?', 'Что ставится после условия?'), ':', [';', '{', '.'])),
      Q(2, (g) => g.quizCode(const Tr('Natija qanday?', 'Каким будет результат?'), word, [word == 'Issiq' ? 'Salqin' : 'Issiq', '$t', 'Xato'],
          code: 't = $t\nif t > $limit:\n    print("Issiq")\nelse:\n    print("Salqin")')),
      Q(3, (g) => g.quiz(const Tr('Bu kodda nima xato?', 'Что не так в этом коде?'),
          const Tr('print oldida 4 bo‘sh joy yo‘q', 'Перед print нет 4 пробелов'),
          const [Tr(': ortiqcha', 'Лишнее :'), Tr('if o‘rniga when kerak', 'Нужно when вместо if'), Tr('Xato yo‘q', 'Ошибки нет')],
          code: 'if 5 > 3:\nprint("Ha")')),
    ], 2),
    g.order(const Tr('Shartni yig‘ing:', 'Соберите условие:'), ['t = $t', 'if t > $limit:', '    print("Issiq")', 'else:', '    print("Salqin")']),
    g.tryIt(
      mode: 'py',
      task: Tr('n juft bo‘lsa “juft”, aks holda “toq” chiqaring.', 'Если n чётное — выведите «juft», иначе «toq».'),
      start: 'n = ${g.n(10, 99)}\n',
      hint: lit('if n % 2 == 0:\n    print("juft")\nelse:\n    print("toq")'),
      check: (c, o) {
        final m = RegExp(r'n\s*=\s*(\d+)').firstMatch(c);
        if (m == null || !has(r'\bif\b', c, ci: false)) return false;
        final n = int.parse(m.group(1)!);
        return o.trim() == (n % 2 == 0 ? 'juft' : 'toq');
      },
      solution: 'n = 42\nif n % 2 == 0:\n    print("juft")\nelse:\n    print("toq")',
    ),
  ];
}

List<LessonStep> py5(Gen g) {
  final n = g.n(4, 8);
  final st = g.n(1, 3);
  return [
    const LessonStep.read(
      h: Tr('for sikli va range', 'Цикл for и range'),
      p: Tr(
          'for i in range(5): — kodni 5 marta takrorlaydi, i esa 0, 1, 2, 3, 4 bo‘ladi. '
              'range(1, 6) — 1 dan 5 gacha (6 kirmaydi!). range(0, 10, 2) — 2 qadam bilan: 0, 2, 4, 6, 8.',
          'for i in range(5): — повторяет код 5 раз, а i будет 0, 1, 2, 3, 4. '
              'range(1, 6) — от 1 до 5 (6 не входит!). range(0, 10, 2) — с шагом 2: 0, 2, 4, 6, 8.'),
      code: 'for i in range(1, 4):\n    print(i)\n# 1\n# 2\n# 3',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(Tr('range($n) qaysi sonlarni beradi?', 'Какие числа даёт range($n)?'),
          [for (var i = 0; i < n; i++) '$i'].join(', '), [
        [for (var i = 1; i <= n; i++) '$i'].join(', '),
        [for (var i = 0; i <= n; i++) '$i'].join(', '),
        '$n',
      ])),
      Q(2, (g) => g.quizCode(const Tr('Sikl necha marta ishlaydi?', 'Сколько раз выполнится цикл?'), '${n - st}', ['${n - st + 1}', '$n', '${n - st - 1}'],
          code: 'for i in range($st, $n):\n    print(i)')),
      Q(3, (g) => g.quizCode(Tr('range(0, ${n * 2}, 2) nechta son beradi?', 'Сколько чисел даёт range(0, ${n * 2}, 2)?'), '$n',
          ['${n * 2}', '${n + 1}', '2'])),
    ], 2),
    g.fill(const Tr('Siklni to‘ldiring:', 'Допишите цикл:'), 'for i ', ' range($n):', ['in']),
    g.tryIt(
      mode: 'py',
      task: Tr('for sikli bilan 1 dan $n gacha sonlarni (har biri yangi qatorda) chiqaring.', 'Циклом for выведите числа от 1 до $n (каждое с новой строки).'),
      start: 'for i in range():\n    print(i)\n',
      hint: lit('for i in range(1, ${n + 1}):'),
      check: (c, o) => has(r'\bfor\b', c, ci: false) && words(o).join(' ') == [for (var i = 1; i <= n; i++) '$i'].join(' '),
      solution: 'for i in range(1, ${n + 1}):\n    print(i)',
    ),
  ];
}

List<LessonStep> py6(Gen g) {
  final nums = [for (var i = 0; i < 4; i++) g.n(2, 20)];
  final fruits = g.sample(['olma', 'nok', 'uzum', 'anor', 'gilos'], 3);
  return [
    const LessonStep.read(
      h: Tr('Ro‘yxatlar (list)', 'Списки (list)'),
      p: Tr(
          'Ro‘yxat — ko‘p qiymatni bitta o‘zgaruvchida saqlash: sonlar = [3, 7, 1]. Sanash 0 dan boshlanadi: sonlar[0] = 3. '
              'len() — elementlar soni, sum() — yig‘indi, max() — eng kattasi, .append(x) — oxiriga qo‘shish.',
          'Список хранит много значений в одной переменной: sonlar = [3, 7, 1]. Счёт с 0: sonlar[0] = 3. '
              'len() — количество, sum() — сумма, max() — максимум, .append(x) — добавить в конец.'),
      code: 'sonlar = [3, 7, 1]\nprint(sonlar[0])   # 3\nprint(len(sonlar)) # 3\nprint(sum(sonlar)) # 11',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Birinchi element indeksi:', 'Индекс первого элемента:'), '0', ['1', '-1', 'birinchi'])),
      Q(2, (g) => g.quizCode(Tr('sonlar = $nums. sonlar[1] nechaga teng?', 'sonlar = $nums. Чему равно sonlar[1]?'), '${nums[1]}',
          ['${nums[0]}', '${nums[2]}', '1'])),
      Q(2, (g) => g.quizCode(Tr('sum($nums) nechaga teng?', 'Чему равно sum($nums)?'), '${nums.reduce((a, b) => a + b)}',
          ['${nums.length}', '${nums.reduce((a, b) => a > b ? a : b)}', '${nums.reduce((a, b) => a + b) + 1}'])),
      Q(3, (g) => g.quizCode(const Tr('Natija qanday?', 'Каким будет результат?'), '${fruits.length + 1}',
          ['${fruits.length}', '1', 'Xato'], code: 'mevalar = ${fruits.map((f) => '"$f"').toList()}\nmevalar.append("shaftoli")\nprint(len(mevalar))')),
    ], 2),
    g.fill(const Tr('Ro‘yxat oxiriga qo‘shing:', 'Добавьте в конец списка:'), 'mevalar.', '("shaftoli")', ['append']),
    g.tryIt(
      mode: 'py',
      task: Tr('sonlar ro‘yxatining yig‘indisini va eng kattasini (ikki qatorda) chiqaring.',
          'Выведите сумму и максимум списка sonlar (в двух строках).'),
      start: 'sonlar = $nums\n',
      hint: lit('print(sum(sonlar))\nprint(max(sonlar))'),
      check: (c, o) =>
          outLines(o).length >= 2 &&
          outLines(o)[0] == '${nums.reduce((a, b) => a + b)}' &&
          outLines(o)[1] == '${nums.reduce((a, b) => a > b ? a : b)}',
      solution: 'sonlar = $nums\nprint(sum(sonlar))\nprint(max(sonlar))',
    ),
  ];
}
