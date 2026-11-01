// CSS kursi — boshlovchilar uchun / курс CSS — для начинающих.
import 'model.dart';

const _colors = ['red', 'blue', 'green', 'orange', 'purple', 'navy', 'teal'];
const _colorUz = {
  'red': Tr('qizil', 'красный'),
  'blue': Tr('ko‘k', 'синий'),
  'green': Tr('yashil', 'зелёный'),
  'orange': Tr('to‘q sariq', 'оранжевый'),
  'purple': Tr('binafsha', 'фиолетовый'),
  'navy': Tr('to‘q ko‘k', 'тёмно-синий'),
  'teal': Tr('moviy-yashil', 'бирюзовый'),
};

List<LessonStep> css1(Gen g) {
  final col = g.pick(_colors);
  final cn = _colorUz[col]!;
  final sel = g.pick(['h1', 'p', 'h2']);
  return [
    const LessonStep.read(
      h: Tr('CSS — sahifaning kiyimi', 'CSS — одежда страницы'),
      p: Tr(
          'HTML — skelet bo‘lsa, CSS — kiyim: rang, o‘lcham, joylashuv. Qoida shunday yoziladi: '
              'kimga { nima: qanday; }. Masalan h1 { color: blue; } — barcha h1 larni ko‘k qiladi.',
          'Если HTML — скелет, то CSS — одежда: цвет, размер, расположение. Правило пишется так: '
              'кому { что: как; }. Например, h1 { color: blue; } — делает все h1 синими.'),
      code: 'h1 {\n  color: blue;\n}',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Matn rangini qaysi xususiyat o‘zgartiradi?', 'Какое свойство меняет цвет текста?'), 'color',
          ['background', 'font', 'text'])),
      Q(1, (g) => g.quizCode(const Tr('Har bir qoida oxirida nima qo‘yiladi?', 'Что ставится в конце каждого правила?'), ';', [':', ',', '.'])),
      Q(2, (g) => g.quiz(Tr('Bu kod kimni ${cn.uz} qiladi?', 'Кого этот код сделает «${cn.ru}»?'), lit(sel),
          [lit(sel == 'h1' ? 'p' : 'h1'), const Tr('Butun sahifani', 'Всю страницу'), const Tr('Hech kimni', 'Никого')],
          code: '$sel {\n  color: $col;\n}', mono: true)),
      Q(3, (g) => g.quiz(const Tr('Xato qayerda?', 'Где ошибка?'), const Tr('“:” o‘rniga “=” yozilgan', 'Вместо «:» написано «=»'),
          const [Tr('Qavslar ortiqcha', 'Лишние скобки'), Tr('Xato yo‘q', 'Ошибки нет'), Tr('color degan xususiyat yo‘q', 'Свойства color нет')],
          code: 'p {\n  color = red;\n}')),
    ], 2),
    g.fill(Tr('Matnni ${cn.uz} qiling:', 'Сделайте текст «${cn.ru}»:'), '$sel { ', ': $col; }', ['color']),
    g.tryIt(
      mode: 'css',
      task: Tr('$sel uchun $col rangini bering.', 'Задайте $sel цвет $col.'),
      start: '$sel {\n  \n}',
      hint: lit('color: $col;'),
      check: (c, o) => has('$sel\\s*\\{[^}]*(?<![-\\w])color\\s*:\\s*$col', c),
      solution: '$sel {\n  color: $col;\n}',
    ),
  ];
}

