// Ilovani to‘liq "bosib ko‘rish" testi / тест: проходим приложение целиком.
// Ekranlarda xato (masalan, joy yetmasligi) bo‘lsa, test yiqiladi.
// Если на экранах есть ошибки (например, переполнение), тест упадёт.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodla/lessons.dart';
import 'package:kodla/main.dart';
import 'package:kodla/state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> settle(WidgetTester t, [int ms = 700]) async {
  await t.pump();
  await t.pump(Duration(milliseconds: ms));
}

Future<void> tapKey(WidgetTester t, Key key) async {
  final f = find.byKey(key);
  expect(f, findsWidgets, reason: '$key');
  await t.ensureVisible(f.last);
  await t.pump(const Duration(milliseconds: 100));
  await t.pump(const Duration(milliseconds: 1200));
  await t.tap(f.last);
  await settle(t);
}

late AppState gState;

/// Pastki menyuda bo‘lsa bosamiz, aks holda sahifani ochamiz.
/// Если вкладка есть в нижнем меню — нажимаем, иначе открываем страницу.
Future<void> tapTab(WidgetTester tester, String id) async {
  final nav = find.byKey(ValueKey('nav-$id'));
  if (gState.tabs.contains(id) && nav.evaluate().isNotEmpty) {
    await tester.tap(nav);
  } else {
    gState.go(id);
  }
  await settle(tester);
}

Future<void> fillField(WidgetTester t, String key, String text) async {
  final f = find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(TextField));
  await t.ensureVisible(f);
  await t.enterText(f, text);
  await t.pump();
}

bool has(Key k) => find.byKey(k).evaluate().isNotEmpty;

String solution(WidgetTester t) => t.widgetList<Text>(find.byKey(const ValueKey('test-solution'))).last.data!;

/// Bitta qadamga to‘g‘ri javob berish / правильный ответ на один шаг.
Future<void> answer(WidgetTester t, String sol) async {
  if (sol.startsWith('opt:')) {
    await tapKey(t, ValueKey('opt-${sol.substring(4)}'));
  } else if (sol.startsWith('fill:')) {
    await t.enterText(find.byKey(const ValueKey('fill-input')), sol.substring(5));
    await t.pump();
  } else if (sol.startsWith('order:')) {
    final n = int.parse(sol.substring(6));
    for (var k = 0; k < n; k++) {
      await tapKey(t, ValueKey('order-line-$k'));
    }
  } else {
    final f = find.descendant(of: find.byKey(const ValueKey('code-editor')), matching: find.byType(TextField));
    await t.enterText(f, sol.substring(4));
    await t.pump();
  }
  await tapKey(t, const ValueKey('step-check'));
}

/// Butun dars yoki isinishni o‘tish / пройти урок или разминку целиком.
Future<void> playSteps(WidgetTester t, {bool mistakeWithHelper = false, String doneText = 'Dars tugadi!'}) async {
  var mistakeDone = !mistakeWithHelper;
  for (var guard = 0; guard < 60; guard++) {
    await settle(t);
    if (find.text(doneText).evaluate().isNotEmpty) return;
    if (!has(const ValueKey('test-solution'))) {
      if (has(const ValueKey('step-next'))) await tapKey(t, const ValueKey('step-next'));
      continue;
    }
    final sol = solution(t);
    if (!mistakeDone && sol.startsWith('opt:')) {
      // Ataylab xato javob va AI yordamchi / намеренная ошибка и AI-помощник
      final right = int.parse(sol.substring(4));
      await tapKey(t, ValueKey('opt-${right == 0 ? 1 : 0}'));
      await tapKey(t, const ValueKey('step-check'));
      expect(find.byKey(const ValueKey('helper-btn')), findsOneWidget);
      await tapKey(t, const ValueKey('helper-btn'));
      expect(find.byKey(const ValueKey('helper-ok')), findsOneWidget);
      await tapKey(t, const ValueKey('helper-ok'));
      mistakeDone = true;
    }
    await answer(t, sol);
    await tapKey(t, const ValueKey('step-next'));
  }
  fail('steps did not finish');
}

