// Kurslar katalogi / каталог курсов.
// MUHIM: id va xp server/content/lessons.json bilan bir xil bo‘lishi shart (test tekshiradi).
// ВАЖНО: id и xp должны совпадать с server/content/lessons.json (проверяется тестом).
import 'ai.dart';
import 'css.dart';
import 'html.dart';
import 'js.dart';
import 'model.dart';
import 'python.dart';
import 'scenes.dart';

/// XP harakatga qarab: bir xil uzunlikdagi darslar har bir ligada bir xil XP beradi.
/// XP за усилия: уроки одинаковой длины дают одинаковый XP в любой лиге.
const int kLessonXp = 20;
const int kProjectXp = 30;

Lesson _l(String id, String course, Tr title, StepBuilder b, {int xp = kLessonXp, Set<String>? leagues}) =>
    Lesson(id: id, courseId: course, xp: xp, title: title, builder: _withScene(id, b), leagues: leagues);

/// Nazariyadan keyin animatsiya qadamini qo‘shadi / добавляет шаг-анимацию после теории.
StepBuilder _withScene(String id, StepBuilder b) {
  final sc = kScenes[id];
  if (sc == null) return b;
  return (g) {
    final steps = [...b(g)];
    final at = steps.indexWhere((x) => x.type == StepType.read) + 1;
    steps.insert(at, LessonStep.read(h: sc.$1, p: sc.$2, anim: sc.$3(g)));
    return steps;
  };
}

final List<Course> kCourses = [
  Course(id: 'html', tag: '</>', color: '#0A6CFF', name: const Tr('HTML', 'HTML'),
      sub: const Tr('Veb-sahifa tuzilishi', 'Структура веб-страницы'), lessons: [
    _l('html1', 'html', const Tr('HTML nima?', 'Что такое HTML?'), html1),
    _l('html2', 'html', const Tr('Sarlavha va paragraf', 'Заголовки и абзацы'), html2),
    _l('html3', 'html', const Tr('Havola va rasm', 'Ссылки и картинки'), html3),
    _l('html4', 'html', const Tr('Ro‘yxatlar', 'Списки'), html4),
    _l('html5', 'html', const Tr('Sahifa tuzilishi', 'Структура страницы'), html5),
    _l('html6', 'html', const Tr('Formalar', 'Формы'), html6),
  ]),
  Course(id: 'css', tag: '{ }', color: '#0A1226', name: const Tr('CSS', 'CSS'),
      sub: const Tr('Sahifani bezash', 'Оформление страницы'), lessons: [
    _l('css1', 'css', const Tr('Birinchi qoida', 'Первое правило'), css1),
    _l('css2', 'css', const Tr('Matn', 'Текст'), css2),
    _l('css3', 'css', const Tr('Ranglar va fon', 'Цвета и фон'), css3),
    _l('css4', 'css', const Tr('Quti modeli', 'Блочная модель'), css4),
    _l('css5', 'css', const Tr('Klass va id', 'Класс и id'), css5),
    _l('css6', 'css', const Tr('Flexbox', 'Flexbox'), css6),
  ]),
  Course(id: 'js', tag: 'JS', color: '#1FB6F5', name: const Tr('JavaScript', 'JavaScript'),
      sub: const Tr('Sahifaga jon berish', 'Оживляем страницу'), lessons: [
    _l('js1', 'js', const Tr('console.log', 'console.log'), js1),
    _l('js2', 'js', const Tr('O‘zgaruvchilar', 'Переменные'), js2),
    _l('js3', 'js', const Tr('Hisob-kitob', 'Вычисления'), js3),
    _l('js4', 'js', const Tr('Shartlar', 'Условия'), js4),
    _l('js5', 'js', const Tr('Sikllar', 'Циклы'), js5),
    _l('js6', 'js', const Tr('Funksiyalar', 'Функции'), js6),
  ]),
  Course(id: 'py', tag: 'Py', color: '#5B6CFF', name: const Tr('Python', 'Python'),
      sub: const Tr('Olimpiada tili', 'Язык олимпиад'), lessons: [
    _l('py1', 'py', const Tr('print()', 'print()'), py1),
    _l('py2', 'py', const Tr('O‘zgaruvchi va input', 'Переменные и input'), py2),
    _l('py3', 'py', const Tr('Sonlar', 'Числа'), py3),
    _l('py4', 'py', const Tr('if / elif / else', 'if / elif / else'), py4),
    _l('py5', 'py', const Tr('for va range', 'for и range'), py5),
    _l('py6', 'py', const Tr('Ro‘yxatlar', 'Списки'), py6),
  ]),
  Course(id: 'ai', tag: 'AI', color: '#2D3FE0', name: const Tr('Sun’iy intellekt', 'Искусственный интеллект'),
      sub: const Tr('AI ni tushunish va yaratish', 'Понять и создать AI'), lessons: [
    _l('ai1', 'ai', const Tr('AI nima?', 'Что такое AI?'), ai1, leagues: kBeginner),
    _l('ai2', 'ai', const Tr('AI qanday o‘rganadi', 'Как учится AI'), ai2, leagues: kBeginner),
    _l('ai3', 'ai', const Tr('Aqlli so‘rov', 'Умный запрос'), ai3, leagues: kBeginner),
    _l('ai4', 'ai', const Tr('AI xatolari', 'Ошибки AI'), ai4, leagues: kBeginner),
    _l('ai5', 'ai', const Tr('Soxta va xavfsizlik', 'Фейки и безопасность'), ai5, leagues: kBeginner),
    _l('ai6', 'ai', const Tr('AI qanday ko‘radi', 'Как AI видит'), ai6, leagues: kBeginner),
    _l('ai7', 'ai', const Tr('Halol va xavfsiz AI', 'Честный и безопасный AI'), ai7, leagues: kBeginner),
    _l('aiA1', 'ai', const Tr('Chatbot', 'Чат-бот'), aiA1, xp: kProjectXp, leagues: kAdvanced),
    _l('aiA2', 'ai', const Tr('Raqamni tanish', 'Распознавание цифр'), aiA2, xp: kProjectXp, leagues: kAdvanced),
    _l('aiA3', 'ai', const Tr('Savol generatori', 'Генератор вопросов'), aiA3, xp: kProjectXp, leagues: kAdvanced),
    _l('aiA4', 'ai', const Tr('Matn kayfiyati', 'Настроение текста'), aiA4, xp: kProjectXp, leagues: kAdvanced),
    _l('aiM1', 'ai', const Tr('Niyatli chatbot', 'Чат-бот с намерениями'), aiM1, xp: kProjectXp, leagues: kMaster),
    _l('aiM2', 'ai', const Tr('k-NN tanish', 'Распознавание k-NN'), aiM2, xp: kProjectXp, leagues: kMaster),
    _l('aiM3', 'ai', const Tr('Moslashuvchan test', 'Адаптивный тест'), aiM3, xp: kProjectXp, leagues: kMaster),
    _l('aiM4', 'ai', const Tr('Sun’iy neyron', 'Искусственный нейрон'), aiM4, xp: kProjectXp, leagues: kMaster),
  ]),
];

final Map<String, (Lesson, Course)> kAllLessons = {
  for (final c in kCourses)
    for (final l in c.lessons) l.id: (l, c),
};

const String kPlaygroundStart = '# Kvadratlar jadvali\nn = int(input("Nechta son? "))\nfor i in range(1, n + 1):\n    print(i, "→", i * i)\n';
