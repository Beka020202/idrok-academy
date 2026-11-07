// Qo‘shimcha darslar: HTML 7–9, CSS 7–9, JavaScript 7–9, Python 7–9.
// Дополнительные уроки: HTML 7–9, CSS 7–9, JavaScript 7–9, Python 7–9.
import 'anim.dart';
import 'model.dart';

const _names = ['Aziza', 'Bekzod', 'Laylo', 'Sardor', 'Madina', 'Jasur'];
const _fruits = ['olma', 'nok', 'uzum', 'anor', 'gilos', 'shaftoli'];
const _subjects = ['Matematika', 'Ona tili', 'Ingliz tili', 'Fizika', 'Tarix', 'Informatika'];

RenderEl _e(String tag, String text, int line, [Map<String, String> style = const {}]) => RenderEl(tag, text, line, style: style);

const _watch = Tr('Ko‘k tugmani bosing yoki barmoq bilan suring — har bir qadamni ko‘rasiz.',
    'Нажмите синюю кнопку или листайте пальцем — увидите каждый шаг.');

// ============================================================ HTML 7 — jadvallar / таблицы
List<LessonStep> html7(Gen g) {
  final subj = g.sample(_subjects, 3);
  final n = g.n(2, 5);
  return [
    const LessonStep.read(
      h: Tr('Jadvallar: table, tr, td', 'Таблицы: table, tr, td'),
      p: Tr(
          'Jadval — qator va ustunlar. <table> jadvalni ochadi, <tr> — bitta qator (table row), <td> — bitta katak (table data). '
              '<th> — sarlavha katagi, u qalin bo‘ladi. Dars jadvali, baholar, narxlar — hammasi jadval.',
          'Таблица — это строки и столбцы. <table> открывает таблицу, <tr> — одна строка (table row), <td> — одна ячейка (table data). '
              '<th> — ячейка-заголовок, она жирная. Расписание, оценки, цены — всё это таблицы.'),
      code: '<table>\n  <tr><th>Fan</th><th>Baho</th></tr>\n  <tr><td>Matematika</td><td>5</td></tr>\n</table>',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Jadvalning bitta qatori qaysi teg?', 'Какой тег — одна строка таблицы?'), '<tr>',
          ['<td>', '<row>', '<th>'],
          e: const Tr('tr — table row, ya’ni “jadval qatori”.', 'tr — table row, то есть «строка таблицы».'))),
      Q(1, (g) => g.quizCode(const Tr('Oddiy katak qaysi teg?', 'Какой тег — обычная ячейка?'), '<td>', ['<tr>', '<cell>', '<table>'],
          e: const Tr('td — table data, katak ichidagi ma’lumot.', 'td — table data, данные в ячейке.'))),
      Q(2, (g) => g.quiz(const Tr('<th> katagi <td> dan nimasi bilan farq qiladi?', 'Чем ячейка <th> отличается от <td>?'),
          const Tr('Sarlavha — qalin va markazda', 'Это заголовок — жирный и по центру'),
          const [Tr('Rangli bo‘ladi', 'Она цветная'), Tr('Hech farqi yo‘q', 'Ничем'), Tr('U ko‘rinmaydi', 'Она невидима')],
          e: const Tr('th — table header, ustun nomi uchun.', 'th — table header, для названия столбца.'))),
      Q(2, (g) => g.quizCode(Tr('Bu jadvalda nechta qator bor?', 'Сколько строк в этой таблице?'), '$n', ['${n + 1}', '${n * 2}', '1'],
          code: '<table>\n${[for (var i = 0; i < n; i++) '  <tr><td>${i + 1}</td><td>${subj[i % 3]}</td></tr>'].join('\n')}\n</table>',
          e: const Tr('Har bir <tr> — bitta qator. Ularni sanaymiz.', 'Каждый <tr> — одна строка. Считаем их.'))),
      Q(3, (g) => g.quiz(const Tr('Bu kodda qanday xato bor?', 'Какая ошибка в этом коде?'),
          const Tr('<td> katagi <tr> qatorining ichida emas', 'Ячейка <td> не внутри строки <tr>'),
          const [Tr('Xato yo‘q', 'Ошибки нет'), Tr('<table> ni yopish shart emas', '<table> не надо закрывать'), Tr('td o‘rniga tr yozish kerak', 'Вместо td нужно tr')],
          code: '<table>\n  <td>${subj[0]}</td>\n</table>',
          e: const Tr('Tartib: table → tr → td. Katak doim qator ichida bo‘ladi.', 'Порядок: table → tr → td. Ячейка всегда внутри строки.'))),
    ], 3),
    g.pick([
      g.order(const Tr('Jadvalni to‘g‘ri tartibda yig‘ing:', 'Соберите таблицу в правильном порядке:'),
          ['<table>', '  <tr>', '    <td>${subj[0]}</td>', '  </tr>', '</table>'],
          e: const Tr('Tashqaridan ichkariga: table → tr → td, keyin teskari tartibda yopiladi.',
              'Снаружи внутрь: table → tr → td, закрываются в обратном порядке.')),
      g.fill(const Tr('Katakni yozing:', 'Напишите ячейку:'), '<tr><', '>${subj[1]}</td></tr>', ['td'],
          e: const Tr('Katak — td.', 'Ячейка — td.')),
    ]),
    g.tryIt(
      mode: 'html',
      task: Tr('Jadval yarating: bitta qator, ikkita katak — “${subj[0]}” va “5”.', 'Создайте таблицу: одна строка, две ячейки — «${subj[0]}» и «5».'),
      start: '<table>\n\n</table>',
      hint: lit('<table>\n  <tr><td>${subj[0]}</td><td>5</td></tr>\n</table>'),
      check: (c, o) => has('<tr>', c) && count('<td>', c) >= 2 && has('${subj[0]}', c) && has('<td>\\s*5\\s*</td>', c),
      solution: '<table>\n  <tr><td>${subj[0]}</td><td>5</td></tr>\n</table>',
    ),
  ];
}