List<LessonStep> css2(Gen g) {
  final px = g.pick([18, 20, 22, 24, 28, 32]);
  final align = g.pick(['center', 'right', 'left']);
  final alignT = {'center': const Tr('markazga', 'по центру'), 'right': const Tr('o‘ngga', 'вправо'), 'left': const Tr('chapga', 'влево')}[align]!;
  return [
    const LessonStep.read(
      h: Tr('Matn bilan ishlash', 'Работа с текстом'),
      p: Tr(
          'font-size — harf o‘lchami (masalan 20px). font-weight — qalinlik (bold — qalin). '
              'text-align — tekislash: left (chap), center (markaz), right (o‘ng).',
          'font-size — размер букв (например 20px). font-weight — жирность (bold — жирный). '
              'text-align — выравнивание: left (влево), center (по центру), right (вправо).'),
      code: 'h1 {\n  font-size: 32px;\n  font-weight: bold;\n  text-align: center;\n}',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Harf o‘lchamini nima belgilaydi?', 'Что задаёт размер букв?'), 'font-size',
          ['font-weight', 'text-size', 'size'])),
      Q(1, (g) => g.quizCode(const Tr('Matnni qalin qilish:', 'Сделать текст жирным:'), 'font-weight: bold;',
          ['font-size: bold;', 'text: bold;', 'bold: true;'])),
      Q(2, (g) => g.quizCode(Tr('Matnni $alignT qanday tekislaymiz?', 'Как выровнять текст $alignT?'), 'text-align: $align;',
          ['align: $align;', 'font-align: $align;', 'text: $align;'])),
      Q(3, (g) => g.quiz(Tr('Qaysi biri kattaroq: ${px}px yoki ${px + 6}px?', 'Что крупнее: ${px}px или ${px + 6}px?'), lit('${px + 6}px'),
          [lit('${px}px'), const Tr('Bir xil', 'Одинаково'), const Tr('Bilib bo‘lmaydi', 'Нельзя сказать')])),
    ], 2),
    g.fill(Tr('Sarlavhani ${px}px qiling:', 'Сделайте заголовок ${px}px:'), 'h1 { font-', ': ${px}px; }', ['size']),
    g.tryIt(
      mode: 'css',
      task: Tr('p uchun font-size: ${px}px va text-align: $align bering.', 'Задайте p: font-size ${px}px и text-align $align.'),
      start: 'p {\n  \n}',
      hint: lit('font-size: ${px}px;\ntext-align: $align;'),
      check: (c, o) => has('p\\s*\\{[^}]*font-size\\s*:\\s*${px}px', c) && has('p\\s*\\{[^}]*text-align\\s*:\\s*$align', c),
      solution: 'p {\n  font-size: ${px}px;\n  text-align: $align;\n}',
    ),
  ];
}

List<LessonStep> css3(Gen g) {
  final hex = g.pick(['#0A6CFF', '#FF5733', '#22AA55', '#111111', '#FFFFFF']);
  final name = {'#0A6CFF': 'ko‘k / синий', '#FF5733': 'qizg‘ish / красноватый', '#22AA55': 'yashil / зелёный', '#111111': 'qora / чёрный', '#FFFFFF': 'oq / белый'}[hex]!;
  return [
    LessonStep.read(
      h: const Tr('Ranglar va fon', 'Цвета и фон'),
      p: const Tr(
          'Rangni so‘z bilan (blue) yoki kod bilan (#0A6CFF) yozish mumkin. Kod — qizil, yashil va ko‘k aralashmasi. '
              'background-color — elementning orqa foni.',
          'Цвет можно писать словом (blue) или кодом (#0A6CFF). Код — смесь красного, зелёного и синего. '
              'background-color — фон элемента.'),
      code: 'body {\n  background-color: #F2F5FA;\n}\nh1 {\n  color: $hex; /* $name */\n}',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Fon rangini nima o‘zgartiradi?', 'Что меняет цвет фона?'), 'background-color',
          ['color', 'font-color', 'bg'])),
      Q(1, (g) => g.quiz(const Tr('#FFFFFF qaysi rang?', 'Какой цвет #FFFFFF?'), const Tr('Oq', 'Белый'),
          const [Tr('Qora', 'Чёрный'), Tr('Qizil', 'Красный'), Tr('Ko‘k', 'Синий')])),
      Q(2, (g) => g.quiz(const Tr('#000000 qaysi rang?', 'Какой цвет #000000?'), const Tr('Qora', 'Чёрный'),
          const [Tr('Oq', 'Белый'), Tr('Kulrang', 'Серый'), Tr('Yashil', 'Зелёный')])),
      Q(3, (g) => g.quiz(const Tr('Matn va fon bir xil rangda bo‘lsa nima bo‘ladi?', 'Что будет, если текст и фон одного цвета?'),
          const Tr('Matn ko‘rinmay qoladi', 'Текст станет невидимым'),
          const [Tr('Matn qalinlashadi', 'Текст станет жирным'), Tr('Xato chiqadi', 'Будет ошибка'), Tr('Hech narsa', 'Ничего')])),
    ], 2),
    g.fill(const Tr('Fon rangini bering:', 'Задайте цвет фона:'), 'body { background-', ': $hex; }', ['color']),
    g.tryIt(
      mode: 'css',
      task: Tr('body uchun background-color: $hex bering.', 'Задайте body фон $hex.'),
      start: 'body {\n  \n}',
      hint: lit('background-color: $hex;'),
      check: (c, o) => has('body\\s*\\{[^}]*background(-color)?\\s*:\\s*${RegExp.escape(hex)}', c),
      solution: 'body {\n  background-color: $hex;\n}',
    ),
  ];
}

