// Sun’iy intellekt kursi — har bir liga uchun alohida.
// Курс «Искусственный интеллект» — отдельно для каждой лиги.
import 'model.dart';

const kBeginner = {'beginner'};
const kAdvanced = {'advanced'};
const kMaster = {'master'};

// ============================================================ BOSHLANG‘ICH / НАЧАЛЬНАЯ
List<LessonStep> ai1(Gen g) => [
      const LessonStep.read(
        h: Tr('Sun’iy intellekt nima?', 'Что такое искусственный интеллект?'),
        p: Tr(
            'Sun’iy intellekt (AI) — kompyuterga “o‘ylashga o‘xshash” ishlarni o‘rgatish: rasmni tanish, gapni tarjima qilish, savolga javob berish. '
                'AI sehr emas: u millionlab misollardan qonuniyat topadi. Telefoningizdagi yuzni tanish, YouTube tavsiyalari, tarjimon — hammasi AI.',
            'Искусственный интеллект (AI) — это когда компьютер учат делать «похожие на мышление» вещи: узнавать картинки, переводить, отвечать на вопросы. '
                'AI — не магия: он находит закономерности в миллионах примеров. Разблокировка по лицу, рекомендации YouTube, переводчик — всё это AI.'),
      ),
      ...g.from([
        Q(1, (g) => g.quiz(const Tr('Qaysi biri AI ga misol?', 'Что из этого пример AI?'), const Tr('Yuz bilan telefonni ochish', 'Разблокировка телефона по лицу'),
            const [Tr('Oddiy kalkulyator', 'Обычный калькулятор'), Tr('Qog‘oz daftar', 'Бумажная тетрадь'), Tr('Chiroq tugmasi', 'Выключатель света')])),
        Q(1, (g) => g.quiz(const Tr('AI qanday o‘rganadi?', 'Как учится AI?'), const Tr('Ko‘p misollardan qonuniyat topib', 'Находя закономерности в множестве примеров'),
            const [Tr('O‘zi tug‘ilganidan biladi', 'Знает с рождения'), Tr('Sehr bilan', 'С помощью магии'), Tr('Hech qachon o‘rganmaydi', 'Никогда не учится')])),
        Q(2, (g) => g.quiz(const Tr('AI har doim to‘g‘ri javob beradimi?', 'AI всегда отвечает правильно?'), const Tr('Yo‘q, u ham xato qiladi', 'Нет, он тоже ошибается'),
            const [Tr('Ha, har doim', 'Да, всегда'), Tr('Faqat kechasi xato qiladi', 'Ошибается только ночью'), Tr('Faqat ingliz tilida to‘g‘ri', 'Прав только на английском')])),
        Q(3, (g) => g.quiz(const Tr('Qaysi vazifa AI uchun eng qiyin?', 'Какая задача для AI самая трудная?'),
            const Tr('Hech qachon ko‘rmagan, misoli yo‘q narsa haqida xulosa', 'Вывод о том, чего он никогда не видел и примеров чего нет'),
            const [Tr('Mashhur tilni tarjima qilish', 'Перевод с популярного языка'), Tr('Mushuk rasmini tanish', 'Узнать кошку на фото'), Tr('Matnni qisqartirish', 'Сократить текст')])),
      ], 2),
      g.order(const Tr('AI qanday ishlaydi — tartiblang:', 'Как работает AI — упорядочьте:'),
          ['Ko‘p misol yig‘iladi', 'AI qonuniyat qidiradi', 'Yangi savolga javob beradi', 'Odam natijani tekshiradi']),
    ];

List<LessonStep> ai2(Gen g) {
  final animal = g.pick(const [Tr('mushuk', 'кошка'), Tr('it', 'собака'), Tr('qush', 'птица')]);
  return [
    const LessonStep.read(
      h: Tr('AI qanday o‘rganadi?', 'Как учится AI?'),
      p: Tr(
          'Bolaga mushukni o‘rgatishni eslang: unga ko‘p mushuk ko‘rsatasiz va “bu mushuk” deysiz. AI ham shunday: '
              'unga “belgilangan” misollar beriladi (rasm + javob). Bu — o‘qitish (training). Misollar qancha ko‘p va xilma-xil bo‘lsa, AI shuncha yaxshi.',
          'Вспомните, как ребёнка учат узнавать кошку: показывают много кошек и говорят «это кошка». AI так же: '
              'ему дают «размеченные» примеры (картинка + ответ). Это обучение (training). Чем больше и разнообразнее примеры, тем лучше AI.'),
    ),
    ...g.from([
      Q(1, (g) => g.quiz(const Tr('O‘qitish uchun nima kerak?', 'Что нужно для обучения?'), const Tr('Javobi bor ko‘p misollar', 'Много примеров с ответами'),
          const [Tr('Faqat bitta rasm', 'Только одна картинка'), Tr('Tez internet', 'Быстрый интернет'), Tr('Katta ekran', 'Большой экран')])),
      Q(2, (g) => g.quiz(Tr('AI faqat oq ${animal.uz}larni ko‘rib o‘rgandi. Qora ${animal.uz}ni ko‘rsa nima bo‘lishi mumkin?',
              'AI учили только на белых (${animal.ru}). Что может случиться с чёрной?'),
          const Tr('Xato qilishi mumkin', 'Может ошибиться'),
          const [Tr('Albatta to‘g‘ri topadi', 'Точно угадает'), Tr('Rangni o‘zgartiradi', 'Перекрасит её'), Tr('O‘chib qoladi', 'Выключится')],
          e: const Tr('Misollar xilma-xil bo‘lmasa, AI “bir tomonlama” o‘rganadi.', 'Если примеры однообразные, AI учится «однобоко».'))),
      Q(3, (g) => g.quiz(const Tr('Misollardagi noto‘g‘ri javoblar nimaga olib keladi?', 'К чему приводят неправильные ответы в примерах?'),
          const Tr('AI ham noto‘g‘ri o‘rganadi', 'AI тоже научится неправильно'),
          const [Tr('Hech narsaga', 'Ни к чему'), Tr('AI tezlashadi', 'AI ускорится'), Tr('AI o‘zi tuzatadi', 'AI сам исправит')])),
    ], 2),
    g.order(const Tr('O‘qitish bosqichlarini tartiblang:', 'Расставьте этапы обучения:'),
        ['Rasmlar yig‘ish', 'Har biriga javob yozish', 'AI ni o‘qitish', 'Yangi rasmlarda sinash']),
  ];
}

