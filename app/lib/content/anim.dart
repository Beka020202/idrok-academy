// Darslardagi animatsiyalar (ma’lumot qismi). Ko‘rsatish — screens/anim_player.dart.
// Анимации в уроках (данные). Отрисовка — screens/anim_player.dart.
//
// Turlari / виды:
//   trace  — kod qatorma-qator bajariladi: o‘zgaruvchi qutilari, ro‘yxat, konsol
//   render — HTML kod yoziladi va telefon ekranida natija paydo bo‘ladi
//   box    — CSS quti modeli: content → padding → border → margin
//   flex   — Flexbox: qutilar joylashuvi o‘zgaradi
//   learn  — AI o‘rganadi: nuqtalar va ajratuvchi chiziq
//   chat   — AI bilan suhbat pufakchalari
//   grid   — piksel rasm va namunalar bilan solishtirish
import 'model.dart';

class AnimFrame {
  final Tr say;
  final int line;
  final Map<String, String> vars;
  final String? hot;
  final List<String> out;
  final List<String>? arr;
  final String arrName;
  final int arrHot;
  final int reveal;
  final Map<String, Object> extra;
  const AnimFrame({
    required this.say,
    this.line = -1,
    this.vars = const {},
    this.hot,
    this.out = const [],
    this.arr,
    this.arrName = '',
    this.arrHot = -1,
    this.reveal = 0,
    this.extra = const {},
  });
}

/// HTML elementi (render uchun) / HTML-элемент (для отрисовки).
class RenderEl {
  final String tag, text;
  final Map<String, String> style;
  final int line; // qaysi kod qatoridan / из какой строки кода
  const RenderEl(this.tag, this.text, this.line, {this.style = const {}});
}

class AnimScene {
  final String kind, lang;
  final List<String> code;
  final List<AnimFrame> frames;
  final List<RenderEl> els;
  final List<(bool, Tr)> chat;
  final List<(double, double, int)> points; // learn: x, y, sinf / класс
  final List<List<int>> grids; // grid: 0/1 piksellar / пиксели
  const AnimScene({
    required this.kind,
    this.lang = '',
    this.code = const [],
    required this.frames,
    this.els = const [],
    this.chat = const [],
    this.points = const [],
    this.grids = const [],
  });
}

/// Kodni qadamma-qadam “bajaruvchi” yordamchi / помощник, «выполняющий» код по шагам.
class Tracer {
  final List<String> code;
  final String lang;
  final frames = <AnimFrame>[];
  final vars = <String, String>{};
  final out = <String>[];
  List<String>? arr;
  String arrName = '';
  Tracer(this.lang, this.code);

  void step(int line, Tr say, {String? set, Object? val, Object? print, int arrHot = -1}) {
    if (set != null) vars[set] = '$val';
    if (print != null) out.add('$print');
    frames.add(AnimFrame(
      say: say,
      line: line,
      vars: Map.of(vars),
      hot: set,
      out: List.of(out),
      arr: arr == null ? null : List.of(arr!),
      arrName: arrName,
      arrHot: arrHot,
    ));
  }

  AnimScene scene() => AnimScene(kind: 'trace', lang: lang, code: code, frames: frames);
}

String _q(String lang, String s) => '"$s"';
String _print(String lang, String x) => lang == 'js' ? 'console.log($x);' : 'print($x)';
String _let(String lang) => lang == 'js' ? 'let ' : '';
String _end(String lang) => lang == 'js' ? ';' : '';

// ============================================================ TRACE sahnalari / сцены TRACE
AnimScene tracePrint(Gen g, String lang) {
  final w = g.pick(const ['Salom', 'Idrok', 'Dunyo']);
  final n = g.n(2, 9);
  final code = [_print(lang, _q(lang, w)), _print(lang, '$n + 1'), _print(lang, _q(lang, 'Tayyor!'))];
  final t = Tracer(lang, code)
    ..step(-1, const Tr('Kompyuter kodni yuqoridan pastga, qatorma-qator bajaradi.', 'Компьютер выполняет код сверху вниз, строка за строкой.'))
    ..step(0, Tr('1-qator: qo‘shtirnoq ichidagi matn ekranga chiqadi — $w', 'Строка 1: текст в кавычках выводится на экран — $w'), print: w)
    ..step(1, Tr('2-qator: qo‘shtirnoqsiz — bu hisob! $n + 1 = ${n + 1}', 'Строка 2: без кавычек — это вычисление! $n + 1 = ${n + 1}'), print: n + 1)
    ..step(2, const Tr('3-qator ham bajarildi. Dastur tugadi!', 'Строка 3 тоже выполнена. Программа завершена!'), print: 'Tayyor!');
  return t.scene();
}

