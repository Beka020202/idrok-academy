// HTML kursi — boshlovchilar uchun / курс HTML — для начинающих.
import 'model.dart';

const _words = ['Salom', 'Idrok', 'Kod', 'Asaka', 'Python', 'Dunyo', 'Olma', 'Kitob'];
const _names = ['Aziza', 'Bekzod', 'Laylo', 'Sardor', 'Madina', 'Jasur'];

LessonStep _html1(Gen g) => g.from([
      Q(1, (g) => g.quizCode(const Tr('Paragrafni qaysi teg yopadi?', 'Какой тег закрывает абзац?'), '</p>',
          ['<p>', '<\\p>', '(p)', '<p/>'],
          e: const Tr('Yopuvchi teg nomidan oldin / qo‘yiladi: </p>.', 'В закрывающем теге перед именем стоит /: </p>.'))),
      Q(1, (g) => g.quiz(const Tr('<h1> nima yaratadi?', 'Что создаёт <h1>?'),
          const Tr('Katta sarlavha', 'Крупный заголовок'),
          const [Tr('Rasm', 'Картинку'), Tr('Havola', 'Ссылку'), Tr('Tugma', 'Кнопку')],
          e: const Tr('h1 — "heading 1", eng katta sarlavha.', 'h1 — «heading 1», самый крупный заголовок.'))),
      Q(2, (g) {
        final w = g.pick(_words);
        return g.quiz(const Tr('Ekranda nima ko‘rinadi?', 'Что появится на экране?'), lit(w),
            [lit('<h1>$w</h1>'), lit('h1'), const Tr('Hech narsa', 'Ничего')],
            code: '<h1>$w</h1>',
            e: const Tr('Teglar ko‘rinmaydi — faqat ular orasidagi matn chiqadi.',
                'Теги не видны — показывается только текст между ними.'));
      }),
      Q(2, (g) {
        final w = g.pick(_words);
        return g.quizCode(const Tr('Qaysi qator to‘g‘ri yozilgan?', 'Какая строка написана правильно?'), '<p>$w</p>',
            ['<p>$w<p>', '<p>$w</p', 'p>$w</p>'],
            e: const Tr('Ochuvchi <p> va yopuvchi </p> — ikkalasi ham to‘liq bo‘lishi kerak.',
                'Нужны оба тега полностью: открывающий <p> и закрывающий </p>.'));
      }),
      Q(3, (g) => g.quiz(const Tr('Bu kodda qanday xato bor?', 'Какая ошибка в этом коде?'),
          const Tr('Yopuvchi teg ochuvchiga mos emas', 'Закрывающий тег не совпадает с открывающим'),
          const [Tr('Xato yo‘q', 'Ошибки нет'), Tr('Matn juda qisqa', 'Текст слишком короткий'), Tr('h1 degan teg yo‘q', 'Тега h1 не существует')],
          code: '<h1>Salom</h2>',
          e: const Tr('<h1> bilan ochilgan teg </h1> bilan yopilishi kerak.', 'Тег, открытый как <h1>, закрывается </h1>.'))),
    ], 2);

List<LessonStep> html1(Gen g) {
  final w = g.pick(_words);
  final name = g.pick(_names);
  return [
    const LessonStep.read(
      h: Tr('HTML — sahifaning skeleti', 'HTML — скелет страницы'),
      p: Tr(
          'Har bir sayt HTML’dan quriladi. HTML — matnga yorliq qo‘yish: <h1> bu “katta sarlavha”, <p> bu “paragraf”. '
              'Yorliq ochiladi <p> va yopiladi </p>. Ekranda faqat ular orasidagi matn ko‘rinadi.',
          'Любой сайт построен из HTML. HTML — это ярлыки для текста: <h1> — «крупный заголовок», <p> — «абзац». '
              'Ярлык открывается <p> и закрывается </p>. На экране видно только текст между ними.'),
      code: '<h1>Salom!</h1>\n<p>Men dasturlashni o‘rganyapman.</p>',
    ),
    ..._html1(g),
    g.pick([
      g.fill(const Tr('Sarlavhani yoping:', 'Закройте заголовок:'), '<h1>$w', '', ['</h1>'],
          e: const Tr('h1 ochilgan — demak </h1> bilan yopiladi.', 'Открыт h1 — значит закрываем </h1>.')),
      g.order(const Tr('Paragrafni to‘g‘ri tartibda yig‘ing:', 'Соберите абзац в правильном порядке:'), ['<p>', w, '</p>'],
          e: const Tr('Avval ochuvchi teg, keyin matn, oxirida yopuvchi teg.', 'Сначала открывающий тег, потом текст, в конце закрывающий.')),
    ]),
    g.tryIt(
      mode: 'html',
      task: Tr('<h1> ichiga “$name” ismini yozing.', 'Напишите имя «$name» внутри <h1>.'),
      start: '<h1></h1>',
      hint: lit('<h1>$name</h1>'),
      check: (c, o) => has('<h1>\\s*$name\\s*</h1>', c),
      solution: '<h1>$name</h1>',
    ),
  ];
}