List<LessonStep> ai3(Gen g) {
  final topic = g.pick(const [Tr('quyosh tizimi', 'солнечная система'), Tr('kasrlar', 'дроби'), Tr('fotosintez', 'фотосинтез')]);
  return [
    const LessonStep.read(
      h: Tr('Aqlli so‘rov (prompt) yozish', 'Как писать умный запрос (промпт)'),
      p: Tr(
          'AI ga qanchalik aniq yozsangiz, javob shunchalik yaxshi. Yaxshi so‘rov 4 qismdan iborat: '
              '1) kimsiz (7-sinf o‘quvchisi), 2) nima kerak (kasrlarni tushuntir), 3) qanday shaklda (3 ta misol bilan, qisqa), '
              '4) cheklov (oddiy so‘zlar bilan).',
          'Чем точнее вы пишете AI, тем лучше ответ. Хороший запрос состоит из 4 частей: '
              '1) кто вы (ученик 7 класса), 2) что нужно (объясни дроби), 3) в каком виде (3 примера, коротко), '
              '4) ограничение (простыми словами).'),
    ),
    ...g.from([
      Q(1, (g) => g.quiz(const Tr('Qaysi so‘rov yaxshiroq?', 'Какой запрос лучше?'),
          Tr('Men 7-sinf o‘quvchisiman. ${topic.uz} haqida 3 ta qisqa misol bilan oddiy tushuntir.',
              'Я ученик 7 класса. Объясни «${topic.ru}» просто, с 3 короткими примерами.'),
          [Tr(topic.uz, topic.ru), const Tr('Bir narsa ayt', 'Скажи что-нибудь'), const Tr('Tushuntir', 'Объясни')])),
      Q(2, (g) => g.quiz(const Tr('“Qanday shaklda” qismiga misol:', 'Пример части «в каком виде»:'), const Tr('jadval ko‘rinishida', 'в виде таблицы'),
          const [Tr('men o‘quvchiman', 'я ученик'), Tr('tarix haqida', 'про историю'), Tr('salom', 'привет')])),
      Q(3, (g) => g.quiz(const Tr('AI javobi juda murakkab chiqdi. Nima qilasiz?', 'Ответ AI слишком сложный. Что делать?'),
          const Tr('Oddiyroq va qisqaroq qilib qayta so‘rash', 'Попросить ещё раз — проще и короче'),
          const [Tr('Hammasini yod olish', 'Выучить всё наизусть'), Tr('AI ni o‘chirish', 'Выключить AI'), Tr('Boshqa mavzuga o‘tish', 'Сменить тему')])),
    ], 2),
    g.order(const Tr('Yaxshi so‘rov qismlarini tartiblang:', 'Упорядочьте части хорошего запроса:'),
        ['Men kimman', 'Menga nima kerak', 'Qanday shaklda', 'Qanday cheklov bilan']),
    g.tryIt(
      mode: 'text',
      task: Tr('“${topic.uz}” haqida yaxshi so‘rov yozing: kimligingiz, nima kerakligi va shakli (masalan “3 ta misol”).',
          'Напишите хороший запрос про «${topic.ru}»: кто вы, что нужно и в каком виде (например, «3 примера»).'),
      start: '',
      hint: Tr('Men 7-sinf o‘quvchisiman. ${topic.uz} haqida oddiy so‘zlar bilan 3 ta misol keltirib tushuntir.',
          'Я ученик 7 класса. Объясни «${topic.ru}» простыми словами на 3 примерах.'),
      check: (c, o) {
        final t = c.toLowerCase();
        final who = has(r'(men|я)\s', t) || t.contains('o‘quvchi') || t.contains("o'quvchi") || t.contains('ученик');
        final form = has(r'\d', t) || t.contains('misol') || t.contains('пример') || t.contains('jadval') || t.contains('таблиц');
        return who && form && t.trim().length >= 40;
      },
      solution: 'Men 7-sinf o‘quvchisiman. ${topic.uz} haqida oddiy so‘zlar bilan 3 ta misol keltirib tushuntir.',
    ),
  ];
}

List<LessonStep> ai4(Gen g) => [
      const LessonStep.read(
        h: Tr('AI xatolarini topish', 'Как находить ошибки AI'),
        p: Tr(
            'AI ba’zan ishonch bilan yolg‘on gapiradi — bunga “gallyutsinatsiya” deyiladi: mavjud bo‘lmagan kitob, noto‘g‘ri sana, '
                'o‘ylab topilgan raqam. Qoida: muhim faktni kamida 2 ta ishonchli manbada tekshiring (darslik, rasmiy sayt, o‘qituvchi).',
            'AI иногда уверенно говорит неправду — это называют «галлюцинацией»: несуществующая книга, неверная дата, '
                'выдуманное число. Правило: важный факт проверяйте минимум в 2 надёжных источниках (учебник, официальный сайт, учитель).'),
      ),
      ...g.from([
        Q(1, (g) => g.quiz(const Tr('“Gallyutsinatsiya” nima?', 'Что такое «галлюцинация»?'), const Tr('AI ishonch bilan noto‘g‘ri ma’lumot berishi', 'Когда AI уверенно даёт неверные сведения'),
            const [Tr('AI ning tezligi', 'Скорость AI'), Tr('AI ning rasm chizishi', 'Рисование картинок AI'), Tr('Internet uzilishi', 'Обрыв интернета')])),
        Q(2, (g) => g.quiz(const Tr('AI aytdi: “Amir Temur 1900-yilda tug‘ilgan”. Nima qilasiz?', 'AI сказал: «Амир Темур родился в 1900 году». Что делать?'),
            const Tr('Darslikda tekshiraman — bu xato (1336-yil)', 'Проверю в учебнике — это ошибка (1336 год)'),
            const [Tr('Ishonaman, AI biladi', 'Поверю, AI знает'), Tr('Do‘stlarimga yuboraman', 'Отправлю друзьям'), Tr('Hech narsa', 'Ничего')])),
        Q(3, (g) => g.quiz(const Tr('Qaysi belgi AI xato qilganini ko‘rsatishi mumkin?', 'Какой признак может указывать на ошибку AI?'),
            const Tr('Manba so‘ralganda, u mavjud bo‘lmagan sayt beradi', 'На просьбу дать источник он даёт несуществующий сайт'),
            const [Tr('Javob o‘zbek tilida', 'Ответ на узбекском'), Tr('Javob qisqa', 'Ответ короткий'), Tr('Javobda raqam bor', 'В ответе есть число')])),
      ], 2),
      g.order(const Tr('Faktni tekshirish tartibi:', 'Порядок проверки факта:'),
          ['AI javobini o‘qish', 'Muhim faktni ajratish', '2 ta manbada tekshirish', 'Xulosa qilish']),
    ];

