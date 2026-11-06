import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'config.dart';
import 'i18n.dart';
import 'lessons.dart';
import 'progress.dart';
import 'theme.dart';
import 'widgets.dart' show AppRoute, AppToast, PageShell;

const String _prefsKey = 'kodla.prefs';

/// Do‘kon mahsuloti / товар магазина.
class ShopItem {
  final String id;
  final int price;
  final Tr name, desc;
  const ShopItem(this.id, this.price, this.name, this.desc);
  String get image => 'assets/shop/$id.png';

  factory ShopItem.fromJson(Map<String, dynamic> j) {
    Tr tr(Object? v) => v is Map ? Tr('${v['uz'] ?? ''}', '${v['ru'] ?? v['uz'] ?? ''}') : const Tr('', '');
    return ShopItem('${j['id']}', (j['price'] as num?)?.toInt() ?? 0, tr(j['name']), tr(j['desc']));
  }
}

/// Buyurtma / заказ.
class ShopOrder {
  final int id, price;
  final String itemId, status;
  final double ts;
  final String name, school, city, username;
  const ShopOrder(this.id, this.itemId, this.price, this.status, this.ts,
      {this.name = '', this.school = '', this.city = '', this.username = ''});
  factory ShopOrder.fromJson(Map<String, dynamic> j) => ShopOrder(
        (j['id'] as num?)?.toInt() ?? 0,
        '${j['item_id']}',
        (j['price'] as num?)?.toInt() ?? 0,
        '${j['status']}',
        (j['ts'] as num?)?.toDouble() ?? 0,
        name: '${j['name'] ?? ''}',
        school: '${j['school'] ?? ''}',
        city: '${j['city'] ?? ''}',
        username: '${j['username'] ?? ''}',
      );
}

/// Ilovaning butun holati / всё состояние приложения.
class AppState extends ChangeNotifier {
  final navigatorKey = GlobalKey<NavigatorState>();
  final _rand = Random();

  SharedPreferences? _sp;
  bool ready = false;

  /// Ochilish videosi tugadimi / закончилось ли вступительное видео.
  bool introDone = false;

  /// Testlarda: video, tarmoq va qurilma funksiyalari o‘chiriladi.
  /// В тестах: видео, сеть и функции устройства отключены.
  bool testMode = false;

  // Sozlamalar / настройки (qurilmada saqlanadi / хранятся на устройстве)
  String lang = 'uz';
  String theme = 'system'; // system | light | dark
  Brightness platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
  String server = kDefaultServer;
  String token = '';
  String mode = ''; // '' | online | offline
  Map<String, dynamic> offlineState = {};
  String courseId = 'html';

  // Oflayn profil / офлайн-профиль
  String localName = '', localSchool = '', localCity = '', localRegion = '';

  /// Eslatma vaqti (daqiqada, -1 — o‘chirilgan) / время напоминания (минуты, -1 — выкл.)
  int reminderMinutes = -1;
  bool reminderAsked = false;

  /// Saqlangan dars xulosalari / сохранённые карточки-конспекты.
  List<String> savedCards = [];

  /// Portfolio loyihalari: kurs → kod, kurs → havola / проекты портфолио: курс → код, курс → ссылка.
  Map<String, String> projects = {};
  Map<String, String> projectLinks = {};

  /// O‘z rasmim (kesh) / моё фото (кэш)
  Uint8List? myPhoto;

  Map<String, dynamic>? user; // serverdagi foydalanuvchi / пользователь сервера
  GameState st = normalize(null);
  late Api api;
  String tab = 'home';
  String bootError = '';
  bool busy = false; // so‘rov ketmoqda / идёт запрос

  // Mashq maydoni / песочница
  String playCode = kPlaygroundStart;
  String playInputs = '5';
  String playOut = '';

  // Do‘kon / магазин
  List<ShopItem> shopItems = [];

  /// Test bekor qilinganini qaytganda ko‘rsatish / показать при возврате, что тест отменён.
  String pendingNotice = '';

  // ---------------------------------------------------------------- yordamchilar / помощники
  bool get online => user != null;
  String get role => online ? '${user!['role'] ?? 'student'}' : 'student';
  bool get isTeacher => role == 'teacher';
  bool get isAdmin => role == 'admin';
  bool get isStudent => role == 'student';

  /// Ustoz yoki admin — o‘qimaydi / учитель или админ — не учится.
  bool get isStaff => isTeacher || isAdmin;
  bool get isDark => theme == 'dark' || (theme == 'system' && platformBrightness == Brightness.dark);
  AppColors get c => isDark ? kDark : kLight;