// ============================================================ HTML 8 — matnni bezash / оформление текста
List<LessonStep> html8(Gen g) {
  final w = g.pick(const ['muhim', 'diqqat', 'yangi', 'bepul']);
  final name = g.pick(_names);
  return [
    const LessonStep.read(
      h: Tr('Qalin, qiya va belgilangan matn', 'Жирный, курсив и выделенный текст'),
      p: Tr(
          'Matn ichida ayrim so‘zlarni ajratish mumkin: <strong> — qalin (muhim), <em> — qiya (urg‘u), <mark> — marker bilan belgilangan. '
              '<br> — yangi qatorga o‘tish, <hr> — gorizontal chiziq. br va hr yopilmaydi!',
          'Внутри текста можно выделять слова: <strong> — жирный (важно), <em> — курсив (акцент), <mark> — выделение маркером. '
              '<br> — перенос строки, <hr> — горизонтальная линия. br и hr не закрываются!'),
      code: '<p>Bu <strong>muhim</strong> xabar.</p>\n<p><em>Diqqat</em> bilan o‘qing.</p>\n<hr>\n<p><mark>Ertaga</mark> imtihon!</p>',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('So‘zni qalin qiladigan teg:', 'Тег, который делает слово жирным:'), '<strong>', ['<em>', '<big>', '<hr>'],
          e: const Tr('strong — “kuchli”, muhim so‘z.', 'strong — «сильный», важное слово.'))),
      Q(1, (g) => g.quizCode(const Tr('Qiya (kursiv) matn qaysi teg?', 'Какой тег — курсив?'), '<em>', ['<strong>', '<i-text>', '<mark>'],
          e: const Tr('em — emphasis, urg‘u.', 'em — emphasis, акцент.'))),
      Q(2, (g) => g.quizCode(const Tr('Qaysi teg YOPILMAYDI?', 'Какой тег НЕ закрывается?'), '<hr>', ['<mark>', '<strong>', '<em>'],
          e: const Tr('hr va br — bo‘sh teglar, ichida matn yo‘q.', 'hr и br — пустые теги, внутри нет текста.'))),
      Q(2, (g) => g.quiz(const Tr('Ekranda nima ko‘rinadi?', 'Что будет на экране?'),
          Tr('“$w” so‘zi sariq fon bilan', 'Слово «$w» на жёлтом фоне'),
          const [Tr('Qizil matn', 'Красный текст'), Tr('Teg yozuvi', 'Надпись тега'), Tr('Hech narsa', 'Ничего')],
          code: '<p>Bu <mark>$w</mark> xabar</p>',
          e: const Tr('mark — markerdek sariq belgi.', 'mark — жёлтое выделение, как маркером.'))),
      Q(3, (g) => g.quizCode(const Tr('Qaysi kod to‘g‘ri?', 'Какой код правильный?'), '<p><strong>$w</strong> xabar</p>',
          ['<p><strong>$w</p></strong>', '<strong><p>$w</strong></p>', '<p><strong>$w xabar</p>'],
          e: const Tr('Ichkaridagi teg birinchi yopiladi.', 'Внутренний тег закрывается первым.'))),
    ], 3),
    g.fill(const Tr('So‘zni qalin qiling:', 'Сделайте слово жирным:'), '<p>Salom, <', '>$name</strong>!</p>', ['strong'],
        e: const Tr('Yopuvchi teg </strong> — demak ochuvchi ham strong.', 'Закрывающий </strong> — значит и открывающий strong.')),
    g.tryIt(
      mode: 'html',
      task: Tr('Paragraf yozing: “$name” ismi <strong> bilan qalin, “$w” so‘zi <mark> bilan belgilangan bo‘lsin.',
          'Напишите абзац: имя «$name» жирным через <strong>, слово «$w» выделено через <mark>.'),
      start: '<p></p>',
      hint: lit('<p><strong>$name</strong> — <mark>$w</mark></p>'),
      check: (c, o) => has('<strong>\\s*$name\\s*</strong>', c) && has('<mark>\\s*$w\\s*</mark>', c),
      solution: '<p><strong>$name</strong> — <mark>$w</mark></p>',
    ),
  ];
}

// ============================================================ HTML 9 — forma maydonlari / поля формы
List<LessonStep> html9(Gen g) {
  final opt = g.sample(const ['Toshkent', 'Andijon', 'Samarqand', 'Buxoro', 'Namangan'], 3);
  return [
    const LessonStep.read(
      h: Tr('Belgilash va tanlash maydonlari', 'Поля для отметок и выбора'),
      p: Tr(
          '<input type="checkbox"> — belgilash katagi (bir nechtasini tanlash mumkin). <input type="radio"> — faqat bittasini tanlash. '
              '<select> — ochiluvchi ro‘yxat, ichida <option> lar. <label> — maydon nomi: uni bossangiz ham maydon tanlanadi.',
          '<input type="checkbox"> — флажок (можно выбрать несколько). <input type="radio"> — выбор только одного. '
              '<select> — выпадающий список, внутри <option>. <label> — подпись поля: нажатие на неё тоже выбирает поле.'),
      code: '<label>Shahar</label>\n<select>\n  <option>Toshkent</option>\n  <option>Andijon</option>\n</select>\n<input type="checkbox"> Roziman',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Ochiluvchi ro‘yxat qaysi teg?', 'Какой тег — выпадающий список?'), '<select>', ['<list>', '<option>', '<input>'],
          e: const Tr('select — tanlash; ichidagi har bir variant — option.', 'select — выбор; каждый вариант внутри — option.'))),
      Q(1, (g) => g.quizCode(const Tr('Faqat BITTA variant tanlanadigan maydon:', 'Поле, где выбирают только ОДИН вариант:'), 'type="radio"',
          ['type="checkbox"', 'type="text"', 'type="one"'],
          e: const Tr('radio — eski radiodagi tugmalar kabi: bittasi bosilsa, boshqasi chiqadi.', 'radio — как кнопки старого радио: нажмёшь одну — другая отжимается.'))),
      Q(2, (g) => g.quizCode(Tr('Ro‘yxatda nechta variant bor?', 'Сколько вариантов в списке?'), '${opt.length}', ['1', '${opt.length + 1}', '0'],
          code: '<select>\n${[for (final o in opt) '  <option>$o</option>'].join('\n')}\n</select>',
          e: const Tr('Har bir <option> — bitta variant.', 'Каждый <option> — один вариант.'))),
      Q(2, (g) => g.quiz(const Tr('<label> nima uchun kerak?', 'Зачем нужен <label>?'),
          const Tr('Maydon nomini yozish uchun', 'Чтобы подписать поле'),
          const [Tr('Rasm qo‘yish uchun', 'Чтобы вставить картинку'), Tr('Sahifani yopish uchun', 'Чтобы закрыть страницу'), Tr('Rangni o‘zgartirish uchun', 'Чтобы менять цвет')],
          e: const Tr('label — yorliq, foydalanuvchi nima yozishni biladi.', 'label — подпись, пользователь понимает, что вводить.'))),
      Q(3, (g) => g.quizCode(const Tr('Bir nechta qiziqishni belgilash uchun qaysi tur?', 'Какой тип, чтобы отметить несколько интересов?'), 'checkbox',
          ['radio', 'select', 'button'],
          e: const Tr('checkbox — har birini alohida belgilash mumkin.', 'checkbox — можно отметить каждый отдельно.'))),
    ], 3),
    g.order(const Tr('Ro‘yxatni to‘g‘ri tartibda yig‘ing:', 'Соберите список в правильном порядке:'),
        ['<select>', '  <option>${opt[0]}</option>', '  <option>${opt[1]}</option>', '</select>'],
        e: const Tr('select ochiladi, ichida optionlar, oxirida select yopiladi.', 'Открываем select, внутри option, в конце закрываем select.')),
    g.tryIt(
      mode: 'html',
      task: Tr('<select> yarating, ichida ikkita <option>: “${opt[0]}” va “${opt[1]}”.',
          'Создайте <select> с двумя <option>: «${opt[0]}» и «${opt[1]}».'),
      start: '<select>\n\n</select>',
      hint: lit('<option>${opt[0]}</option>'),
      check: (c, o) => has('<select', c) && has('<option>\\s*${opt[0]}\\s*</option>', c) && has('<option>\\s*${opt[1]}\\s*</option>', c),
      solution: '<select>\n  <option>${opt[0]}</option>\n  <option>${opt[1]}</option>\n</select>',
    ),
  ];
}