List<LessonStep> ai5(Gen g) => [
      const LessonStep.read(
        h: Tr('Soxta rasm, video va xavfsizlik', 'Фейковые фото, видео и безопасность'),
        p: Tr(
            'AI soxta rasm va video (deepfake) yasay oladi. Belgilar: g‘alati barmoqlar, xira fon, lab va ovoz mos emas, soyalar noto‘g‘ri. '
                'Xavfsizlik: AI chatlarga parol, manzil, telefon raqam va shaxsiy rasmlarni yubormang.',
            'AI умеет создавать фейковые фото и видео (дипфейки). Признаки: странные пальцы, размытый фон, губы не совпадают со звуком, неправильные тени. '
                'Безопасность: не отправляйте в AI-чаты пароли, адрес, номер телефона и личные фото.'),
      ),
      ...g.from([
        Q(1, (g) => g.quiz(const Tr('Deepfake nima?', 'Что такое дипфейк?'), const Tr('AI yasagan soxta video yoki rasm', 'Фейковое видео или фото, созданное AI'),
            const [Tr('Yangi telefon', 'Новый телефон'), Tr('Kompyuter o‘yini', 'Компьютерная игра'), Tr('Ijtimoiy tarmoq', 'Соцсеть')])),
        Q(1, (g) => g.quiz(const Tr('AI chatga nimani yubormaslik kerak?', 'Что нельзя отправлять в AI-чат?'), const Tr('Parol va uy manzilini', 'Пароль и домашний адрес'),
            const [Tr('Matematik misolni', 'Пример по математике'), Tr('She’r so‘rovini', 'Просьбу написать стих'), Tr('Tarjima uchun matnni', 'Текст для перевода')])),
        Q(2, (g) => g.quiz(const Tr('Qaysi belgi rasm soxta ekanini ko‘rsatadi?', 'Какой признак выдаёт фейковое фото?'), const Tr('Qo‘lda 6 ta barmoq', '6 пальцев на руке'),
            const [Tr('Rasm rangli', 'Фото цветное'), Tr('Rasmda odam bor', 'На фото есть человек'), Tr('Rasm katta', 'Фото большое')])),
        Q(3, (g) => g.quiz(const Tr('Do‘stingiz haqida g‘alati video tarqaldi. To‘g‘ri harakat?', 'Распространилось странное видео о друге. Как правильно поступить?'),
            const Tr('Tarqatmayman, kattalarga va do‘stimga aytaman', 'Не распространяю, сообщаю взрослым и другу'),
            const [Tr('Hammaga yuboraman', 'Отправлю всем'), Tr('Izoh yozaman', 'Напишу комментарий'), Tr('Hech narsa qilmayman', 'Ничего не сделаю')])),
      ], 2),
      g.order(const Tr('Shubhali videoni ko‘rganda:', 'Если видите подозрительное видео:'),
          ['To‘xtab, shoshilmaslik', 'Belgilarni tekshirish', 'Manbani qidirish', 'Tarqatmaslik']),
    ];

// ============================================================ ILG‘OR / ПРОДВИНУТАЯ — loyihalar / проекты
const _replies = {
  'salom': ('Salom! Qanday yordam beray?', 'salom'),
  'dars': ('Bugun dasturlash darsini o‘tamiz!', 'dars'),
  'rahmat': ('Arzimaydi!', 'rahmat'),
  'xayr': ('Xayr, ko‘rishguncha!', 'xayr'),
};

List<LessonStep> aiA1(Gen g) {
  final keys = g.sample(_replies.keys.toList(), 3);
  final newKey = g.pick(['ob-havo', 'sport', 'kitob']);
  final newReply = {'ob-havo': 'Bugun havo ochiq!', 'sport': 'Sport foydali!', 'kitob': 'Kitob — eng yaxshi do‘st!'}[newKey]!;
  final dict = keys.map((k) => '    "$k": "${_replies[k]!.$1}",').join('\n');
  return [
    const LessonStep.read(
      h: Tr('Loyiha: oddiy chatbot', 'Проект: простой чат-бот'),
      p: Tr(
          'Eng birinchi chatbotlar kalit so‘zlar bilan ishlagan: xabarda “salom” bo‘lsa — salomlashadi. '
              'Biz lug‘at (dict) qilamiz: kalit so‘z → javob. Funksiya xabarni kichik harfga o‘tkazadi va kalit so‘zlarni qidiradi.',
          'Первые чат-боты работали по ключевым словам: если в сообщении есть «salom» — бот здоровается. '
              'Сделаем словарь (dict): ключевое слово → ответ. Функция переводит сообщение в нижний регистр и ищет ключевые слова.'),
      code: 'javoblar = {"salom": "Salom!"}\n\ndef javob(xabar):\n    xabar = xabar.lower()\n    for kalit in javoblar:\n        if kalit in xabar:\n            return javoblar[kalit]\n    return "Tushunmadim"',
    ),
    ...g.from([
      Q(1, (g) => g.quiz(const Tr('dict nimani saqlaydi?', 'Что хранит dict?'), const Tr('Kalit → qiymat juftliklarini', 'Пары ключ → значение'),
          const [Tr('Faqat raqamlarni', 'Только числа'), Tr('Rasmlarni', 'Картинки'), Tr('Hech narsani', 'Ничего')])),
      Q(2, (g) => g.quiz(const Tr('Nega .lower() kerak?', 'Зачем нужен .lower()?'), const Tr('“SALOM” va “salom” bir xil topilishi uchun', 'Чтобы «SALOM» и «salom» находились одинаково'),
          const [Tr('Tezlik uchun', 'Для скорости'), Tr('Xatoni yashirish uchun', 'Чтобы скрыть ошибку'), Tr('Rang uchun', 'Для цвета')])),
      Q(3, (g) => g.quiz(const Tr('Bu bot “Salom, dars qachon?” ga nima deydi?', 'Что ответит бот на «Salom, dars qachon?»?'),
          const Tr('Lug‘atda birinchi topilgan kalitning javobini', 'Ответ первого найденного ключа в словаре'),
          const [Tr('Ikkala javobni', 'Оба ответа'), Tr('Tushunmadim', 'Tushunmadim'), Tr('Xato beradi', 'Выдаст ошибку')])),
    ], 2),
    g.tryIt(
      mode: 'py',
      task: Tr('Lug‘atga "$newKey" kalitini “$newReply” javobi bilan qo‘shing va javob("$newKey haqida gapir") ni chiqaring.',
          'Добавьте в словарь ключ "$newKey" с ответом «$newReply» и выведите javob("$newKey haqida gapir").'),
      start: 'javoblar = {\n$dict\n}\n\ndef javob(xabar):\n    xabar = xabar.lower()\n    for kalit in javoblar:\n        if kalit in xabar:\n            return javoblar[kalit]\n    return "Tushunmadim"\n\n# shu yerga yozing\n',
      hint: lit('javoblar["$newKey"] = "$newReply"\nprint(javob("$newKey haqida gapir"))'),
      check: (c, o) => o.contains(newReply),
      solution:
          'javoblar = {\n$dict\n}\n\ndef javob(xabar):\n    xabar = xabar.lower()\n    for kalit in javoblar:\n        if kalit in xabar:\n            return javoblar[kalit]\n    return "Tushunmadim"\n\njavoblar["$newKey"] = "$newReply"\nprint(javob("$newKey haqida gapir"))',
    ),
  ];
}

const _digits = {
  '0': '111101101101111',
  '1': '010110010010111',
  '4': '101101111001001',
  '7': '111001010010010',
};