AnimScene traceVars(Gen g, String lang) {
  final a = g.n(3, 9), b = g.n(2, 6);
  final code = ['${_let(lang)}x = $a${_end(lang)}', 'x = x + $b${_end(lang)}', _print(lang, 'x')];
  final t = Tracer(lang, code)
    ..step(-1, const Tr('O‘zgaruvchi — nomli quti. Keling, kuzatamiz.', 'Переменная — коробка с именем. Давайте посмотрим.'))
    ..step(0, Tr('“x” nomli quti yaratildi va ichiga $a solindi.', 'Создана коробка «x», в неё положили $a.'), set: 'x', val: a)
    ..step(1, Tr('Avval o‘ng tomon hisoblanadi: x + $b = ${a + b}. Keyin natija qutiga yoziladi.',
        'Сначала считается правая часть: x + $b = ${a + b}. Потом результат кладут в коробку.'), set: 'x', val: a + b)
    ..step(2, Tr('Qutidagi qiymat ekranga chiqadi: ${a + b}', 'Значение из коробки выводится: ${a + b}'), print: a + b);
  return t.scene();
}

AnimScene traceInput(Gen g) {
  final name = g.pick(const ['Aziza', 'Bekzod', 'Laylo', 'Sardor']);
  final code = ['ism = input("Ismingiz? ")', 'print("Salom,", ism)'];
  final t = Tracer('py', code)
    ..step(0, const Tr('input() dastur to‘xtab, siz yozishingizni kutadi…', 'input() останавливает программу и ждёт, пока вы напишете…'))
    ..step(0, Tr('Siz “$name” deb yozdingiz — u “ism” qutisiga tushdi.', 'Вы написали «$name» — это попало в коробку «ism».'), set: 'ism', val: '"$name"')
    ..step(1, const Tr('print ikki narsani bo‘sh joy bilan chiqaradi.', 'print выводит две вещи через пробел.'), print: 'Salom, $name');
  return t.scene();
}

AnimScene traceMath(Gen g, String lang) {
  final a = g.n(11, 29), b = g.n(3, 5);
  final py = lang != 'js';
  final code = py
      ? ['a = $a', 'b = $b', 'print(a // b)', 'print(a % b)', 'print(b ** 2)']
      : ['let a = $a;', 'let b = $b;', 'console.log(Math.floor(a / b));', 'console.log(a % b);', 'console.log(b ** 2);'];
  final t = Tracer(lang, code)
    ..step(0, Tr('a = $a', 'a = $a'), set: 'a', val: a)
    ..step(1, Tr('b = $b', 'b = $b'), set: 'b', val: b)
    ..step(2, Tr('Butun bo‘lish: $a ni $b ga bo‘lsak, butun qismi ${a ~/ b}.', 'Целое деление: $a на $b — целая часть ${a ~/ b}.'), print: a ~/ b)
    ..step(3, Tr('Qoldiq: ${b * (a ~/ b)} dan keyin ${a % b} qoladi.', 'Остаток: после ${b * (a ~/ b)} остаётся ${a % b}.'), print: a % b)
    ..step(4, Tr('Daraja: $b × $b = ${b * b}', 'Степень: $b × $b = ${b * b}'), print: b * b);
  return t.scene();
}