  String t(String key) => (kStrings[lang]![key] ?? kStrings['uz']![key] ?? key) as String;
  List<String> tl(String key) => (kStrings[lang]![key] as List).cast<String>();
  String tr(Tr v) => v.of(lang);
  String pick(String key) {
    final l = tl(key);
    return l[_rand.nextInt(l.length)];
  }

  String get displayName {
    if (online) {
      final n = '${user!['name'] ?? ''}';
      return n.isNotEmpty ? n : '${user!['username'] ?? ''}';
    }
    return localName;
  }

  String get school => online ? '${user!['school'] ?? ''}' : localSchool;
  String get city => online ? '${user!['district'] ?? user!['city'] ?? ''}' : localCity;
  String get region => online ? '${user!['region'] ?? ''}' : localRegion;
  String get district => city;
  String get username => online ? '${user!['username'] ?? ''}' : '';
  String get league => st.league;
  String get leagueName => tr(kLeagueNames[st.league] ?? kLeagueNames['beginner']!);

  /// Oflayn rejimda profil hali to‘ldirilmagan / офлайн-профиль ещё не заполнен.
  bool get needsProfile =>
      (!online && mode == 'offline' && (localName.trim().isEmpty || localRegion.isEmpty)) ||
      (online && isStudent && region.isEmpty);

  /// Isinish mashqi (liga aniqlash) kerak / нужна разминка (определение лиги).
  bool get needsPlacement => isStudent && st.league.isEmpty;

  /// Isinishdan keyin eslatma vaqtini so‘rash / после разминки спросить время напоминания.
  bool get needsReminder => isStudent && !reminderAsked;

  /// Boshqa o‘quvchi rasmi manzili / адрес фото другого ученика.
  String photoUrl(String user) => '${api.base}/api/photo/${Uri.encodeComponent(user)}';
  Map<String, String> get authHeaders => token.isEmpty ? const {} : {'Authorization': 'Bearer $token'};

  Course get course => kCourses.firstWhere((x) => x.id == courseId, orElse: () => kCourses.first);
  List<Lesson> lessonsOf(Course co) => co.lessonsFor(st.league);
  int progressOf(Course co) => lessonsOf(co).where((l) => st.isDone(l.id)).length;
  Lesson? nextLesson(Course co) {
    for (final l in lessonsOf(co)) {
      if (!st.isDone(l.id)) return l;
    }
    return null;
  }

  bool unlocked(Course co, int i) {
    final ls = lessonsOf(co);
    return i == 0 || st.isDone(ls[i - 1].id);
  }

  List<String> get tabs => isAdmin
      ? ['admin', 'orders', 'teacher', 'ranking', 'profile']
      : isTeacher
          ? ['teacher', 'tests', 'ranking', 'profile']
          : ['home', 'ranking', 'profile'];