// ============================================================ CSS 7 — border va soya / рамка и тень
List<LessonStep> css7(Gen g) {
  final px = g.pick(const [2, 3, 4, 5]);
  final col = g.pick(const ['red', 'blue', 'green', 'orange']);
  return [
    const LessonStep.read(
      h: Tr('Chegara (border) va soya', 'Рамка (border) и тень'),
      p: Tr(
          'border uch qismdan iborat: qalinlik, turi, rangi — border: 2px solid blue; (solid — to‘xtovsiz, dashed — shtrix, dotted — nuqtali). '
              'border-radius burchaklarni yumaloqlaydi. box-shadow: 0 4px 12px gray; — elementga soya beradi, u “ko‘tarilgandek” ko‘rinadi.',
          'border состоит из трёх частей: толщина, тип, цвет — border: 2px solid blue; (solid — сплошная, dashed — штрих, dotted — точки). '
              'border-radius скругляет углы. box-shadow: 0 4px 12px gray; — даёт тень, элемент будто «приподнят».'),
      code: '.karta {\n  border: 2px solid blue;\n  border-radius: 12px;\n  box-shadow: 0 4px 12px gray;\n}',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Uzluksiz chiziqli chegara turi:', 'Тип сплошной рамки:'), 'solid', ['dashed', 'dotted', 'line'],
          e: const Tr('solid — yaxlit, to‘xtovsiz chiziq.', 'solid — сплошная линия.'))),
      Q(1, (g) => g.quizCode(const Tr('Soya beradigan xususiyat:', 'Свойство, которое даёт тень:'), 'box-shadow', ['shadow', 'border', 'text-dark'],
          e: const Tr('box-shadow — quti soyasi.', 'box-shadow — тень блока.'))),
      Q(2, (g) => g.quiz(Tr('border: ${px}px dashed $col; — chegara qanday bo‘ladi?', 'border: ${px}px dashed $col; — какая будет рамка?'),
          Tr('${px}px qalin, shtrixli, rangi $col', 'толщина ${px}px, штриховая, цвет $col'),
          [
            Tr('${px}px qalin, uzluksiz, rangi $col', 'толщина ${px}px, сплошная, цвет $col'),
            Tr('Nuqtali, rangi qora', 'Точечная, чёрная'),
            const Tr('Chegara bo‘lmaydi', 'Рамки не будет'),
          ],
          e: const Tr('dashed — shtrix (– – –).', 'dashed — штрих (– – –).'))),
      Q(2, (g) => g.quizCode(const Tr('Burchaklarni yumaloqlash:', 'Скругление углов:'), 'border-radius', ['border-round', 'corner', 'radius-border'],
          e: const Tr('border-radius — chegara radiusi.', 'border-radius — радиус рамки.'))),
      Q(3, (g) => g.quizCode(const Tr('Qaysi yozuv to‘g‘ri?', 'Какая запись правильная?'), 'border: ${px}px solid $col;',
          ['border: solid;${px}px $col', 'border = ${px}px solid $col;', 'border: ${px}px, solid, $col;'],
          e: const Tr('Qiymatlar bo‘sh joy bilan ajratiladi, oxirida nuqta-vergul.', 'Значения через пробел, в конце точка с запятой.'))),
    ], 3),
    g.fill(const Tr('Chegara turini yozing (uzluksiz):', 'Впишите тип рамки (сплошная):'), 'border: ${px}px ', ' $col;', ['solid']),
    g.tryIt(
      mode: 'css',
      task: Tr('.karta ga ${px}px qalin, uzluksiz, $col rangli chegara bering.', 'Дайте .karta рамку ${px}px, сплошную, цвета $col.'),
      start: '.karta {\n\n}',
      hint: lit('border: ${px}px solid $col;'),
      check: (c, o) => has('border\\s*:\\s*${px}px\\s+solid\\s+$col', c),
      solution: '.karta {\n  border: ${px}px solid $col;\n}',
    ),
  ];
}

// ============================================================ CSS 8 — hover va transition / hover и transition
List<LessonStep> css8(Gen g) {
  final col = g.pick(const ['orange', 'green', 'purple', 'red']);
  final sec = g.pick(const ['0.3s', '0.5s', '1s']);
  return [
    const LessonStep.read(
      h: Tr(':hover va silliq o‘tish', ':hover и плавный переход'),
      p: Tr(
          ':hover — sichqoncha ustiga kelganda (telefonda — bosib turganda) ishlaydigan qoida: button:hover { background: orange; }. '
              'transition: 0.3s; — o‘zgarish birdan emas, 0.3 soniyada silliq bo‘ladi. Shunday qilib tugmalar “jonli” ko‘rinadi.',
          ':hover — правило, которое срабатывает при наведении мыши (на телефоне — при нажатии): button:hover { background: orange; }. '
              'transition: 0.3s; — изменение происходит не сразу, а плавно за 0.3 секунды. Так кнопки выглядят «живыми».'),
      code: 'button {\n  background: blue;\n  transition: 0.3s;\n}\nbutton:hover {\n  background: orange;\n}',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Sichqoncha ustiga kelganda ishlaydigan holat:', 'Состояние при наведении мыши:'), ':hover',
          [':click', ':mouse', ':over'], e: const Tr('hover — “ustida suzish”.', 'hover — «парить над».'))),
      Q(1, (g) => g.quizCode(const Tr('O‘zgarishni silliq qiladigan xususiyat:', 'Свойство, делающее изменение плавным:'), 'transition',
          ['animation-speed', 'smooth', 'delay'], e: const Tr('transition — o‘tish.', 'transition — переход.'))),
      Q(2, (g) => g.quiz(Tr('transition: $sec; nimani bildiradi?', 'Что значит transition: $sec;?'),
          Tr('O‘zgarish $sec davom etadi', 'Изменение длится $sec'),
          const [Tr('Element yashirinadi', 'Элемент скрывается'), Tr('Rang qorayadi', 'Цвет темнеет'), Tr('Hech narsa', 'Ничего')],
          e: const Tr('s — soniya (second).', 's — секунды (second).'))),
      Q(2, (g) => g.quizCode(const Tr('Tugma ustiga kelganda qizarsin. Qaysi selektor?', 'Кнопка краснеет при наведении. Какой селектор?'), 'button:hover',
          ['button.hover', 'button hover', 'hover:button'], e: const Tr('Holat ikki nuqta bilan yoziladi: button:hover.', 'Состояние пишут через двоеточие: button:hover.'))),
      Q(3, (g) => g.quiz(const Tr('transition qaysi qoidaga yoziladi?', 'В какое правило пишут transition?'),
          const Tr('Oddiy holatga (button {…})', 'В обычное состояние (button {…})'),
          const [Tr('Faqat :hover ga', 'Только в :hover'), Tr('HTML ga', 'В HTML'), Tr('Hech qayerga', 'Никуда')],
          e: const Tr('Shunda ham kirish, ham chiqish silliq bo‘ladi.', 'Тогда плавными будут и вход, и выход.'))),
    ], 3),
    g.fill(const Tr('Holatni yozing:', 'Впишите состояние:'), 'button:', ' { background: $col; }', ['hover']),
    g.tryIt(
      mode: 'css',
      task: Tr('button:hover qoidasini yozing — fon rangi $col bo‘lsin. button ga transition: $sec; qo‘shing.',
          'Напишите правило button:hover — фон $col. Добавьте button transition: $sec;.'),
      start: 'button {\n  background: blue;\n}\n',
      hint: lit('button:hover { background: $col; }'),
      check: (c, o) => has('button\\s*:hover\\s*\\{[^}]*background(-color)?\\s*:\\s*$col', c) && has('transition\\s*:\\s*$sec', c),
      solution: 'button {\n  background: blue;\n  transition: $sec;\n}\nbutton:hover {\n  background: $col;\n}',
    ),
  ];
}