AnimScene traceIf(Gen g, String lang) {
  final x = g.n(5, 30), lim = 18;
  final py = lang != 'js';
  final code = py
      ? ['t = $x', 'if t > $lim:', '    print("Issiq")', 'else:', '    print("Salqin")']
      : ['let t = $x;', 'if (t > $lim) {', '  console.log("Issiq");', '} else {', '  console.log("Salqin");', '}'];
  final big = x > lim;
  final t = Tracer(lang, code)..step(0, Tr('Harorat: $x°', 'Температура: $x°'), set: 't', val: x);
  t.step(1, Tr('Savol: $x > $lim mi? — ${big ? 'HA' : 'YO‘Q'}', 'Вопрос: $x > $lim? — ${big ? 'ДА' : 'НЕТ'}'));
  if (big) {
    t.step(2, const Tr('Shart to‘g‘ri — faqat shu blok bajariladi.', 'Условие верно — выполняется только этот блок.'), print: 'Issiq');
  } else {
    t.step(3, const Tr('Shart noto‘g‘ri — “aks holda” blokiga o‘tamiz.', 'Условие неверно — переходим в блок «иначе».'));
    t.step(4, const Tr('Faqat shu blok bajarildi.', 'Выполнен только этот блок.'), print: 'Salqin');
  }
  return t.scene();
}

AnimScene traceLoop(Gen g, String lang) {
  final n = g.n(3, 4);
  final py = lang != 'js';
  final code = py
      ? ['s = 0', 'for i in range(1, ${n + 1}):', '    s = s + i', 'print(s)']
      : ['let s = 0;', 'for (let i = 1; i <= $n; i++) {', '  s = s + i;', '}', 'console.log(s);'];
  final t = Tracer(lang, code)..step(0, const Tr('Yig‘indi uchun quti: s = 0', 'Коробка для суммы: s = 0'), set: 's', val: 0);
  var s = 0;
  for (var i = 1; i <= n; i++) {
    t.step(1, Tr('Sikl: i = $i', 'Цикл: i = $i'), set: 'i', val: i);
    s += i;
    t.step(2, Tr('s = ${s - i} + $i = $s', 's = ${s - i} + $i = $s'), set: 's', val: s);
  }
  t.step(1, Tr('i $n dan oshdi — sikl tugadi.', 'i больше $n — цикл окончен.'));
  t.step(py ? 3 : 4, Tr('Natija: 1 dan $n gacha yig‘indi = $s', 'Итог: сумма от 1 до $n = $s'), print: s);
  return t.scene();
}

AnimScene traceFunc(Gen g, String lang) {
  final a = g.n(2, 9);
  final py = lang != 'js';
  final code = py
      ? ['def ikki(x):', '    return x * 2', '', 'y = ikki($a)', 'print(y)']
      : ['function ikki(x) {', '  return x * 2;', '}', 'let y = ikki($a);', 'console.log(y);'];
  final t = Tracer(lang, code)
    ..step(0, const Tr('Funksiya — retsept. Hozircha faqat eslab qolinadi, bajarilmaydi.',
        'Функция — это рецепт. Пока его только запоминают, не выполняют.'))
    ..step(3, Tr('Chaqiruv: ikki($a) — $a funksiyaga “kirdi”.', 'Вызов: ikki($a) — $a «вошло» в функцию.'), set: 'x', val: a)
    ..step(1, Tr('Funksiya ichida: x * 2 = ${a * 2}. return natijani qaytaradi.', 'Внутри функции: x * 2 = ${a * 2}. return возвращает результат.'))
    ..step(3, Tr('Qaytgan ${a * 2} “y” qutisiga tushdi.', 'Вернувшееся ${a * 2} попало в коробку «y».'), set: 'y', val: a * 2)
    ..step(4, const Tr('Endi ikki() ni xohlagancha qayta ishlatish mumkin!', 'Теперь ikki() можно использовать сколько угодно раз!'), print: a * 2);
  return t.scene();
}

