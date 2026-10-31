// Darslar / Уроки.
// Kurs ma’lumotlari lessons.py dan avtomatik ko‘chirilgan; tekshirish qoidalari pastda.
// Данные курсов перенесены из lessons.py; правила проверки — ниже.
//
// MUHIM / ВАЖНО: yangi dars qo‘shsangiz, uni server/lessons.py ga ham qo‘shing
// (id va xp bir xil bo‘lsin). Добавляя урок, добавьте его и в server/lessons.py.

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

enum StepType { read, quiz, fill, tryIt }

/// (kod, natija) -> to‘g‘rimi / (код, вывод) -> верно ли.
typedef CodeCheck = bool Function(String code, String output);

class LessonStep {
  final StepType type;
  final Tr? h, p, q, e, task, hint;
  final String? code, pre, post, mode, start;
  final List<Tr> options;
  final int answer;
  final List<String> answers;
  final bool mono;
  final CodeCheck? check;

  const LessonStep._({
    required this.type,
    this.h,
    this.p,
    this.q,
    this.e,
    this.task,
    this.hint,
    this.code,
    this.pre,
    this.post,
    this.mode,
    this.start,
    this.options = const [],
    this.answer = 0,
    this.answers = const [],
    this.mono = false,
    this.check,
  });

  const LessonStep.read({required Tr h, required Tr p, String? code})
      : this._(type: StepType.read, h: h, p: p, code: code);

  const LessonStep.quiz({required Tr q, required List<Tr> o, required int answer, String? code, bool mono = false, Tr? e})
      : this._(type: StepType.quiz, q: q, options: o, answer: answer, code: code, mono: mono, e: e);

  const LessonStep.fill({required Tr q, required String pre, required String post, required List<String> answers, Tr? e})
      : this._(type: StepType.fill, q: q, pre: pre, post: post, answers: answers, e: e);

  const LessonStep.tryIt({required String mode, required Tr task, required String start, required Tr hint, required CodeCheck check})
      : this._(type: StepType.tryIt, mode: mode, task: task, start: start, hint: hint, check: check);

  /// Bosqich turi kaliti (tarjima uchun) / ключ типа шага (для перевода).
  String get kindKey => switch (type) {
        StepType.read => 'read',
        StepType.quiz => 'quiz',
        StepType.fill => 'fill',
        StepType.tryIt => 'try',
      };
}

class Lesson {
  final String id;
  final int xp;
  final Tr title;
  final List<LessonStep> steps;
  const Lesson({required this.id, required this.xp, required this.title, required this.steps});
}

class Course {
  final String id, tag, color;
  final Tr name, sub;
  final List<Lesson> lessons;
  const Course({required this.id, required this.tag, required this.color, required this.name, required this.sub, required this.lessons});
  List<String> get lessonIds => [for (final l in lessons) l.id];
}

// ---------------------------------------------------------------- tekshirish / проверка

bool _has(String pattern, String text, {bool ci = true}) =>
    RegExp(pattern, caseSensitive: !ci).hasMatch(text);

int _count(String pattern, String text, {bool ci = true}) =>
    RegExp(pattern, caseSensitive: !ci).allMatches(text).length;

List<String> _words(String s) {
  final t = s.trim();
  return t.isEmpty ? <String>[] : t.split(RegExp(r'\s+'));
}

