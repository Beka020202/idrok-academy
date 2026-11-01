// AI yordamchi: o‘quvchi xatosini sodda tilda tushuntiradi.
// Hozircha bepul generator (qoidalar asosida), tashqi AI xarajatisiz.
// AI-помощник: простыми словами объясняет ошибку ученика.
// Пока бесплатный генератор (на правилах), без затрат на внешний AI.
import 'package:flutter/material.dart';

import '../lessons.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class HelperItem {
  final IconData icon;
  final String title;
  final String body;
  final bool mono;
  const HelperItem(this.icon, this.title, this.body, {this.mono = false});
}

const Map<String, Tr> _courseTips = {
  'html': Tr('HTML’da deyarli har bir teg ochiladi va yopiladi: <p> … </p>. Yopuvchi tegda “/” belgisi bo‘ladi.',
      'В HTML почти каждый тег открывается и закрывается: <p> … </p>. В закрывающем теге есть «/».'),
  'css': Tr('CSS qoidasi: selektor { xususiyat: qiymat; }. Har bir qatordan keyin “;” qo‘yishni unutmang.',
      'Правило CSS: селектор { свойство: значение; }. Не забывайте «;» после каждой строки.'),
  'js': Tr('JavaScript’da matn qo‘shtirnoq ichida yoziladi, buyruq oxirida “;” qo‘yish odat tusiga kirgan.',
      'В JavaScript текст пишут в кавычках, а в конце команды принято ставить «;».'),
  'py': Tr('Python’da bo‘sh joylar muhim: if/for ichidagi qatorlar 4 ta bo‘sh joy bilan suriladi va “:” bilan boshlanadi.',
      'В Python важны отступы: строки внутри if/for сдвигаются на 4 пробела, а сама строка заканчивается «:».'),
  'ai': Tr('AI javobini doim tekshiring: manbani so‘rang, raqamlarni qayta hisoblang va aniq so‘rov yozing.',
      'Всегда проверяйте ответ AI: спрашивайте источник, пересчитывайте числа и пишите точный запрос.'),
};