String _flip(Gen g, String p) {
  final i = g.n(0, p.length - 1);
  return p.substring(0, i) + (p[i] == '1' ? '0' : '1') + p.substring(i + 1);
}

List<LessonStep> aiA2(Gen g) {
  final d = g.pick(_digits.keys.toList());
  final noisy = _flip(g, _digits[d]!);
  final tmpl = _digits.entries.map((e) => '    "${e.key}": "${e.value}",').join('\n');
  const fn = 'def farq(a, b):\n    return sum(1 for x, y in zip(a, b) if x != y)';
  final base = 'namunalar = {\n$tmpl\n}\n\n';
  const recog = '\n\ndef tanib_ol(rasm):\n    return min(namunalar, key=lambda r: farq(namunalar[r], rasm))\n\n';
  return [
    const LessonStep.read(
      h: Tr('Loyiha: raqamni taniydigan dastur', 'Проект: программа, узнающая цифры'),
      p: Tr(
          'Raqam 3×5 katakli rasm: 1 — bo‘yalgan, 0 — bo‘sh. Har bir raqamning namunasi bor. Yangi rasmni har bir namuna bilan solishtiramiz: '
              'nechta katak farq qiladi? Eng kam farq qilgan namuna — javob. Bu “eng yaqin qo‘shni” usuli — haqiqiy AI ning soddalashgan ko‘rinishi.',
          'Цифра — картинка 3×5 клеток: 1 — закрашено, 0 — пусто. У каждой цифры есть образец. Новую картинку сравниваем с каждым образцом: '
              'сколько клеток отличается? Образец с наименьшей разницей — ответ. Это метод «ближайшего соседа» — упрощённый настоящий AI.'),
      code: '1 1 1\n1 0 1\n1 0 1   ← "0"\n1 0 1\n1 1 1',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('"101" va "111" nechta katakda farq qiladi?', 'В скольких клетках различаются "101" и "111"?'), '1', ['0', '2', '3'])),
      Q(2, (g) => g.quiz(const Tr('Qaysi namuna tanlanadi?', 'Какой образец будет выбран?'), const Tr('Farqi eng kichik bo‘lgani', 'С наименьшей разницей'),
          const [Tr('Farqi eng katta bo‘lgani', 'С наибольшей разницей'), Tr('Birinchisi', 'Первый'), Tr('Tasodifiysi', 'Случайный')])),
      Q(3, (g) => g.quiz(const Tr('Rasmda 1 ta katak xato bo‘lsa ham dastur topadimi?', 'Найдёт ли программа цифру, если 1 клетка испорчена?'),
          const Tr('Ha, chunki eng yaqin namuna baribir o‘sha raqam', 'Да, ближайший образец всё равно та же цифра'),
          const [Tr('Yo‘q, hech qachon', 'Нет, никогда'), Tr('Faqat 0 uchun', 'Только для 0'), Tr('Faqat kechasi', 'Только ночью')])),
    ], 2),
    g.tryIt(
      mode: 'py',
      task: Tr('farq(a, b) funksiyasini yozing (nechta belgi farq qiladi) va tanib_ol("$noisy") natijasini chiqaring.',
          'Напишите farq(a, b) (сколько символов различается) и выведите tanib_ol("$noisy").'),
      start: '${base}def farq(a, b):\n    # shu yerga yozing\n    return 0$recog',
      hint: lit('return sum(1 for x, y in zip(a, b) if x != y)\n…\nprint(tanib_ol("$noisy"))'),
      check: (c, o) => o.trim() == d,
      solution: '$base$fn${recog}print(tanib_ol("$noisy"))',
    ),
  ];
}

List<LessonStep> aiA3(Gen g) {
  final k = g.n(3, 5);
  final seed = g.n(1, 99);
  final op = g.pick(['+', '*']);
  return [
    const LessonStep.read(
      h: Tr('Loyiha: test savollari generatori', 'Проект: генератор тестовых вопросов'),
      p: Tr(
          'Ilovamiz har urinishda yangi savol beradi — xuddi shunday generatorni o‘zingiz yozasiz. random.randint(1, 10) — 1 dan 10 gacha tasodifiy son. '
              'random.seed(n) — “tasodif”ni takrorlanadigan qiladi (tekshirish uchun qulay).',
          'Наше приложение каждый раз даёт новые вопросы — такой же генератор напишете вы. random.randint(1, 10) — случайное число от 1 до 10. '
              'random.seed(n) делает «случайность» повторяемой (удобно для проверки).'),
      code: 'import random\nrandom.seed(7)\na = random.randint(1, 10)\nb = random.randint(1, 10)\nprint(f"{a} + {b} = {a + b}")',
    ),
    ...g.from([
      Q(1, (g) => g.quizCode(const Tr('Tasodifiy butun son qaysi funksiya?', 'Какая функция даёт случайное целое?'), 'random.randint',
          ['random.seed', 'random.list', 'print'])),
      Q(2, (g) => g.quiz(const Tr('random.seed nima uchun?', 'Зачем random.seed?'), const Tr('Natijani takrorlanadigan qilish uchun', 'Чтобы результат повторялся'),
          const [Tr('Tezlik uchun', 'Для скорости'), Tr('Savollarni o‘chirish uchun', 'Чтобы удалить вопросы'), Tr('Rang uchun', 'Для цвета')])),
      Q(3, (g) => g.quiz(const Tr('Savollar har doim har xil bo‘lishi uchun nima qilinadi?', 'Как сделать, чтобы вопросы всегда были разными?'),
          const Tr('seed ni qo‘ymaslik (yoki vaqtdan olish)', 'Не задавать seed (или брать из времени)'),
          const [Tr('seed(1) qo‘yish', 'Поставить seed(1)'), Tr('Savolni qo‘lda yozish', 'Писать вопрос вручную'), Tr('print ni olib tashlash', 'Убрать print')])),
    ], 2),
    g.tryIt(
      mode: 'py',
      task: Tr('$k ta savol chiqaring: har qatorda “a $op b = javob” (a va b — 1..20 tasodifiy).',
          'Выведите $k вопросов: в каждой строке «a $op b = ответ» (a и b — случайные 1..20).'),
      start: 'import random\nrandom.seed($seed)\n\nfor i in range($k):\n    # shu yerga yozing\n    pass\n',
      hint: lit('a = random.randint(1, 20)\nb = random.randint(1, 20)\nprint(f"{a} $op {b} = {a $op b}")'),
      check: (c, o) {
        final ls = outLines(o);
        if (ls.length != k) return false;
        final re = RegExp(r'^(\d+)\s*([+*])\s*(\d+)\s*=\s*(\d+)$');
        for (final l in ls) {
          final m = re.firstMatch(l);
          if (m == null || m.group(2) != op) return false;
          final a = int.parse(m.group(1)!), b = int.parse(m.group(3)!), r = int.parse(m.group(4)!);
          if (a < 1 || a > 20 || b < 1 || b > 20 || r != (op == '+' ? a + b : a * b)) return false;
        }
        return true;
      },
      solution:
          'import random\nrandom.seed($seed)\n\nfor i in range($k):\n    a = random.randint(1, 20)\n    b = random.randint(1, 20)\n    print(f"{a} $op {b} = {a $op b}")',
    ),
  ];
}