List<LessonStep> css4(Gen g) {
  final pad = g.pick([8, 12, 16, 20, 24]);
  return [
    const LessonStep.read(
      h: Tr('Har bir element — quti', 'Каждый элемент — коробка'),
      p: Tr(
          'Sovg‘a qutisini tasavvur qiling: padding — sovg‘a va devor orasidagi yumshoq joy, border — quti devori, '
              'margin — qutidan boshqa qutilargacha masofa.',
          'Представьте подарочную коробку: padding — мягкое место между подарком и стенкой, border — стенка коробки, '
              'margin — расстояние до соседних коробок.'),
      code: '.karta {\n  padding: 16px;\n  border: 2px solid blue;\n  margin: 20px;\n}',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Ichki bo‘sh joy qanday ataladi?', 'Как называется внутренний отступ?'), 'padding',
          ['margin', 'border', 'gap'])),
      Q(1, (g) => g.quizCode(const Tr('Tashqi masofa qaysi?', 'Какой отступ внешний?'), 'margin', ['padding', 'border', 'space'])),
      Q(2, (g) => g.quizCode(const Tr('Qaysi chegara to‘g‘ri yozilgan?', 'Какая рамка написана правильно?'), 'border: 2px solid blue;',
          ['border: blue 2px line;', 'border = 2px blue;', 'border-all: 2px;'],
          e: const Tr('Tartib: qalinlik, uslub, rang.', 'Порядок: толщина, стиль, цвет.'))),
      Q(3, (g) => g.quiz(Tr('padding: ${pad}px bo‘lsa, matn devordan qancha uzoq?', 'При padding: ${pad}px — как далеко текст от рамки?'),
          lit('${pad}px'), [lit('${pad * 2}px'), lit('0px'), const Tr('Bilib bo‘lmaydi', 'Нельзя сказать')])),
    ], 2),
    g.order(const Tr('Qoidani yig‘ing:', 'Соберите правило:'), ['.karta {', '  padding: ${pad}px;', '  border: 1px solid gray;', '}']),
    g.tryIt(
      mode: 'css',
      task: Tr('.karta ga padding: ${pad}px va istalgan border qo‘shing.', 'Добавьте .karta padding ${pad}px и любую рамку border.'),
      start: '.karta {\n  \n}',
      hint: lit('padding: ${pad}px;\nborder: 2px solid blue;'),
      check: (c, o) => has('\\.karta\\s*\\{[^}]*padding\\s*:\\s*${pad}px', c) && has('\\.karta\\s*\\{[^}]*border\\s*:', c),
      solution: '.karta {\n  padding: ${pad}px;\n  border: 2px solid blue;\n}',
    ),
  ];
}

List<LessonStep> css5(Gen g) {
  final cls = g.pick(['tugma', 'karta', 'eslatma']);
  final col = g.pick(_colors);
  return [
    const LessonStep.read(
      h: Tr('Klass va id: aniq kimga?', 'Класс и id: кому именно?'),
      p: Tr(
          'h1 { } hamma h1 ga ta’sir qiladi. Faqat ba’zilarini bezash uchun klass beramiz: <p class="muhim">. '
              'CSS da klass nuqta bilan yoziladi: .muhim { }. id esa # bilan: #asosiy { } — u yagona element uchun.',
          'h1 { } влияет на все h1. Чтобы оформить только некоторые, даём класс: <p class="muhim">. '
              'В CSS класс пишется с точкой: .muhim { }. А id — с #: #asosiy { } — для одного элемента.'),
      code: '<p class="muhim">Diqqat!</p>\n\n.muhim {\n  color: red;\n}',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Klass CSS da qanday yoziladi?', 'Как класс пишется в CSS?'), '.muhim', ['#muhim', 'muhim', '*muhim'])),
      Q(1, (g) => g.quizCode(const Tr('id CSS da qanday yoziladi?', 'Как id пишется в CSS?'), '#asosiy', ['.asosiy', 'asosiy', '@asosiy'])),
      Q(2, (g) => g.quiz(const Tr('class va id farqi?', 'Разница class и id?'),
          const Tr('Klass ko‘p elementda, id — bittada', 'Класс — у многих элементов, id — у одного'),
          const [Tr('Farqi yo‘q', 'Никакой разницы'), Tr('id faqat rasmlar uchun', 'id только для картинок'), Tr('Klass faqat bitta', 'Класс только один')])),
      Q(3, (g) => g.quiz(Tr('Qaysi element $col bo‘ladi?', 'Какой элемент станет $col?'), lit('<p class="$cls">B</p>'),
          [lit('<p>A</p>'), lit('<p id="$cls">C</p>'), const Tr('Hammasi', 'Все')],
          code: '.$cls { color: $col; }', mono: true)),
    ], 2),
    g.fill(Tr('“$cls” klassini tanlang:', 'Выберите класс «$cls»:'), '', '$cls { color: $col; }', ['.']),
    g.tryIt(
      mode: 'css',
      task: Tr('.$cls klassiga color: $col bering.', 'Задайте классу .$cls color: $col.'),
      start: '\n',
      hint: lit('.$cls {\n  color: $col;\n}'),
      check: (c, o) => has('\\.$cls\\s*\\{[^}]*(?<![-\\w])color\\s*:\\s*$col', c),
      solution: '.$cls {\n  color: $col;\n}',
    ),
  ];
}