List<LessonStep> html2(Gen g) {
  final n = g.n(2, 6);
  final w = g.pick(_words);
  return [
    const LessonStep.read(
      h: Tr('Sarlavhalar va paragraflar', 'Заголовки и абзацы'),
      p: Tr(
          'Sarlavhalar 6 xil: <h1> eng katta, <h6> eng kichik. Xuddi kitobdagi bob va bo‘lim nomlari kabi. '
              'Oddiy matn <p> ichida yoziladi. Har bir paragraf yangi qatordan boshlanadi.',
          'Заголовков 6 видов: <h1> самый крупный, <h6> самый мелкий — как названия глав и разделов в книге. '
              'Обычный текст пишут внутри <p>. Каждый абзац начинается с новой строки.'),
      code: '<h1>Kitob nomi</h1>\n<h2>1-bob</h2>\n<p>Bu birinchi paragraf.</p>\n<p>Bu ikkinchi paragraf.</p>',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Eng kichik sarlavha qaysi?', 'Какой заголовок самый маленький?'), '<h6>', ['<h1>', '<h3>', '<p>'],
          e: const Tr('Raqam qancha katta bo‘lsa, sarlavha shuncha kichik.', 'Чем больше цифра, тем меньше заголовок.'))),
      Q(1, (g) => g.quizCode(const Tr('Oddiy matn qaysi tegda yoziladi?', 'В каком теге пишут обычный текст?'), '<p>', ['<h1>', '<text>', '<a>'],
          e: const Tr('<p> — paragraph, ya’ni paragraf.', '<p> — paragraph, то есть абзац.'))),
      Q(2, (g) => g.quizCode(Tr('<h$n> ga qaraganda kattaroq sarlavha qaysi?', 'Какой заголовок крупнее, чем <h$n>?'), '<h${n - 1}>',
          ['<h${n + 1 > 6 ? 6 : n + 1}>', '<p>', '<h${n}x>'],
          e: const Tr('Kichikroq raqam — kattaroq sarlavha.', 'Меньше цифра — крупнее заголовок.'))),
      Q(2, (g) => g.quiz(const Tr('Bu kodda nechta paragraf bor?', 'Сколько абзацев в этом коде?'), lit('$n'),
          [lit('${n + 1}'), lit('${n - 1}'), lit('1')],
          code: [for (var i = 1; i <= n; i++) '<p>$i-qator</p>'].join('\n'))),
      Q(3, (g) => g.quiz(const Tr('Nima uchun bu yerda h1 noto‘g‘ri tanlangan?', 'Почему здесь h1 выбран неудачно?'),
          const Tr('Uzun oddiy matn uchun <p> kerak', 'Для длинного обычного текста нужен <p>'),
          const [Tr('h1 faqat raqamlar uchun', 'h1 только для чисел'), Tr('h1 yopilmaydi', 'h1 не закрывается'), Tr('Hammasi to‘g‘ri', 'Всё правильно')],
          code: '<h1>Bugun men maktabga bordim va do‘stlarim bilan uchrashdim...</h1>')),
    ], 2),
    g.pick([
      g.fill(const Tr('Ikkinchi darajali sarlavha yozing:', 'Напишите заголовок второго уровня:'), '<', '>Bo‘lim</h2>', ['h2']),
      g.order(const Tr('Sahifani yuqoridan pastga yig‘ing:', 'Соберите страницу сверху вниз:'),
          ['<h1>$w</h1>', '<h2>Kirish</h2>', '<p>Birinchi paragraf.</p>'],
          e: const Tr('Avval katta sarlavha, keyin kichikrog‘i, so‘ng matn.', 'Сначала крупный заголовок, затем поменьше, потом текст.')),
    ]),
    g.tryIt(
      mode: 'html',
      task: Tr('$n ta paragraf (<p>) yozing — har biriga istalgan matn.', 'Напишите $n абзаца(ев) (<p>) с любым текстом.'),
      start: '<h1>Mening kunim</h1>\n',
      hint: lit('<p>Ertalab turdim.</p> — shunday $n ta'),
      check: (c, o) => count('<p>\\s*[^<\\s][^<]*</p>', c) >= n,
      solution: '<h1>Mening kunim</h1>\n${[for (var i = 1; i <= n; i++) '<p>Qator $i</p>'].join('\n')}',
    ),
  ];
}

