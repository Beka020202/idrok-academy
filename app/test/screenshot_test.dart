// Ekran rasmlari (faqat CI uchun): SCREENSHOTS_DIR o‘rnatilganda ishlaydi.
// Скриншоты экранов (только для CI): работает, если задан SCREENSHOTS_DIR.

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kodla/api.dart';
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

  testWidgets('staff screenshots', (t) async {
    SharedPreferences.setMockInitialValues({});
    await _loadFonts();
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    var role = 'teacher';
    final students = [
      for (final (n, x, lg) in [('Aziza Karimova', 340, 'master'), ('Bekzod Aliyev', 260, 'advanced'), ('Laylo Tosheva', 180, 'beginner')])
        {
          'username': n.split(' ').first.toLowerCase(), 'name': n, 'school': '45-maktab', 'district': 'Asaka',
          'region': 'Andijon viloyati', 'league': lg, 'xp': x, 'xp_total': x + 100, 'week_xp': x ~/ 3, 'level': 3,
          'streak': 4, 'done': ['html1', 'html2', 'css1'], 'last_day': '2026-11-02', 'has_photo': false,
        }
    ];
    Map<String, Object?> user() => {
          'username': role, 'name': role == 'admin' ? 'Behruz' : 'Dilnoza Karimova', 'role': role, 'school': '45-maktab',
          'district': 'Asaka', 'region': 'Andijon viloyati', 'league': '', 'has_photo': false, 'state': {},
        };
    final tests = [
      {
        'id': 1, 'title': 'Sikllar bo‘yicha test', 'text': '', 'active': true, 'mine': true, 'submitted': 12, 'avg': 78,
        'questions': [
          {'type': 'quiz', 'q': 'for sikli nima qiladi?', 'options': ['Takrorlaydi', 'To‘xtatadi'], 'answer': 0},
          {'type': 'fill', 'q': 'Ekranga chiqarish buyrug‘i?', 'answers': ['print']},
        ],
      }
    ];
    Api.client = MockClient((req) async {
      final p = req.url.path;
      Object body = {'rows': []};
      if (p == '/api/login') body = {'token': 'tok', 'user': user()};
      if (p == '/api/teacher/students' || p == '/api/admin/students') body = {'rows': students, 'lessons': []};
      if (p == '/api/leaderboard') body = {'rows': students, 'league': 'beginner', 'scope': 'school', 'period': 'week'};
      if (p == '/api/teacher/tests') body = {'rows': tests};
      if (p == '/api/teacher/results') {
        body = {'rows': [for (final s in students) {...s, 'correct': 2, 'best': 2, 'total': 2, 'tries': 1}], 'test': tests.first};
      }
      if (p == '/api/admin/codes' && req.method == 'GET') {
        body = {
          'rows': [
            {'code': 'IDR-7K4P-9QX2', 'school': '45-maktab', 'district': 'Asaka', 'region': 'Andijon viloyati', 'note': 'Karimova D.', 'used_by': 'Dilnoza Karimova'},
            {'code': 'IDR-M3TZ-2HRW', 'school': '12-maktab', 'district': 'Asaka', 'region': 'Andijon viloyati', 'note': '+998 90 …', 'used_by': ''},
          ]
        };
      }
      if (p == '/api/admin/codes' && req.method == 'POST') body = {'code': 'IDR-Q8VN-5JKD'};
      if (p == '/api/admin/orders') {
        body = {
          'rows': [
            {'id': 1, 'item_id': 'backpack', 'price': 25000, 'status': 'new', 'ts': 1793600000, 'username': 'aziza', 'name': 'Aziza Karimova', 'school': '45-maktab', 'city': 'Asaka'},
            {'id': 2, 'item_id': 'mug', 'price': 6000, 'status': 'delivered', 'ts': 1793500000, 'username': 'bekzod', 'name': 'Bekzod Aliyev', 'school': '12-maktab', 'city': 'Asaka'},
          ]
        };
      }
      return http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json; charset=utf-8'});
    });
    addTearDown(() => Api.client = http.Client());

    final state = AppState()
      ..allowWarmUp = false
      ..testMode = true;
    await t.pumpWidget(RepaintBoundary(key: _shotKey, child: KodlaApp(state: state)));
    await state.init();
    await settle(t, 900);
    await t.tap(find.text('Ro‘yxatdan o‘tish').first);
    await settle(t, 900);
    await t.tap(find.text('Ustoz').first);
    await settle(t, 900);
    await shot(t, '40-register-teacher');

    await t.runAsync(() => state.auth(register: false, username: 'teacher', password: '1234', serverUrl: 'http://test'));
    await settle(t, 1500);
    await shot(t, '41-teacher-school');
    state.go('tests');
    await settle(t, 1200);
    await shot(t, '42-teacher-tests');
    await tapKey(t, const ValueKey('test-1'));
    await settle(t, 1200);
    await shot(t, '43-test-results');
    await t.pageBack();
    await settle(t, 900);
    await tapKey(t, const ValueKey('test-new'));
    await settle(t, 900);
    await shot(t, '44-test-editor');
    await t.pageBack();
    await settle(t, 900);
    state.go('ranking');
    await settle(t, 1200);
    await shot(t, '45-teacher-ranking');

    await state.logout();
    await settle(t, 900);
    role = 'admin';
    await t.runAsync(() => state.auth(register: false, username: 'admin', password: '1234', serverUrl: 'http://test'));
    await settle(t, 1500);
    await shot(t, '46-admin-codes');
    await tapKey(t, const ValueKey('school-region'));
    await tapKey(t, const ValueKey('pick-Andijon viloyati'));
    await tapKey(t, const ValueKey('school-district'));
    await tapKey(t, const ValueKey('pick-Asaka'));
    await t.enterText(find.descendant(of: find.byKey(const ValueKey('school-number')), matching: find.byType(TextField)), '12');
    FocusManager.instance.primaryFocus?.unfocus();
    await tapKey(t, const ValueKey('code-make'));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await settle(t, 1200);
    await shot(t, '47-admin-new-code');
    await t.tapAt(const Offset(30, 60));
    await settle(t, 900);
    state.go('orders');
    await settle(t, 1200);
    await shot(t, '48-admin-orders');
    await t.pump(const Duration(seconds: 4));
  }, skip: _dir == null);
}