  /// Yuqoridan chiquvchi bildirishnoma / всплывающее уведомление сверху.
  void toast(String text, {IconData icon = Icons.info_rounded}) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    AppToast.show(overlay, text, icon: icon);
  }

  // ---------------------------------------------------------------- saqlash / сохранение
  Future<void> init() async {
    try {
      _sp = await SharedPreferences.getInstance();
      final raw = _sp!.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) _loadPrefs(jsonDecode(raw));
    } catch (_) {
      // buzilgan sozlamalar — standart qiymatlar bilan / повреждённые настройки — по умолчанию
    }
    api = Api(server, token: token.isEmpty ? null : token);
    st = normalize(offlineState);
    await loadShop();
    if (mode == 'online' && token.isNotEmpty && !testMode) {
      try {
        final res = await api.call('/api/me');
        _setUser(res['user']);
      } on ApiError catch (e) {
        user = null;
        if (e.code == 'auth') {
          token = '';
          mode = '';
        } else {
          bootError = t('err_conn');
        }
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<void> loadShop() async {
    try {
      final raw = await rootBundle.loadString('assets/content/shop.json');
      shopItems = [for (final j in jsonDecode(raw) as List) ShopItem.fromJson(Map<String, dynamic>.from(j as Map))];
    } catch (_) {
      shopItems = [];
    }
  }

  ShopItem? shopItem(String id) {
    for (final i in shopItems) {
      if (i.id == id) return i;
    }
    return null;
  }

  void _loadPrefs(Object? raw) {
    if (raw is! Map) return;
    final Map j = raw;
    String s(String k, String d) => j[k] is String ? j[k] as String : d;
    lang = s('lang', 'uz') == 'ru' ? 'ru' : 'uz';
    final th = s('theme', 'system');
    theme = const ['system', 'light', 'dark'].contains(th) ? th : 'system';
    server = s('server', kDefaultServer);
    if (server.trim().isEmpty) server = kDefaultServer;
    token = s('token', '');
    mode = s('mode', '');
    courseId = s('course', 'html');
    localName = s('name', '');
    localSchool = s('school', '');
    localCity = s('city', '');
    localRegion = s('region', '');
    reminderMinutes = j['reminder'] is int ? j['reminder'] as int : -1;
    reminderAsked = j['reminder_asked'] == true;
    savedCards = j['cards'] is List ? [for (final x in j['cards'] as List) '$x'] : [];
    Map<String, String> strMap(Object? v) => v is Map ? {for (final e in v.entries) '${e.key}': '${e.value}'} : {};
    projects = strMap(j['projects']);
    projectLinks = strMap(j['project_links']);
    final ph = s('photo', '');
    if (ph.isNotEmpty) {
      try {
        myPhoto = base64Decode(ph);
      } catch (_) {}
    }
    final os = j['offline_state'];
    offlineState = os is Map ? Map<String, dynamic>.from(os) : {};
  }

  Future<void> savePrefs() async {
    if (!online) offlineState = st.toJson();
    final data = {
      'lang': lang,
      'theme': theme,
      'server': server,
      'token': token,
      'mode': mode,
      'offline_state': offlineState,
      'course': courseId,
      'name': localName,
      'school': localSchool,
      'city': localCity,
      'region': localRegion,
      'reminder': reminderMinutes,
      'reminder_asked': reminderAsked,
      'cards': savedCards,
      'projects': projects,
      'project_links': projectLinks,
      'photo': myPhoto == null ? '' : base64Encode(myPhoto!),
    };
    try {
      _sp ??= await SharedPreferences.getInstance();
      await _sp!.setString(_prefsKey, jsonEncode(data));
    } catch (_) {}
  }

  void _setUser(Object? u) {
    if (u is! Map) return;
    user = Map<String, dynamic>.from(u);
    st = normalize(user!['state']);
    final lg = '${user!['league'] ?? ''}';
    if (lg.isNotEmpty) st.league = lg;
  }

  // ---------------------------------------------------------------- kirish / вход
  /// Xato matnini qaytaradi yoki null / возвращает текст ошибки или null.
  Future<String?> auth({
    required bool register,
    required String username,
    required String password,
    required String serverUrl,
    String name = '',
    String school = '',
    String city = '',
    String region = '',
    String code = '',
    Uint8List? photo,
  }) async {
    if (username.trim().length < 3 || password.length < 4) return t('err_short');
    final asTeacher = code.trim().isNotEmpty;
    if (register) {
      if (name.trim().isEmpty) return t('err_profile');
      if (!asTeacher) {
        if (school.trim().isEmpty || city.trim().isEmpty || region.trim().isEmpty) return t('err_school');
        if (photo == null) return t('err_photo');
      }
    }
    if (busy) return null;
    busy = true;
    notifyListeners();
    final srv = serverUrl.trim().isEmpty ? kDefaultServer : serverUrl.trim();
    final a = Api(srv);
    try {
      final res = await a.call(
          register ? '/api/register' : '/api/login',
          {
            'username': username.trim(),
            'password': password,
            if (register) ...{
              'name': name.trim(),
              if (asTeacher) 'code': code.trim().toUpperCase(),
              if (!asTeacher) ...{'region': region, 'district': city, 'school': school},
              if (photo != null) 'photo': base64Encode(photo),
            },
          },
          const Duration(seconds: 40));
      a.token = '${res['token']}';
      api = a;
      server = srv;
      token = a.token!;
      mode = 'online';
      bootError = '';
      tab = 'home';
      myPhoto = register ? photo : null;
      tab = 'home';
      _setUser(res['user']);
      if (tabs.isNotEmpty) tab = tabs.first;
      await savePrefs();
      return null;
    } on ApiError catch (e) {
      return t(switch (e.code) {
        'conn' => 'err_conn',
        'taken' => 'err_taken',
        'short' => 'err_short',
        'photo' => 'err_photo',
        'profile' => 'err_profile',
        'code' => 'err_code',
        _ => 'err_auth'
      });
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> goOffline() async {
    user = null;
    mode = 'offline';
    token = '';
    bootError = '';
    st = normalize(offlineState);
    tab = 'home';
    await savePrefs();
    notifyListeners();
  }

  Future<void> logout() async {
    if (online) {
      api.call('/api/logout', {}).then((_) {}, onError: (_) {});
    }
    user = null;
    mode = '';
    token = '';
    bootError = '';
    st = normalize(offlineState);
    tab = 'home';
    await savePrefs();
    notifyListeners();
  }

  // ---------------------------------------------------------------- profil / профиль
  /// Oflayn profilni saqlash / сохранить офлайн-профиль.
  Future<void> saveLocalProfile(
      {required String name, required String school, required String city, String region = '', Uint8List? photo}) async {
    localName = name.trim().length > 40 ? name.trim().substring(0, 40) : name.trim();
    localSchool = school.trim();
    localCity = city.trim();
    localRegion = region.trim();
    if (photo != null) myPhoto = photo;
    await savePrefs();
    notifyListeners();
  }

  /// Ism, maktab, shahar / имя, школа, город.
  Future<void> updateProfile({String? name, String? school, String? city, String? region}) async {
    if (online) {
      try {
        final res = await api.call('/api/profile', {
          if (name != null) 'name': name.trim(),
          if (school != null) 'school': school.trim(),
          if (city != null) 'district': city.trim(),
          if (region != null) 'region': region.trim(),
        });
        _setUser(res['user']);
      } on ApiError {
        toast(t('err_conn'), icon: Icons.cloud_off_rounded);
      }
    } else {
      if (name != null && name.trim().isNotEmpty) localName = name.trim();
      if (school != null) localSchool = school.trim();
      if (city != null) localCity = city.trim();
      if (region != null) localRegion = region.trim();
      await savePrefs();
    }
    notifyListeners();
  }

  /// Profil rasmini yangilash / обновить фото профиля.
  Future<bool> updatePhoto(Uint8List bytes) async {
    if (online) {
      try {
        final res = await api.call('/api/photo', {'photo': base64Encode(bytes)}, const Duration(seconds: 40));
        _setUser(res['user']);
      } on ApiError {
        toast(t('err_conn'), icon: Icons.cloud_off_rounded);
        return false;
      }
    }
    myPhoto = bytes;
    PaintingBinding.instance.imageCache.clear();
    await savePrefs();
    notifyListeners();
    return true;
  }

  // ---------------------------------------------------------------- o‘yin amallari / игровые действия
  /// Onlayn — serverga, oflayn — shu yerda / онлайн — на сервер, офлайн — локально.
  Future<Map<String, dynamic>?> _serverOrLocal(
      String path, Map<String, Object?> payload, Map<String, dynamic> Function() local,
      {bool quiet = false}) async {
    if (online) {
      try {
        final res = await api.call(path, payload);
        _setUser(res['user']);
        notifyListeners();
        return res;
      } on ApiError catch (e) {
        if (!quiet) {
          if (e.code == 'auth') {
            toast(t('err_auth'), icon: Icons.lock_rounded);
          } else if (e.code == 'not_enough') {
            toast(t('not_enough'), icon: Icons.bolt_rounded);
          } else {
            toast(e.code == 'conn' ? t('err_conn') : t('error'), icon: Icons.cloud_off_rounded);
          }
        }
        return null;
      }
    }
    final res = local();
    await savePrefs();
    notifyListeners();
    return res;
  }

  Future<void> claim(String questId) async {
    if (busy) return;
    busy = true;
    final res = await _serverOrLocal('/api/claim', {'quest_id': questId}, () {
      final (s, x) = claimQuest(st, questId);
      st = s;
      return {'xp': x};
    });
    busy = false;
    final x = (res?['xp'] as num?)?.toInt() ?? 0;
    if (x > 0) toast('+$x XP', icon: Icons.bolt_rounded);
    notifyListeners();
  }

  Future<void> chest(Course co) async {
    if (busy) return;
    busy = true;
    final res = await _serverOrLocal('/api/chest', {'course_id': co.id}, () {
      final (s, x) = openChest(st, co.id, co.idsFor(st.league));
      st = s;
      return {'xp': x};
    });
    busy = false;
    final x = (res?['xp'] as num?)?.toInt() ?? 0;
    if (x > 0) toast('${t('chest')}: +$x XP', icon: Icons.redeem_rounded);
    notifyListeners();
  }

  /// Isinish mashqi natijasi -> liga / результат разминки -> лига.
  Future<void> submitPlacement(int points, double timeShare) async {
    final league = leagueFor(points, timeShare);
    final res = await _serverOrLocal('/api/placement', {'points': points, 'time_share': timeShare, 'league': league}, () {
      final (s, x) = setLeague(st, league);
      st = s;
      return {'xp': x};
    });
    if (res == null && online) {
      // Server javob bermasa, vaqtincha mahalliy / если сервер не ответил — временно локально
      final (s, _) = setLeague(st, league);
      st = s;
    }
    notifyListeners();
  }

  /// Test bekor qilindi (ilovadan chiqildi) / тест отменён (вышли из приложения).
  Future<void> cancelLessonTest(Lesson l) async {
    pendingNotice = t('test_cancelled');
    await _serverOrLocal('/api/cancel', {'lesson_id': l.id}, () {
      st = cancelTest(st, l.id);
      return {};
    }, quiet: true);
    if (online && (st.retries[l.id] ?? 0) == 0) st = cancelTest(st, l.id);
    notifyListeners();
  }

  /// AI yordamchidan foydalanish (XP sarflanadi) / использование AI-помощника (тратит XP).
  Future<bool> payForHelper() async {
    if (st.xp < kHelperCost) {
      toast(t('not_enough'), icon: Icons.bolt_rounded);
      return false;
    }
    final res = await _serverOrLocal('/api/helper', {}, () {
      final (s, ok) = spendXp(st, kHelperCost);
      st = s;
      return {'ok': ok};
    });
    return res != null && (res['ok'] ?? true) != false;
  }

  /// null — saqlab bo‘lmadi / не удалось сохранить.
  Future<LessonResult?> finishLesson(Lesson l,
      {required bool perfect, required int bestCombo, required int correct, required int total, required double timeShare}) async {
    final res = await _serverOrLocal('/api/complete', {
      'lesson_id': l.id,
      'perfect': perfect,
      'best_combo': bestCombo,
      'correct': correct,
      'total': total,
      'time_share': timeShare,
    }, () {
      final (s, r) = completeLesson(st, l.id, l.xp,
          perfect: perfect, bestCombo: bestCombo, correct: correct, total: total, timeShare: timeShare);
      st = s;
      return {
        'result': {'xp': r.xp, 'first': r.first, 'perfect': r.perfect, 'level_up': r.levelUp, 'level': r.level}
      };
    });
    if (res == null) return null;
    return LessonResult.fromJson(res['result']);
  }

  // ---------------------------------------------------------------- do‘kon / магазин
  /// Sotib olish (faqat onlayn — haqiqiy sovg‘alar) / покупка (только онлайн — реальные призы).
  Future<bool> buy(ShopItem item) async {
    if (!online) {
      toast(t('shop_online'), icon: Icons.wifi_off_rounded);
      return false;
    }
    if (st.xp < item.price) {
      toast(t('not_enough'), icon: Icons.bolt_rounded);
      return false;
    }
    if (busy) return false;
    busy = true;
    notifyListeners();
    try {
      final res = await api.call('/api/shop/buy', {'item_id': item.id});
      _setUser(res['user']);
      toast(t('order_done'), icon: Icons.check_circle_rounded);
      return true;
    } on ApiError catch (e) {
      toast(e.code == 'not_enough' ? t('not_enough') : t('err_conn'), icon: Icons.cloud_off_rounded);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<List<ShopOrder>> myOrders() async {
    if (!online) return [];
    final res = await api.call('/api/orders');
    final rows = res['rows'];
    return rows is List ? [for (final r in rows) if (r is Map) ShopOrder.fromJson(Map<String, dynamic>.from(r))] : [];
  }

  Future<List<ShopOrder>> teacherOrders() async {
    final res = await api.call('/api/admin/orders');
    final rows = res['rows'];
    return rows is List ? [for (final r in rows) if (r is Map) ShopOrder.fromJson(Map<String, dynamic>.from(r))] : [];
  }

  Future<bool> setOrderStatus(int id, String status) async {
    try {
      await api.call('/api/admin/order', {'order_id': id, 'status': status});
      return true;
    } on ApiError {
      toast(t('err_conn'), icon: Icons.cloud_off_rounded);
      return false;
    }
  }

  // ---------------------------------------------------------------- ustoz va admin / учитель и админ
  /// Ro‘yxat so‘rovi (xato bo‘lsa — null) / запрос списка (null при ошибке).
  Future<List<Map<String, dynamic>>?> fetchRows(String path) async {
    try {
      final res = await api.call(path);
      final rows = res['rows'];
      return rows is List ? [for (final r in rows) if (r is Map) Map<String, dynamic>.from(r)] : [];
    } on ApiError {
      return null;
    }
  }

  /// Javob yoki null (xato bo‘lsa xabar chiqadi) / ответ или null (при ошибке — уведомление).
  Future<Map<String, dynamic>?> post(String path, Map<String, Object?> data) async {
    if (busy) return null;
    busy = true;
    notifyListeners();
    try {
      return await api.call(path, data);
    } on ApiError catch (e) {
      toast(e.code == 'conn' ? t('err_conn') : t('error'), icon: Icons.cloud_off_rounded);
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------- eslatma va konspekt / напоминание и конспект
  Future<void> setReminder(int minutes) async {
    reminderMinutes = minutes;
    reminderAsked = true;
    await savePrefs();
    notifyListeners();
  }

  bool isCardSaved(String lessonId) => savedCards.contains(lessonId);

  Future<void> toggleCard(String lessonId) async {
    if (savedCards.contains(lessonId)) {
      savedCards.remove(lessonId);
    } else {
      savedCards.add(lessonId);
    }
    await savePrefs();
    notifyListeners();
  }

  // ---------------------------------------------------------------- portfolio
  Future<void> saveProject(String course, String code) async {
    projects[course] = code;
    await savePrefs();
    notifyListeners();
  }

  /// Loyihani nashr qilish va havola olish (faqat onlayn) / опубликовать проект и получить ссылку.
  Future<String?> publishProject(String course, String mode, String title, String code) async {
    await saveProject(course, code);
    if (!online) {
      toast(t('project_online'), icon: Icons.wifi_off_rounded);
      return null;
    }
    final res = await post('/api/portfolio', {'course': course, 'mode': mode, 'title': title, 'code': code});
    if (res == null) return null;
    final link = '${api.base}${res['path']}';
    projectLinks[course] = link;
    await savePrefs();
    notifyListeners();
    return link;
  }

  Future<void> resetProgress() async {
    final lg = st.league;
    st = normalize(null);
    st.league = lg;
    await savePrefs();
    notifyListeners();
  }

  Future<RunResult> run(String code, {List<String> inputs = const []}) => runPython(server, code, inputs: inputs);

  /// Testlarda o‘chiriladi / отключается в тестах.
  bool allowWarmUp = true;

  void warmUp() {
    if (allowWarmUp && !testMode) warmUpRunner(server);
  }

  void finishIntro() {
    if (introDone) return;
    introDone = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------- sozlamalar / настройки
  /// Tab bo‘lmagan sahifalar (kurslar, do‘kon, kod maydoni) ustiga ochiladi.
  /// Страницы, которые не являются вкладками (курсы, магазин, песочница), открываются поверх.
  Widget Function(String id)? pageBuilder;

  void go(String name) {
    final nav = navigatorKey.currentState;
    nav?.popUntil((r) => r.isFirst);
    if (tabs.contains(name) || pageBuilder == null || nav == null) {
      tab = name;
      notifyListeners();
      return;
    }
    nav.push(AppRoute<void>(builder: (_) => PageShell(child: pageBuilder!(name))));
  }

  void setTheme(String m) {
    theme = const ['system', 'light', 'dark'].contains(m) ? m : 'system';
    savePrefs();
    notifyListeners();
  }

  void toggleTheme() => setTheme(isDark ? 'light' : 'dark');

  void toggleLang() {
    lang = lang == 'uz' ? 'ru' : 'uz';
    savePrefs();
    notifyListeners();
  }

  void pickCourse(String id, {bool open = false}) {
    courseId = id;
    if (open) tab = 'courses';
    savePrefs();
    notifyListeners();
  }

  /// Telefon mavzusi o‘zgarganda / при смене темы телефона.
  void setPlatformBrightness(Brightness b) {
    if (b == platformBrightness) return;
    platformBrightness = b;
    if (theme == 'system') notifyListeners();
  }

  /// Ekranga qaytganda kun almashgan bo‘lsa yangilaydi / обновляет, если сменился день.
  void refreshDay() {
    final n = normalize(st);
    if (n.todayDate != st.todayDate || n.streak != st.streak || n.quests.date != st.quests.date) {
      st = n;
      notifyListeners();
    }
  }
}

/// Holatni daraxt bo‘ylab uzatadi / передаёт состояние по дереву виджетов.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Qayta chizmasdan olish / получить без подписки на перерисовку.
  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
