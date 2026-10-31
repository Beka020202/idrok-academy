// O‘yin qoidalari — server/progress.py bilan bir xil bo‘lishi shart.
// Правила игры — должны совпадать с server/progress.py.
//
// Onlayn rejimda natijani server hisoblaydi; bu fayl oflayn rejim uchun.
// В онлайн-режиме результат считает сервер; этот файл — для офлайн-режима.

import 'lessons.dart';

const int kGoal = 30;
const int kReviewXp = 5;
const int kLessonGems = 10;
const int kPerfectGems = 5;
const int kPerfectXp = 5;
const int kChestGems = 50;
const int kKeepDays = 60;

class Quest {
  final String id, icon;
  final int target, gems;
  final Tr title;
  const Quest(this.id, this.target, this.gems, this.icon, this.title);
}

const List<Quest> kQuests = [
  Quest('xp', 30, 15, '⚡', Tr('30 XP to‘plang', 'Наберите 30 XP')),
  Quest('lessons', 2, 15, '📙', Tr('2 ta dars o‘ting', 'Пройдите 2 урока')),
  Quest('combo', 3, 20, '🔥', Tr('Ketma-ket 3 ta to‘g‘ri javob', '3 верных ответа подряд')),
];

/// Avatar -> narx / аватар -> цена (tartib muhim / порядок важен).
const Map<String, int> kAvatars = {
  '🤖': 0, '🦊': 40, '🐼': 40, '🐯': 60, '🦉': 60, '🐙': 80, '🦄': 100, '🐲': 150, '🚀': 200, '👑': 300,
};

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

int levelOf(int xp) => xp ~/ 100 + 1;

int _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
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

/// O‘quvchi holati / состояние ученика (JSON kalitlari server bilan bir xil).
class GameState {
  int xp, streak, todayXp, gems, perfect;
  Map<String, bool> done;
  String lastDay, todayDate, avatar;
  List<String> days, owned, chests;
  QuestState quests;

  GameState({
    this.xp = 0,
    Map<String, bool>? done,
    this.streak = 0,
    this.lastDay = '',
    this.todayXp = 0,
    this.todayDate = '',
    List<String>? days,
    this.gems = 0,
    this.avatar = '🤖',
    List<String>? owned,
    List<String>? chests,
    this.perfect = 0,
    QuestState? quests,
  })  : done = done ?? {},
        days = days ?? [],
        owned = owned ?? ['🤖'],
        chests = chests ?? [],
        quests = quests ?? QuestState();

  factory GameState.fromJson(Object? j) {
    final m = j is Map ? j : const {};
    final doneRaw = m['done'];
    return GameState(
      xp: _int(m['xp']),
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
      gems: _int(m['gems']),
      avatar: m['avatar'] is String ? m['avatar'] as String : '🤖',
      owned: m['owned'] is List ? _strList(m['owned']) : ['🤖'],
      chests: _strList(m['chests']),
      perfect: _int(m['perfect']),
      quests: QuestState.fromJson(m['quests']),
    );
  }

  Map<String, Object?> toJson() => {
        'xp': xp,
        'done': Map<String, bool>.of(done),
        'streak': streak,
        'last_day': lastDay,
        'today_xp': todayXp,
        'today_date': todayDate,
        'days': List<String>.of(days),
        'gems': gems,
        'avatar': avatar,
        'owned': List<String>.of(owned),
        'chests': List<String>.of(chests),
        'perfect': perfect,
        'quests': quests.toJson(),
      };

  GameState copy() => GameState.fromJson(toJson());

  bool isDone(String lessonId) => done[lessonId] == true;
}

