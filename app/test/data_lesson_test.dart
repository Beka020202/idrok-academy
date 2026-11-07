import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kodla/content/data_lesson.dart';
import 'package:kodla/lessons.dart';

void main() {
  group('lessons as data', () {
    for (final e in Map.of(kAllLessons).entries) {
      test('${e.key} survives JSON round trip', () {
        final raw = jsonDecode(jsonEncode(lessonToJson(e.value.$1))) as Map<String, dynamic>;
        final l = lessonFromJson(e.key, raw, source: 'global');
        expect(l, isNotNull, reason: e.key);
        final steps = l!.build(3, 2);
        expect(steps.length, e.value.$1.build(1, 2).length, reason: e.key);
        for (final st in steps) {
          if (st.type == StepType.quiz) {
            expect(st.answer, inInclusiveRange(0, st.options.length - 1));
          }
          if (st.type == StepType.tryIt && st.mode != 'py') {
            expect(st.check!(st.solution!, ''), isTrue, reason: '${e.key} solution must pass');
          }
          if (st.anim != null) {
            final again = sceneFromJson(jsonDecode(jsonEncode(sceneToJson(st.anim!))));
            expect(again, isNotNull);
            expect(again!.frames.length, st.anim!.frames.length);
          }
        }
      });
    }

    test('quiz options are shuffled but the answer stays right', () {
      final raw = {
        'title': {'uz': 'T', 'ru': 'T'},
        'course': 'html',
        'steps': [
          {
            't': 'quiz',
            'q': {'uz': 'Q', 'ru': 'Q'},
            'o': ['a', 'b', 'c', 'd'],
            'a': 2
          }
        ]
      };
      final l = lessonFromJson('x', raw)!;
      for (final seed in [1, 2, 3, 4, 5]) {
        final st = l.build(seed, 1).single;
        expect(st.options[st.answer].uz, 'c');
      }
    });

    test('check uses must and out', () {
      final c = makeCheck(['<h1>'], const []);
      expect(c('<H1>Salom</H1>', ''), isTrue);
      expect(c('<p>x</p>', ''), isFalse);
      final p = makeCheck(['print'], ['Salom']);
      expect(p('print("Salom")', 'Salom\n'), isTrue);
      expect(p('print("Salom")', 'Hayr'), isFalse);
    });

    test('server content overrides, hides and adds lessons', () {
      final html = kCourses.first;
      final before = [for (final l in html.lessons) l.id];
      applyContent([
        {
          'id': 'html2',
          'scope': 'global',
          'hidden': false,
          'updated': 1,
          'data': {
            'title': {'uz': 'Yangi nom', 'ru': 'Новое имя'},
            'course': 'html',
            'xp': 25,
            'steps': [
              {
                't': 'read',
                'h': {'uz': 'a', 'ru': 'a'},
                'p': {'uz': 'b', 'ru': 'b'}
              },
              {
                't': 'quiz',
                'q': 'q',
                'o': ['a', 'b'],
                'a': 0
              }
            ]
          }
        },
        {'id': 'html3', 'scope': 'global', 'hidden': true, 'updated': 2, 'data': null},
        {
          'id': 'g_new',
          'scope': 'global',
          'hidden': false,
          'updated': 3,
          'data': {
            'title': {'uz': 'Jadval', 'ru': 'Таблица'},
            'course': 'html',
            'pos': 1,
            'steps': [
              {
                't': 'quiz',
                'q': 'q',
                'o': ['a', 'b'],
                'a': 1
              }
            ]
          }
        },
        {
          'id': 's_one',
          'scope': 'school',
          'hidden': false,
          'updated': 4,
          'data': {
            'title': 'Maktab',
            'course': 'html',
            'xp': 40,
            'steps': [
              {
                't': 'quiz',
                'q': 'q',
                'o': ['a', 'b'],
                'a': 1
              }
            ]
          }
        },
      ]);
      final ids = [for (final l in html.lessons) l.id];
      expect(ids.contains('html3'), isFalse);
      expect(ids[1], 'g_new');
      expect(kAllLessons['html2']!.$1.title.uz, 'Yangi nom');
      expect(kAllLessons['html2']!.$1.xp, 25);
      expect(kSchoolLessons['html']!.single.xp, 0);
      expect(kAllLessons['s_one']!.$1.local, isTrue);
      expect(adminLessonsOf(html).map((l) => l.id), contains('html3'));
      applyContent(const []);
      expect([for (final l in html.lessons) l.id], before);
      expect(kAllLessons.containsKey('s_one'), isFalse);
    });
  });
}