// ============================================================ CSS 9 — o‘lchamlar / размеры
List<LessonStep> css9(Gen g) {
  final w = g.pick(const [25, 50, 75]);
  final px = g.pick(const [100, 150, 200, 300]);
  return [
    const LessonStep.read(
      h: Tr('O‘lchamlar: px va %', 'Размеры: px и %'),
      p: Tr(
          'width — kenglik, height — balandlik. px — aniq piksel: width: 200px; har doim bir xil. % — ota-elementdan ulush: width: 50%; — yarmi. '
              'Telefon va kompyuterda chiroyli ko‘rinishi uchun ko‘pincha % ishlatiladi. max-width: 600px; — “bundan katta bo‘lma”.',
          'width — ширина, height — высота. px — точные пиксели: width: 200px; всегда одинаково. % — доля от родителя: width: 50%; — половина. '
              'Чтобы было красиво и на телефоне, и на компьютере, часто используют %. max-width: 600px; — «не больше этого».'),
      code: '.quti {\n  width: 50%;\n  height: 120px;\n  max-width: 600px;\n}',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Kenglik xususiyati:', 'Свойство ширины:'), 'width', ['height', 'size', 'long'],
          e: const Tr('width — eni, height — bo‘yi.', 'width — ширина, height — высота.'))),
      Q(2, (g) => g.quiz(Tr('Ota-element 400px. width: $w%; bo‘lsa, quti necha px?', 'Родитель 400px. При width: $w%; блок сколько px?'),
          lit('${400 * w ~/ 100}px'), [lit('${w}px'), lit('400px'), lit('${400 * w ~/ 50}px')],
          e: Tr('$w% × 400 = ${400 * w ~/ 100}.', '$w% × 400 = ${400 * w ~/ 100}.'))),
      Q(2, (g) => g.quiz(const Tr('Qaysi biri ekran o‘lchamiga moslashadi?', 'Что подстраивается под размер экрана?'), lit('width: 80%;'),
          [lit('width: 300px;'), lit('height: 50px;'), lit('border: 1px;')],
          e: const Tr('% — ota-elementga nisbatan, u o‘zgaradi.', '% — относительно родителя, он меняется.'))),
      Q(3, (g) => g.quizCode(const Tr('Element 600px dan katta bo‘lmasin:', 'Элемент не шире 600px:'), 'max-width: 600px;',
          ['min-width: 600px;', 'width: max 600px;', 'limit: 600px;'],
          e: const Tr('max — eng ko‘pi, min — eng kami.', 'max — максимум, min — минимум.'))),
    ], 2),
    g.fill(Tr('Balandlikni ${px}px qiling:', 'Сделайте высоту ${px}px:'), '.quti { ', ': ${px}px; }', ['height']),
    g.tryIt(
      mode: 'css',
      task: Tr('.quti ning kengligi $w%, balandligi ${px}px bo‘lsin.', 'Ширина .quti — $w%, высота — ${px}px.'),
      start: '.quti {\n\n}',
      hint: lit('width: $w%;\nheight: ${px}px;'),
      check: (c, o) => has('width\\s*:\\s*$w%', c) && has('height\\s*:\\s*${px}px', c),
      solution: '.quti {\n  width: $w%;\n  height: ${px}px;\n}',
    ),
  ];
}

// ============================================================ JS 7 — massivlar / массивы
List<LessonStep> js7(Gen g) {
  final f = g.sample(_fruits, 4);
  final k = g.n(0, 2);
  return [
    const LessonStep.read(
      h: Tr('Massivlar (Array)', 'Массивы (Array)'),
      p: Tr(
          'Massiv — ko‘p qiymatni bitta o‘zgaruvchida saqlash: let mevalar = ["olma", "nok"]; Sanash 0 dan: mevalar[0] — "olma". '
              '.length — nechta element, .push(x) — oxiriga qo‘shadi, .pop() — oxirgisini olib tashlaydi.',
          'Массив хранит много значений в одной переменной: let mevalar = ["olma", "nok"]; Счёт с 0: mevalar[0] — "olma". '
              '.length — сколько элементов, .push(x) — добавить в конец, .pop() — убрать последний.'),
      code: 'let mevalar = ["olma", "nok"];\nmevalar.push("uzum");\nconsole.log(mevalar.length); // 3',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Massivning birinchi elementi indeksi:', 'Индекс первого элемента массива:'), '0', ['1', '-1', 'first'],
          e: const Tr('JavaScript ham 0 dan sanaydi.', 'JavaScript тоже считает с 0.'))),
      Q(1, (g) => g.quizCode(const Tr('Oxiriga element qo‘shish:', 'Добавить элемент в конец:'), '.push()', ['.add()', '.append()', '.pop()'],
          e: const Tr('Pythonda append, JS da push.', 'В Python append, в JS push.'))),
      Q(2, (g) => g.quizCode(const Tr('Natija qanday?', 'Каким будет результат?'), f[k],
          [for (var i = 0; i < 3; i++) if (i != k) f[i], 'undefined'],
          code: 'let m = ["${f[0]}", "${f[1]}", "${f[2]}"];\nconsole.log(m[$k]);',
          e: Tr('m[$k] — ${k + 1}-element.', 'm[$k] — ${k + 1}-й элемент.'))),
      Q(2, (g) => g.quizCode(const Tr('Natija qanday?', 'Каким будет результат?'), '4', ['3', '5', '2'],
          code: 'let m = ["${f[0]}", "${f[1]}", "${f[2]}"];\nm.push("${f[3]}");\nconsole.log(m.length);',
          e: const Tr('3 ta edi, push bittasini qo‘shdi — 4.', 'Было 3, push добавил ещё один — 4.'))),
      Q(3, (g) => g.quizCode(const Tr('Natija qanday?', 'Каким будет результат?'), '2', ['3', '1', '"${f[2]}"'],
          code: 'let m = ["${f[0]}", "${f[1]}", "${f[2]}"];\nm.pop();\nconsole.log(m.length);',
          e: const Tr('pop() oxirgisini olib tashladi.', 'pop() убрал последний.'))),
    ], 3),
    g.fill(const Tr('Massiv uzunligini chiqaring:', 'Выведите длину массива:'), 'console.log(mevalar.', ');', ['length']),
    g.tryIt(
      mode: 'js',
      task: Tr('“mevalar” massivini yarating: "${f[0]}", "${f[1]}". So‘ng push bilan "${f[2]}" qo‘shing.',
          'Создайте массив mevalar: "${f[0]}", "${f[1]}". Затем добавьте push-ем "${f[2]}".'),
      start: 'let mevalar = [];\n',
      hint: lit('let mevalar = ["${f[0]}", "${f[1]}"];\nmevalar.push("${f[2]}");'),
      check: (c, o) => has('mevalar\\s*=\\s*\\[\\s*["\']${f[0]}["\']\\s*,\\s*["\']${f[1]}["\']', c) && has('mevalar\\.push\\(\\s*["\']${f[2]}["\']\\s*\\)', c),
      solution: 'let mevalar = ["${f[0]}", "${f[1]}"];\nmevalar.push("${f[2]}");',
    ),
  ];
}

// ============================================================ JS 8 — massiv bo‘ylab sikl / цикл по массиву
List<LessonStep> js8(Gen g) {
  final nums = [for (var i = 0; i < 3; i++) g.n(2, 9)];
  final sum = nums.reduce((a, b) => a + b);
  return [
    const LessonStep.read(
      h: Tr('Massiv bo‘ylab yurish: for…of', 'Обход массива: for…of'),
      p: Tr(
          'for (let x of sonlar) { … } — massivning har bir elementi navbat bilan x ga tushadi. '
              'Yig‘indi topish: avval let s = 0; keyin siklda s = s + x; (yoki qisqa: s += x;). Bu — dasturlashdagi eng mashhur usullardan biri.',
          'for (let x of sonlar) { … } — каждый элемент массива по очереди попадает в x. '
              'Сумма: сначала let s = 0; потом в цикле s = s + x; (или коротко: s += x;). Это один из самых популярных приёмов в программировании.'),
      code: 'let sonlar = [3, 5, 2];\nlet s = 0;\nfor (let x of sonlar) {\n  s += x;\n}\nconsole.log(s); // 10',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Massivning har bir elementi bo‘ylab yurish:', 'Пройти по каждому элементу массива:'), 'for (let x of m)',
          ['for (let x in 5)', 'loop m', 'for x = m'], e: const Tr('of — “ichidan”.', 'of — «из».'))),
      Q(2, (g) => g.quizCode(const Tr('Natija qanday?', 'Каким будет результат?'), '$sum', ['${nums.length}', '${nums.first}', '0'],
          code: 'let s = 0;\nfor (let x of $nums) {\n  s += x;\n}\nconsole.log(s);',
          e: Tr('${nums.join(' + ')} = $sum', '${nums.join(' + ')} = $sum'))),
      Q(2, (g) => g.quiz(const Tr('s += x; nimani bildiradi?', 'Что значит s += x;?'), lit('s = s + x;'),
          [lit('s = x;'), lit('x = s + x;'), lit('s = s * x;')], e: const Tr('+= — qo‘shib, o‘ziga yozadi.', '+= — прибавляет и записывает в себя.'))),
      Q(3, (g) => g.quizCode(const Tr('Sikl necha marta aylanadi?', 'Сколько раз выполнится цикл?'), '${nums.length + 1}',
          ['${nums.length}', '1', '${nums.length + 2}'],
          code: 'let m = [...${nums.toString()}, 1];\nfor (let x of m) {\n  console.log(x);\n}',
          e: const Tr('Har bir element uchun bir marta.', 'По разу на каждый элемент.'))),
    ], 2),
    g.order(const Tr('Yig‘indini hisoblovchi kodni tartiblang:', 'Расставьте код, считающий сумму:'),
        ['let s = 0;', 'for (let x of sonlar) {', '  s += x;', '}', 'console.log(s);'],
        e: const Tr('Avval s = 0, keyin sikl, oxirida natija.', 'Сначала s = 0, потом цикл, в конце результат.')),
    g.tryIt(
      mode: 'js',
      task: Tr('sonlar = $nums massivining yig‘indisini for…of bilan hisoblab, console.log bilan chiqaring.',
          'Посчитайте сумму массива sonlar = $nums циклом for…of и выведите console.log.'),
      start: 'let sonlar = $nums;\nlet s = 0;\n',
      hint: lit('for (let x of sonlar) {\n  s += x;\n}\nconsole.log(s);'),
      check: (c, o) => has('for\\s*\\(\\s*(let|const|var)\\s+\\w+\\s+of\\s+sonlar', c) && has('console\\.log', c),
      solution: 'let sonlar = $nums;\nlet s = 0;\nfor (let x of sonlar) {\n  s += x;\n}\nconsole.log(s);',
    ),
  ];
}