/// Eski holatni to‘ldiradi, yangi kunda kunlik ko‘rsatkichlarni yangilaydi.
GameState normalize(Object? json, {String? today}) {
  final t = today ?? todayStr();
  final s = json is GameState ? json.copy() : GameState.fromJson(json);
  if (s.todayDate != t) {
    s.todayXp = 0;
    s.todayDate = t;
  }
  if (s.quests.date != t) {
    s.quests = QuestState(date: t);
  }
  if (s.lastDay.isNotEmpty && s.lastDay != t && s.lastDay != dayBefore(t)) {
    s.streak = 0;
  }
  if (!s.owned.contains('🤖')) s.owned.insert(0, '🤖');
  if (!s.owned.contains(s.avatar)) s.avatar = '🤖';
  return s;
}

class LessonResult {
  final int xp, gems, level;
  final bool first, perfect, levelUp;
  const LessonResult({
    required this.xp,
    required this.gems,
    required this.first,
    required this.perfect,
    required this.levelUp,
    required this.level,
  });

  factory LessonResult.fromJson(Object? j) {
    final m = j is Map ? j : const {};
    return LessonResult(
      xp: _int(m['xp']),
      gems: _int(m['gems']),
      first: m['first'] == true,
      perfect: m['perfect'] == true,
      levelUp: m['level_up'] == true,
      level: _int(m['level']),
    );
  }
}

/// Dars tugadi / урок завершён.
(GameState, LessonResult) completeLesson(GameState state, String lessonId, int lessonXp,
    {bool perfect = false, int bestCombo = 0, String? today}) {
  final t = today ?? todayStr();
  final s = normalize(state, today: t);
  final levelBefore = levelOf(s.xp);
  final first = !s.isDone(lessonId);
  var xp = first ? lessonXp : kReviewXp;
  var gems = first ? kLessonGems : 0;
  if (perfect) {
    xp += kPerfectXp;
    gems += kPerfectGems;
    s.perfect += 1;
  }
  s.xp += xp;
  s.gems += gems;
  s.todayXp += xp;
  s.done[lessonId] = true;
  s.quests.xp += xp;
  s.quests.lessons += 1;
  if (bestCombo > s.quests.combo) s.quests.combo = bestCombo;
  if (s.lastDay != t) {
    s.streak = s.lastDay == dayBefore(t) ? s.streak + 1 : 1;
    s.lastDay = t;
  }
  if (!s.days.contains(t)) {
    s.days.add(t);
    if (s.days.length > kKeepDays) s.days = s.days.sublist(s.days.length - kKeepDays);
  }
  final level = levelOf(s.xp);
  return (
    s,
    LessonResult(xp: xp, gems: gems, first: first, perfect: perfect, levelUp: level > levelBefore, level: level)
  );
}

int questProgress(GameState s, Quest q) {
  final v = s.quests.valueOf(q.id);
  return v < q.target ? v : q.target;
}

/// Vazifa mukofoti / награда за задание. Qaytaradi (holat, olmos yoki 0).
(GameState, int) claimQuest(GameState state, String questId) {
  final s = normalize(state);
  Quest? quest;
  for (final q in kQuests) {
    if (q.id == questId) quest = q;
  }
  if (quest == null || s.quests.claimed.contains(questId) || questProgress(s, quest) < quest.target) {
    return (s, 0);
  }
  s.quests.claimed.add(questId);
  s.gems += quest.gems;
  return (s, quest.gems);
}

/// Kurs sandig‘i / сундук курса.
(GameState, int) openChest(GameState state, String courseId, List<String> lessonIds) {
  final s = normalize(state);
  if (s.chests.contains(courseId) || !lessonIds.every(s.isDone)) return (s, 0);
  s.chests.add(courseId);
  s.gems += kChestGems;
  return (s, kChestGems);
}

/// Avatar sotib olish yoki tanlash / покупка или выбор аватара.
(GameState, bool) buyAvatar(GameState state, String avatar) {
  final s = normalize(state);
  final price = kAvatars[avatar];
  if (price == null) return (s, false);
  if (!s.owned.contains(avatar)) {
    if (s.gems < price) return (s, false);
    s.gems -= price;
    s.owned.add(avatar);
  }
  s.avatar = avatar;
  return (s, true);
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
