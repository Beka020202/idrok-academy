// O‘yin qoidalari — server/progress.py bilan bir xil bo‘lishi shart.
// Правила игры — должны совпадать с server/progress.py.
//
// Yagona valyuta — XP. xp — balans (sarflanadi), xpTotal — jami ishlab topilgan (daraja shundan).
// Единственная валюта — XP. xp — баланс (тратится), xpTotal — всего заработано (от него уровень).

import 'lessons.dart';

const int kGoal = 30;
const int kReviewXp = 5;
const int kPerfectXp = 5;
const int kChestXp = 50;
const int kPlacementXp = 20;
const int kHelperCost = 5;
const int kKeepDays = 60;
const int kMaxRetry = 2;

class Quest {
  final String id;
  final int target, reward;
  final Tr title;
  const Quest(this.id, this.target, this.reward, this.title);
}

const List<Quest> kQuests = [
  Quest('xp', 30, 10, Tr('30 XP to‘plang', 'Наберите 30 XP')),
  Quest('lessons', 2, 10, Tr('2 ta dars o‘ting', 'Пройдите 2 урока')),
  Quest('combo', 3, 15, Tr('Ketma-ket 3 ta to‘g‘ri javob', '3 верных ответа подряд')),
];

/// Liga nomlari / названия лиг.
const Map<String, Tr> kLeagueNames = {
  'beginner': Tr('Boshlang‘ich liga', 'Начальная лига'),
  'advanced': Tr('Ilg‘or liga', 'Продвинутая лига'),
  'master': Tr('Usta liga', 'Лига мастеров'),
};

/// Liga bo‘yicha asosiy qiyinlik / базовая сложность по лиге.
int leagueBase(String league) => switch (league) { 'master' => 3, 'advanced' => 2, _ => 1 };

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String todayStr() => isoDate(DateTime.now());

