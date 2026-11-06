// Ekran rasmlari (faqat CI uchun): SCREENSHOTS_DIR o‘rnatilganda ishlaydi.
// Скриншоты экранов (только для CI): работает, если задан SCREENSHOTS_DIR.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodla/main.dart';
import 'package:kodla/screens/lesson.dart' show openLesson;
import 'package:kodla/state.dart';
import 'package:shared_preferences/shared_preferences.dart';

final String? _dir = Platform.environment['SCREENSHOTS_DIR'];
final _shotKey = GlobalKey();

Future<void> _loadFonts() async {
  Future<void> fam(String family, List<String> files) async {
    final l = FontLoader(family);
    for (final f in files) {
      l.addFont(rootBundle.load(f));
    }
    await l.load();
  }

  await fam('Manrope', [for (final w in [400, 600, 700, 800]) 'assets/fonts/Manrope-$w.ttf']);
  await fam('JetBrainsMono', ['assets/fonts/JetBrainsMono-400.ttf', 'assets/fonts/JetBrainsMono-700.ttf']);
  await fam('Unbounded', ['assets/fonts/Unbounded-800.ttf']);
  final root = Platform.environment['FLUTTER_ROOT'] ?? '';
  final icons = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final l = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await l.load();
  }
}

Future<void> shot(WidgetTester t, String name) async {
  await t.pump(const Duration(milliseconds: 900));
  // Rasmlarni yuklab olish / дождаться загрузки картинок
  await t.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      final w = e.widget as Image;
      try {
        await precacheImage(w.image, e);
      } catch (_) {}
    }
  });
  await t.pump(const Duration(milliseconds: 100));
  await t.runAsync(() async {
    final b = _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$_dir/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
  });
}

Future<void> settle(WidgetTester t, [int ms = 700]) async {
  await t.pump();
  await t.pump(Duration(milliseconds: ms));
}

Future<void> tapKey(WidgetTester t, Key key) async {
  final f = find.byKey(key);
  await t.ensureVisible(f.last);
  await t.pump(const Duration(milliseconds: 1300));
  await t.tap(f.last);
  await settle(t);
}

bool has(Key k) => find.byKey(k).evaluate().isNotEmpty;
String sol(WidgetTester t) => t.widgetList<Text>(find.byKey(const ValueKey('test-solution'))).last.data!;

Future<void> answer(WidgetTester t, String s) async {
  if (s.startsWith('opt:')) {
    await tapKey(t, ValueKey('opt-${s.substring(4)}'));
  } else if (s.startsWith('fill:')) {
    await t.enterText(find.byKey(const ValueKey('fill-input')), s.substring(5));
  } else if (s.startsWith('order:')) {
    for (var k = 0; k < int.parse(s.substring(6)); k++) {
      await tapKey(t, ValueKey('order-line-$k'));
    }
  } else {
    await t.enterText(
        find.descendant(of: find.byKey(const ValueKey('code-editor')), matching: find.byType(TextField)), s.substring(4));
  }
  await t.pump();
  FocusManager.instance.primaryFocus?.unfocus();
  await settle(t);
}

