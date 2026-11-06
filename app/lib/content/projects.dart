// Har bir kurs oxiridagi portfolio loyihasi / портфолио-проект в конце каждого курса.
import 'model.dart';

class Project {
  final String course;
  final String mode; // html — sahifa sifatida ochiladi / открывается как страница; py — kod sifatida / как код
  final Tr title, brief;
  final List<(Tr, bool Function(String code))> checks;
  final String starter;
  const Project(
      {required this.course,
      required this.mode,
      required this.title,
      required this.brief,
      required this.checks,
      required this.starter});

  List<bool> results(String code) => [for (final c in checks) c.$2(code)];
  bool passes(String code) => results(code).every((x) => x);
}

bool _has(String p, String t) => RegExp(p, caseSensitive: false, dotAll: true).hasMatch(t);
int _count(String p, String t) => RegExp(p, caseSensitive: false).allMatches(t).length;

final Map<String, Project> kProjects = {
  'html': Project(
    course: 'html',
    mode: 'html',
    title: const Tr('Mening shaxsiy sahifam', 'Моя личная страница'),
    brief: const Tr(
        'O‘zingiz haqingizda haqiqiy veb-sahifa yarating. Uni havola orqali do‘stlaringiz va ota-onangizga ko‘rsatishingiz mumkin.',
        'Создайте настоящую веб-страницу о себе. Её можно показать друзьям и родителям по ссылке.'),
    checks: [
      (const Tr('<h1> ichida ismingiz', 'Ваше имя внутри <h1>'), (c) => _has(r'<h1>\s*(?!Ismingiz)[^<\s][^<]*</h1>', c)),
      (const Tr('<p> — o‘zingiz haqingizda', '<p> — о себе'), (c) => _has(r'<p>\s*(?!O‘zingiz)[^<\s][^<]{10,}</p>', c)),
      (const Tr('<ul> ichida kamida 3 ta <li>', 'Минимум 3 <li> внутри <ul>'), (c) => _has(r'<ul>', c) && _count(r'<li>', c) >= 3),
      (const Tr('Havola <a> yoki rasm <img>', 'Ссылка <a> или картинка <img>'), (c) => _has(r'<a\s+href=|<img\s+src=', c)),
    ],
    starter: '<h1>Ismingiz</h1>\n<p>O‘zingiz haqingizda yozing</p>\n\n<h2>Qiziqishlarim</h2>\n<ul>\n  <li>...</li>\n</ul>\n',
  ),
  'css': Project(
    course: 'css',
    mode: 'html',
    title: const Tr('Chiroyli portfolio sahifasi', 'Красивая страница-портфолио'),
    brief: const Tr('Sahifangizni CSS bilan bezang: fon, ranglar va chiroyli karta.',
        'Оформите страницу с помощью CSS: фон, цвета и красивая карточка.'),
    checks: [
      (const Tr('body uchun fon (background)', 'Фон для body (background)'), (c) => _has(r'body\s*\{[^}]*background', c)),
      (const Tr('h1 uchun rang (color)', 'Цвет для h1 (color)'), (c) => _has(r'h1\s*\{[^}]*color\s*:', c)),
      (const Tr('.card klassi: padding va border-radius', 'Класс .card: padding и border-radius'),
          (c) => _has(r'\.card\s*\{[^}]*padding[^}]*\}', c) && _has(r'\.card\s*\{[^}]*border-radius', c)),
      (const Tr('class="card" ishlatilgan element', 'Элемент с class="card"'), (c) => _has(r'class="card"', c)),
    ],
    starter: '<style>\n  body {\n    \n  }\n  h1 {\n    \n  }\n  .card {\n    \n  }\n</style>\n\n'
        '<div class="card">\n  <h1>Ismingiz</h1>\n  <p>Men dasturlashni o‘rganyapman!</p>\n</div>\n',
  ),
  'js': Project(
    course: 'js',
    mode: 'html',
    title: const Tr('Viktorina o‘yini', 'Игра-викторина'),
    brief: const Tr('Tugma bosilganda savol beradigan va ochko sanaydigan kichik o‘yin yarating.',
        'Создайте маленькую игру: по кнопке задаёт вопрос и считает очки.'),
    checks: [
      (const Tr('<button> tugmasi', 'Кнопка <button>'), (c) => _has(r'<button', c)),
      (const Tr('<script> ichida function', 'function внутри <script>'), (c) => _has(r'<script>.*function', c)),
      (const Tr('Javobni if bilan tekshirish', 'Проверка ответа через if'), (c) => _has(r'\bif\s*\(', c)),
      (const Tr('Ochko sanagich (score)', 'Счётчик очков (score)'), (c) => _has(r'score\s*(\+\+|\+=|=\s*score\s*\+)', c)),
    ],
    starter: '<h1>Viktorina</h1>\n<button onclick="play()">Boshlash</button>\n<p id="result"></p>\n\n<script>\n'
        '  let score = 0;\n  function play() {\n    let a = prompt("2 + 2 = ?");\n    // javobni tekshiring\n\n'
        '    document.getElementById("result").textContent = "Ochko: " + score;\n  }\n</script>\n',
  ),
  'py': Project(
    course: 'py',
    mode: 'py',
    title: const Tr('Python viktorinasi', 'Викторина на Python'),
    brief: const Tr('Savollar ro‘yxati, sikl va ochko bilan haqiqiy viktorina dasturini yozing.',
        'Напишите настоящую программу-викторину со списком вопросов, циклом и очками.'),
    checks: [
      (const Tr('Kamida 3 ta savolli ro‘yxat', 'Список минимум из 3 вопросов'), (c) => _has(r'=\s*\[.*,.*,.*\]', c)),
      (const Tr('for sikli', 'Цикл for'), (c) => _has(r'for\s+\w+\s+in\s', c)),
      (const Tr('input() bilan javob olish', 'Получение ответа через input()'), (c) => _has(r'input\(', c)),
      (const Tr('Ochkoni oshirish (+= 1)', 'Увеличение очков (+= 1)'), (c) => _has(r'\+=\s*1|=\s*\w+\s*\+\s*1', c)),
      (const Tr('Yakuniy natijani chiqarish', 'Вывод итогового результата'), (c) => _count(r'print\(', c) >= 1),
    ],
    starter: 'savollar = [\n    ("2 + 2 = ?", "4"),\n]\nochko = 0\n\n# sikl bilan har bir savolni bering\n\n'
        'print("Natija:", ochko)\n',
  ),
  'ai': Project(
    course: 'ai',
    mode: 'py',
    title: const Tr('Mening chatbotim', 'Мой чат-бот'),
    brief: const Tr('Savollarga javob beradigan va “xayr” deyilganda to‘xtaydigan o‘z chatbotingizni yarating.',
        'Создайте своего чат-бота, который отвечает на вопросы и останавливается на «xayr».'),
    checks: [
      (const Tr('Javoblar lug‘ati {…}', 'Словарь ответов {…}'), (c) => _has(r'=\s*\{[^}]*:[^}]*,[^}]*:', c)),
      (const Tr('while sikli', 'Цикл while'), (c) => _has(r'while\s', c)),
      (const Tr('input() va .lower()', 'input() и .lower()'), (c) => _has(r'input\(', c) && _has(r'\.lower\(\)', c)),
      (const Tr('“xayr” da to‘xtash (break)', 'Остановка на «xayr» (break)'), (c) => _has(r'xayr', c) && _has(r'\bbreak\b', c)),
    ],
    starter: 'javoblar = {\n    "salom": "Salom! Men Idrok botiman.",\n}\n\nwhile True:\n    gap = input("Siz: ")\n'
        '    # "xayr" bo‘lsa to‘xtating, aks holda javob bering\n',
  ),
};