// ============================================================ USTA / МАСТЕР — murakkabroq loyihalar / сложнее
List<LessonStep> aiM1(Gen g) {
  final msgs = g.sample(const [
    ('Assalomu alaykum, qalaysiz?', 'Salom! Qanday yordam beray?'),
    ('Bugun havo issiq bo‘ladimi?', 'Ob-havo ilovasini tekshiring.'),
    ('Uy vazifa juda qiyin', 'Keling, darsni birga ko‘ramiz!'),
    ('Imtihonga qanday tayyorlanay?', 'Keling, darsni birga ko‘ramiz!'),
  ], 2);
  const intents =
      'niyatlar = {\n    "salomlashish": ["salom", "assalomu", "hayrli"],\n    "ob-havo": ["havo", "yomg‘ir", "issiq"],\n    "dars": ["dars", "vazifa", "imtihon"],\n}\njavoblar = {\n    "salomlashish": "Salom! Qanday yordam beray?",\n    "ob-havo": "Ob-havo ilovasini tekshiring.",\n    "dars": "Keling, darsni birga ko‘ramiz!",\n}\n';
  const tail =
      '\n\ndef javob(xabar):\n    xabar = xabar.lower()\n    eng_yaxshi = max(niyatlar, key=lambda n: ball(xabar, niyatlar[n]))\n    if ball(xabar, niyatlar[eng_yaxshi]) == 0:\n        return "Tushunmadim"\n    return javoblar[eng_yaxshi]\n\n';
  final prints = msgs.map((m) => 'print(javob("${m.$1}"))').join('\n');
  return [
    const LessonStep.read(
      h: Tr('Loyiha: niyatni aniqlaydigan chatbot', 'Проект: чат-бот, определяющий намерение'),
      p: Tr(
          'Oddiy bot birinchi topilgan so‘zga javob beradi. Aqlliroq bot har bir “niyat” (salomlashish, ob-havo, dars) uchun ball hisoblaydi: '
              'xabarda shu niyatning nechta kalit so‘zi bor. Eng ko‘p ball olgan niyat tanlanadi. Zamonaviy botlar ham niyatni aniqlaydi — faqat ancha murakkab usulda.',
          'Простой бот отвечает на первое найденное слово. Бот умнее считает баллы для каждого «намерения» (приветствие, погода, учёба): '
              'сколько ключевых слов этого намерения есть в сообщении. Выбирается намерение с наибольшим баллом. Современные боты тоже определяют намерение — только намного сложнее.'),
    ),
    ...g.from([
      Q(2, (g) => g.quiz(const Tr('Niyat (intent) nima?', 'Что такое намерение (intent)?'), const Tr('Foydalanuvchi nimani xohlayotgani', 'Чего хочет пользователь'),
          const [Tr('Botning nomi', 'Имя бота'), Tr('Xabar uzunligi', 'Длина сообщения'), Tr('Javob rangi', 'Цвет ответа')])),
      Q(3, (g) => g.quiz(const Tr('Hamma niyatlar balli 0 bo‘lsa?', 'Если у всех намерений 0 баллов?'), const Tr('“Tushunmadim” deyish', 'Ответить «Tushunmadim»'),
          const [Tr('Tasodifiy javob', 'Случайный ответ'), Tr('Dasturni to‘xtatish', 'Остановить программу'), Tr('Birinchi niyatni tanlash', 'Выбрать первое намерение')])),
      Q(3, (g) => g.quizCode(const Tr('ball("bugun havo issiq", ["havo", "yomg‘ir", "issiq"]) = ?', 'ball("bugun havo issiq", ["havo", "yomg‘ir", "issiq"]) = ?'),
          '2', ['1', '3', '0'])),
    ], 2),
    g.tryIt(
      mode: 'py',
      task: const Tr('ball(xabar, sozlar) funksiyasini yozing: xabarda nechta so‘z uchrashini qaytarsin. Keyin ikkala xabarga javobni chiqaring.',
          'Напишите ball(xabar, sozlar): сколько слов из списка встречается в сообщении. Затем выведите ответы на оба сообщения.'),
      start: '${intents}\ndef ball(xabar, sozlar):\n    # shu yerga yozing\n    return 0$tail$prints\n',
      hint: lit('return sum(1 for s in sozlar if s in xabar)'),
      check: (c, o) {
        final ls = outLines(o);
        return ls.length == msgs.length && [for (var i = 0; i < msgs.length; i++) ls[i] == msgs[i].$2].every((x) => x);
      },
      solution: '${intents}\ndef ball(xabar, sozlar):\n    return sum(1 for s in sozlar if s in xabar)$tail$prints',
    ),
  ];
}

