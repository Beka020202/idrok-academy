// O‘yin qoidalari, savol generatori va kontent testlari.
// Тесты правил игры, генератора вопросов и контента.
// Ishga tushirish / запуск:  flutter test

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kodla/lessons.dart';
import 'package:kodla/progress.dart';
import 'package:kodla/screens/helper.dart' show codeIssues;
import 'package:kodla/screens/lesson.dart' show timeLimitFor;

void main() {
  group('progress', () {
    test('first lesson gives XP and starts streak', () {
      final (s, r) = completeLesson(normalize(null, today: '2026-10-30'), 'html1', 20,
          perfect: true, bestCombo: 3, correct: 5, total: 5, timeShare: 0.4, today: '2026-10-30');
      expect(r.xp, 20 + kPerfectXp);
      expect(r.first, isTrue);
      expect(s.xp, 25);
      expect(s.xpTotal, 25);
      expect(s.streak, 1);
      expect(s.quests.combo, 3);
      expect(s.isDone('html1'), isTrue);
      expect(s.stats.attempts, 1);
      expect(s.stats.accuracy, 1.0);
    });

    test('review gives 5 XP; streak grows next day', () {
      final (s, _) = completeLesson(normalize(null, today: '2026-10-30'), 'html1', 20, today: '2026-10-30');
      final (s2, r) = completeLesson(s, 'html1', 20, today: '2026-10-31');
      expect(r.xp, kReviewXp);
      expect(r.first, isFalse);
      expect(s2.streak, 2);
    });

    test('streak resets after a missed day', () {
      final (s, _) = completeLesson(normalize(null, today: '2026-10-01'), 'html1', 20, today: '2026-10-01');
      expect(normalize(s.toJson(), today: '2026-10-05').streak, 0);
    });

    test('quests can be claimed once and pay XP', () {
      final s = normalize(null);
      s.quests.combo = 3;
      final (s1, x1) = claimQuest(s, 'combo');
      final (_, x2) = claimQuest(s1, 'combo');
      expect(x1, 15);
      expect(x2, 0);
      expect(s1.xp, 15);
    });

    test('spending XP lowers balance but never total earned', () {
      final s = normalize(null);
      s.xp = 30;
      s.xpTotal = 30;
      final (s1, ok) = spendXp(s, kHelperCost);
      expect(ok, isTrue);
      expect(s1.xp, 30 - kHelperCost);
      expect(s1.xpTotal, 30);
      final (_, ok2) = spendXp(normalize(null), kHelperCost);
      expect(ok2, isFalse);
    });

    test('league is set once by the warm-up', () {
      final (s1, x) = setLeague(normalize(null), 'advanced');
      expect(s1.league, 'advanced');
      expect(x, kPlacementXp);
      final (s2, x2) = setLeague(s1, 'master');
      expect(s2.league, 'advanced');
      expect(x2, 0);
    });

    test('cancelled test makes the next try harder; finishing resets it', () {
      var s = normalize(null);
      s.league = 'beginner';
      expect(s.difficultyFor('css1'), 1);
      s = cancelTest(s, 'css1');
      expect(s.difficultyFor('css1'), 2);
      s = cancelTest(s, 'css1');
      s = cancelTest(s, 'css1');
      expect(s.difficultyFor('css1'), 3);
      final (s2, _) = completeLesson(s, 'css1', 20);
      expect(s2.difficultyFor('css1'), 1);
    });

    test('state survives JSON round trip', () {
      final (s, _) = completeLesson(normalize(null), 'js1', 20, correct: 3, total: 4, timeShare: 0.5);
      s.league = 'master';
      final back = normalize(jsonDecode(jsonEncode(s.toJson())));
      expect(back.league, 'master');
      expect(back.isDone('js1'), isTrue);
      expect(back.xpTotal, s.xpTotal);
      expect(back.stats.correct, 3);
    });
  });

  group('placement', () {
    test('warm-up has 8 questions from easy to hard', () {
      final steps = placementTest(42);
      expect(steps.length, 8);
      expect(steps.every((x) => x.type == StepType.quiz), isTrue);
      expect([for (final x in steps) x.difficulty], [1, 1, 1, 2, 2, 2, 3, 3]);
    });

    test('warm-up questions are valid for many seeds', () {
      for (var seed = 0; seed < 200; seed++) {
        for (final st in placementTest(seed)) {
          final texts = [for (final o in st.options) o.uz];
          expect(texts.length, greaterThanOrEqualTo(3), reason: 'seed $seed: ${st.q?.uz} $texts');
          expect(texts.toSet().length, texts.length, reason: 'seed $seed: $texts');
        }
      }
    });

    test('leagues from points', () {
      expect(leagueFor(3, 0.5), 'beginner');
      expect(leagueFor(8, 0.9), 'advanced');
      expect(leagueFor(12, 0.5), 'master');
      expect(leagueFor(12, 0.9), 'advanced');
      expect(leagueFor(15, 1), 'master');
    });
  });

  group('lessons', () {
    test('catalog matches the server list', () {
      final server = jsonDecode(File('../server/content/lessons.json').readAsStringSync()) as Map;
      expect(server.keys.toSet(), kAllLessons.keys.toSet());
      for (final e in kAllLessons.entries) {
        final m = server[e.key] as Map;
        expect(m['xp'], e.value.$1.xp, reason: e.key);
        expect(m['course'], e.value.$2.id, reason: e.key);
      }
    });

    test('shop lists are identical in app and server', () {
      final a = jsonDecode(File('assets/content/shop.json').readAsStringSync());
      final b = jsonDecode(File('../server/content/shop.json').readAsStringSync());
      expect(a, b);
      for (final it in a as List) {
        expect(File('assets/shop/${it['id']}.png').existsSync(), isTrue, reason: '${it['id']}');
      }
    });

    test('every league has lessons in every course', () {
      for (final lg in kLeagues) {
        for (final co in kCourses) {
          expect(co.lessonsFor(lg), isNotEmpty, reason: '${co.id}/$lg');
        }
      }
    });

    test('similar lessons give similar XP in every league', () {
      for (final lg in kLeagues) {
        final xs = {for (final co in kCourses) for (final l in co.lessonsFor(lg)) l.xp};
        expect(xs.difference({kLessonXp, kProjectXp}), isEmpty, reason: lg);
      }
    });

    for (final e in kAllLessons.entries) {
      test('lesson ${e.key} builds valid steps', () {
        final l = e.value.$1;
        for (final d in [1, 2, 3]) {
          for (final seed in [1, 7, 99, 12345]) {
            final steps = l.build(seed, d);
            expect(steps, isNotEmpty);
            expect(steps.where((x) => x.timed), isNotEmpty, reason: '${l.id} has questions');
            for (final st in steps) {
              switch (st.type) {
                case StepType.read:
                  expect(st.h, isNotNull);
                  expect(st.p, isNotNull);
                case StepType.quiz:
                  expect(st.options.length, greaterThanOrEqualTo(2), reason: l.id);
                  expect(st.answer, inInclusiveRange(0, st.options.length - 1));
                  final texts = [for (final o in st.options) o.uz];
                  expect(texts.toSet().length, texts.length, reason: '${l.id}: $texts');
                case StepType.fill:
                  expect(st.answers, isNotEmpty);
                  expect(st.pre, isNotNull);
                  expect(st.post, isNotNull);
                case StepType.order:
                  expect(st.lines.length, greaterThanOrEqualTo(2), reason: l.id);
                case StepType.tryIt:
                  expect(st.solution, isNotNull);
                  expect(st.check, isNotNull);
                  if (st.mode != 'py') {
                    expect(st.check!(st.solution!, ''), isTrue, reason: '${l.id} solution must pass');
                    expect(st.check!(st.start ?? '', ''), isFalse, reason: '${l.id} start must not pass');
                  }
                  expect(timeLimitFor(st, 'master'), greaterThanOrEqualTo(240));
              }
            }
          }
        }
      });
    }

    test('each attempt gets different questions', () {
      for (final e in kAllLessons.entries) {
        final a = e.value.$1.build(1, 2);
        final b = e.value.$1.build(2, 2);
        final sa = [for (final x in a) '${x.q?.uz}${x.options.map((o) => o.uz).join()}${x.code}${x.lines.join()}'];
        final sb = [for (final x in b) '${x.q?.uz}${x.options.map((o) => o.uz).join()}${x.code}${x.lines.join()}'];
        expect(sa.join('|') == sb.join('|'), isFalse, reason: e.key);
      }
    });

    test('generator is deterministic for a seed', () {
      final a = kAllLessons['py3']!.$1.build(5, 2);
      final b = kAllLessons['py3']!.$1.build(5, 2);
      expect([for (final x in a) x.q?.uz], [for (final x in b) x.q?.uz]);
    });
  });

  group('timers and helper', () {
    test('harder questions get more time, beginners get extra', () {
      const q1 = LessonStep.quiz(q: Tr.same('a'), o: [Tr.same('1'), Tr.same('2')], answer: 0, difficulty: 1);
      const q3 = LessonStep.quiz(q: Tr.same('a'), o: [Tr.same('1'), Tr.same('2')], answer: 0, difficulty: 3);
      expect(timeLimitFor(q3, 'master'), greaterThan(timeLimitFor(q1, 'master')));
      expect(timeLimitFor(q1, 'beginner'), greaterThan(timeLimitFor(q1, 'advanced')));
    });

    test('code issues are found', () {
      expect(codeIssues('py', 'if x > 3\n    print(x)', 'uz'), isNotEmpty);
      expect(codeIssues('html', '<h1>Salom', 'uz'), isNotEmpty);
      expect(codeIssues('css', 'p {\n  color: red\n}', 'ru'), isNotEmpty);
      expect(codeIssues('py', 'print("ok")', 'uz'), isEmpty);
    });
  });
}