/// Xatoni tushuntirish / объяснение ошибки.
List<HelperItem> explainMistake(
  AppState s,
  LessonStep st, {
  required String courseId,
  int? selected,
  String input = '',
  List<int> picked = const [],
  String code = '',
  String output = '',
  bool timedOut = false,
}) {
  final items = <HelperItem>[];
  String t(String uz, String ru) => s.lang == 'ru' ? ru : uz;

  if (timedOut) {
    items.add(HelperItem(Icons.timer_off_rounded, t('Vaqt tugadi', 'Время вышло'),
        t('Shoshilmang, lekin savolni o‘qib, avval eng oson qismini toping. Keyingi safar vaqtni kuzatib boring.',
            'Не спешите, но сначала прочитайте вопрос и найдите самую простую часть. В следующий раз следите за таймером.')));
  }

  switch (st.type) {
    case StepType.quiz:
      final right = s.tr(st.options[st.answer]);
      if (selected != null && selected != st.answer && selected < st.options.length) {
        items.add(HelperItem(Icons.close_rounded, t('Siz tanladingiz', 'Вы выбрали'), s.tr(st.options[selected]), mono: st.mono));
      }
      items.add(HelperItem(Icons.check_rounded, t('To‘g‘ri javob', 'Правильный ответ'), right, mono: st.mono));
      if (st.e != null) {
        items.add(HelperItem(Icons.lightbulb_rounded, t('Nega?', 'Почему?'), s.tr(st.e!)));
      } else if (st.code != null) {
        items.add(HelperItem(Icons.lightbulb_rounded, t('Qanday tekshirish mumkin?', 'Как проверить?'),
            t('Kodni qatorma-qator “qo‘lda” bajarib ko‘ring: har bir o‘zgaruvchi qiymatini qog‘ozga yozing.',
                'Выполните код «вручную» строка за строкой: записывайте значение каждой переменной на бумаге.')));
      }

    case StepType.fill:
      final want = st.answers.first;
      final got = input.trim();
      items.add(HelperItem(Icons.check_rounded, t('Kerakli javob', 'Нужный ответ'), '${st.pre}$want${st.post}', mono: true));
      if (got.isNotEmpty) {
        String why;
        if (got.toLowerCase() == want.toLowerCase()) {
          why = t('Deyarli! Faqat katta-kichik harflar boshqacha.', 'Почти! Отличаются только заглавные/строчные буквы.');
        } else if (got.replaceAll(' ', '') == want.replaceAll(' ', '')) {
          why = t('Ortiqcha bo‘sh joy bor — uni olib tashlang.', 'Есть лишний пробел — уберите его.');
        } else if (_distance(got.toLowerCase(), want.toLowerCase()) <= 2) {
          why = t('Bitta-ikkita harf xato yozilgan. Imloni diqqat bilan tekshiring.',
              'Ошибка в одной-двух буквах. Внимательно проверьте написание.');
        } else if (RegExp(r'[<>{}();:"]').hasMatch(got) && !RegExp(r'[<>{}();:"]').hasMatch(want)) {
          why = t('Bu joyga belgilar emas, faqat so‘z kerak — qavslar allaqachon yozilgan.',
              'Здесь нужно только слово — скобки и знаки уже написаны.');
        } else {
          why = t('Bu boshqa buyruq. Nazariyani yana bir bor o‘qib chiqing — javob o‘sha yerda.',
              'Это другая команда. Перечитайте теорию — ответ там.');
        }
        items.add(HelperItem(Icons.search_rounded, '${t('Siz yozdingiz', 'Вы написали')}: $got', why));
      }
      if (st.e != null) items.add(HelperItem(Icons.lightbulb_rounded, t('Eslatma', 'Подсказка'), s.tr(st.e!)));

    case StepType.order:
      var firstBad = -1;
      for (var k = 0; k < picked.length && k < st.lines.length; k++) {
        if (st.lines[picked[k]] != st.lines[k]) {
          firstBad = k;
          break;
        }
      }
      if (firstBad >= 0) {
        items.add(HelperItem(Icons.format_list_numbered_rounded,
            t('${firstBad + 1}-qator noto‘g‘ri joyda', 'Строка ${firstBad + 1} не на своём месте'),
            '${t('Bu yerda turishi kerak:', 'Здесь должна стоять:')}\n${st.lines[firstBad]}',
            mono: true));
      }
      items.add(HelperItem(Icons.lightbulb_rounded, t('Qoida', 'Правило'),
          t('Kompyuter buyruqlarni yuqoridan pastga bajaradi. Avval nima tayyor bo‘lishi kerakligini o‘ylang: o‘zgaruvchi ishlatilishidan oldin yaratiladi, ochilgan narsa oxirida yopiladi.',
              'Компьютер выполняет команды сверху вниз. Подумайте, что должно быть готово раньше: переменную создают до использования, а открытое закрывают в конце.')));
      if (st.e != null) items.add(HelperItem(Icons.info_rounded, t('Eslatma', 'Подсказка'), s.tr(st.e!)));

    case StepType.tryIt:
      final issues = codeIssues(st.mode ?? '', code, s.lang);
      for (final x in issues) {
        items.add(HelperItem(Icons.bug_report_rounded, t('Topilgan muammo', 'Найденная проблема'), x));
      }
      if (st.mode == 'py' && output.trim().isNotEmpty) {
        items.add(HelperItem(Icons.terminal_rounded, t('Dasturingiz chiqardi', 'Ваша программа вывела'), output.trim(), mono: true));
      }
      items.add(HelperItem(Icons.lightbulb_rounded, t('Maslahat', 'Подсказка'), s.tr(st.hint!), mono: true));
      if (st.solution != null) {
        items.add(HelperItem(Icons.check_circle_rounded, t('Namuna yechim', 'Пример решения'), st.solution!, mono: true));
      }

    case StepType.read:
      break;
  }

  final tip = _courseTips[courseId];
  if (tip != null) items.add(HelperItem(Icons.school_rounded, t('Yodda tuting', 'Запомните'), s.tr(tip)));
  return items;
}