final Map<String, CodeCheck> kChecks = {
  'html1': (c, o) => _has(r'<h1>\s*[^<\s][^<]*</h1>', c),
  'html2': (c, o) => _has(r'''<a\s+[^>]*href\s*=\s*["']https?://[^"']+["'][^>]*>\s*[^<\s][^<]*</a>''', c),
  'html3': (c, o) => _has(r'<ul>', c) && _count(r'<li>\s*[^<\s][^<]*</li>', c) >= 3,
  'css1': (c, o) => _has(r'h1\s*\{[^}]*\bcolor\s*:\s*[^;}\s]+', c),
  'css2': (c, o) => _has(r'p\s*\{[^}]*font-size\s*:\s*\d+(\.\d+)?(px|rem|em|pt)', c),
  'css3': (c, o) => _has(r'\.karta\s*\{[^}]*padding\s*:', c) && _has(r'\.karta\s*\{[^}]*border\s*:', c),
  'js1': (c, o) =>
      _has(r'\b(let|const|var)\s+yosh\s*=', c, ci: false) && _has(r'console\.log\s*\(\s*yosh', c, ci: false),
  'js2': (c, o) =>
      _has(r'if\s*\(', c, ci: false) && _has(r'\belse\b', c, ci: false) && _has(r'console\.log', c, ci: false),
  'js3': (c, o) =>
      _has(r'return\s+(n\s*\*\s*n|n\s*\*\*\s*2)', c, ci: false) &&
      _has(r'console\.log\s*\(\s*kvadrat\s*\(', c, ci: false),
  'py1': (c, o) => c.contains('print') && o.trim().isNotEmpty,
  'py2': (c, o) => _has(r'''f["']''', c, ci: false) && o.contains('yashayman') && !o.contains('{'),
  'py3': (c, o) => _has(r'\bfor\b', c, ci: false) && _words(o).join(' ') == '1 2 3 4 5',
};

// ---------------------------------------------------------------- kurslar / курсы


