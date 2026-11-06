// ============================================================================
//  Yakuniy imtihon / итоговый экзамен
//  Kurs tugagach — 30 ta savol. 70% va undan ko‘p — sertifikat.
//  После курса — 30 вопросов. 70% и больше — сертификат.
// ============================================================================

import 'dart:math';

import 'model.dart';

const int kExamSize = 30;
const int kExamPass = 70; // foiz / процент
const Duration kExamWait = Duration(hours: 24);

/// Imtihon savollari: kursning barcha darslaridan navbatma-navbat, takrorlarsiz.
/// Вопросы экзамена: по очереди из всех уроков курса, без повторов.
List<LessonStep> examQuestions(List<Lesson> lessons, int seed, {int n = kExamSize}) {
  if (lessons.isEmpty) return const [];
  final r = Random(seed);
  final seen = <String>{};
  // Har bir dars uchun navbat / очередь для каждого урока
  final queues = <List<LessonStep>>[for (final _ in lessons) <LessonStep>[]];
  var round = 0;
  final out = <LessonStep>[];

  String keyOf(LessonStep st) => [
        st.type.name,
        st.q?.uz ?? '',
        st.code ?? '',
        st.pre ?? '',
        st.post ?? '',
        ...([for (final o in st.options) o.uz]..sort()),
        ...([...st.lines]..sort()),
      ].join('|');

  void refill(int k) {
    final l = lessons[k];
    final steps = l.build(seed + round * 7919 + k * 104729, 2);
    for (var j = 0; j < steps.length; j++) {
      var st = steps[j];
      if (st.type == StepType.read) continue;
      if (st.type == StepType.tryIt) st = offlineFallback(st, seed + round * 31 + j);
      if (st.type == StepType.tryIt) continue;
      if (seen.add(keyOf(st))) queues[k].add(st);
    }
    queues[k].shuffle(r);
  }

  // Navbat bilan: har bir darsdan bittadan / по кругу: по одному из каждого урока
  var guard = 0;
  while (out.length < n && guard++ < 60) {
    var added = false;
    for (var k = 0; k < lessons.length && out.length < n; k++) {
      if (queues[k].isEmpty) refill(k);
      if (queues[k].isNotEmpty) {
        out.add(queues[k].removeLast());
        added = true;
      }
    }
    round++;
    if (!added && guard > 8) break;
  }
  out.shuffle(r);
  return out;
}

/// Foiz / процент.
int examScore(int correct, int total) => total <= 0 ? 0 : (correct * 100 / total).round();

/// Sertifikat / сертификат.
class Cert {
  final String id, course, name, school;
  final int score;
  final DateTime issued;
  const Cert({required this.id, required this.course, required this.name, required this.school, required this.score, required this.issued});

  factory Cert.fromJson(Map<String, dynamic> j) => Cert(
        id: '${j['id'] ?? ''}',
        course: '${j['course'] ?? ''}',
        name: '${j['name'] ?? ''}',
        school: '${j['school'] ?? ''}',
        score: (j['score'] as num?)?.toInt() ?? 0,
        issued: DateTime.fromMillisecondsSinceEpoch((j['issued'] as num?)?.toInt() ?? 0),
      );

  Map<String, Object> toJson() => {
        'id': id,
        'course': course,
        'name': name,
        'school': school,
        'score': score,
        'issued': issued.millisecondsSinceEpoch,
      };
}