/// Koddagi oddiy xatolarni topish / поиск простых ошибок в коде.
List<String> codeIssues(String mode, String code, String lang) {
  String t(String uz, String ru) => lang == 'ru' ? ru : uz;
  final out = <String>[];
  int n(String ch) => ch.allMatches(code).length;
  if (code.trim().isEmpty) {
    out.add(t('Kod bo‘sh. Avval topshiriqni bajaradigan qator yozing.', 'Код пустой. Сначала напишите строку, выполняющую задание.'));
    return out;
  }
  if (n('(') != n(')')) out.add(t('Qavslar soni teng emas: “(” va “)”.', 'Число скобок не совпадает: «(» и «)».'));
  if (n('{') != n('}')) out.add(t('Jingalak qavslar soni teng emas: “{” va “}”.', 'Число фигурных скобок не совпадает: «{» и «}».'));
  if (n('[') != n(']')) out.add(t('Kvadrat qavslar soni teng emas: “[” va “]”.', 'Число квадратных скобок не совпадает: «[» и «]».'));
  if (n('"') % 2 == 1) out.add(t('Qo‘shtirnoq yopilmagan: “"” juft bo‘lishi kerak.', 'Кавычка не закрыта: «"» должны быть парными.'));
  if (mode == 'py') {
    for (final line in code.split('\n')) {
      final l = line.trim();
      if (RegExp(r'^(if|elif|else|for|while|def)\b').hasMatch(l) && !l.endsWith(':')) {
        out.add(t('“$l” qatori oxirida “:” yo‘q.', 'В конце строки «$l» нет «:».'));
        break;
      }
    }
    if (RegExp(r'\bprint\s+[^(\s]').hasMatch(code)) {
      out.add(t('print dan keyin qavs kerak: print("...").', 'После print нужны скобки: print("...").'));
    }
  }
  if (mode == 'html') {
    final open = RegExp(r'<([a-z][a-z0-9]*)\b[^>]*>', caseSensitive: false).allMatches(code).map((m) => m.group(1)!.toLowerCase());
    const single = {'img', 'br', 'hr', 'input', 'meta', 'link'};
    for (final tag in open.toSet()) {
      if (single.contains(tag)) continue;
      final o = RegExp('<$tag\\b', caseSensitive: false).allMatches(code).length;
      final c = RegExp('</$tag>', caseSensitive: false).allMatches(code).length;
      if (o > c) {
        out.add(t('<$tag> tegi yopilmagan — </$tag> qo‘shing.', 'Тег <$tag> не закрыт — добавьте </$tag>.'));
        break;
      }
    }
  }
  if (mode == 'css') {
    for (final line in code.split('\n')) {
      final l = line.trim();
      if (l.contains(':') && !l.contains('{') && !l.endsWith(';') && !l.endsWith('}') && l.isNotEmpty) {
        out.add(t('“$l” qatori oxirida “;” yo‘q.', 'В конце строки «$l» нет «;».'));
        break;
      }
    }
  }
  return out;
}

int _distance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (j) => j);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      final x = prev[j] + 1, y = cur[j - 1] + 1, z = prev[j - 1] + cost;
      cur[j] = x < y ? (x < z ? x : z) : (y < z ? y : z);
    }
    prev = cur;
  }
  return prev[b.length];
}

/// Yordamchi oynasi / окно помощника.
Future<void> showHelperSheet(BuildContext context, List<HelperItem> items) {
  final s = AppScope.read(context);
  return showAppSheet<void>(context, builder: (ctx) {
    final c = AppScope.of(ctx).c;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.8),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const IconTile(Icons.smart_toy_rounded, size: 46, vivid: true),
          const SizedBox(width: S.x3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.t('helper_title'), style: AppType.title3.copyWith(color: c.text)),
              Text(s.t('helper_sub'), style: AppType.footnote.copyWith(color: c.text2)),
            ]),
          ),
        ]),
        const SizedBox(height: S.x4),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            children: [
              for (final it in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: S.x3),
                  child: AppCard(
                    kind: CardKind.inset,
                    padding: const EdgeInsets.all(S.x3 + 2),
                    radius: R.lg,
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(it.icon, size: 20, color: c.accentText),
                      const SizedBox(width: S.x3),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(it.title, style: AppType.subhead.copyWith(color: c.text, fontWeight: w8)),
                          const SizedBox(height: 4),
                          Text(it.body, style: (it.mono ? AppType.mono : AppType.subhead).copyWith(color: c.text2)),
                        ]),
                      ),
                    ]),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: S.x2),
        AppButton(s.t('helper_ok'),
            key: const ValueKey('helper-ok'), expand: true, onPressed: () => Navigator.of(ctx).pop()),
      ]),
    );
  });
}