List<LessonStep> aiM2(Gen g) {
  final d = g.pick(['0', '1', '7']);
  final a = _flip(g, _digits[d]!);
  final b = _flip(g, _flip(g, _digits[g.pick(_digits.keys.where((x) => x != d).toList())]!));
  final samples = <String>[];
  for (final e in _digits.entries) {
    samples.add('    ("${e.value}", "${e.key}"),');
    samples.add('    ("${_flip(Gen(e.key.codeUnitAt(0), 1), e.value)}", "${e.key}"),');
  }
  final base = 'from collections import Counter\n\nmisollar = [\n${samples.join('\n')}\n]\n\ndef farq(a, b):\n    return sum(1 for x, y in zip(a, b) if x != y)\n\n';
  const solFn =
      'def tanib_ol(rasm, k=3):\n    yaqinlar = sorted(misollar, key=lambda m: farq(m[0], rasm))[:k]\n    ovozlar = Counter(raqam for _, raqam in yaqinlar)\n    return ovozlar.most_common(1)[0][0]\n';
  return [
    const LessonStep.read(
      h: Tr('Loyiha: k-eng yaqin qo‘shni (k-NN)', 'Проект: k ближайших соседей (k-NN)'),
      p: Tr(
          'Bitta namuna yetarli emas — har bir raqamdan bir nechta misol olamiz. Yangi rasm uchun eng yaqin k ta misolni topamiz '
              'va ular “ovoz beradi”: qaysi raqam ko‘p bo‘lsa — o‘sha javob. Bu haqiqiy mashinali o‘qitish algoritmi!',
          'Одного образца мало — берём несколько примеров каждой цифры. Для новой картинки находим k ближайших примеров, '
              'и они «голосуют»: какая цифра встречается чаще — та и ответ. Это настоящий алгоритм машинного обучения!'),
    ),
    ...g.from([
      Q(2, (g) => g.quiz(const Tr('k-NN da “k” nima?', 'Что означает «k» в k-NN?'), const Tr('Nechta eng yaqin misol ovoz beradi', 'Сколько ближайших примеров голосуют'),
          const [Tr('Raqamlar soni', 'Количество цифр'), Tr('Rasm o‘lchami', 'Размер картинки'), Tr('Xatolar soni', 'Количество ошибок')])),
      Q(3, (g) => g.quiz(const Tr('Nega k odatda toq son (3, 5)?', 'Почему k обычно нечётное (3, 5)?'), const Tr('Ovozlar teng bo‘lib qolmasligi uchun', 'Чтобы голоса не разделились поровну'),
          const [Tr('Tezroq ishlashi uchun', 'Чтобы быстрее работало'), Tr('Chiroyli bo‘lishi uchun', 'Для красоты'), Tr('Farqi yo‘q', 'Без разницы')])),
      Q(3, (g) => g.quizCode(const Tr('Counter(["7","1","7"]).most_common(1)[0][0] = ?', 'Counter(["7","1","7"]).most_common(1)[0][0] = ?'), '7', ['1', '2', '3'])),
    ], 2),
    g.tryIt(
      mode: 'py',
      task: Tr('tanib_ol(rasm, k=3) ni yozing: eng yaqin 3 ta misolni oling va ko‘pchilik ovozini qaytaring. Keyin tanib_ol("$a") ni chiqaring.',
          'Напишите tanib_ol(rasm, k=3): возьмите 3 ближайших примера и верните ответ большинства. Затем выведите tanib_ol("$a").'),
      start: '${base}def tanib_ol(rasm, k=3):\n    # shu yerga yozing\n    return "?"\n\n# print(tanib_ol("$b")) — sinab ko‘ring\n',
      hint: lit('yaqinlar = sorted(misollar, key=lambda m: farq(m[0], rasm))[:k]\novozlar = Counter(r for _, r in yaqinlar)\nreturn ovozlar.most_common(1)[0][0]'),
      check: (c, o) => outLines(o).isNotEmpty && outLines(o).last == d,
      solution: '$base$solFn\nprint(tanib_ol("$a"))',
    ),
  ];
}

List<LessonStep> aiM3(Gen g) {
  final ans = [for (var i = 0; i < 6; i++) g.r.nextBool()];
  var level = 1;
  final exp = <int>[];
  for (final x in ans) {
    level = x ? (level < 3 ? level + 1 : 3) : (level > 1 ? level - 1 : 1);
    exp.add(level);
  }
  final pyList = '[${ans.map((x) => x ? 'True' : 'False').join(', ')}]';
  return [
    const LessonStep.read(
      h: Tr('Loyiha: moslashuvchan test', 'Проект: адаптивный тест'),
      p: Tr(
          'Aqlli test o‘quvchiga moslashadi: to‘g‘ri javobdan keyin qiyinroq savol (daraja +1, ko‘pi bilan 3), xatodan keyin osonroq (daraja -1, kamida 1). '
              'Idrok Akademiyasi ham shunday ishlaydi!',
          'Умный тест подстраивается под ученика: после правильного ответа — вопрос сложнее (уровень +1, максимум 3), после ошибки — проще (уровень -1, минимум 1). '
              'Idrok Akademiyasi работает так же!'),
    ),
    ...g.from([
      Q(2, (g) => g.quizCode(const Tr('Daraja 3 da to‘g‘ri javob berilsa?', 'Уровень 3, ответ верный — какой уровень?'), '3', ['4', '2', '1'])),
      Q(3, (g) => g.quizCode(const Tr('Daraja 1, javoblar: xato, to‘g‘ri, to‘g‘ri. Oxirgi daraja?', 'Уровень 1, ответы: ошибка, верно, верно. Итоговый уровень?'), '3', ['2', '1', '4'])),
      Q(3, (g) => g.quiz(const Tr('Moslashuvchan testning foydasi?', 'Польза адаптивного теста?'), const Tr('Har kimga mos qiyinlik', 'Подходящая сложность для каждого'),
          const [Tr('Savollar kamroq', 'Меньше вопросов'), Tr('Hamma bir xil', 'Все одинаково'), Tr('Tezroq tugaydi', 'Быстрее заканчивается')])),
    ], 2),
    g.tryIt(
      mode: 'py',
      task: const Tr('Har bir javobdan keyin darajani yangilang (to‘g‘ri: +1, maks 3; xato: -1, min 1) va darajani chiqaring.',
          'После каждого ответа обновляйте уровень (верно: +1, макс 3; ошибка: -1, мин 1) и выводите уровень.'),
      start: 'javoblar = $pyList\ndaraja = 1\n\nfor togri in javoblar:\n    # shu yerga yozing\n    print(daraja)\n',
      hint: lit('if togri:\n    daraja = min(3, daraja + 1)\nelse:\n    daraja = max(1, daraja - 1)'),
      check: (c, o) => words(o).join(' ') == exp.join(' '),
      solution:
          'javoblar = $pyList\ndaraja = 1\n\nfor togri in javoblar:\n    if togri:\n        daraja = min(3, daraja + 1)\n    else:\n        daraja = max(1, daraja - 1)\n    print(daraja)',
    ),
  ];
}

