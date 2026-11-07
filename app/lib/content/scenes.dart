// Har bir dars uchun animatsiya qadami (nazariyadan keyin qo‘yiladi).
// Анимированный шаг для каждого урока (ставится после теории).
import 'anim.dart';
import 'model.dart';
import 'more.dart' show kMoreScenes;

typedef SceneDef = (Tr h, Tr p, AnimScene Function(Gen g));

const _watch = Tr('Pastdagi ko‘k tugmani bosing yoki o‘qlar bilan qadamma-qadam o‘ting — kompyuter nima qilayotganini ko‘rasiz.',
    'Нажмите синюю кнопку внизу или идите по шагам стрелками — вы увидите, что делает компьютер.');

RenderEl _e(String tag, String text, int line, [Map<String, String> style = const {}]) => RenderEl(tag, text, line, style: style);

final Map<String, SceneDef> kScenes = {
  // ---------------------------------------------------------------- HTML
  'html1': (const Tr('Brauzer kodni qanday o‘qiydi', 'Как браузер читает код'), _watch, (g) => renderHtml(
        const Tr('Chapda — kod, o‘ngda — telefon ekrani. Hozircha bo‘sh.', 'Слева — код, справа — экран телефона. Пока пусто.'), [
          ('<h1>Salom!</h1>', _e('h1', 'Salom!', 0), const Tr('<h1> — katta sarlavha paydo bo‘ldi. Teglarning o‘zi ko‘rinmaydi!', '<h1> — появился крупный заголовок. Сами теги не видны!')),
          ('<p>Men kod yozyapman.</p>', _e('p', 'Men kod yozyapman.', 1), const Tr('<p> — oddiy matn (paragraf).', '<p> — обычный текст (абзац).')),
          ('<p>Bu juda oson!</p>', _e('p', 'Bu juda oson!', 2), const Tr('Har bir yangi <p> — yangi qator.', 'Каждый новый <p> — новая строка.')),
        ])),
  'html2': (const Tr('Sarlavhalar o‘lchami', 'Размеры заголовков'), _watch, (g) => renderHtml(
        const Tr('Sarlavhalar h1 dan h6 gacha. Raqam qancha kichik — shuncha katta.', 'Заголовки от h1 до h6. Чем меньше число — тем крупнее.'), [
          ('<h1>Kitob nomi</h1>', _e('h1', 'Kitob nomi', 0), const Tr('h1 — eng katta, sahifada odatda bitta.', 'h1 — самый крупный, обычно один на странице.')),
          ('<h2>1-bob</h2>', _e('h2', '1-bob', 1), const Tr('h2 — bo‘lim sarlavhasi.', 'h2 — заголовок раздела.')),
          ('<h3>Kirish</h3>', _e('h3', 'Kirish', 2), const Tr('h3 — kichikroq.', 'h3 — поменьше.')),
          ('<p>Matn shu yerda…</p>', _e('p', 'Matn shu yerda…', 3), const Tr('Oddiy matn esa <p> ichida.', 'А обычный текст — внутри <p>.')),
        ])),
  'html3': (const Tr('Havola va rasm qanday ko‘rinadi', 'Как выглядят ссылка и картинка'), _watch, (g) => renderHtml(
        const Tr('Havola boshqa sahifaga olib boradi, rasm esa ko‘rsatiladi.', 'Ссылка ведёт на другую страницу, а картинка показывается.'), [
          ('<h2>Sevimli saytim</h2>', _e('h2', 'Sevimli saytim', 0), const Tr('Sarlavha.', 'Заголовок.')),
          ('<a href="https://idrok.uz">Idrok</a>', _e('a', 'Idrok', 1), const Tr('<a> — ko‘k, ostiga chizilgan havola. href — manzil.', '<a> — синяя подчёркнутая ссылка. href — адрес.')),
          ('<img src="mushuk.jpg">', _e('img', 'mushuk.jpg', 2), const Tr('<img> — rasm. U yopilmaydi! src — fayl nomi.', '<img> — картинка. Она не закрывается! src — имя файла.')),
        ])),
  'html4': (const Tr('Ro‘yxatlar paydo bo‘lishi', 'Как появляются списки'), _watch, (g) => renderHtml(
        const Tr('ul — nuqtali ro‘yxat, ol — raqamli ro‘yxat.', 'ul — список с точками, ol — нумерованный.'), [
          ('<ul>', null, const Tr('ul ochildi — nuqtali ro‘yxat boshlandi.', 'Открыт ul — начался список с точками.')),
          ('  <li>Olma</li>', _e('li', 'Olma', 1), const Tr('Har bir <li> — bitta band.', 'Каждый <li> — один пункт.')),
          ('  <li>Nok</li>', _e('li', 'Nok', 2), const Tr('Yana bir band.', 'Ещё один пункт.')),
          ('</ul>', null, const Tr('ul yopildi.', 'ul закрыт.')),
          ('<ol>', null, const Tr('ol — tartib muhim bo‘lsa.', 'ol — когда важен порядок.')),
          ('  <li>Uyg‘onish</li>', _e('oli', '1. Uyg‘onish', 5), const Tr('Raqamlar avtomatik qo‘yiladi!', 'Номера ставятся автоматически!')),
          ('  <li>Nonushta</li>', _e('oli', '2. Nonushta', 6), const Tr('2, 3, 4… — o‘zi sanaydi.', '2, 3, 4… — считает сам.')),
          ('</ol>', null, const Tr('Tayyor!', 'Готово!')),
        ])),
  'html5': (const Tr('Sahifa qismlari', 'Части страницы'), _watch, (g) => renderHtml(
        const Tr('Har bir sahifa uch qismdan iborat bo‘ladi.', 'Каждая страница состоит из трёх частей.'), [
          ('<header>Idrok Academy</header>', _e('header', 'Idrok Academy', 0), const Tr('header — tepasi: logotip, menyu.', 'header — верх: логотип, меню.')),
          ('<main>Bugungi dars: HTML</main>', _e('main', 'Bugungi dars: HTML', 1), const Tr('main — asosiy mazmun.', 'main — основное содержимое.')),
          ('<footer>© 2026</footer>', _e('footer', '© 2026', 2), const Tr('footer — pasti: aloqa, mualliflik.', 'footer — низ: контакты, авторство.')),
        ])),
  'html6': (const Tr('Forma qanday ishlaydi', 'Как работает форма'), _watch, (g) => renderHtml(
        const Tr('Forma — foydalanuvchidan ma’lumot olish uchun.', 'Форма — чтобы получить данные от пользователя.'), [
          ('<form>', null, const Tr('form ochildi.', 'Открыта form.')),
          ('  <input placeholder="Ismingiz">', _e('input', 'Ismingiz', 1), const Tr('input — yozish maydoni. placeholder — kulrang maslahat.', 'input — поле для ввода. placeholder — серая подсказка.')),
          ('  <button>Yuborish</button>', _e('button', 'Yuborish', 2), const Tr('button — bosiladigan tugma.', 'button — кнопка.')),
          ('</form>', null, const Tr('Forma tayyor!', 'Форма готова!')),
        ])),

  // ---------------------------------------------------------------- CSS
  'css1': (const Tr('CSS qoidasi ishlashi', 'Как работает правило CSS'), _watch, (g) => renderCss(
        ['h1 {', '  color: blue;', '  font-size: 40px;', '}'], [_e('h1', 'Salom!', 0)], [
          (-1, const {}, const Tr('CSS yo‘q — oddiy qora sarlavha.', 'Без CSS — обычный чёрный заголовок.')),
          (0, const {}, const Tr('h1 { … } — “hamma h1 larga” degani.', 'h1 { … } — значит «всем h1».')),
          (1, const {'all': {'color': '#0A6CFF'}}, const Tr('color: blue — matn ko‘k bo‘ldi.', 'color: blue — текст стал синим.')),
          (2, const {'all': {'color': '#0A6CFF', 'size': '40'}}, const Tr('font-size: 40px — kattalashdi.', 'font-size: 40px — стал крупнее.')),
        ])),
  'css2': (const Tr('Matn xususiyatlari', 'Свойства текста'), _watch, (g) => renderCss(
        ['p {', '  font-size: 24px;', '  font-weight: bold;', '  text-align: center;', '}'], [_e('p', 'Kod — bu kuch!', 0)], [
          (-1, const {}, const Tr('Oddiy matn.', 'Обычный текст.')),
          (1, const {'all': {'size': '24'}}, const Tr('font-size — o‘lcham.', 'font-size — размер.')),
          (2, const {'all': {'size': '24', 'bold': '1'}}, const Tr('font-weight: bold — qalin.', 'font-weight: bold — жирный.')),
          (3, const {'all': {'size': '24', 'bold': '1', 'align': 'center'}}, const Tr('text-align: center — markazga.', 'text-align: center — по центру.')),
        ])),
  'css3': (const Tr('Rang va fon', 'Цвет и фон'), _watch, (g) => renderCss(
        ['.karta {', '  background: #0A6CFF;', '  color: white;', '  border-radius: 16px;', '}'], [_e('div', 'Mening kartam', 0, {'class': 'karta'})], [
          (-1, const {}, const Tr('Oddiy blok.', 'Обычный блок.')),
          (1, const {'karta': {'bg': '#0A6CFF'}}, const Tr('background — fon rangi.', 'background — цвет фона.')),
          (2, const {'karta': {'bg': '#0A6CFF', 'color': '#FFFFFF'}}, const Tr('color — matn rangi. Ko‘k fonda oq yaxshi o‘qiladi.', 'color — цвет текста. Белый хорошо читается на синем.')),
          (3, const {'karta': {'bg': '#0A6CFF', 'color': '#FFFFFF', 'radius': '16'}}, const Tr('border-radius — yumaloq burchaklar.', 'border-radius — скруглённые углы.')),
        ])),
  'css4': (const Tr('Quti modeli', 'Блочная модель'), _watch, (g) => boxModel()),
  'css5': (const Tr('Klass va id — kimga tegadi?', 'Класс и id — кого касается?'), _watch, (g) => renderCss(
        ['.muhim { color: red; }', '#sarlavha { color: blue; }'], [
          _e('h2', 'Sarlavha', 0, {'id': 'sarlavha'}),
          _e('p', 'Muhim xabar', 1, {'class': 'muhim'}),
          _e('p', 'Oddiy matn', 2),
          _e('p', 'Yana muhim', 3, {'class': 'muhim'}),
        ], [
          (-1, const {}, const Tr('To‘rtta element. Hozircha hammasi bir xil.', 'Четыре элемента. Пока все одинаковые.')),
          (0, const {'muhim': {'color': '#D93A44'}}, const Tr('.muhim — class="muhim" bo‘lgan HAMMA elementlar. Ikkitasi qizardi.', '.muhim — ВСЕ элементы с class="muhim". Покраснели два.')),
          (1, const {'muhim': {'color': '#D93A44'}, '#sarlavha': {'color': '#0A6CFF'}}, const Tr('#sarlavha — faqat BITTA element (id takrorlanmaydi).', '#sarlavha — только ОДИН элемент (id не повторяется).')),
        ])),
  'css6': (const Tr('Flexbox harakatda', 'Flexbox в действии'), _watch, (g) => flexScene()),

  // ---------------------------------------------------------------- JavaScript
  'js1': (const Tr('console.log ichidan qarash', 'console.log изнутри'), _watch, (g) => tracePrint(g, 'js')),
  'js2': (const Tr('Qutilar qanday o‘zgaradi', 'Как меняются коробки'), _watch, (g) => traceVars(g, 'js')),
  'js3': (const Tr('Hisob-kitobni kuzatamiz', 'Следим за вычислениями'), _watch, (g) => traceMath(g, 'js')),
  'js4': (const Tr('if qaysi yo‘lni tanlaydi', 'Какой путь выбирает if'), _watch, (g) => traceIf(g, 'js')),
  'js5': (const Tr('Sikl aylanib chiqadi', 'Цикл делает круги'), _watch, (g) => traceLoop(g, 'js')),
  'js6': (const Tr('Funksiyaga “sayohat”', '«Путешествие» в функцию'), _watch, (g) => traceFunc(g, 'js')),

  // ---------------------------------------------------------------- Python
  'py1': (const Tr('print qatorma-qator', 'print строка за строкой'), _watch, (g) => tracePrint(g, 'py')),
  'py2': (const Tr('input va o‘zgaruvchi', 'input и переменная'), _watch, (g) => traceInput(g)),
  'py3': (const Tr('//, % va ** ni ko‘ramiz', 'Смотрим //, % и **'), _watch, (g) => traceMath(g, 'py')),
  'py4': (const Tr('Shart yo‘l tanlaydi', 'Условие выбирает путь'), _watch, (g) => traceIf(g, 'py')),
  'py5': (const Tr('for sikli ichida', 'Внутри цикла for'), _watch, (g) => traceLoop(g, 'py')),
  'py6': (const Tr('Ro‘yxat qutilari', 'Коробки списка'), _watch, (g) => traceList(g)),

  // ---------------------------------------------------------------- AI
  'ai1': (const Tr('AI bilan birinchi suhbat', 'Первый разговор с AI'), _watch, (g) => chatScene(
        const Tr('AI — siz yozasiz, u javob beradi.', 'AI — вы пишете, он отвечает.'), const [
          (true, Tr('Fotosintez nima? Qisqa ayt.', 'Что такое фотосинтез? Коротко.')),
          (false, Tr('O‘simlik quyosh nuri yordamida suv va havodan ozuqa yasaydi.', 'Растение с помощью света делает пищу из воды и воздуха.')),
          (true, Tr('Rahmat! Misol bilan-chi?', 'Спасибо! А с примером?')),
          (false, Tr('Masalan, derazadagi gul quyoshga qarab o‘sadi — u nur yig‘yapti.', 'Например, цветок на окне тянется к солнцу — он собирает свет.')),
        ], const [
          Tr('Siz savol berasiz.', 'Вы задаёте вопрос.'),
          Tr('AI millionlab matnlardan o‘rgangan qonuniyat asosida javob beradi.', 'AI отвечает по закономерностям из миллионов текстов.'),
          Tr('Aniqlashtiruvchi savol — yaxshiroq javob.', 'Уточняющий вопрос — ответ лучше.'),
          Tr('Lekin AI ham xato qilishi mumkin — doim tekshiring!', 'Но AI тоже ошибается — всегда проверяйте!'),
        ])),
  'ai2': (const Tr('AI o‘rganishini ko‘ramiz', 'Смотрим, как учится AI'), _watch, (g) => learnScene(g)),
  'ai3': (const Tr('Yomon va yaxshi so‘rov', 'Плохой и хороший запрос'), _watch, (g) => chatScene(
        const Tr('Bir xil mavzu, ikki xil so‘rov.', 'Одна тема, два разных запроса.'), const [
          (true, Tr('Kasrlar', 'Дроби')),
          (false, Tr('Kasr — butunning qismi… (uzun, umumiy, tushunarsiz matn)', 'Дробь — часть целого… (длинный, общий, непонятный текст)')),
          (true, Tr('Men 6-sinfman. Kasrlarni pitsa misolida 3 qadamda oddiy tushuntir.', 'Я в 6 классе. Объясни дроби на примере пиццы в 3 шага, просто.')),
          (false, Tr('1) Pitsa 4 bo‘lakka bo‘lindi. 2) 1 bo‘lak — 1/4. 3) 3 bo‘lak — 3/4. Oson!', '1) Пиццу разрезали на 4 части. 2) 1 кусок — 1/4. 3) 3 куска — 3/4. Легко!')),
        ], const [
          Tr('Bir so‘z — aniqlik yo‘q.', 'Одно слово — никакой точности.'),
          Tr('Natija: umumiy va zerikarli javob.', 'Результат: общий и скучный ответ.'),
          Tr('Kim + nima + qanday shakl + cheklov.', 'Кто + что + в каком виде + ограничение.'),
          Tr('Natija: aynan sizga mos javob!', 'Результат: ответ именно для вас!'),
        ])),
  'ai4': (const Tr('AI xatosini ushlaymiz', 'Ловим ошибку AI'), _watch, (g) => chatScene(
        const Tr('AI ishonch bilan gapiradi — lekin har doim ham to‘g‘ri emas.', 'AI говорит уверенно — но не всегда правильно.'), const [
          (true, Tr('Toshkent metrosi qachon ochilgan?', 'Когда открыли ташкентское метро?')),
          (false, Tr('Toshkent metrosi 1995-yilda ochilgan.', 'Ташкентское метро открыли в 1995 году.')),
          (true, Tr('Manbangni ko‘rsat. Darslikda 1977 deyilgan.', 'Покажи источник. В учебнике написано 1977.')),
          (false, Tr('Kechirasiz, to‘g‘risi — 1977-yil.', 'Извините, правильно — 1977 год.')),
        ], const [
          Tr('Savol — fakt haqida.', 'Вопрос — о факте.'),
          Tr('⚠ Javob ishonchli ko‘rinadi, lekin XATO. Bu — gallyutsinatsiya.', '⚠ Ответ выглядит уверенно, но это ОШИБКА. Это галлюцинация.'),
          Tr('Manba so‘rang va boshqa joyda tekshiring.', 'Спросите источник и проверьте в другом месте.'),
          Tr('Qoida: muhim faktni 2 ta ishonchli manbada tekshiring.', 'Правило: важный факт проверяйте в 2 надёжных источниках.'),
        ])),
  'ai5': (const Tr('Soxtani qanday tanish', 'Как распознать фейк'), _watch, (g) => chatScene(
        const Tr('Sizga shunday xabar keldi…', 'Вам пришло такое сообщение…'), const [
          (false, Tr('🎉 Tabriklaymiz! Siz iPhone yutdingiz! Havolaga kiring va karta raqamingizni yozing!', '🎉 Поздравляем! Вы выиграли iPhone! Перейдите по ссылке и введите номер карты!')),
          (true, Tr('Men hech qanday tanlovda qatnashmaganman…', 'Я ни в каком конкурсе не участвовал…')),
          (false, Tr('Tezroq! 10 daqiqada yo‘qoladi!', 'Быстрее! Через 10 минут сгорит!')),
          (true, Tr('Bu firibgarlik. Havolani ochmayman va kattalarga aytaman.', 'Это мошенничество. Ссылку не открою и расскажу взрослым.')),
        ], const [
          Tr('1-belgi: kutilmagan “sovg‘a”.', 'Признак 1: неожиданный «подарок».'),
          Tr('2-belgi: siz qatnashmagansiz.', 'Признак 2: вы не участвовали.'),
          Tr('3-belgi: shoshiltirish va karta raqamini so‘rash.', 'Признак 3: торопят и просят номер карты.'),
          Tr('To‘g‘ri harakat: ochmang, yozmang, kattalarga ayting.', 'Правильно: не открывать, не писать, сказать взрослым.'),
        ])),
  'aiA1': (const Tr('Chatbot javob topishi', 'Как чат-бот находит ответ'), _watch, (g) {
        final q = g.pick(const ['salom', 'isming', 'xayr']);
        final ans = {'salom': 'Salom!', 'isming': 'Men Idrok botman', 'xayr': 'Ko‘rishguncha!'}[q]!;
        return (Tracer('py', [
          'javoblar = {"salom": "Salom!", "isming": "Men Idrok botman", "xayr": "Ko‘rishguncha!"}',
          'gap = input().lower()',
          'print(javoblar.get(gap, "Tushunmadim"))',
        ])
              ..step(0, const Tr('Lug‘at: kalit → javob. Bu botning “xotirasi”.', 'Словарь: ключ → ответ. Это «память» бота.'))
              ..step(1, Tr('Foydalanuvchi “${q.toUpperCase()}” yozdi → .lower() → “$q”', 'Пользователь написал «${q.toUpperCase()}» → .lower() → «$q»'), set: 'gap', val: '"$q"')
              ..step(2, Tr('.get() lug‘atdan “$q” kalitini topdi.', '.get() нашёл в словаре ключ «$q».'), print: ans))
            .scene();
      }),
  'aiA2': (const Tr('Raqamni piksel bo‘yicha tanish', 'Распознаём цифру по пикселям'), _watch, (g) => gridScene(g)),
  'aiA3': (const Tr('Savol generatori ichida', 'Внутри генератора вопросов'), _watch, (g) {
        final a = g.n(2, 9), b = g.n(2, 9);
        return (Tracer('py', ['import random', 'a = random.randint(1, 9)', 'b = random.randint(1, 9)', 'print(a, "+", b, "=", "?")', 'javob = a + b'])
              ..step(0, const Tr('random — tasodifiy sonlar uchun.', 'random — для случайных чисел.'))
              ..step(1, Tr('Tasodifan a = $a chiqdi.', 'Случайно выпало a = $a.'), set: 'a', val: a)
              ..step(2, Tr('b = $b', 'b = $b'), set: 'b', val: b)
              ..step(3, const Tr('Savol tayyor — har safar yangi!', 'Вопрос готов — каждый раз новый!'), print: '$a + $b = ?')
              ..step(4, Tr('To‘g‘ri javob ham hisoblab qo‘yildi: ${a + b}', 'Правильный ответ тоже посчитан: ${a + b}'), set: 'javob', val: a + b))
            .scene();
      }),
  'aiM1': (const Tr('Niyatni ball bilan topish', 'Находим намерение по баллам'), _watch, (g) {
        return (Tracer('py', [
          'gap = "bugun ob-havo qanday"',
          'ball = {"salom": 0, "havo": 0}',
          'for soz in gap.split():',
          '    if soz in ["havo", "ob-havo"]: ball["havo"] += 1',
          'print(max(ball, key=ball.get))',
        ])
              ..step(0, const Tr('Foydalanuvchi gapi.', 'Фраза пользователя.'), set: 'gap', val: '"bugun ob-havo qanday"')
              ..step(1, const Tr('Har bir niyat uchun ball 0 dan boshlanadi.', 'Баллы каждого намерения начинаются с 0.'), set: 'ball', val: '{salom: 0, havo: 0}')
              ..step(2, const Tr('Gapni so‘zlarga bo‘lamiz va birma-bir tekshiramiz.', 'Делим фразу на слова и проверяем по одному.'), set: 'soz', val: '"ob-havo"')
              ..step(3, const Tr('“ob-havo” — havo niyatiga +1 ball!', '«ob-havo» — +1 балл намерению havo!'), set: 'ball', val: '{salom: 0, havo: 1}')
              ..step(4, const Tr('Eng ko‘p ball — “havo”. Bot ob-havo haqida javob beradi.', 'Больше всего баллов — «havo». Бот ответит про погоду.'), print: 'havo'))
            .scene();
      }),
  'aiM2': (const Tr('Eng yaqin qo‘shnilar (k-NN)', 'Ближайшие соседи (k-NN)'), _watch, (g) => learnScene(g)),
  'aiM3': (const Tr('Moslashuvchan daraja', 'Адаптивный уровень'), _watch, (g) {
        final t = Tracer('py', ['daraja = 1', 'if togri: daraja += 1', 'else: daraja -= 1', 'daraja = max(1, min(3, daraja))'])
          ..step(0, const Tr('Test 1-darajadan boshlanadi.', 'Тест начинается с уровня 1.'), set: 'daraja', val: 1)
          ..step(1, const Tr('To‘g‘ri javob → qiyinroq savol.', 'Правильный ответ → вопрос сложнее.'), set: 'daraja', val: 2)
          ..step(1, const Tr('Yana to‘g‘ri → 3-daraja.', 'Снова верно → уровень 3.'), set: 'daraja', val: 3)
          ..step(2, const Tr('Xato → bir pog‘ona osonroq.', 'Ошибка → на ступень проще.'), set: 'daraja', val: 2)
          ..step(3, const Tr('Daraja doim 1 va 3 orasida qoladi.', 'Уровень всегда остаётся между 1 и 3.'));
        return t.scene();
      }),
  'ai6': (const Tr('Rasm — raqamlar jadvali', 'Картинка — таблица чисел'), _watch, (g) => gridScene(g)),
  'ai7': (const Tr('Nimani yozish mumkin emas', 'Что нельзя писать'), _watch, (g) => chatScene(
        const Tr('Kimdir “AI yordamchi” deb yozdi…', 'Кто-то написал как «AI-помощник»…'), const [
          (false, Tr('Salom! Sizga yordam berishim uchun parolingiz va uy manzilingizni yozing.', 'Привет! Чтобы я помог, напишите пароль и домашний адрес.')),
          (true, Tr('Nega senga parolim kerak?', 'Зачем тебе мой пароль?')),
          (false, Tr('Shunchaki tekshirish uchun 🙂', 'Просто для проверки 🙂')),
          (true, Tr('Yo‘q. Haqiqiy yordamchi parol so‘ramaydi. Men kattalarga aytaman.', 'Нет. Настоящий помощник пароль не просит. Я скажу взрослым.')),
        ], const [
          Tr('⚠ Shaxsiy ma’lumot so‘ralmoqda.', '⚠ Просят личные данные.'),
          Tr('To‘g‘ri savol: nega kerak?', 'Правильный вопрос: зачем?'),
          Tr('Asossiz javob — xavf belgisi.', 'Необоснованный ответ — признак опасности.'),
          Tr('Parol, manzil, karta — hech qachon hech kimga!', 'Пароль, адрес, карта — никогда и никому!'),
        ])),
  'aiA4': (const Tr('Sharh balini hisoblaymiz', 'Считаем балл отзыва'), _watch, (g) {
        final t = Tracer('py', ['ball = 0', 'for soz in matn.split():', '    if soz in ijobiy: ball += 1', '    if soz in salbiy: ball -= 1', 'print(ball)'])
          ..step(0, const Tr('Matn: “zo‘r dars lekin qiyin”. Ball 0 dan boshlanadi.', 'Текст: «zo‘r dars lekin qiyin». Балл начинается с 0.'), set: 'ball', val: 0)
          ..step(1, const Tr('1-so‘z: “zo‘r”', 'Слово 1: «zo‘r»'), set: 'soz', val: '"zo‘r"')
          ..step(2, const Tr('Ijobiy so‘z → +1', 'Позитивное слово → +1'), set: 'ball', val: 1)
          ..step(1, const Tr('“dars”, “lekin” — neytral, ball o‘zgarmaydi.', '«dars», «lekin» — нейтральные, балл не меняется.'), set: 'soz', val: '"lekin"')
          ..step(1, const Tr('Oxirgi so‘z: “qiyin”', 'Последнее слово: «qiyin»'), set: 'soz', val: '"qiyin"')
          ..step(3, const Tr('Salbiy so‘z → −1', 'Негативное слово → −1'), set: 'ball', val: 0)
          ..step(4, const Tr('Ball 0 — sharh neytral.', 'Балл 0 — отзыв нейтральный.'), print: 0);
        return t.scene();
      }),
  'aiM4': (const Tr('Neyron ichida', 'Внутри нейрона'), _watch, (g) {
        final t = Tracer('py', ['x1, x2 = 1, 2', 'w1, w2, b = 3, 1, -4', 's = w1*x1 + w2*x2 + b', 'natija = 1 if s > 0 else 0', 'print(natija)'])
          ..step(0, const Tr('Ikki kirish: masalan, “quloq uzunligi” va “o‘lcham”.', 'Два входа: например, «длина ушей» и «размер».'), set: 'x1', val: 1)
          ..step(0, const Tr('x2 = 2', 'x2 = 2'), set: 'x2', val: 2)
          ..step(1, const Tr('Og‘irliklar: x1 muhimroq (3), x2 kamroq (1). bias = −4.', 'Веса: x1 важнее (3), x2 меньше (1). bias = −4.'), set: 'w1', val: 3)
          ..step(2, const Tr('Yig‘indi: 3·1 + 1·2 − 4 = 1', 'Сумма: 3·1 + 1·2 − 4 = 1'), set: 's', val: 1)
          ..step(3, const Tr('1 > 0 → neyron “yonadi”: natija 1.', '1 > 0 → нейрон «загорается»: результат 1.'), set: 'natija', val: 1)
          ..step(4, const Tr('Millionlab shunday neyron birga — bu neyron tarmoq!', 'Миллионы таких нейронов вместе — это нейросеть!'), print: 1);
        return t.scene();
      }),
  ...kMoreScenes,
};