final List<Course> kCourses = [
  Course(id: 'html', tag: '</>', color: '#F86400', name: Tr('HTML', 'HTML'), sub: Tr('Veb-sahifa tuzilishi', 'Структура веб-страницы'), lessons: [
    Lesson(id: 'html1', xp: 15, title: Tr('Birinchi sahifa', 'Первая страница'), steps: [
      LessonStep.read(h: Tr('HTML nima?', 'Что такое HTML?'), p: Tr('HTML — veb-sahifaning skeleti. U teglardan iborat: ochuvchi <p> va yopuvchi </p>. Ular orasidagi matn sahifada ko‘rinadi.', 'HTML — это скелет веб-страницы. Он состоит из тегов: открывающего <p> и закрывающего </p>. Текст между ними видно на странице.'), code: '<h1>Salom, dunyo!</h1>\n<p>Bu mening birinchi sahifam.</p>'),
      LessonStep.quiz(q: Tr('Qaysi teg eng katta sarlavhani yaratadi?', 'Какой тег создаёт самый крупный заголовок?'), o: [Tr.same('<h1>'), Tr.same('<h6>'), Tr.same('<p>'), Tr.same('<head>')], answer: 0, mono: true, e: Tr('<h1> — eng muhim va eng katta sarlavha. <h6> esa eng kichigi.', '<h1> — самый важный и крупный заголовок. <h6> — самый маленький.')),
      LessonStep.quiz(q: Tr('Yopuvchi teg qanday yoziladi?', 'Как пишется закрывающий тег?'), o: [Tr.same('</p>'), Tr.same('<p/>'), Tr.same('<\\p>'), Tr.same('(p)')], answer: 0, mono: true, e: Tr('Yopuvchi teg nomidan oldin / belgisi qo‘yiladi.', 'В закрывающем теге перед именем ставится /.')),
      LessonStep.tryIt(mode: 'html', task: Tr('<h1> ichiga ismingizni yozing.', 'Напишите своё имя внутри <h1>.'), start: '<h1></h1>\n<p>Men dasturlashni o‘rganyapman.</p>', hint: Tr('<h1>Aziza</h1>', '<h1>Азиза</h1>'), check: kChecks['html1']!),
    ]),
    Lesson(id: 'html2', xp: 15, title: Tr('Havola va rasm', 'Ссылки и картинки'), steps: [
      LessonStep.read(h: Tr('Havola va rasm', 'Ссылки и картинки'), p: Tr('<a> — havola. Manzil href atributiga yoziladi. <img> — rasm: manba src ga, tavsif alt ga. <img> yopuvchi tegga ega emas.', '<a> — ссылка. Адрес пишется в атрибут href. <img> — картинка: источник в src, описание в alt. У <img> нет закрывающего тега.'), code: '<a href="https://uz.wikipedia.org">Vikipediya</a>\n<img src="mushuk.png" alt="Mushuk">'),
      LessonStep.quiz(q: Tr('Havola manzili qaysi atributga yoziladi?', 'В какой атрибут пишется адрес ссылки?'), o: [Tr.same('href'), Tr.same('src'), Tr.same('alt'), Tr.same('link')], answer: 0, mono: true, e: Tr('href — havola manzili.', 'href — адрес ссылки.')),
      LessonStep.fill(q: Tr('Rasm faylini ko‘rsating:', 'Укажите файл картинки:'), pre: '<img ', post: '="rasm.png" alt="Mushuk">', answers: ['src'], e: Tr('Rasm manbasi src atributida bo‘ladi.', 'Источник картинки задаётся в атрибуте src.')),
      LessonStep.tryIt(mode: 'html', task: Tr('https://uz.wikipedia.org saytiga istalgan matnli havola yarating.', 'Создайте ссылку с любым текстом на https://uz.wikipedia.org.'), start: '<p>Foydali sayt:</p>\n', hint: Tr('<a href="https://uz.wikipedia.org">Vikipediya</a>', '<a href="https://uz.wikipedia.org">Википедия</a>'), check: kChecks['html2']!),
    ]),
    Lesson(id: 'html3', xp: 15, title: Tr('Ro‘yxatlar', 'Списки'), steps: [
      LessonStep.read(h: Tr('Ro‘yxatlar', 'Списки'), p: Tr('<ul> — belgili ro‘yxat, <ol> — raqamli ro‘yxat. Har bir element <li> ichida yoziladi.', '<ul> — маркированный список, <ol> — нумерованный. Каждый пункт пишется внутри <li>.'), code: '<ul>\n  <li>Olma</li>\n  <li>Nok</li>\n</ul>'),
      LessonStep.quiz(q: Tr('Raqamli ro‘yxat uchun qaysi teg kerak?', 'Какой тег нужен для нумерованного списка?'), o: [Tr.same('<ol>'), Tr.same('<ul>'), Tr.same('<li>'), Tr.same('<nl>')], answer: 0, mono: true, e: Tr('<ol> — «ordered list», tartiblangan ro‘yxat.', '<ol> — «ordered list», упорядоченный список.')),
      LessonStep.tryIt(mode: 'html', task: Tr('Sevimli 3 ta faningiz bilan <ul> ro‘yxat tuzing.', 'Составьте список <ul> из 3 любимых предметов.'), start: '<h2>Sevimli fanlarim</h2>\n<ul>\n  \n</ul>', hint: Tr('<li>Matematika</li> — shunday 3 ta qator', '<li>Математика</li> — три такие строки'), check: kChecks['html3']!),
    ]),
  ]),
  Course(id: 'css', tag: '{ }', color: '#111111', name: Tr('CSS', 'CSS'), sub: Tr('Sahifani bezash', 'Оформление страницы'), lessons: [
    Lesson(id: 'css1', xp: 15, title: Tr('Ranglar', 'Цвета'), steps: [
      LessonStep.read(h: Tr('CSS qoidasi', 'Правило CSS'), p: Tr('CSS sahifaga ko‘rinish beradi. Qoida: selektor, keyin { } ichida «xususiyat: qiymat;». color — matn rangi, background-color — fon rangi.', 'CSS задаёт внешний вид страницы. Правило: селектор, затем в { } «свойство: значение;». color — цвет текста, background-color — цвет фона.'), code: 'h1 {\n  color: blue;\n  background-color: lightyellow;\n}'),
      LessonStep.quiz(q: Tr('Fon rangini qaysi xususiyat o‘zgartiradi?', 'Какое свойство меняет цвет фона?'), o: [Tr.same('background-color'), Tr.same('color'), Tr.same('font-color'), Tr.same('bg')], answer: 0, mono: true, e: Tr('color faqat matnga ta’sir qiladi, fon uchun background-color.', 'color влияет только на текст, для фона — background-color.')),
      LessonStep.fill(q: Tr('Paragraf matnini qizil qiling:', 'Сделайте текст абзаца красным:'), pre: 'p { ', post: ': red; }', answers: ['color'], e: Tr('Matn rangi — color.', 'Цвет текста — color.')),
      LessonStep.tryIt(mode: 'css', task: Tr('h1 sarlavhasiga istalgan rang bering.', 'Задайте заголовку h1 любой цвет.'), start: 'h1 {\n  \n}', hint: Tr('color: royalblue;', 'color: royalblue;'), check: kChecks['css1']!),
    ]),
    Lesson(id: 'css2', xp: 15, title: Tr('Matn', 'Текст'), steps: [
      LessonStep.read(h: Tr('Matn bilan ishlash', 'Работа с текстом'), p: Tr('font-size — o‘lcham, font-weight — qalinlik, text-align — tekislash (left, center, right).', 'font-size — размер, font-weight — жирность, text-align — выравнивание (left, center, right).'), code: 'h1 {\n  font-size: 32px;\n  font-weight: bold;\n  text-align: center;\n}'),
      LessonStep.quiz(q: Tr('Matnni markazga qanday tekislaymiz?', 'Как выровнять текст по центру?'), o: [Tr.same('text-align: center;'), Tr.same('align: middle;'), Tr.same('font-align: center;'), Tr.same('center: true;')], answer: 0, mono: true, e: Tr('text-align matnni gorizontal tekislaydi.', 'text-align выравнивает текст по горизонтали.')),
      LessonStep.fill(q: Tr('Sarlavha o‘lchamini belgilang:', 'Задайте размер заголовка:'), pre: 'h1 { font-', post: ': 32px; }', answers: ['size'], e: Tr('To‘liq nomi — font-size.', 'Полное название — font-size.')),
      LessonStep.tryIt(mode: 'css', task: Tr('p uchun font-size ni 22px qiling.', 'Сделайте font-size у p равным 22px.'), start: 'p {\n  \n}', hint: Tr('font-size: 22px;', 'font-size: 22px;'), check: kChecks['css2']!),
    ]),
    Lesson(id: 'css3', xp: 20, title: Tr('Quti modeli', 'Блочная модель'), steps: [
      LessonStep.read(h: Tr('Har bir element — quti', 'Каждый элемент — коробка'), p: Tr('padding — kontent va chegara orasidagi ichki joy. border — chegara. margin — boshqa elementlardan tashqi masofa.', 'padding — внутренний отступ между содержимым и рамкой. border — рамка. margin — внешний отступ от других элементов.'), code: '.karta {\n  padding: 16px;\n  border: 2px solid blue;\n  margin: 20px;\n}'),
      LessonStep.quiz(q: Tr('Kontent va chegara orasidagi ichki joy qanday ataladi?', 'Как называется внутренний отступ между содержимым и рамкой?'), o: [Tr.same('padding'), Tr.same('margin'), Tr.same('border'), Tr.same('gap')], answer: 0, mono: true, e: Tr('padding — ichki, margin — tashqi masofa.', 'padding — внутренний, margin — внешний отступ.')),
      LessonStep.quiz(q: Tr('Qaysi yozuv to‘g‘ri?', 'Какая запись правильная?'), o: [Tr.same('border: 2px solid blue;'), Tr.same('border: blue 2px line;'), Tr.same('border = 2px blue;'), Tr.same('border-all: 2px;')], answer: 0, mono: true, e: Tr('Tartib: qalinlik, uslub, rang.', 'Порядок: толщина, стиль, цвет.')),
      LessonStep.tryIt(mode: 'css', task: Tr('.karta ga padding va border qo‘shing.', 'Добавьте .karta свойства padding и border.'), start: '.karta {\n  \n}', hint: Tr('padding: 16px; border: 2px solid blue;', 'padding: 16px; border: 2px solid blue;'), check: kChecks['css3']!),
    ]),
  ]),
  Course(id: 'js', tag: 'JS', color: '#FFC800', name: Tr('JavaScript', 'JavaScript'), sub: Tr('Sahifaga jon berish', 'Оживляем страницу'), lessons: [
    Lesson(id: 'js1', xp: 15, title: Tr('O‘zgaruvchilar', 'Переменные'), steps: [
      LessonStep.read(h: Tr('Ma’lumotni saqlash', 'Храним данные'), p: Tr('O‘zgaruvchi — qiymat saqlanadigan quti. let qiymatni keyin o‘zgartirishga ruxsat beradi, const esa yo‘q. console.log() qiymatni chiqaradi.', 'Переменная — коробка для значения. let позволяет потом менять значение, const — нет. console.log() выводит значение.'), code: 'let ism = "Ali";\nconst yil = 2026;\nconsole.log(ism, yil);'),
      LessonStep.quiz(q: Tr('Qaysi o‘zgaruvchini qayta o‘zgartirib bo‘lmaydi?', 'Какую переменную нельзя переприсвоить?'), o: [Tr.same('const'), Tr.same('let'), Tr.same('var'), Tr.same('change')], answer: 0, mono: true, e: Tr('const — doimiy, uni qayta yozib bo‘lmaydi.', 'const — константа, её нельзя переприсвоить.')),
      LessonStep.fill(q: Tr('O‘zgaruvchi e’lon qiling:', 'Объявите переменную:'), pre: '', post: ' ism = "Ali";', answers: ['let', 'const', 'var'], e: Tr('let, const yoki var bilan e’lon qilinadi.', 'Объявляется через let, const или var.')),
      LessonStep.tryIt(mode: 'js', task: Tr('yosh nomli o‘zgaruvchi yarating va uni console.log bilan chiqaring.', 'Создайте переменную yosh и выведите её через console.log.'), start: '// kodingizni shu yerga yozing\n', hint: Tr('let yosh = 15;\nconsole.log(yosh);', 'let yosh = 15;\nconsole.log(yosh);'), check: kChecks['js1']!),
    ]),
    Lesson(id: 'js2', xp: 15, title: Tr('Shartlar', 'Условия'), steps: [
      LessonStep.read(h: Tr('Agar… aks holda', 'Если… иначе'), p: Tr('if sharti to‘g‘ri bo‘lsa, birinchi blok ishlaydi; aks holda else bloki. Tenglikni === bilan tekshiramiz.', 'Если условие if истинно, выполняется первый блок; иначе — блок else. Равенство проверяем через ===.'), code: 'let ball = 85;\nif (ball >= 80) {\n  console.log("A’lo");\n} else {\n  console.log("Yaxshi");\n}'),
      LessonStep.quiz(q: Tr('Bu kod nima chiqaradi?', 'Что выведет этот код?'), o: [Tr.same('katta'), Tr.same('kichik'), Tr.same('7'), Tr.same('Xato')], answer: 0, code: 'let b = 7;\nif (b > 5) {\n  console.log("katta");\n} else {\n  console.log("kichik");\n}', mono: true, e: Tr('7 > 5 to‘g‘ri, shuning uchun birinchi blok ishlaydi.', '7 > 5 — истина, поэтому выполняется первый блок.')),
      LessonStep.fill(q: Tr('Qat’iy tenglikni tekshiring:', 'Проверьте строгое равенство:'), pre: 'if (a ', post: ' 10) { … }', answers: ['==='], e: Tr('=== qiymat va turini tekshiradi.', '=== сравнивает и значение, и тип.')),
      LessonStep.tryIt(mode: 'js', task: Tr('ball 80 dan katta yoki teng bo‘lsa «A’lo», aks holda «Harakat qiling» deb chiqaring.', 'Если ball больше или равен 80, выведите «A’lo», иначе — «Harakat qiling».'), start: 'let ball = 92;\n', hint: Tr('if (ball >= 80) { console.log("A’lo"); } else { … }', 'if (ball >= 80) { console.log("A’lo"); } else { … }'), check: kChecks['js2']!),
    ]),
    Lesson(id: 'js3', xp: 20, title: Tr('Funksiyalar', 'Функции'), steps: [
      LessonStep.read(h: Tr('Qayta ishlatiladigan kod', 'Код, который можно повторять'), p: Tr('Funksiya — nomlangan kod bo‘lagi. U parametrlar oladi va return orqali natija qaytaradi.', 'Функция — именованный кусок кода. Она принимает параметры и возвращает результат через return.'), code: 'function qoshish(a, b) {\n  return a + b;\n}\nconsole.log(qoshish(2, 3)); // 5'),
      LessonStep.quiz(q: Tr('return nima qiladi?', 'Что делает return?'), o: [Tr('Natijani funksiyadan qaytaradi', 'Возвращает результат из функции'), Tr('Sahifani yangilaydi', 'Обновляет страницу'), Tr('Xato chiqaradi', 'Выдаёт ошибку'), Tr('Funksiyani o‘chiradi', 'Удаляет функцию')], answer: 0, e: Tr('return dan keyin funksiya to‘xtaydi va qiymat qaytaradi.', 'После return функция завершается и отдаёт значение.')),
      LessonStep.tryIt(mode: 'js', task: Tr('Sonning kvadratini qaytaradigan kvadrat(n) funksiyasini yozing va kvadrat(4) ni chiqaring.', 'Напишите функцию kvadrat(n), возвращающую квадрат числа, и выведите kvadrat(4).'), start: 'function kvadrat(n) {\n  \n}\n', hint: Tr('return n * n;\nconsole.log(kvadrat(4));', 'return n * n;\nconsole.log(kvadrat(4));'), check: kChecks['js3']!),
    ]),
  ]),
  Course(id: 'py', tag: 'Py', color: '#FF9500', name: Tr('Python', 'Python'), sub: Tr('Olimpiada tili', 'Язык олимпиад'), lessons: [
    Lesson(id: 'py1', xp: 15, title: Tr('print()', 'print()'), steps: [
      LessonStep.read(h: Tr('Birinchi dastur', 'Первая программа'), p: Tr('Python — sodda va kuchli til. print() ekranga ma’lumot chiqaradi. Matn qo‘shtirnoq ichida yoziladi.', 'Python — простой и мощный язык. print() выводит данные на экран. Текст пишется в кавычках.'), code: 'print("Salom, dunyo!")\nprint(2 + 3)'),
      LessonStep.quiz(q: Tr('print(2 + 3) nima chiqaradi?', 'Что выведет print(2 + 3)?'), o: [Tr.same('5'), Tr.same('2 + 3'), Tr.same('23'), Tr.same('Xato')], answer: 0, mono: true, e: Tr('Qo‘shtirnoqsiz ifoda hisoblanadi: 2 + 3 = 5.', 'Выражение без кавычек вычисляется: 2 + 3 = 5.')),
      LessonStep.fill(q: Tr('Ekranga chiqaring:', 'Выведите на экран:'), pre: '', post: '("Salom")', answers: ['print'], e: Tr('Chiqarish funksiyasi — print.', 'Функция вывода — print.')),
      LessonStep.tryIt(mode: 'py', task: Tr('Ismingizni ekranga chiqaring.', 'Выведите на экран своё имя.'), start: 'print()\n', hint: Tr('print("Aziza")', 'print("Азиза")'), check: kChecks['py1']!),
    ]),
    Lesson(id: 'py2', xp: 15, title: Tr('O‘zgaruvchi va input', 'Переменные и input'), steps: [
      LessonStep.read(h: Tr('Foydalanuvchidan so‘rash', 'Спрашиваем пользователя'), p: Tr('Pythonda turi yozilmaydi: ism = "Ali". input() foydalanuvchi kiritgan matnni oladi. f-satr ichida {} qiymat qo‘yadi.', 'В Python тип не указывается: ism = "Ali". input() получает введённый текст. В f-строке {} подставляет значение.'), code: 'ism = input("Ismingiz? ")\nprint(f"Salom, {ism}!")'),
      LessonStep.quiz(q: Tr('ism = "Laylo" bo‘lsa, print(f"Salom, {ism}") nima chiqaradi?', 'Если ism = "Laylo", что выведет print(f"Salom, {ism}")?'), o: [Tr.same('Salom, Laylo'), Tr.same('Salom, {ism}'), Tr.same('Salom, ism'), Tr.same('Xato')], answer: 0, mono: true, e: Tr('f-satr {ism} o‘rniga qiymatni qo‘yadi.', 'f-строка подставляет значение вместо {ism}.')),
      LessonStep.fill(q: Tr('Foydalanuvchidan so‘rang:', 'Спросите пользователя:'), pre: 'ism = ', post: '("Ismingiz? ")', answers: ['input'], e: Tr('Kiritish funksiyasi — input.', 'Функция ввода — input.')),
      LessonStep.tryIt(mode: 'py', task: Tr('shahar o‘zgaruvchisini yarating va f-satr bilan "Men ... da yashayman" deb chiqaring.', 'Создайте переменную shahar и выведите через f-строку "Men ... da yashayman".'), start: 'shahar = "Asaka"\n', hint: Tr('print(f"Men {shahar}da yashayman")', 'print(f"Men {shahar}da yashayman")'), check: kChecks['py2']!),
    ]),
    Lesson(id: 'py3', xp: 20, title: Tr('for sikli', 'Цикл for'), steps: [
      LessonStep.read(h: Tr('Takrorlash', 'Повторение'), p: Tr('for sikli kodni bir necha marta bajaradi. range(3) — 0, 1, 2 sonlari. Ichki kod 4 ta bo‘sh joy bilan suriladi.', 'Цикл for повторяет код несколько раз. range(3) — числа 0, 1, 2. Внутренний код сдвигается на 4 пробела.'), code: 'for i in range(3):\n    print(i)'),
      LessonStep.quiz(q: Tr('range(3) qaysi sonlarni beradi?', 'Какие числа даёт range(3)?'), o: [Tr.same('0, 1, 2'), Tr.same('1, 2, 3'), Tr.same('0, 1, 2, 3'), Tr.same('3')], answer: 0, mono: true, e: Tr('Hisob 0 dan boshlanadi va 3 gacha (3 kirmaydi).', 'Отсчёт с 0 и до 3 (3 не входит).')),
      LessonStep.fill(q: Tr('Siklni to‘ldiring:', 'Допишите цикл:'), pre: 'for i ', post: ' range(5):', answers: ['in'], e: Tr('To‘g‘ri yozuv: for i in range(5):', 'Правильно: for i in range(5):')),
      LessonStep.tryIt(mode: 'py', task: Tr('for sikli yordamida 1 dan 5 gacha sonlarni chiqaring (har biri yangi qatorda).', 'С помощью цикла for выведите числа от 1 до 5 (каждое с новой строки).'), start: 'for i in range():\n    print(i)\n', hint: Tr('for i in range(1, 6):', 'for i in range(1, 6):'), check: kChecks['py3']!),
    ]),
  ]),
];

final Map<String, (Lesson, Course)> kAllLessons = {
  for (final c in kCourses)
    for (final l in c.lessons) l.id: (l, c),
};

const String kPlaygroundStart = '# Kvadratlar jadvali\nn = int(input("Nechta son? "))\nfor i in range(1, n + 1):\n    print(i, "→", i * i)\n';