AnimScene traceList(Gen g) {
  final items = g.sample(const ['olma', 'nok', 'uzum', 'anor', 'shaftoli'], 4);
  final code = ['mevalar = ["${items[0]}", "${items[1]}", "${items[2]}"]', 'print(mevalar[0])', 'print(mevalar[2])', 'mevalar.append("${items[3]}")', 'print(len(mevalar))'];
  final t = Tracer('py', code)
    ..arr = items.sublist(0, 3)
    ..arrName = 'mevalar';
  t.step(0, const Tr('Ro‘yxat — tartiblangan qutilar qatori. Raqamlash 0 dan boshlanadi!', 'Список — ряд пронумерованных коробок. Нумерация с 0!'));
  t.step(1, Tr('mevalar[0] — birinchi quti: ${items[0]}', 'mevalar[0] — первая коробка: ${items[0]}'), print: items[0], arrHot: 0);
  t.step(2, Tr('mevalar[2] — uchinchi quti: ${items[2]}', 'mevalar[2] — третья коробка: ${items[2]}'), print: items[2], arrHot: 2);
  t.arr = items;
  t.step(3, Tr('append() oxiriga yangi quti qo‘shadi: ${items[3]}', 'append() добавляет коробку в конец: ${items[3]}'), arrHot: 3);
  t.step(4, const Tr('len() — nechta element bor: 4', 'len() — сколько элементов: 4'), print: 4);
  return t.scene();
}

// ============================================================ RENDER (HTML / CSS)
AnimScene renderHtml(Tr intro, List<(String, RenderEl?, Tr)> lines) {
  final els = [for (final l in lines) if (l.$2 != null) l.$2!];
  final frames = <AnimFrame>[AnimFrame(say: intro, reveal: 0)];
  var shown = 0;
  for (var k = 0; k < lines.length; k++) {
    if (lines[k].$2 != null) shown++;
    frames.add(AnimFrame(say: lines[k].$3, line: k, reveal: shown));
  }
  return AnimScene(kind: 'render', lang: 'html', code: [for (final l in lines) l.$1], frames: frames, els: els);
}

/// CSS: har qadamda maqsad → uslub (all | klass | #id) / CSS: на каждом шаге цель → стиль.
AnimScene renderCss(List<String> code, List<RenderEl> els, List<(int, Map<String, Map<String, String>>, Tr)> steps) {
  final frames = <AnimFrame>[
    for (final s in steps) AnimFrame(say: s.$3, line: s.$1, reveal: els.length, extra: {'styles': s.$2}),
  ];
  return AnimScene(kind: 'render', lang: 'css', code: code, frames: frames, els: els);
}

AnimScene boxModel() => const AnimScene(kind: 'box', lang: 'css', code: [
      '.quti {',
      '  padding: 16px;',
      '  border: 4px solid blue;',
      '  margin: 24px;',
      '}',
    ], frames: [
      AnimFrame(say: Tr('Har bir element — quti. Markazda — matn (content).', 'Каждый элемент — коробка. В центре — содержимое (content).'), extra: {'layer': 0}),
      AnimFrame(say: Tr('padding — matn va chegara orasidagi ichki joy.', 'padding — внутренний отступ между текстом и рамкой.'), line: 1, extra: {'layer': 1}),
      AnimFrame(say: Tr('border — qutining chegarasi (ramka).', 'border — граница (рамка) коробки.'), line: 2, extra: {'layer': 2}),
      AnimFrame(say: Tr('margin — qutidan tashqaridagi joy, qo‘shnilarni itaradi.', 'margin — место снаружи, отталкивает соседей.'), line: 3, extra: {'layer': 3}),
    ]);

AnimScene flexScene() => const AnimScene(kind: 'flex', lang: 'css', code: [
      '.qator {',
      '  display: flex;',
      '  justify-content: center;',
      '  gap: 12px;',
      '}',
    ], frames: [
      AnimFrame(say: Tr('Odatda bloklar bir-birining ostida turadi.', 'Обычно блоки стоят друг под другом.'), extra: {'mode': 'block'}),
      AnimFrame(say: Tr('display: flex — hammasi bir qatorga tizildi!', 'display: flex — все выстроились в ряд!'), line: 1, extra: {'mode': 'row'}),
      AnimFrame(say: Tr('justify-content: center — qator markazga keldi.', 'justify-content: center — ряд встал по центру.'), line: 2, extra: {'mode': 'center'}),
      AnimFrame(say: Tr('gap — qutilar orasida bir xil masofa.', 'gap — одинаковое расстояние между коробками.'), line: 3, extra: {'mode': 'gap'}),
    ]);