// ============================================================ JS 9 — obyektlar / объекты
List<LessonStep> js9(Gen g) {
  final name = g.pick(_names);
  final age = g.n(10, 16);
  return [
    const LessonStep.read(
      h: Tr('Obyektlar: nom → qiymat', 'Объекты: имя → значение'),
      p: Tr(
          'Obyekt — bitta narsa haqidagi ma’lumotlar to‘plami: let bola = { ism: "Ali", yosh: 12 }; '
              'Qiymatni olish: bola.ism — "Ali". O‘zgartirish: bola.yosh = 13; Yangi qo‘shish: bola.sinf = 7; Bu — o‘yinlardagi qahramon kartochkasi kabi.',
          'Объект — набор данных об одной вещи: let bola = { ism: "Ali", yosh: 12 }; '
              'Получить значение: bola.ism — "Ali". Изменить: bola.yosh = 13; Добавить: bola.sinf = 7; Это как карточка героя в игре.'),
      code: 'let bola = { ism: "Ali", yosh: 12 };\nconsole.log(bola.ism); // Ali\nbola.yosh = 13;',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Obyekt qaysi qavslarda yoziladi?', 'В каких скобках пишут объект?'), '{ }', ['[ ]', '( )', '< >'],
          e: const Tr('{ } — obyekt, [ ] — massiv.', '{ } — объект, [ ] — массив.'))),
      Q(2, (g) => g.quizCode(const Tr('Natija qanday?', 'Каким будет результат?'), name, ['ism', '$age', 'undefined'],
          code: 'let b = { ism: "$name", yosh: $age };\nconsole.log(b.ism);',
          e: const Tr('b.ism — “ism” kalitidagi qiymat.', 'b.ism — значение по ключу «ism».'))),
      Q(2, (g) => g.quizCode(const Tr('Natija qanday?', 'Каким будет результат?'), '${age + 1}', ['$age', '${age}1', 'undefined'],
          code: 'let b = { ism: "$name", yosh: $age };\nb.yosh = b.yosh + 1;\nconsole.log(b.yosh);',
          e: const Tr('Avval qiymat o‘qiladi, 1 qo‘shiladi, keyin qayta yoziladi.', 'Сначала читаем значение, прибавляем 1, записываем обратно.'))),
      Q(3, (g) => g.quizCode(const Tr('Obyektga “sinf” xususiyatini qo‘shish:', 'Добавить объекту свойство «sinf»:'), 'b.sinf = 7;',
          ['b(sinf) = 7;', 'b.push(sinf: 7);', 'sinf.b = 7;'],
          e: const Tr('Nuqta bilan yangi nom yozib qiymat beriladi.', 'Через точку пишут новое имя и дают значение.'))),
    ], 2),
    g.fill(const Tr('Ismni chiqaring:', 'Выведите имя:'), 'console.log(bola.', ');', ['ism']),
    g.tryIt(
      mode: 'js',
      task: Tr('“bola” obyektini yarating: ism — "$name", yosh — $age. So‘ng console.log(bola.ism) yozing.',
          'Создайте объект bola: ism — "$name", yosh — $age. Затем напишите console.log(bola.ism).'),
      start: 'let bola = {};\n',
      hint: lit('let bola = { ism: "$name", yosh: $age };\nconsole.log(bola.ism);'),
      check: (c, o) => has('ism\\s*:\\s*["\']$name["\']', c) && has('yosh\\s*:\\s*$age', c) && has('console\\.log\\(\\s*bola\\.ism\\s*\\)', c),
      solution: 'let bola = { ism: "$name", yosh: $age };\nconsole.log(bola.ism);',
    ),
  ];
}

// ============================================================ PY 7 — while
List<LessonStep> py7(Gen g) {
  final n = g.n(3, 6);
  final start = g.n(10, 20);
  return [
    const LessonStep.read(
      h: Tr('while — shart to‘g‘ri ekan takrorla', 'while — повторяй, пока условие верно'),
      p: Tr(
          'while shart: — shart True bo‘lsa, ichidagi kod qayta-qayta bajariladi. Har aylanishda nimadir o‘zgarishi shart, '
              'aks holda sikl hech qachon tugamaydi! Masalan, i = i + 1. break — siklni darhol to‘xtatadi.',
          'while условие: — пока условие True, код внутри повторяется снова и снова. На каждом круге что-то должно меняться, '
              'иначе цикл никогда не закончится! Например, i = i + 1. break — сразу останавливает цикл.'),
      code: 'i = 1\nwhile i <= 3:\n    print(i)\n    i = i + 1\n# 1\n# 2\n# 3',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Siklni darhol to‘xtatuvchi so‘z:', 'Слово, которое сразу останавливает цикл:'), 'break', ['stop', 'exit', 'end'],
          e: const Tr('break — “sindirish”, sikldan chiqish.', 'break — «сломать», выйти из цикла.'))),
      Q(2, (g) => g.quizCode(const Tr('Sikl necha marta ishlaydi?', 'Сколько раз выполнится цикл?'), '$n', ['${n + 1}', '${n - 1}', 'Cheksiz'],
          code: 'i = 0\nwhile i < $n:\n    print(i)\n    i = i + 1',
          e: Tr('i = 0, 1, … ${n - 1} — jami $n marta.', 'i = 0, 1, … ${n - 1} — всего $n раз.'))),
      Q(2, (g) => g.quiz(const Tr('Bu kodda nima bo‘ladi?', 'Что произойдёт в этом коде?'),
          const Tr('Sikl hech qachon tugamaydi', 'Цикл никогда не закончится'),
          const [Tr('1 marta ishlaydi', 'Выполнится 1 раз'), Tr('Xato chiqadi', 'Будет ошибка'), Tr('Hech narsa chiqmaydi', 'Ничего не выведется')],
          code: 'i = 1\nwhile i > 0:\n    print(i)',
          e: const Tr('i o‘zgarmayapti — shart doim True.', 'i не меняется — условие всегда True.'))),
      Q(3, (g) => g.quizCode(const Tr('Oxirida nima chiqadi?', 'Что выведется в конце?'), '${start - 3 * (start ~/ 3)}',
          ['${start ~/ 3}', '0', '$start'],
          code: 'x = $start\nwhile x >= 3:\n    x = x - 3\nprint(x)',
          e: Tr('$start dan 3 ni ayirib boramiz, 3 dan kichik qolguncha.', 'Отнимаем 3 от $start, пока не станет меньше 3.'))),
    ], 2),
    g.fill(const Tr('Siklni to‘ldiring:', 'Допишите цикл:'), '', ' i < $n:', ['while']),
    g.tryIt(
      mode: 'py',
      task: Tr('while bilan $n dan 1 gacha teskari sanang (har biri yangi qatorda).', 'С помощью while посчитайте от $n до 1 (каждое с новой строки).'),
      start: 'i = $n\n',
      hint: lit('while i >= 1:\n    print(i)\n    i = i - 1'),
      check: (c, o) => has(r'\bwhile\b', c, ci: false) && words(o).join(' ') == [for (var i = n; i >= 1; i--) '$i'].join(' '),
      solution: 'i = $n\nwhile i >= 1:\n    print(i)\n    i = i - 1',
    ),
  ];
}