void main() {
  testWidgets('screenshots', (t) async {
    SharedPreferences.setMockInitialValues({});
    await _loadFonts();
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);

    final state = AppState()
      ..allowWarmUp = false
      ..testMode = true;
    await t.pumpWidget(RepaintBoundary(key: _shotKey, child: KodlaApp(state: state)));
    await state.init();
    await settle(t, 900);
    await shot(t, '01-auth');

    await tapKey(t, const ValueKey('go-offline'));
    await shot(t, '02-profile-setup');
    await tapKey(t, const ValueKey('photo-pick'));
    await t.enterText(find.descendant(of: find.byKey(const ValueKey('f-name')), matching: find.byType(TextField)), 'Aziza Karimova');
    await tapKey(t, const ValueKey('school-region'));
    await shot(t, '02a-region-list');
    await tapKey(t, const ValueKey('pick-Andijon viloyati'));
    await tapKey(t, const ValueKey('school-district'));
    await tapKey(t, const ValueKey('pick-Asaka'));
    await t.enterText(find.descendant(of: find.byKey(const ValueKey('school-number')), matching: find.byType(TextField)), '45');
    await t.pump();
    await shot(t, '02b-school-number');
    FocusManager.instance.primaryFocus?.unfocus();
    await tapKey(t, const ValueKey('setup-save'));
    await settle(t, 900);
    await shot(t, '03-warmup-gate');
    await tapKey(t, const ValueKey('test-start'));
    await shot(t, '04-warmup-question');

    // Isinishni oxirigacha / разминку до конца
    for (var g = 0; g < 30 && !has(const ValueKey('placement-finish')); g++) {
      if (has(const ValueKey('test-solution'))) {
        await answer(t, sol(t));
        await tapKey(t, const ValueKey('step-check'));
      }
      if (has(const ValueKey('step-next'))) await tapKey(t, const ValueKey('step-next'));
      await settle(t);
    }
    await shot(t, '05-warmup-done');
    await tapKey(t, const ValueKey('placement-finish'));
    await settle(t, 1200);
    await shot(t, '05a-reminder-evening');
    await tapKey(t, const ValueKey('preset-450'));
    await settle(t, 900);
    await shot(t, '05b-reminder-morning');
    await t.drag(find.byKey(const ValueKey('wheel-hour')), const Offset(0, -150));
    await settle(t, 1200);
    await shot(t, '05c-reminder-wheel');
    await tapKey(t, const ValueKey('reminder-save'));
    await settle(t, 1200);
    await shot(t, '06-home');
    await t.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await settle(t, 1200);
    await shot(t, '07-home-scrolled');

    state.go('courses');
    await settle(t, 900);
    await shot(t, '08-courses');
    state.pickCourse('ai');
    await settle(t, 900);
    await shot(t, '09-courses-ai');
    state.pickCourse('html');
    await settle(t);

    await tapKey(t, const ValueKey('lesson-html1'));
    await shot(t, '10-lesson-gate');
    await tapKey(t, const ValueKey('test-start'));
    await shot(t, '11-lesson-read');

    var n = 12, helperShown = false, orderShown = false;
    for (var g = 0; g < 40 && find.text('Dars tugadi!').evaluate().isEmpty; g++) {
      if (!has(const ValueKey('test-solution'))) {
        if (has(const ValueKey('step-next'))) await tapKey(t, const ValueKey('step-next'));
        await settle(t);
        continue;
      }
      final s = sol(t);
      if (s.startsWith('opt:') && !helperShown) {
        await shot(t, '${n++}-lesson-quiz');
        final right = int.parse(s.substring(4));
        await tapKey(t, ValueKey('opt-${right == 0 ? 1 : 0}'));
        await tapKey(t, const ValueKey('step-check'));
        await shot(t, '${n++}-lesson-wrong');
        await tapKey(t, const ValueKey('helper-btn'));
        await settle(t, 900);
        await shot(t, '${n++}-ai-helper');
        await tapKey(t, const ValueKey('helper-ok'));
        helperShown = true;
      }
      if (s.startsWith('order:') && !orderShown) {
        await shot(t, '${n++}-lesson-order');
        orderShown = true;
      }
      if (s.startsWith('try:')) await shot(t, '${n++}-lesson-try');
      await answer(t, s);
      await tapKey(t, const ValueKey('step-check'));
      if (s.startsWith('fill:') || s.startsWith('order:')) await shot(t, '${n++}-lesson-correct');
      await tapKey(t, const ValueKey('step-next'));
      await settle(t);
    }
    await settle(t, 1500);
    await shot(t, '${n++}-lesson-done');
    await tapKey(t, const ValueKey('lesson-back'));

    // Animatsiyalar / анимации
    for (final id in ['html3', 'css4', 'css6', 'js4', 'py5', 'py6', 'ai2', 'ai3', 'aiA2']) {
      openLesson(state.navigatorKey.currentContext!, id);
      await settle(t, 900);
      await tapKey(t, const ValueKey('test-start'));
      for (var g = 0; g < 6 && !has(const ValueKey('anim-player')); g++) {
        await tapKey(t, const ValueKey('step-next'));
      }
      for (var k = 0; k < 3; k++) {
        if (has(const ValueKey('anim-next'))) await tapKey(t, const ValueKey('anim-next'));
      }
      await settle(t, 1200);
      await shot(t, '${n++}-anim-$id');
      await tapKey(t, const ValueKey('lesson-close'));
      await tapKey(t, const ValueKey('quit-yes'));
      await settle(t, 1500);
    }

    state.go('shop');
    await settle(t, 1200);
    await shot(t, '${n++}-shop');
    await t.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await settle(t, 1200);
    await shot(t, '${n++}-shop-scrolled');
    await tapKey(t, const ValueKey('shop-backpack'));
    await settle(t, 900);
    await shot(t, '${n++}-shop-backpack');
    await t.tapAt(const Offset(30, 60));
    await settle(t);

    state.go('ranking');
    await settle(t, 900);
    await shot(t, '${n++}-ranking-offline');
    state.go('profile');
    await settle(t, 900);
    await shot(t, '${n++}-profile');

    state.toggleTheme();
    await settle(t, 900);
    state.go('home');
    await settle(t, 1200);
    await shot(t, '${n++}-home-dark');
    state.go('shop');
    await settle(t, 1200);
    await shot(t, '${n++}-shop-dark');
    state.toggleLang();
    state.go('courses');
    await settle(t, 900);
    await tapKey(t, const ValueKey('lesson-html2'));
    await shot(t, '${n++}-lesson-gate-dark-ru');
    await t.pump(const Duration(seconds: 4));
  }, skip: _dir == null);
}