// ============================================================ AI sahnalari / сцены AI
AnimScene learnScene(Gen g) {
  // Ikki sinf: mushuklar (0) chapda-pastda, itlar (1) o‘ngda-yuqorida.
  // Два класса: кошки (0) слева снизу, собаки (1) справа сверху.
  final pts = <(double, double, int)>[];
  for (var k = 0; k < 7; k++) {
    pts.add((0.12 + g.r.nextDouble() * 0.33, 0.15 + g.r.nextDouble() * 0.35, 0));
    pts.add((0.55 + g.r.nextDouble() * 0.33, 0.5 + g.r.nextDouble() * 0.35, 1));
  }
  return AnimScene(kind: 'learn', points: pts, frames: const [
    AnimFrame(say: Tr('Misollar: 🐱 mushuklar va 🐶 itlar. O‘q: o‘lcham va quloq uzunligi.', 'Примеры: 🐱 кошки и 🐶 собаки. Оси: размер и длина ушей.'), reveal: 14, extra: {'line': -1.0}),
    AnimFrame(say: Tr('AI tasodifiy chiziq chizadi — ko‘p xato!', 'AI проводит случайную линию — много ошибок!'), reveal: 14, extra: {'line': 0.15}),
    AnimFrame(say: Tr('Xatolarni ko‘rib, chiziqni biroz suradi…', 'Видит ошибки и немного сдвигает линию…'), reveal: 14, extra: {'line': 0.35}),
    AnimFrame(say: Tr('…yana va yana. Bu — o‘qitish (training).', '…снова и снова. Это и есть обучение (training).'), reveal: 14, extra: {'line': 0.5}),
    AnimFrame(say: Tr('Yangi hayvon keldi ❓ — AI chiziqqa qarab “it” deydi.', 'Пришло новое животное ❓ — AI по линии говорит «собака».'), reveal: 14, extra: {'line': 0.5, 'new': 1}),
  ]);
}

AnimScene chatScene(Tr intro, List<(bool, Tr)> bubbles, List<Tr> says) {
  final frames = <AnimFrame>[AnimFrame(say: intro, reveal: 0)];
  for (var k = 0; k < bubbles.length; k++) {
    frames.add(AnimFrame(say: k < says.length ? says[k] : const Tr('', ''), reveal: k + 1));
  }
  return AnimScene(kind: 'chat', chat: bubbles, frames: frames);
}

/// 3×5 raqam rasmlari / изображения цифр 3×5.
const Map<int, List<int>> kDigits = {
  0: [1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1],
  1: [0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1],
  4: [1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 0, 1, 0, 0, 1],
  7: [1, 1, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0],
};

int pixelDiff(List<int> a, List<int> b) {
  var d = 0;
  for (var k = 0; k < a.length; k++) {
    if (a[k] != b[k]) d++;
  }
  return d;
}

AnimScene gridScene(Gen g) {
  final target = g.pick(const [0, 1, 4, 7]);
  final img = List.of(kDigits[target]!);
  final flip = g.n(0, 14);
  img[flip] = 1 - img[flip]; // bitta piksel “xira” / один пиксель «смазан»
  final ds = {for (final e in kDigits.entries) e.key: pixelDiff(img, e.value)};
  final frames = <AnimFrame>[
    const AnimFrame(say: Tr('Rasm — piksellar jadvali: 1 — qora, 0 — oq. Bu yerda bitta piksel buzilgan.',
        'Картинка — таблица пикселей: 1 — чёрный, 0 — белый. Здесь один пиксель испорчен.'), reveal: 0),
    for (final (k, d) in [for (final e in kDigits.entries) (e.key, ds[e.key]!)])
      AnimFrame(say: Tr('$k namunasi bilan farq: $d ta piksel', 'Отличие от образца $k: $d пикс.'), reveal: k + 1, extra: {'cmp': k, 'diff': d}),
    AnimFrame(say: Tr('Eng kam farq — $target. Javob: bu $target!', 'Меньше всего отличий — $target. Ответ: это $target!'), reveal: 99, extra: {'cmp': target, 'win': 1}),
  ];
  return AnimScene(kind: 'grid', frames: frames, grids: [img, for (final e in kDigits.entries) e.value]);
}