List<LessonStep> css6(Gen g) {
  final jc = g.pick(['center', 'space-between', 'flex-end']);
  final gap = g.pick([8, 12, 16, 24]);
  return [
    const LessonStep.read(
      h: Tr('Flexbox: elementlarni qatorga terish', 'Flexbox: выстраиваем элементы в ряд'),
      p: Tr(
          'display: flex — ichidagi elementlarni bir qatorga teradi (javondagi kitoblar kabi). '
              'justify-content — qatorda qanday joylashish: center (o‘rtada), space-between (chetlarga), flex-end (oxirida). '
              'gap — elementlar orasidagi masofa.',
          'display: flex — выстраивает вложенные элементы в ряд (как книги на полке). '
              'justify-content — как расположить в ряду: center (по центру), space-between (по краям), flex-end (в конце). '
              'gap — расстояние между элементами.'),
      code: '.menyu {\n  display: flex;\n  justify-content: center;\n  gap: 12px;\n}',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Elementlarni qatorga nima teradi?', 'Что выстраивает элементы в ряд?'), 'display: flex;',
          ['display: row;', 'flex: on;', 'align: line;'])),
      Q(2, (g) => g.quizCode(const Tr('Elementlar orasidagi masofa:', 'Расстояние между элементами:'), 'gap: ${gap}px;',
          ['space: ${gap}px;', 'margin-all: ${gap}px;', 'between: ${gap}px;'])),
      Q(2, (g) => g.quiz(const Tr('justify-content: center nima qiladi?', 'Что делает justify-content: center?'),
          const Tr('Elementlarni o‘rtaga to‘playdi', 'Собирает элементы по центру'),
          const [Tr('Matnni qalin qiladi', 'Делает текст жирным'), Tr('Fonni o‘zgartiradi', 'Меняет фон'), Tr('Elementlarni yashiradi', 'Скрывает элементы')])),
      Q(3, (g) => g.quiz(const Tr('Bu kodda nima yetishmaydi?', 'Чего не хватает в этом коде?'), lit('display: flex;'),
          [lit('color: red;'), lit('padding: 0;'), const Tr('Hech narsa', 'Ничего')],
          code: '.menyu {\n  justify-content: center;\n  gap: 12px;\n}', mono: true,
          e: const Tr('justify-content faqat flex qutida ishlaydi.', 'justify-content работает только во flex-контейнере.'))),
    ], 2),
    g.order(const Tr('Flex qoidasini yig‘ing:', 'Соберите flex-правило:'),
        ['.menyu {', '  display: flex;', '  justify-content: $jc;', '}']),
    g.tryIt(
      mode: 'css',
      task: Tr('.menyu ga display: flex, justify-content: $jc va gap: ${gap}px bering.',
          'Задайте .menyu: display flex, justify-content $jc и gap ${gap}px.'),
      start: '.menyu {\n  \n}',
      hint: lit('display: flex;\njustify-content: $jc;\ngap: ${gap}px;'),
      check: (c, o) =>
          has('\\.menyu\\s*\\{[^}]*display\\s*:\\s*flex', c) &&
          has('\\.menyu\\s*\\{[^}]*justify-content\\s*:\\s*$jc', c) &&
          has('\\.menyu\\s*\\{[^}]*gap\\s*:\\s*${gap}px', c),
      solution: '.menyu {\n  display: flex;\n  justify-content: $jc;\n  gap: ${gap}px;\n}',
    ),
  ];
}