// ============================================================ PY 8 — satrlar / строки
List<LessonStep> py8(Gen g) {
  final w = g.pick(const ['salom', 'python', 'idrok', 'kitob', 'dunyo']);
  return [
    const LessonStep.read(
      h: Tr('Satrlar bilan ishlash', 'Работа со строками'),
      p: Tr(
          'Satr (str) — matn. len("olma") — 4 ta harf. .upper() — KATTA harf, .lower() — kichik harf. '
              's[0] — birinchi harf, s[-1] — oxirgi harf. "a" + "b" — satrlarni ulash. "ha" * 3 — "hahaha".',
          'Строка (str) — это текст. len("olma") — 4 буквы. .upper() — ЗАГЛАВНЫЕ, .lower() — строчные. '
              's[0] — первая буква, s[-1] — последняя. "a" + "b" — склеить строки. "ha" * 3 — "hahaha".'),
      code: 's = "olma"\nprint(len(s))     # 4\nprint(s.upper())  # OLMA\nprint(s[0])       # o',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(Tr('len("$w") nechaga teng?', 'Чему равно len("$w")?'), '${w.length}', ['${w.length + 1}', '${w.length - 1}', '1'],
          e: Tr('“$w” da ${w.length} ta harf bor.', 'В «$w» ${w.length} букв.'))),
      Q(1, (g) => g.quizCode(const Tr('Hamma harflarni KATTA qilish:', 'Сделать все буквы ЗАГЛАВНЫМИ:'), '.upper()', ['.big()', '.lower()', '.capital()'],
          e: const Tr('upper — yuqori (katta) harflar.', 'upper — верхний регистр.'))),
      Q(2, (g) => g.quizCode(const Tr('Natija qanday?', 'Каким будет результат?'), w[w.length - 1], [w[0], w[1], '-1'],
          code: 's = "$w"\nprint(s[-1])', e: const Tr('-1 — oxiridan birinchi.', '-1 — первый с конца.'))),
      Q(2, (g) => g.quizCode(const Tr('Natija qanday?', 'Каким будет результат?'), w.toUpperCase(), [w, w[0].toUpperCase() + w.substring(1), 'Xato'],
          code: 'print("$w".upper())', e: const Tr('upper() hamma harfni katta qiladi.', 'upper() делает все буквы заглавными.'))),
      Q(3, (g) => g.quizCode(const Tr('Natija qanday?', 'Каким будет результат?'), 'hahaha', ['ha3', 'ha ha ha', 'Xato'],
          code: 'print("ha" * 3)', e: const Tr('Satrni songa ko‘paytirish — takrorlash.', 'Умножение строки на число — повтор.'))),
    ], 3),
    g.fill(const Tr('Birinchi harfni oling:', 'Возьмите первую букву:'), 'print(s[', '])', ['0']),
    g.tryIt(
      mode: 'py',
      task: Tr('s = "$w" uchun: birinchi qatorda harflar sonini, ikkinchi qatorda KATTA harfdagi ko‘rinishini chiqaring.',
          'Для s = "$w": в первой строке выведите число букв, во второй — ЗАГЛАВНЫМИ.'),
      start: 's = "$w"\n',
      hint: lit('print(len(s))\nprint(s.upper())'),
      check: (c, o) => outLines(o).length >= 2 && outLines(o)[0] == '${w.length}' && outLines(o)[1] == w.toUpperCase(),
      solution: 's = "$w"\nprint(len(s))\nprint(s.upper())',
    ),
  ];
}

// ============================================================ PY 9 — lug‘atlar / словари
List<LessonStep> py9(Gen g) {
  final name = g.pick(_names);
  final ball = g.n(60, 99);
  final word = g.pick(const [('olma', 'apple'), ('kitob', 'book'), ('it', 'dog'), ('mushuk', 'cat')]);
  return [
    const LessonStep.read(
      h: Tr('Lug‘at (dict): kalit → qiymat', 'Словарь (dict): ключ → значение'),
      p: Tr(
          'Lug‘at — so‘zlik kabi: har bir kalitga qiymat mos. baho = {"Ali": 5, "Laylo": 4}. Qiymat olish: baho["Ali"] — 5. '
              'Qo‘shish yoki o‘zgartirish: baho["Sardor"] = 3. len(baho) — nechta juftlik. Chatbotlar ham shunday ishlaydi!',
          'Словарь — как разговорник: каждому ключу соответствует значение. baho = {"Ali": 5, "Laylo": 4}. Получить: baho["Ali"] — 5. '
              'Добавить или изменить: baho["Sardor"] = 3. len(baho) — сколько пар. Чат-боты работают так же!'),
      code: 'lugat = {"olma": "apple", "it": "dog"}\nprint(lugat["it"])   # dog\nlugat["mushuk"] = "cat"',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Lug‘at qaysi qavslarda yoziladi?', 'В каких скобках пишут словарь?'), '{ }', ['[ ]', '( )', '< >'],
          e: const Tr('{kalit: qiymat}', '{ключ: значение}'))),
      Q(2, (g) => g.quizCode(const Tr('Natija qanday?', 'Каким будет результат?'), word.$2, [word.$1, 'Xato', '0'],
          code: 'd = {"${word.$1}": "${word.$2}"}\nprint(d["${word.$1}"])', e: const Tr('Kalit bo‘yicha qiymat olinadi.', 'По ключу получаем значение.'))),
      Q(2, (g) => g.quizCode(const Tr('Natija qanday?', 'Каким будет результат?'), '3', ['2', '4', '1'],
          code: 'b = {"a": 1, "b": 2}\nb["c"] = 3\nprint(len(b))', e: const Tr('Yangi kalit qo‘shildi — 3 ta juftlik.', 'Добавили ключ — 3 пары.'))),
      Q(3, (g) => g.quizCode(const Tr('Natija qanday?', 'Каким будет результат?'), '${ball + 5}', ['$ball', '5', 'Xato'],
          code: 'b = {"$name": $ball}\nb["$name"] = b["$name"] + 5\nprint(b["$name"])',
          e: const Tr('Eski qiymat o‘qildi, 5 qo‘shildi, qayta yozildi.', 'Прочитали старое значение, прибавили 5, записали.'))),
    ], 2),
    g.fill(const Tr('Qiymatni oling:', 'Получите значение:'), 'print(baho', ')', ['["Ali"]', "['Ali']"]),
    g.tryIt(
      mode: 'py',
      task: Tr('baho = {"$name": $ball} lug‘atiga "Sardor": 90 qo‘shing va len(baho) ni chiqaring.',
          'Добавьте в словарь baho = {"$name": $ball} пару "Sardor": 90 и выведите len(baho).'),
      start: 'baho = {"$name": $ball}\n',
      hint: lit('baho["Sardor"] = 90\nprint(len(baho))'),
      check: (c, o) => has(r'''baho\[\s*["']Sardor["']\s*\]\s*=\s*90''', c) && outLines(o).isNotEmpty && outLines(o).last == '2',
      solution: 'baho = {"$name": $ball}\nbaho["Sardor"] = 90\nprint(len(baho))',
    ),
  ];
}