List<LessonStep> html3(Gen g) {
  final site = g.pick(['https://uz.wikipedia.org', 'https://kun.uz', 'https://google.com']);
  final img = g.pick(['mushuk.png', 'maktab.jpg', 'logo.png']);
  return [
    const LessonStep.read(
      h: Tr('Havola va rasm', 'Ссылки и картинки'),
      p: Tr(
          '<a> — havola: bosilsa boshqa sahifa ochiladi. Manzil href ichiga yoziladi. '
              '<img> — rasm: fayl src ichida, tavsif alt ichida. <img> yopilmaydi — u “bo‘sh” teg.',
          '<a> — ссылка: при нажатии открывает другую страницу. Адрес пишут в href. '
              '<img> — картинка: файл в src, описание в alt. <img> не закрывается — это «пустой» тег.'),
      code: '<a href="https://kun.uz">Yangiliklar</a>\n<img src="mushuk.png" alt="Mushuk">',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Havola manzili qaysi atributda?', 'В каком атрибуте адрес ссылки?'), 'href', ['src', 'alt', 'link'])),
      Q(1, (g) => g.quizCode(const Tr('Rasm fayli qaysi atributda?', 'В каком атрибуте файл картинки?'), 'src', ['href', 'alt', 'img'])),
      Q(2, (g) => g.quiz(const Tr('alt nima uchun kerak?', 'Зачем нужен alt?'),
          const Tr('Rasm ochilmasa — uning tavsifi', 'Описание, если картинка не загрузилась'),
          const [Tr('Rasm o‘lchami', 'Размер картинки'), Tr('Havola manzili', 'Адрес ссылки'), Tr('Rasm rangi', 'Цвет картинки')])),
      Q(2, (g) => g.quiz(const Tr('Bu havola bosilsa qayerga olib boradi?', 'Куда ведёт эта ссылка?'), lit(site),
          [const Tr('“Ochish” sahifasiga', 'На страницу «Ochish»'), lit('<a>'), const Tr('Hech qayerga', 'Никуда')],
          code: '<a href="$site">Ochish</a>')),
      Q(3, (g) => g.quiz(const Tr('Xato qayerda?', 'Где ошибка?'),
          const Tr('<img> yopuvchi tegga muhtoj emas', '<img> не нужен закрывающий тег'),
          const [Tr('src noto‘g‘ri yozilgan', 'src написан неверно'), Tr('alt bo‘lmasligi kerak', 'alt не должно быть'), Tr('Xato yo‘q', 'Ошибки нет')],
          code: '<img src="$img" alt="Rasm"></img>')),
    ], 2),
    g.pick([
      g.fill(const Tr('Rasm faylini ko‘rsating:', 'Укажите файл картинки:'), '<img ', '="$img" alt="Rasm">', ['src']),
      g.fill(const Tr('Havola manzilini qo‘ying:', 'Укажите адрес ссылки:'), '<a ', '="$site">Ochish</a>', ['href']),
    ]),
    g.tryIt(
      mode: 'html',
      task: Tr('$site saytiga havola yarating (matni istalgan).', 'Создайте ссылку на $site (текст любой).'),
      start: '<p>Foydali sayt:</p>\n',
      hint: lit('<a href="$site">Ochish</a>'),
      check: (c, o) => has('<a\\s+[^>]*href\\s*=\\s*["\']${RegExp.escape(site)}/?["\'][^>]*>\\s*[^<\\s][^<]*</a>', c),
      solution: '<p>Foydali sayt:</p>\n<a href="$site">Ochish</a>',
    ),
  ];
}