void main() {
  testWidgets('offline: profile, warm-up, tabs, lesson, helper, cancel, shop', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final state = AppState()
      ..allowWarmUp = false
      ..testMode = true;
    gState = state;
    await tester.pumpWidget(KodlaApp(state: state));
    await state.init();
    await settle(tester, 900);

    // 1) Kirish ekrani / экран входа
    expect(find.byKey(const ValueKey('go-offline')), findsOneWidget);
    await tapKey(tester, const ValueKey('go-offline'));
    expect(state.mode, 'offline');

    // 2) Profil: rasm, ism, maktab, shahar / профиль: фото, имя, школа, город
    expect(find.text('Keling, tanishamiz!'), findsOneWidget);
    await tapKey(tester, const ValueKey('setup-save'));
    expect(find.text('O‘zingizning rasmingizni qo‘shing.').evaluate().isEmpty &&
        find.text('Ism, maktab va yashash joyini to‘ldiring.').evaluate().isEmpty, isFalse);
    await tapKey(tester, const ValueKey('photo-pick'));
    await fillField(tester, 'f-name', 'Aziza Karimova');
    await tapKey(tester, const ValueKey('school-region'));
    await tapKey(tester, const ValueKey('pick-Andijon viloyati'));
    await tapKey(tester, const ValueKey('school-district'));
    await tapKey(tester, const ValueKey('pick-Asaka'));
    await fillField(tester, 'school-number', '45');
    expect(find.text('-maktab'), findsWidgets);
    FocusManager.instance.primaryFocus?.unfocus();
    await tapKey(tester, const ValueKey('setup-save'));
    expect(state.localName, 'Aziza Karimova');
    expect(state.localSchool, '45-maktab');
    expect(state.localRegion, 'Andijon viloyati');
    expect(state.localCity, 'Asaka');
    expect(state.myPhoto, isNotNull);

    // 3) Isinish (liga aniqlanadi) / разминка (определяет лигу)
    await settle(tester, 900);
    expect(find.text('Kichik isinish'), findsOneWidget);
    await tapKey(tester, const ValueKey('test-start'));
    await playSteps(tester, doneText: 'Zo‘r isinish!');
    await tapKey(tester, const ValueKey('placement-finish'));
    await settle(tester, 900);
    expect(state.st.league, isNotEmpty);

    // Eslatma vaqti / время напоминания
    expect(find.text('Qachon eslatay?'), findsOneWidget);
    await tapKey(tester, const ValueKey('preset-450'));
    expect(find.text('Har kuni soat 07:30 da eslataman'), findsOneWidget);
    await tapKey(tester, const ValueKey('reminder-save'));
    await settle(tester, 900);
    expect(state.reminderMinutes, 450);
    expect(state.st.xp, 20);
    expect(find.byKey(const ValueKey('nav-home')), findsOneWidget);

    // 4) Minimal bosh sahifa: 3 ta tab / минимальная главная: 3 вкладки
    expect(state.tabs, ['home', 'ranking', 'profile']);
    expect(find.byKey(const ValueKey('continue-card')), findsOneWidget);
    await tapKey(tester, const ValueKey('quests-row'));
    await tester.tapAt(const Offset(20, 20));
    await settle(tester);
    await tapKey(tester, const ValueKey('course-row-py'));
    expect(state.courseId, 'py');
    await tapKey(tester, const ValueKey('page-back'));

    // Barcha sahifalar / все страницы
    for (final id in ['courses', 'play', 'ranking', 'profile', 'home']) {
      await tapTab(tester, id);
    }
    await tapKey(tester, const ValueKey('xp-pill'));
    expect(find.text('XP do‘koni'), findsWidgets);
    await tapKey(tester, const ValueKey('shop-pen'));
    expect(find.byKey(const ValueKey('buy-confirm')), findsOneWidget);
    expect(state.online, isFalse); // oflayn — tugma o‘chirilgan / офлайн — кнопка неактивна
    await tester.tapAt(const Offset(20, 20));
    await settle(tester);

    // Rus tili va qorong‘i mavzu / русский язык и тёмная тема
    state.toggleLang();
    state.toggleTheme();
    await settle(tester);
    for (final id in ['courses', 'play', 'ranking', 'profile', 'home']) {
      await tapTab(tester, id);
    }
    state.go('shop');
    await settle(tester);
    state.setTheme('system');
    state.toggleLang();
    await settle(tester);

    // 5) Birinchi dars (xato + AI yordamchi) / первый урок (ошибка + AI-помощник)
    await tapTab(tester, 'courses');
    await tapKey(tester, const ValueKey('course-html'));
    await tapKey(tester, const ValueKey('lesson-html1'));
    expect(find.byKey(const ValueKey('test-start')), findsOneWidget);
    await tapKey(tester, const ValueKey('test-start'));
    await playSteps(tester, mistakeWithHelper: true);
    expect(state.st.isDone('html1'), isTrue);
    expect(state.st.xp, 20 - 5 + 20); // isinish − yordamchi + dars / разминка − помощник + урок
    expect(state.st.xpTotal, 40);
    await tapKey(tester, const ValueKey('lesson-back'));
    expect(find.byKey(const ValueKey('lesson-html2')), findsOneWidget);

    // 6) Ilovadan chiqish testni bekor qiladi / выход из приложения отменяет тест
    await tapKey(tester, const ValueKey('lesson-html2'));
    await tapKey(tester, const ValueKey('test-start'));
    expect(has(const ValueKey('lesson-close')), isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(state.st.retries['html2'], 1);
    expect(state.st.difficultyFor('html2'), greaterThanOrEqualTo(2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(tester, 900);
    expect(has(const ValueKey('lesson-close')), isFalse);
    expect(find.text('Test bekor qilindi'), findsOneWidget);
    await tapKey(tester, const ValueKey('notice-ok'));

    // 7) X tugmasi bilan chiqish / выход кнопкой X
    await tapKey(tester, const ValueKey('lesson-html2'));
    await tapKey(tester, const ValueKey('test-start'));
    await tapKey(tester, const ValueKey('lesson-close'));
    await tapKey(tester, const ValueKey('quit-yes'));
    expect(state.st.retries['html2'], 2);
    expect(has(const ValueKey('lesson-close')), isFalse);

    // 8) Profilni tahrirlash / редактирование профиля
    await tester.pump(const Duration(seconds: 3));
    await tapTab(tester, 'profile');
    await settle(tester, 1500);
    expect(find.byKey(const ValueKey('edit-profile')), findsOneWidget);
    await tapKey(tester, const ValueKey('edit-profile'));
    await settle(tester, 1000);
    expect(find.byKey(const ValueKey('profile-save')), findsOneWidget, reason: 'edit sheet should be open');
    await fillField(tester, 'school-number', '46');
    FocusManager.instance.primaryFocus?.unfocus();
    await tapKey(tester, const ValueKey('profile-save'));
    expect(state.localSchool, '46-maktab');

    // Eslatmani profildan o‘zgartirish / изменить напоминание из профиля
    await tester.pump(const Duration(seconds: 3));
    await tapKey(tester, const ValueKey('reminder-tile'));
    await settle(tester, 900);
    await tapKey(tester, const ValueKey('reminder-skip'));
    await settle(tester, 900);
    expect(state.reminderMinutes, -1);

    // 9) Yakuniy imtihon va sertifikat / итоговый экзамен и сертификат
    await tester.pump(const Duration(seconds: 4));
    final html = kCourses.first;
    for (final l in state.lessonsOf(html)) {
      state.st.done[l.id] = true;
    }
    state.pickCourse('html');
    await tapTab(tester, 'courses');
    await settle(tester, 900);
    await tapKey(tester, const ValueKey('exam-open'));
    expect(find.text('Yakuniy imtihon'), findsWidgets);
    await tapKey(tester, const ValueKey('test-start'));
    await playSteps(tester, doneText: 'Tabriklaymiz!');
    expect(state.certs['html'], isNotNull);
    expect(state.certs['html']!.score, 100);
    await tester.pump(const Duration(seconds: 4));
    await tapKey(tester, const ValueKey('cert-open'));
    expect(find.text('SERTIFIKAT'), findsWidgets);
    expect(find.byKey(const ValueKey('cert-download')), findsOneWidget);
    await tapKey(tester, const ValueKey('page-back'));
    await tapKey(tester, const ValueKey('lesson-back'));
    expect(find.text('Sertifikat'), findsWidgets);

    // Bildirishnoma yopilishini kutamiz / ждём, пока скроется уведомление
    await tester.pump(const Duration(seconds: 4));
  });
}