// ============================================================ animatsiyalar / анимации
AnimScene _traceArrayJs(Gen g) {
  final f = g.sample(_fruits, 4);
  final code = ['let m = ["${f[0]}", "${f[1]}", "${f[2]}"];', 'console.log(m[1]);', 'm.push("${f[3]}");', 'm.pop();', 'console.log(m.length);'];
  final t = Tracer('js', code)
    ..arr = f.sublist(0, 3)
    ..arrName = 'm';
  t.step(0, const Tr('Massiv — raqamlangan qutilar qatori. Raqamlar 0 dan boshlanadi.', 'Массив — ряд пронумерованных коробок. Номера с 0.'));
  t.step(1, Tr('m[1] — ikkinchi quti: ${f[1]}', 'm[1] — вторая коробка: ${f[1]}'), print: f[1], arrHot: 1);
  t.arr = f;
  t.step(2, Tr('push — oxiriga yangi quti: ${f[3]}', 'push — новая коробка в конец: ${f[3]}'), arrHot: 3);
  t.arr = f.sublist(0, 3);
  t.step(3, const Tr('pop — oxirgi quti olib tashlandi.', 'pop — последняя коробка убрана.'), arrHot: 2);
  t.step(4, const Tr('length — nechta quti: 3', 'length — сколько коробок: 3'), print: 3);
  return t.scene();
}

AnimScene _traceSumJs(Gen g) {
  final nums = [for (var i = 0; i < 3; i++) g.n(2, 9)];
  final code = ['let s = 0;', 'for (let x of $nums) {', '  s += x;', '}', 'console.log(s);'];
  final t = Tracer('js', code)
    ..arr = [for (final n in nums) '$n']
    ..arrName = 'sonlar';
  t.step(0, const Tr('Yig‘indi uchun bo‘sh quti: s = 0.', 'Пустая коробка для суммы: s = 0.'), set: 's', val: 0);
  var s = 0;
  for (var k = 0; k < nums.length; k++) {
    t.step(1, Tr('${k + 1}-aylanish: x = ${nums[k]}', 'Круг ${k + 1}: x = ${nums[k]}'), set: 'x', val: nums[k], arrHot: k);
    s += nums[k];
    t.step(2, Tr('s = ${s - nums[k]} + ${nums[k]} = $s', 's = ${s - nums[k]} + ${nums[k]} = $s'), set: 's', val: s, arrHot: k);
  }
  t.step(4, Tr('Sikl tugadi. Natija: $s', 'Цикл закончен. Результат: $s'), print: s);
  return t.scene();
}

AnimScene _traceObjJs(Gen g) {
  final name = g.pick(_names);
  final age = g.n(10, 15);
  final code = ['let b = {', '  ism: "$name",', '  yosh: $age', '};', 'b.yosh = b.yosh + 1;', 'b.sinf = 7;', 'console.log(b.ism);'];
  final t = Tracer('js', code)
    ..step(0, const Tr('Obyekt — bitta katta quti, ichida nomlangan bo‘limlar.', 'Объект — одна большая коробка с именованными отделами.'))
    ..step(1, Tr('b.ism bo‘limiga "$name" yozildi.', 'В отдел b.ism записано "$name".'), set: 'b.ism', val: '"$name"')
    ..step(2, Tr('b.yosh bo‘limiga $age yozildi.', 'В отдел b.yosh записано $age.'), set: 'b.yosh', val: age)
    ..step(4, Tr('Tug‘ilgan kun! b.yosh = $age + 1 = ${age + 1}', 'День рождения! b.yosh = $age + 1 = ${age + 1}'), set: 'b.yosh', val: age + 1)
    ..step(5, const Tr('Yangi bo‘lim qo‘shildi: b.sinf = 7', 'Добавлен новый отдел: b.sinf = 7'), set: 'b.sinf', val: 7)
    ..step(6, Tr('Nuqta bilan qiymat olinadi: $name', 'Через точку получаем значение: $name'), print: name);
  return t.scene();
}

AnimScene _traceWhile(Gen g) {
  final n = g.n(3, 4);
  final code = ['i = $n', 'while i >= 1:', '    print(i)', '    i = i - 1', 'print("Start!")'];
  final t = Tracer('py', code)..step(0, Tr('i qutisiga $n solindi.', 'В коробку i положили $n.'), set: 'i', val: n);
  for (var i = n; i >= 1; i--) {
    t
      ..step(1, Tr('Tekshiramiz: $i >= 1 — True, ichkariga kiramiz.', 'Проверяем: $i >= 1 — True, заходим внутрь.'))
      ..step(2, Tr('$i ni chiqaramiz.', 'Выводим $i.'), print: i)
      ..step(3, Tr('i bittaga kamaydi: ${i - 1}', 'i уменьшилось на 1: ${i - 1}'), set: 'i', val: i - 1);
  }
  t
    ..step(1, const Tr('0 >= 1 — False! Sikl tugadi.', '0 >= 1 — False! Цикл закончен.'))
    ..step(4, const Tr('Sikldan keyingi qator bajariladi.', 'Выполняется строка после цикла.'), print: 'Start!');
  return t.scene();
}

AnimScene _traceStr(Gen g) {
  final w = g.pick(const ['salom', 'python', 'idrok', 'kitob']);
  final code = ['s = "$w"', 'print(len(s))', 'print(s[0], s[-1])', 'print(s.upper())', 'print(s + "!")'];
  final t = Tracer('py', code)
    ..arr = [for (var k = 0; k < w.length; k++) w[k]]
    ..arrName = 's';
  t.step(0, const Tr('Satr — harflar qatori. Har bir harfning o‘z raqami bor.', 'Строка — ряд букв. У каждой буквы свой номер.'), set: 's', val: '"$w"');
  t.step(1, Tr('len — harflar soni: ${w.length}', 'len — число букв: ${w.length}'), print: w.length);
  t.step(2, Tr('s[0] — birinchi “${w[0]}”, s[-1] — oxirgi “${w[w.length - 1]}”', 's[0] — первая «${w[0]}», s[-1] — последняя «${w[w.length - 1]}»'),
      print: '${w[0]} ${w[w.length - 1]}', arrHot: 0);
  t.arr = [for (var k = 0; k < w.length; k++) w[k].toUpperCase()];
  t.step(3, Tr('upper() — hamma harf katta: ${w.toUpperCase()}', 'upper() — все буквы заглавные: ${w.toUpperCase()}'), print: w.toUpperCase());
  t.arr = [for (var k = 0; k < w.length; k++) w[k]];
  t.step(4, const Tr('+ satrlarni ulaydi. Asl s o‘zgarmadi!', '+ склеивает строки. Исходная s не изменилась!'), print: '$w!');
  return t.scene();
}

AnimScene _traceDict(Gen g) {
  final name = g.pick(_names);
  final a = g.n(3, 5);
  final code = ['baho = {"$name": $a}', 'baho["Sardor"] = 4', 'baho["$name"] = 5', 'print(baho["$name"])', 'print(len(baho))'];
  final t = Tracer('py', code)
    ..step(0, Tr('Lug‘at yaratildi: "$name" kaliti → $a', 'Создан словарь: ключ "$name" → $a'), set: '$name', val: a)
    ..step(1, const Tr('Yangi kalit qo‘shildi: "Sardor" → 4', 'Добавлен ключ: "Sardor" → 4'), set: 'Sardor', val: 4)
    ..step(2, Tr('Mavjud kalit — qiymat almashadi: $a → 5', 'Ключ уже есть — значение меняется: $a → 5'), set: '$name', val: 5)
    ..step(3, const Tr('Kalit bo‘yicha qiymat olamiz: 5', 'Берём значение по ключу: 5'), print: 5)
    ..step(4, const Tr('len — juftliklar soni: 2', 'len — число пар: 2'), print: 2);
  return t.scene();
}

typedef MoreScene = (Tr h, Tr p, AnimScene Function(Gen g));