List<LessonStep> html4(Gen g) {
  final n = g.n(3, 5);
  final items = g.sample(['Olma', 'Nok', 'Uzum', 'Anor', 'Shaftoli', 'Gilos'], 3);
  return [
    const LessonStep.read(
      h: Tr('Ro‘yxatlar', 'Списки'),
      p: Tr(
          '<ul> — nuqtali ro‘yxat (xarid ro‘yxati kabi). <ol> — raqamli ro‘yxat (retsept qadamlari kabi). '
              'Har bir element <li> ichida yoziladi.',
          '<ul> — маркированный список (как список покупок). <ol> — нумерованный (как шаги рецепта). '
              'Каждый пункт пишут внутри <li>.'),
      code: '<ul>\n  <li>Non</li>\n  <li>Sut</li>\n</ul>',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Ro‘yxat elementi qaysi teg?', 'Какой тег у пункта списка?'), '<li>', ['<ul>', '<ol>', '<p>'])),
      Q(1, (g) => g.quizCode(const Tr('Raqamli ro‘yxat qaysi?', 'Какой список нумерованный?'), '<ol>', ['<ul>', '<li>', '<nl>'],
          e: const Tr('ol — ordered list, tartiblangan ro‘yxat.', 'ol — ordered list, упорядоченный список.'))),
      Q(2, (g) => g.quiz(const Tr('Ro‘yxatda nechta element bor?', 'Сколько пунктов в списке?'), lit('$n'),
          [lit('${n + 1}'), lit('1'), lit('${n - 1}')],
          code: '<ol>\n${[for (var i = 1; i <= n; i++) '  <li>Qadam $i</li>'].join('\n')}\n</ol>')),
      Q(3, (g) => g.quiz(const Tr('Retsept qadamlari uchun qaysi ro‘yxat yaxshi?', 'Какой список лучше для шагов рецепта?'),
          const Tr('<ol>, chunki tartib muhim', '<ol>, потому что важен порядок'),
          const [Tr('<ul>, chunki chiroyli', '<ul>, потому что красиво'), Tr('<li> yolg‘iz o‘zi', 'Один <li>'), Tr('<p>', '<p>')])),
    ], 2),
    g.order(const Tr('Ro‘yxatni yig‘ing:', 'Соберите список:'), ['<ul>', '  <li>${items[0]}</li>', '  <li>${items[1]}</li>', '</ul>'],
        e: const Tr('<ul> ochiladi, ichida <li> lar, oxirida </ul>.', 'Открываем <ul>, внутри пункты <li>, в конце </ul>.')),
    g.tryIt(
      mode: 'html',
      task: Tr('$n ta mevadan iborat <ul> ro‘yxat tuzing.', 'Составьте список <ul> из $n фруктов.'),
      start: '<h2>Mevalar</h2>\n<ul>\n  \n</ul>',
      hint: lit('<li>Olma</li> — shunday $n ta qator'),
      check: (c, o) => has('<ul>', c) && count('<li>\\s*[^<\\s][^<]*</li>', c) >= n,
      solution: '<h2>Mevalar</h2>\n<ul>\n${[for (var i = 0; i < n; i++) '  <li>Meva $i</li>'].join('\n')}\n</ul>',
    ),
  ];
}