// ============================================================ QO‘SHIMCHA DARSLAR / ДОПОЛНИТЕЛЬНЫЕ УРОКИ
List<LessonStep> ai6(Gen g) {
  final n = g.pick(const [3, 4, 5]);
  return [
    const LessonStep.read(
      h: Tr('AI rasmni qanday “ko‘radi”?', 'Как AI «видит» картинку?'),
      p: Tr(
          'Kompyuter uchun rasm — raqamlar jadvali. Har bir kichik nuqta (piksel) bitta son: 0 — oq, 1 — qora. '
              'Rangli rasmda har pikselda 3 ta son bor: qizil, yashil, ko‘k. AI millionlab shunday jadvallarni ko‘rib, '
              '“ko‘z”, “quloq”, “g‘ildirak” kabi naqshlarni topishni o‘rganadi.',
          'Для компьютера картинка — таблица чисел. Каждая маленькая точка (пиксель) — одно число: 0 — белый, 1 — чёрный. '
              'В цветной картинке у каждого пикселя 3 числа: красный, зелёный, синий. AI смотрит миллионы таких таблиц '
              'и учится находить узоры вроде «глаз», «ухо», «колесо».'),
    ),
    ...g.from([
      Q(1, (g) => g.quiz(const Tr('Kompyuter uchun rasm nima?', 'Что такое картинка для компьютера?'), const Tr('Raqamlar jadvali (piksellar)', 'Таблица чисел (пиксели)'),
          const [Tr('Rangli qog‘oz', 'Цветная бумага'), Tr('Bitta so‘z', 'Одно слово'), Tr('Ovoz', 'Звук')])),
      Q(1, (g) => g.quiz(const Tr('Piksel nima?', 'Что такое пиксель?'), const Tr('Rasmning eng kichik nuqtasi', 'Самая маленькая точка картинки'),
          const [Tr('Kamera turi', 'Вид камеры'), Tr('Fayl nomi', 'Имя файла'), Tr('Internet tezligi', 'Скорость интернета')])),
      Q(2, (g) => g.quiz(Tr('Rasm $n×$n piksel. Unda nechta piksel bor?', 'Картинка $n×$n пикселей. Сколько в ней пикселей?'), lit('${n * n}'),
          [lit('${n * 2}'), lit('$n'), lit('${n * n + n}')])),
      Q(2, (g) => g.quiz(const Tr('Rangli pikselda nechta son bo‘ladi?', 'Сколько чисел в цветном пикселе?'), lit('3'),
          [lit('1'), lit('10'), lit('100')], e: const Tr('Qizil, yashil va ko‘k (RGB).', 'Красный, зелёный и синий (RGB).'))),
      Q(3, (g) => g.quiz(const Tr('AI faqat kunduzgi rasmlarda o‘qitildi. Kechasi olingan rasmda nima bo‘ladi?', 'AI учили только на дневных фото. Что будет с ночным фото?'),
          const Tr('Xato qilishi mumkin — u bunday misollarni ko‘rmagan', 'Может ошибиться — таких примеров он не видел'),
          const [Tr('Yanada yaxshi taniydi', 'Узнает ещё лучше'), Tr('Rasmni o‘zi yoritadi', 'Сам осветлит фото'), Tr('Hech narsa o‘zgarmaydi', 'Ничего не изменится')])),
    ], 3),
    g.order(const Tr('AI rasmni tanish bosqichlarini tartiblang:', 'Расставьте этапы распознавания картинки:'),
        ['Rasm piksellarga bo‘linadi', 'Piksellar raqamga aylanadi', 'AI naqshlarni qidiradi', 'AI javob beradi: “bu mushuk”']),
  ];
}

List<LessonStep> ai7(Gen g) => [
      const LessonStep.read(
        h: Tr('AI dan to‘g‘ri va xavfsiz foydalanish', 'Как пользоваться AI честно и безопасно'),
        p: Tr(
            'AI — kuchli yordamchi, lekin uchta qoida bor. 1) Shaxsiy ma’lumot bermang: parol, uy manzili, karta raqami, hujjatlar. '
                '2) Uy vazifasini AI ga to‘liq yozdirmang — tushuntirishni so‘rang, keyin o‘zingiz yeching. '
                '3) AI ham adolatsiz bo‘lishi mumkin: agar uni bir tomonlama misollarda o‘qitishsa, javoblari ham bir tomonlama bo‘ladi.',
            'AI — сильный помощник, но есть три правила. 1) Не давайте личные данные: пароль, домашний адрес, номер карты, документы. '
                '2) Не просите AI полностью сделать домашнее задание — попросите объяснить, а решите сами. '
                '3) AI тоже бывает несправедливым: если его учили на однобоких примерах, ответы тоже будут однобокими.'),
      ),
      ...g.from([
        Q(1, (g) => g.quiz(const Tr('Qaysi ma’lumotni AI ga yozish mumkin EMAS?', 'Что НЕЛЬЗЯ писать AI?'), const Tr('Parolingiz va uy manzilingiz', 'Ваш пароль и домашний адрес'),
            const [Tr('Matematika savoli', 'Вопрос по математике'), Tr('Kitob nomi', 'Название книги'), Tr('Sevimli rangingiz', 'Любимый цвет')])),
        Q(1, (g) => g.quiz(const Tr('Uy vazifasida AI dan qanday foydalanish to‘g‘ri?', 'Как правильно использовать AI для домашки?'),
            const Tr('Mavzuni tushuntirishni so‘rab, keyin o‘zim yechaman', 'Прошу объяснить тему, потом решаю сам'),
            const [Tr('Javobni ko‘chirib olaman', 'Копирую ответ'), Tr('Do‘stimga AI javobini yuboraman', 'Отправляю ответ AI другу'), Tr('Umuman o‘qimayman', 'Вообще не учусь')])),
        Q(2, (g) => g.quiz(const Tr('AI faqat erkak shifokorlar rasmida o‘qitildi. Nima bo‘lishi mumkin?', 'AI учили только на фото врачей-мужчин. Что может случиться?'),
            const Tr('Ayol shifokorni “shifokor” deb tanimasligi mumkin', 'Может не узнать в женщине врача'),
            const [Tr('Hech narsa', 'Ничего'), Tr('AI tezroq ishlaydi', 'AI заработает быстрее'), Tr('Rasmlar chiroyli bo‘ladi', 'Фото станут красивее')],
            e: const Tr('Bu “tarafkashlik” (bias): misollar bir xil bo‘lsa, AI adolatsiz xulosa qiladi.', 'Это «предвзятость» (bias): однообразные примеры — несправедливые выводы.'))),
        Q(3, (g) => g.quiz(const Tr('Do‘stingiz AI bilan sizning soxta rasmingizni yasadi. Nima qilasiz?', 'Друг сделал с помощью AI ваше фейковое фото. Что делать?'),
            const Tr('Ulashmayman va kattalarga aytaman', 'Не распространяю и говорю взрослым'),
            const [Tr('Hammaga yuboraman', 'Отправлю всем'), Tr('Javob qilib uning rasmini yasayman', 'В ответ сделаю его фото'), Tr('E’tibor bermayman', 'Не обращу внимания')])),
      ], 3),
      g.order(const Tr('AI bilan uy vazifasini to‘g‘ri bajarish tartibi:', 'Правильный порядок работы с домашкой и AI:'),
          ['Avval o‘zim urinib ko‘raman', 'Tushunmagan joyimni AI dan so‘rayman', 'Tushuntirishni o‘qib, o‘zim yechaman', 'Javobni darslikda tekshiraman']),
    ];

const _pos = ['zo‘r', 'yaxshi', 'ajoyib', 'yoqdi'];
const _neg = ['yomon', 'zerikarli', 'yoqmadi', 'qiyin'];