DateTime parseIso(String s) {
  final p = s.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

String dayBefore(String day) {
  final d = parseIso(day);
  return isoDate(DateTime(d.year, d.month, d.day - 1));
}

int levelOf(int xpTotal) => xpTotal ~/ 100 + 1;

int _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
double _dbl(Object? v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;
String _str(Object? v) => v is String ? v : '';
List<String> _strList(Object? v) => v is List ? [for (final x in v) '$x'] : <String>[];

class QuestState {
  String date;
  int xp, lessons, combo;
  List<String> claimed;
  QuestState({this.date = '', this.xp = 0, this.lessons = 0, this.combo = 0, List<String>? claimed})
      : claimed = claimed ?? [];

  int valueOf(String id) => switch (id) { 'xp' => xp, 'lessons' => lessons, 'combo' => combo, _ => 0 };

  Map<String, Object?> toJson() =>
      {'date': date, 'xp': xp, 'lessons': lessons, 'combo': combo, 'claimed': List<String>.of(claimed)};

  factory QuestState.fromJson(Object? j) {
    final m = j is Map ? j : const {};
    return QuestState(
      date: _str(m['date']),
      xp: _int(m['xp']),
      lessons: _int(m['lessons']),
      combo: _int(m['combo']),
      claimed: _strList(m['claimed']),
    );
  }
}

/// Natijalar statistikasi (avto-ko‘tarilish uchun) / статистика (для авто-повышения).
class Stats {
  int attempts, correct, total;
  double timeShare;
  Stats({this.attempts = 0, this.correct = 0, this.total = 0, this.timeShare = 0});
  double get accuracy => total == 0 ? 0 : correct / total;
  Map<String, Object?> toJson() => {'attempts': attempts, 'correct': correct, 'total': total, 'time_share': timeShare};
  factory Stats.fromJson(Object? j) {
    final m = j is Map ? j : const {};
    return Stats(
        attempts: _int(m['attempts']), correct: _int(m['correct']), total: _int(m['total']), timeShare: _dbl(m['time_share']));
  }
}

/// O‘quvchi holati / состояние ученика (JSON kalitlari server bilan bir xil).
class GameState {
  int xp, xpTotal, streak, todayXp, perfect;
  Map<String, bool> done;
  String lastDay, todayDate, league;
  List<String> days, chests;
  Map<String, int> retries;
  QuestState quests;
  Stats stats;

  GameState({
    this.xp = 0,
    this.xpTotal = 0,
    Map<String, bool>? done,
    this.streak = 0,
    this.lastDay = '',
    this.todayXp = 0,
    this.todayDate = '',
    List<String>? days,
    List<String>? chests,
    this.perfect = 0,
    this.league = '',
    Map<String, int>? retries,
    QuestState? quests,
    Stats? stats,
  })  : done = done ?? {},
        days = days ?? [],
        chests = chests ?? [],
        retries = retries ?? {},
        quests = quests ?? QuestState(),
        stats = stats ?? Stats();

  factory GameState.fromJson(Object? j) {
    final m = j is Map ? j : const {};
    final doneRaw = m['done'];
    final rRaw = m['retries'];
    final lg = _str(m['league']);
    return GameState(
      xp: _int(m['xp']),
      xpTotal: m.containsKey('xp_total') ? _int(m['xp_total']) : _int(m['xp']),
      done: {
        if (doneRaw is Map)
          for (final e in doneRaw.entries)
            if (e.value == true) '${e.key}': true,
      },
      streak: _int(m['streak']),
      lastDay: _str(m['last_day']),
      todayXp: _int(m['today_xp']),
      todayDate: _str(m['today_date']),
      days: _strList(m['days']),
      chests: _strList(m['chests']),
      perfect: _int(m['perfect']),
      league: const ['beginner', 'advanced', 'master'].contains(lg) ? lg : '',
      retries: {
        if (rRaw is Map)
          for (final e in rRaw.entries) '${e.key}': _int(e.value),
      },
      quests: QuestState.fromJson(m['quests']),
      stats: Stats.fromJson(m['stats']),
    );
  }

  Map<String, Object?> toJson() => {
        'xp': xp,
        'xp_total': xpTotal,
        'done': Map<String, bool>.of(done),
        'streak': streak,
        'last_day': lastDay,
        'today_xp': todayXp,
        'today_date': todayDate,
        'days': List<String>.of(days),
        'chests': List<String>.of(chests),
        'perfect': perfect,
        'league': league,
        'retries': Map<String, int>.of(retries),
        'quests': quests.toJson(),
        'stats': stats.toJson(),
      };

  GameState copy() => GameState.fromJson(toJson());

  bool isDone(String lessonId) => done[lessonId] == true;

  /// Bu dars uchun qiyinlik: liga + bekor qilingan urinishlar.
  /// Сложность урока: лига + отменённые попытки.
  int difficultyFor(String lessonId) => (leagueBase(league) + (retries[lessonId] ?? 0)).clamp(1, 3).toInt();
}

/// Yangi kunda kunlik ko‘rsatkichlarni yangilaydi / обновляет дневные показатели в новый день.
GameState normalize(Object? json, {String? today}) {
  final t = today ?? todayStr();
  final s = json is GameState ? json.copy() : GameState.fromJson(json);
  if (s.xp < 0) s.xp = 0;
  if (s.todayDate != t) {
    s.todayXp = 0;
    s.todayDate = t;
  }
  if (s.quests.date != t) s.quests = QuestState(date: t);
  if (s.lastDay.isNotEmpty && s.lastDay != t && s.lastDay != dayBefore(t)) s.streak = 0;
  return s;
}

int _earn(GameState s, int amount, {bool quest = true}) {
  final a = amount < 0 ? 0 : amount;
  s.xp += a;
  s.xpTotal += a;
  s.todayXp += a;
  if (quest) s.quests.xp += a;
  return a;
}

class LessonResult {
  final int xp, level;
  final bool first, perfect, levelUp;
  final String promoted; // '' yoki yangi liga / или новая лига
  const LessonResult({
    required this.xp,
    required this.first,
    required this.perfect,
    required this.levelUp,
    required this.level,
    this.promoted = '',
  });

  factory LessonResult.fromJson(Object? j) {
    final m = j is Map ? j : const {};
    return LessonResult(
      xp: _int(m['xp']),
      first: m['first'] == true,
      perfect: m['perfect'] == true,
      levelUp: m['level_up'] == true,
      level: _int(m['level']),
      promoted: _str(m['promoted']),
    );
  }
}

(GameState, LessonResult) completeLesson(GameState state, String lessonId, int lessonXp,
    {bool perfect = false, int bestCombo = 0, int correct = 0, int total = 0, double timeShare = 1, String? today}) {
  final t = today ?? todayStr();
  final s = normalize(state, today: t);
  final levelBefore = levelOf(s.xpTotal);
  final first = !s.isDone(lessonId);
  var xp = first ? lessonXp : kReviewXp;
  if (perfect) {
    xp += kPerfectXp;
    s.perfect += 1;
  }
  _earn(s, xp);
  s.done[lessonId] = true;
  s.retries.remove(lessonId);
  s.quests.lessons += 1;
  if (bestCombo > s.quests.combo) s.quests.combo = bestCombo;
  s.stats
    ..attempts += 1
    ..correct += correct
    ..total += total
    ..timeShare += timeShare.clamp(0.0, 1.0).toDouble();
  if (s.lastDay != t) {
    s.streak = s.lastDay == dayBefore(t) ? s.streak + 1 : 1;
    s.lastDay = t;
  }
  if (!s.days.contains(t)) {
    s.days.add(t);
    if (s.days.length > kKeepDays) s.days = s.days.sublist(s.days.length - kKeepDays);
  }
  final level = levelOf(s.xpTotal);
  return (s, LessonResult(xp: xp, first: first, perfect: perfect, levelUp: level > levelBefore, level: level));
}

int questProgress(GameState s, Quest q) {
  final v = s.quests.valueOf(q.id);
  return v < q.target ? v : q.target;
}

(GameState, int) claimQuest(GameState state, String questId) {
  final s = normalize(state);
  Quest? quest;
  for (final q in kQuests) {
    if (q.id == questId) quest = q;
  }
  if (quest == null || s.quests.claimed.contains(questId) || questProgress(s, quest) < quest.target) return (s, 0);
  s.quests.claimed.add(questId);
  return (s, _earn(s, quest.reward, quest: false));
}

(GameState, int) openChest(GameState state, String courseId, List<String> lessonIds) {
  final s = normalize(state);
  if (lessonIds.isEmpty || s.chests.contains(courseId) || !lessonIds.every(s.isDone)) return (s, 0);
  s.chests.add(courseId);
  return (s, _earn(s, kChestXp, quest: false));
}

(GameState, bool) spendXp(GameState state, int amount) {
  final s = normalize(state);
  if (amount <= 0 || s.xp < amount) return (s, false);
  s.xp -= amount;
  return (s, true);
}

(GameState, int) setLeague(GameState state, String league) {
  final s = normalize(state);
  if (s.league.isNotEmpty || !kLeagueNames.containsKey(league)) return (s, 0);
  s.league = league;
  return (s, _earn(s, kPlacementXp, quest: false));
}

GameState cancelTest(GameState state, String lessonId) {
  final s = normalize(state);
  final r = (s.retries[lessonId] ?? 0) + 1;
  s.retries[lessonId] = r > kMaxRetry ? kMaxRetry : r;
  return s;
}

/// Oxirgi 7 kun / последние 7 дней: [(sana, faolmi)].
List<(String, bool)> lastWeek(GameState s) {
  final now = DateTime.now();
  final active = s.days.toSet();
  return [
    for (var b = 6; b >= 0; b--)
      (() {
        final d = isoDate(DateTime(now.year, now.month, now.day - b));
        return (d, active.contains(d));
      })(),
  ];
}