List<LessonStep> html5(Gen g) {
  final title = g.pick(['Mening saytim', 'Idrok', 'Sevimli kitoblarim']);
  return [
    const LessonStep.read(
      h: Tr('Sahifa tuzilishi', 'Структура страницы'),
      p: Tr(
          'To‘liq sahifa uyga o‘xshaydi: <html> — butun uy, <head> — chordoq (ko‘rinmaydigan sozlamalar, masalan <title>), '
              '<body> — xonalar (ko‘rinadigan hamma narsa).',
          'Полная страница похожа на дом: <html> — весь дом, <head> — чердак (невидимые настройки, например <title>), '
              '<body> — комнаты (всё, что видно).'),
      code: '<html>\n  <head>\n    <title>Sarlavha</title>\n  </head>\n  <body>\n    <h1>Salom!</h1>\n  </body>\n</html>',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Ko‘rinadigan matn qayerga yoziladi?', 'Куда пишут видимый текст?'), '<body>', ['<head>', '<title>', '<html>'])),
      Q(2, (g) => g.quiz(const Tr('<title> qayerda ko‘rinadi?', 'Где виден <title>?'),
          const Tr('Brauzer yorlig‘ida (tab)', 'На вкладке браузера'),
          const [Tr('Sahifa o‘rtasida', 'В центре страницы'), Tr('Hech qayerda', 'Нигде'), Tr('Rasm ostida', 'Под картинкой')])),
      Q(3, (g) => g.quiz(const Tr('Bu tuzilishda nima noto‘g‘ri?', 'Что не так в этой структуре?'),
          const Tr('<h1> <head> ichida — u <body> da bo‘lishi kerak', '<h1> внутри <head> — он должен быть в <body>'),
          const [Tr('Hammasi to‘g‘ri', 'Всё правильно'), Tr('<title> ortiqcha', '<title> лишний'), Tr('<html> kerak emas', '<html> не нужен')],
          code: '<html>\n  <head>\n    <h1>Salom</h1>\n  </head>\n  <body></body>\n</html>')),
    ], 2),
    g.order(const Tr('Sahifa skeletini yig‘ing:', 'Соберите скелет страницы:'),
        ['<html>', '<head><title>$title</title></head>', '<body><h1>$title</h1></body>', '</html>']),
    g.tryIt(
      mode: 'html',
      task: Tr('<title> ga “$title” yozing va <body> ichida <h1> qo‘shing.', 'Впишите «$title» в <title> и добавьте <h1> в <body>.'),
      start: '<html>\n  <head>\n    <title></title>\n  </head>\n  <body>\n  </body>\n</html>',
      hint: lit('<title>$title</title> … <body><h1>$title</h1></body>'),
      check: (c, o) =>
          has('<title>\\s*${RegExp.escape(title)}\\s*</title>', c) && has('<body>[\\s\\S]*<h1>[^<]+</h1>[\\s\\S]*</body>', c),
      solution:
          '<html>\n  <head>\n    <title>$title</title>\n  </head>\n  <body>\n    <h1>$title</h1>\n  </body>\n</html>',
    ),
  ];
}

List<LessonStep> html6(Gen g) {
  final field = g.pick(['Ism', 'Shahar', 'Maktab']);
  return [
    const LessonStep.read(
      h: Tr('Formalar: foydalanuvchidan so‘rash', 'Формы: спрашиваем пользователя'),
      p: Tr(
          '<input> — matn kiritish maydoni (u ham yopilmaydi). placeholder — maydon ichidagi xira yozuv. '
              '<button> — tugma. <label> — maydon nomi.',
          '<input> — поле для ввода текста (тоже не закрывается). placeholder — бледная подсказка внутри поля. '
              '<button> — кнопка. <label> — название поля.'),
      code: '<label>Ism</label>\n<input placeholder="Ismingiz">\n<button>Yuborish</button>',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Tugma qaysi teg?', 'Какой тег у кнопки?'), '<button>', ['<input>', '<a>', '<click>'])),
      Q(1, (g) => g.quizCode(const Tr('Matn kiritish maydoni qaysi?', 'Какое поле для ввода текста?'), '<input>', ['<p>', '<label>', '<text>'])),
      Q(2, (g) => g.quiz(const Tr('placeholder nima?', 'Что такое placeholder?'),
          const Tr('Maydon ichidagi xira maslahat', 'Бледная подсказка внутри поля'),
          const [Tr('Tugma rangi', 'Цвет кнопки'), Tr('Maydon nomi tepada', 'Название поля сверху'), Tr('Sahifa sarlavhasi', 'Заголовок страницы')])),
      Q(3, (g) => g.quiz(const Tr('Qaysi teg yopilmaydi?', 'Какой тег не закрывается?'), lit('<input>'),
          [lit('<button>'), lit('<label>'), lit('<p>')], mono: true)),
    ], 2),
    g.fill(Tr('“$field” uchun maslahat yozing:', 'Добавьте подсказку для «$field»:'), '<input ', '="$field">', ['placeholder']),
    g.tryIt(
      mode: 'html',
      task: Tr('placeholder=“$field” bo‘lgan <input> va bitta <button> yarating.', 'Создайте <input> с placeholder «$field» и одну <button>.'),
      start: '<label>$field</label>\n',
      hint: lit('<input placeholder="$field">\n<button>Yuborish</button>'),
      check: (c, o) => has('<input[^>]*placeholder\\s*=\\s*["\']$field["\']', c) && has('<button>[^<]+</button>', c),
      solution: '<label>$field</label>\n<input placeholder="$field">\n<button>Yuborish</button>',
    ),
  ];
}