List<LessonStep> aiA4(Gen g) {
  final p = g.sample(_pos, 2), n = g.sample(_neg, 1);
  final review = '${p[0]} dars lekin biroz ${n[0]} edi baribir ${p[1]}';
  final fn = 'ijobiy = ${_pos.map((x) => '"$x"').toList()}\nsalbiy = ${_neg.map((x) => '"$x"').toList()}\n\n'
      'def kayfiyat(matn):\n    ball = 0\n    for soz in matn.lower().split():\n        if soz in ijobiy:\n            ball += 1\n        if soz in salbiy:\n            ball -= 1\n    return ball\n';
  return [
    const LessonStep.read(
      h: Tr('Loyiha: matn kayfiyatini aniqlash', 'Проект: определяем настроение текста'),
      p: Tr(
          'Do‘konlar va ilovalar minglab sharhlarni o‘qiy olmaydi — buni AI qiladi. Eng oddiy usul: ijobiy so‘zlar uchun +1, salbiy so‘zlar uchun −1 ball. '
              'Yig‘indi musbat bo‘lsa — sharh ijobiy, manfiy bo‘lsa — salbiy. Haqiqiy AI ham shunday boshlanadi, faqat so‘zlarning “og‘irligi”ni o‘zi o‘rganadi.',
          'Магазины и приложения не могут прочитать тысячи отзывов — это делает AI. Самый простой способ: +1 балл за позитивные слова, −1 за негативные. '
              'Сумма положительная — отзыв хороший, отрицательная — плохой. Настоящий AI начинается так же, только «вес» слов он учит сам.'),
      code: 'def kayfiyat(matn):\n    ball = 0\n    for soz in matn.lower().split():\n        if soz in ijobiy:\n            ball += 1\n        if soz in salbiy:\n            ball -= 1\n    return ball',
    ),
    ...g.from([
      Q(1, (g) => g.quiz(const Tr('.split() nima qiladi?', 'Что делает .split()?'), const Tr('Matnni so‘zlar ro‘yxatiga bo‘ladi', 'Делит текст на список слов'),
          const [Tr('Matnni o‘chiradi', 'Удаляет текст'), Tr('Harflarni sanaydi', 'Считает буквы'), Tr('Matnni teskari qiladi', 'Переворачивает текст')])),
      Q(2, (g) => g.quizCode(const Tr('Bu sharhning bali nechchi?', 'Какой балл у этого отзыва?'), '${2 - 1}', ['3', '-1', '0'],
          code: 'kayfiyat("$review")')),
      Q(3, (g) => g.quiz(const Tr('“yaxshi emas” sharhida bu dastur qayerda xato qiladi?', 'Где ошибётся программа на отзыве «yaxshi emas»?'),
          const Tr('“emas” ni hisobga olmay, ijobiy deb o‘ylaydi', 'Не учтёт «emas» и посчитает отзыв хорошим'),
          const [Tr('Xato qilmaydi', 'Не ошибётся'), Tr('Dastur to‘xtab qoladi', 'Программа зависнет'), Tr('Bal −2 bo‘ladi', 'Балл будет −2')],
          e: const Tr('Shuning uchun haqiqiy AI so‘zlarni alohida emas, birga — kontekstda o‘rganadi.', 'Поэтому настоящий AI учит слова не по отдельности, а вместе — в контексте.'))),
    ], 2),
    g.tryIt(
      mode: 'py',
      task: Tr('kayfiyat("$review") ball 0 dan katta bo‘lsa “ijobiy”, aks holda “salbiy” deb chiqaring.',
          'Если балл kayfiyat("$review") больше 0, выведите «ijobiy», иначе «salbiy».'),
      start: '$fn\n# shu yerga yozing\n',
      hint: lit('if kayfiyat("$review") > 0:\n    print("ijobiy")\nelse:\n    print("salbiy")'),
      check: (c, o) => o.trim() == 'ijobiy',
      solution: '$fn\nif kayfiyat("$review") > 0:\n    print("ijobiy")\nelse:\n    print("salbiy")\n',
    ),
  ];
}

List<LessonStep> aiM4(Gen g) {
  final w1 = g.pick(const [2, 3]), w2 = g.pick(const [1, 2]), b = -g.pick(const [4, 5]);
  final x1 = g.n(1, 2), x2 = g.n(0, 2);
  final s = w1 * x1 + w2 * x2 + b;
  final fn = 'def neyron(x1, x2):\n    s = $w1 * x1 + $w2 * x2 + ($b)\n    return 1 if s > 0 else 0\n';
  return [
    const LessonStep.read(
      h: Tr('Loyiha: eng kichik neyron (perseptron)', 'Проект: самый маленький нейрон (перцептрон)'),
      p: Tr(
          'Neyron tarmoqlar (ChatGPT ham) millionlab oddiy “neyronlardan” iborat. Bitta neyron: har bir kirishni o‘z og‘irligiga (weight) ko‘paytiradi, '
              'qo‘shadi, siljish (bias) qo‘shadi va natija 0 dan katta bo‘lsa 1, aks holda 0 beradi. O‘qitish — og‘irliklarni to‘g‘ri tanlash demak.',
          'Нейросети (и ChatGPT тоже) состоят из миллионов простых «нейронов». Один нейрон умножает каждый вход на свой вес (weight), '
              'складывает, добавляет смещение (bias) и выдаёт 1, если результат больше 0, иначе 0. Обучение — это подбор правильных весов.'),
      code: 'def neyron(x1, x2):\n    s = w1 * x1 + w2 * x2 + b\n    return 1 if s > 0 else 0',
    ),
    ...g.from([
      Q(1, (g) => g.quiz(const Tr('Og‘irlik (weight) nimani bildiradi?', 'Что означает вес (weight)?'), const Tr('Kirish qanchalik muhimligini', 'Насколько важен вход'),
          const [Tr('Kompyuter og‘irligini', 'Вес компьютера'), Tr('Fayl hajmini', 'Размер файла'), Tr('Neyron rangini', 'Цвет нейрона')])),
      Q(2, (g) => g.quizCode(_qOut, '${s > 0 ? 1 : 0}', ['${s > 0 ? 0 : 1}', '$s', '${w1 + w2}'],
          code: '${fn}print(neyron($x1, $x2))')),
      Q(3, (g) => g.quiz(const Tr('Neyron xato javob berdi. O‘qitishda nima o‘zgaradi?', 'Нейрон ответил неверно. Что меняется при обучении?'),
          const Tr('Og‘irliklar va bias biroz to‘g‘rilanadi', 'Веса и bias немного исправляются'),
          const [Tr('Kirishlar o‘chiriladi', 'Входы удаляются'), Tr('Hech narsa', 'Ничего'), Tr('Kod qayta yoziladi', 'Код переписывается')])),
    ], 2),
    g.tryIt(
      mode: 'py',
      task: const Tr('Neyronni (1,1), (0,0) va (2,2) uchun chaqirib, har birining natijasini alohida qatorda chiqaring.',
          'Вызовите нейрон для (1,1), (0,0) и (2,2) и выведите каждый результат на отдельной строке.'),
      start: '$fn\n# shu yerga yozing\n',
      hint: lit('print(neyron(1, 1))\nprint(neyron(0, 0))\nprint(neyron(2, 2))'),
      check: (c, o) {
        int f(int a, int c2) => (w1 * a + w2 * c2 + b) > 0 ? 1 : 0;
        return o.trim().split(RegExp(r'\s+')).join(' ') == '${f(1, 1)} ${f(0, 0)} ${f(2, 2)}';
      },
      solution: '${fn}print(neyron(1, 1))\nprint(neyron(0, 0))\nprint(neyron(2, 2))\n',
    ),
  ];
}

const _qOut = Tr('Bu kod nima chiqaradi?', 'Что выведет этот код?');