final Map<String, MoreScene> kMoreScenes = {
  'html7': (const Tr('Jadval qatorma-qator quriladi', 'Таблица строится строка за строкой'), _watch, (g) {
        final s = g.sample(_subjects, 3);
        return renderHtml(const Tr('Bo‘sh jadval. Qatorlarni qo‘shamiz.', 'Пустая таблица. Добавляем строки.'), [
          ('<table>', null, const Tr('<table> — jadval boshlandi.', '<table> — начало таблицы.')),
          ('  <tr><th>Fan</th><th>Baho</th></tr>', _e('th', 'Fan | Baho', 1), const Tr('<th> — sarlavha qatori, qalin.', '<th> — строка-заголовок, жирная.')),
          ('  <tr><td>${s[0]}</td><td>5</td></tr>', _e('tr', '${s[0]} | 5', 2), const Tr('<tr> — yangi qator, <td> — kataklar.', '<tr> — новая строка, <td> — ячейки.')),
          ('  <tr><td>${s[1]}</td><td>4</td></tr>', _e('tr', '${s[1]} | 4', 3), const Tr('Yana bir qator.', 'Ещё одна строка.')),
          ('  <tr><td>${s[2]}</td><td>5</td></tr>', _e('tr', '${s[2]} | 5', 4), const Tr('Qatorlar pastga qo‘shilib boradi.', 'Строки добавляются вниз.')),
          ('</table>', null, const Tr('Jadval tayyor!', 'Таблица готова!')),
        ]);
      }),
  'html8': (const Tr('So‘zlarni ajratamiz', 'Выделяем слова'), _watch, (g) => renderHtml(
        const Tr('Oddiy matnni bezaymiz.', 'Украшаем обычный текст.'), [
          ('<p>Oddiy matn</p>', _e('p', 'Oddiy matn', 0), const Tr('Oddiy paragraf.', 'Обычный абзац.')),
          ('<strong>Juda muhim!</strong>', _e('strong', 'Juda muhim!', 1), const Tr('<strong> — qalin, muhim so‘z.', '<strong> — жирное, важное слово.')),
          ('<em>Urg‘u bilan</em>', _e('em', 'Urg‘u bilan', 2), const Tr('<em> — qiya harflar.', '<em> — курсив.')),
          ('<hr>', _e('hr', '', 3), const Tr('<hr> — ajratuvchi chiziq. Yopilmaydi!', '<hr> — разделительная линия. Не закрывается!')),
          ('<mark>Ertaga test</mark>', _e('mark', 'Ertaga test', 4), const Tr('<mark> — marker bilan belgilangandek.', '<mark> — будто выделено маркером.')),
        ])),
  'html9': (const Tr('Forma maydonlari', 'Поля формы'), _watch, (g) => renderHtml(
        const Tr('Ro‘yxatdan o‘tish formasini quramiz.', 'Строим форму регистрации.'), [
          ('<label>Shahar</label>', _e('label', 'Shahar', 0), const Tr('<label> — maydon nomi.', '<label> — подпись поля.')),
          ('<select><option>Toshkent</option></select>', _e('select', 'Toshkent', 1), const Tr('<select> — ochiluvchi ro‘yxat.', '<select> — выпадающий список.')),
          ('<input type="radio"> O‘g‘il', _e('radio', '*O‘g‘il', 2), const Tr('radio — faqat bittasini tanlash.', 'radio — выбрать только один.')),
          ('<input type="radio"> Qiz', _e('radio', 'Qiz', 3), const Tr('Bittasi tanlansa, boshqasi o‘chadi.', 'Выбрали один — другой снимается.')),
          ('<input type="checkbox"> Roziman', _e('check', '*Roziman', 4), const Tr('checkbox — belgilash katagi.', 'checkbox — флажок.')),
          ('<button>Yuborish</button>', _e('button', 'Yuborish', 5), const Tr('Forma tayyor!', 'Форма готова!')),
        ])),
  'css7': (const Tr('Chegara va soya qo‘shilishi', 'Добавляем рамку и тень'), _watch, (g) => renderCss(
        ['.karta {', '  border: 3px solid #0A6CFF;', '  border-radius: 16px;', '  box-shadow: 0 6px 12px gray;', '}'],
        [_e('div', 'Mening kartam', 0, {'class': 'karta'})], [
          (-1, const {}, const Tr('Oddiy blok.', 'Обычный блок.')),
          (1, const {'karta': {'border': '#0A6CFF'}}, const Tr('border — ko‘k chegara paydo bo‘ldi.', 'border — появилась синяя рамка.')),
          (2, const {'karta': {'border': '#0A6CFF', 'radius': '32'}}, const Tr('border-radius — burchaklar yumaloqlandi.', 'border-radius — углы скруглились.')),
          (3, const {'karta': {'border': '#0A6CFF', 'radius': '32', 'shadow': '1', 'bg': '#FFFFFF'}},
              const Tr('box-shadow — karta “ko‘tarilgandek”.', 'box-shadow — карточка будто приподнялась.')),
        ])),
  'css8': (const Tr('Tugma jonlanadi', 'Кнопка оживает'), _watch, (g) => renderCss(
        ['button {', '  background: blue;', '  transition: 0.3s;', '}', 'button:hover {', '  background: orange;', '  transform: scale(1.1);', '}'],
        [_e('div', 'Bos meni', 0, {'class': 'btn'})], [
          (1, const {'btn': {'bg': '#0A6CFF', 'color': '#FFFFFF', 'radius': '40'}}, const Tr('Oddiy holat: ko‘k tugma.', 'Обычное состояние: синяя кнопка.')),
          (2, const {'btn': {'bg': '#0A6CFF', 'color': '#FFFFFF', 'radius': '40'}}, const Tr('transition — o‘zgarishlar silliq bo‘lsin.', 'transition — пусть изменения будут плавными.')),
          (5, const {'btn': {'bg': '#FF8A00', 'color': '#FFFFFF', 'radius': '40'}}, const Tr('Barmoq ustiga keldi — :hover! Rang silliq almashdi.', 'Палец над кнопкой — :hover! Цвет плавно сменился.')),
          (6, const {'btn': {'bg': '#FF8A00', 'color': '#FFFFFF', 'radius': '40', 'scale': '1.1'}}, const Tr('scale(1.1) — biroz kattalashdi.', 'scale(1.1) — чуть увеличилась.')),
          (1, const {'btn': {'bg': '#0A6CFF', 'color': '#FFFFFF', 'radius': '40'}}, const Tr('Barmoq ketdi — yana silliq qaytdi.', 'Палец убрали — плавно вернулась.')),
        ])),
  'css9': (const Tr('% ota-elementga bog‘liq', '% зависит от родителя'), _watch, (g) => renderCss(
        ['.quti {', '  width: 25%;', '  width: 50%;', '  width: 100%;', '}'],
        [_e('div', 'quti', 0, {'class': 'q'})], [
          (-1, const {'q': {'bg': '#DCE8FF'}}, const Tr('Quti ota-element (ekran) ichida.', 'Блок внутри родителя (экрана).')),
          (1, const {'q': {'bg': '#DCE8FF', 'w': '25'}}, const Tr('25% — to‘rtdan biri.', '25% — четверть.')),
          (2, const {'q': {'bg': '#9CC0FF', 'w': '50'}}, const Tr('50% — yarmi.', '50% — половина.')),
          (3, const {'q': {'bg': '#0A6CFF', 'color': '#FFFFFF', 'w': '100'}}, const Tr('100% — butun kenglik. Ekran o‘zgarsa, quti ham o‘zgaradi!', '100% — вся ширина. Меняется экран — меняется и блок!')),
        ])),
  'js7': (const Tr('Massiv qutilari', 'Коробки массива'), _watch, _traceArrayJs),
  'js8': (const Tr('Sikl massivni aylanadi', 'Цикл обходит массив'), _watch, _traceSumJs),
  'js9': (const Tr('Obyekt bo‘limlari', 'Отделы объекта'), _watch, _traceObjJs),
  'py7': (const Tr('while ichida nima bo‘ladi', 'Что происходит внутри while'), _watch, _traceWhile),
  'py8': (const Tr('Satr — harflar qatori', 'Строка — ряд букв'), _watch, _traceStr),
  'py9': (const Tr('Lug‘at kalitlari', 'Ключи словаря'), _watch, _traceDict),
};
