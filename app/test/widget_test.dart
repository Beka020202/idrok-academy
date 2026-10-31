// Ilovani to‘liq "bosib ko‘rish" testi / тест: проходим приложение целиком.
// Ekranlarda xato (masalan, joy yetmasligi) bo‘lsa, test yiqiladi.
// Если на экранах есть ошибки (например, переполнение), тест упадёт.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodla/main.dart';
import 'package:kodla/state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> tapText(WidgetTester tester, String text, {bool contains = false}) async {
  final f = contains ? find.textContaining(text) : find.text(text);
  expect(f, findsWidgets, reason: text);
  await tester.ensureVisible(f.first);
  // iOS uslubidagi "qaytish" (bounce) tugashini kutamiz — bu vaqtda bosish e'tiborsiz qoladi.
  // Ждём окончания «отскока» прокрутки — во время него нажатия игнорируются.
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 1500));
  await tester.tap(f.first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> tapTab(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(ValueKey('nav-$id')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  testWidgets('offline mode: every tab and a full lesson', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final state = AppState()..allowWarmUp = false;
    await tester.pumpWidget(KodlaApp(state: state));
    await state.init();
    await tester.pump();

    // Kirish ekrani / экран входа
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Serversiz davom etish'), findsOneWidget);
    await tapText(tester, 'Serversiz davom etish');
    expect(state.mode, 'offline');

    // Barcha tablar / все вкладки
    for (final id in ['courses', 'play', 'ranking', 'profile', 'home']) {
      await tapTab(tester, id);
    }

    // Rus tili va qorong‘i mavzu / русский язык и тёмная тема
    state.toggleLang();
    state.toggleTheme();
    await tester.pump(const Duration(milliseconds: 600));
    for (final id in ['courses', 'play', 'profile', 'home']) {
      await tapTab(tester, id);
    }
    state.setTheme('system');
    await tester.pump(const Duration(milliseconds: 600));
    state.toggleLang();
    await tester.pump(const Duration(milliseconds: 600));

    // Birinchi dars / первый урок: nazariya → savol → savol → amaliyot
    await tapText(tester, 'O‘ynash', contains: true);
    await tapText(tester, 'Davom etish');
    await tapText(tester, '<h1>');
    await tapText(tester, 'Tekshirish');
    await tapText(tester, 'Davom etish');
    await tapText(tester, '<p/>'); // noto‘g‘ri javob / неверный ответ
    await tapText(tester, 'Tekshirish');
    expect(find.textContaining('Qayta urinib'), findsOneWidget);
    await tapText(tester, '</p>');
    await tapText(tester, 'Tekshirish');
    await tapText(tester, 'Davom etish');
    await tester.enterText(find.byType(TextField), '<h1>Aziza</h1>');
    await tester.pump();
    await tapText(tester, 'Tekshirish');
    await tapText(tester, 'Davom etish');
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Dars tugadi!'), findsOneWidget);
    expect(state.st.isDone('html1'), isTrue);
    expect(state.st.xp, 15); // xato bor edi — "xatosiz" bonusi yo‘q / была ошибка — без бонуса
    expect(state.st.gems, 10);

    await tapText(tester, 'Kurslarga qaytish');
    expect(find.byKey(const ValueKey('nav-home')), findsOneWidget);

    // Kunlik vazifa: 2 ta dars kerak, hali bitta / задание: нужно 2 урока, пока один
    await tapTab(tester, 'profile');
    await tapText(tester, 'Progressni o‘chirish');
    await tapText(tester, 'Ha, o‘chirish');
    expect(state.st.xp, 0);

    // Bildirishnoma yopilishini kutamiz / ждём, пока скроется уведомление
    await tester.pump(const Duration(seconds: 4));
  });
}
