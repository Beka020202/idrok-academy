// O‘yin qoidalari va tekshiruvlar testi / тесты правил игры и проверок.
// Ishga tushirish / запуск:  flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:kodla/lessons.dart';
import 'package:kodla/progress.dart';

void main() {
  group('progress', () {
    test('first lesson gives XP, gems and starts streak', () {
      final (s, r) = completeLesson(normalize(null, today: '2026-10-30'), 'html1', 15,
          perfect: true, bestCombo: 3, today: '2026-10-30');
      expect(r.xp, 20);
      expect(r.gems, 15);
      expect(r.first, isTrue);
      expect(s.streak, 1);
      expect(s.quests.combo, 3);
      expect(s.isDone('html1'), isTrue);
    });

    test('review gives 5 XP and no gems; streak grows next day', () {
      var (s, _) = completeLesson(normalize(null, today: '2026-10-30'), 'html1', 15, today: '2026-10-30');
      final (s2, r) = completeLesson(s, 'html1', 15, today: '2026-10-31');
      expect(r.xp, kReviewXp);
      expect(r.gems, 0);
      expect(r.first, isFalse);
      expect(s2.streak, 2);
    });

    test('streak resets after a missed day', () {
      final (s, _) = completeLesson(normalize(null, today: '2026-10-01'), 'html1', 15, today: '2026-10-01');
      expect(normalize(s.toJson(), today: '2026-10-05').streak, 0);
    });

    test('daily quests reset on a new day and can be claimed once', () {
      var s = normalize(null);
      s.quests.combo = 3;
      final (s1, g1) = claimQuest(s, 'combo');
      final (_, g2) = claimQuest(s1, 'combo');
      expect(g1, 20);
      expect(g2, 0);
      expect(claimQuest(normalize(null), 'xp').$2, 0);
    });

    test('chest opens only when the course is finished', () {
      final co = kCourses.first;
      var s = normalize(null);
      expect(openChest(s, co.id, co.lessonIds).$2, 0);
      for (final id in co.lessonIds) {
        s.done[id] = true;
      }
      final (s2, g) = openChest(s, co.id, co.lessonIds);
      expect(g, kChestGems);
      expect(openChest(s2, co.id, co.lessonIds).$2, 0);
    });

    test('avatar shop', () {
      var s = normalize(null)..gems = 50;
      final (s1, ok1) = buyAvatar(s, '🦊');
      expect(ok1, isTrue);
      expect(s1.gems, 10);
      expect(s1.avatar, '🦊');
      expect(buyAvatar(s1, '👑').$2, isFalse);
      expect(buyAvatar(s1, '🤖').$2, isTrue);
    });

    test('JSON round trip keeps server keys', () {
      final s = GameState.fromJson({
        'xp': 120,
        'done': {'py1': true},
        'last_day': '2026-10-31',
        'quests': {'date': '2026-10-31', 'claimed': ['xp']},
      });
      final j = s.toJson();
      expect(j['xp'], 120);
      expect(j['last_day'], '2026-10-31');
      expect((j['quests'] as Map)['claimed'], ['xp']);
      expect(levelOf(120), 2);
    });

    test('dayBefore handles month and year changes', () {
      expect(dayBefore('2026-03-01'), '2026-02-28');
      expect(dayBefore('2027-01-01'), '2026-12-31');
    });
  });

  group('lessons', () {
    test('every lesson has exactly one practice step and unique id', () {
      final ids = <String>{};
      for (final c in kCourses) {
        for (final l in c.lessons) {
          expect(ids.add(l.id), isTrue, reason: l.id);
          expect(l.steps.where((s) => s.type == StepType.tryIt).length, 1, reason: l.id);
          for (final st in l.steps.where((s) => s.type == StepType.quiz)) {
            expect(st.answer, inInclusiveRange(0, st.options.length - 1), reason: l.id);
          }
        }
      }
    });

    test('HTML/CSS/JS checks: start code fails, a correct answer passes', () {
    const solutions = <String, String>{
    'html1': '<h1>Aziza</h1>',
    'html2': '<a href="https://uz.wikipedia.org">Vikipediya</a>',
    'html3': '<ul>\n  <li>Matematika</li>\n  <li>Fizika</li>\n  <li>Ingliz tili</li>\n</ul>',
    'css1': 'h1 {\n  color: royalblue;\n}',
    'css2': 'p {\n  font-size: 22px;\n}',
    'css3': '.karta {\n  padding: 16px;\n  border: 2px solid blue;\n}',
    'js1': 'let yosh = 15;\nconsole.log(yosh);',
    'js2': 'let ball = 92;\nif (ball >= 80) { console.log("A’lo"); } else { console.log("Harakat qiling"); }',
    'js3': 'function kvadrat(n) {\n  return n * n;\n}\nconsole.log(kvadrat(4));',
    };
      for (final c in kCourses.where((c) => c.id != 'py')) {
        for (final l in c.lessons) {
          final st = l.steps.firstWhere((s) => s.type == StepType.tryIt);
          expect(st.check!(st.start!, ''), isFalse, reason: '${l.id} start');
          expect(st.check!(solutions[l.id]!, ''), isTrue, reason: '${l.id} solution');
        }
      }
    });

    test('Python checks use program output', () {
      final py3 = kChecks['py3']!;
      expect(py3('for i in range(1, 6):\n    print(i)', '1\n2\n3\n4\n5\n'), isTrue);
      expect(py3('for i in range(5):\n    print(i)', '0\n1\n2\n3\n4\n'), isFalse);
      expect(kChecks['py2']!('print(f"Men {shahar}da yashayman")', 'Men Asakada yashayman\n'), isTrue);
      expect(kChecks['py1']!('print()', '\n'), isFalse);
    });
  });
}
