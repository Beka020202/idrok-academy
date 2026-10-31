import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'config.dart';
import 'i18n.dart';
import 'lessons.dart';
import 'progress.dart';
import 'theme.dart';
import 'widgets.dart' show AppToast;

const String _prefsKey = 'kodla.prefs';

/// Ilovaning butun holati / всё состояние приложения.
class AppState extends ChangeNotifier {
  final navigatorKey = GlobalKey<NavigatorState>();
  final _rand = Random();

  SharedPreferences? _sp;
  bool ready = false;

  // Sozlamalar / настройки (diskda saqlanadi / хранятся на устройстве)
  String lang = 'uz';
  String theme = 'system'; // system | light | dark
  Brightness platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
  String server = kDefaultServer;
  String token = '';
  String mode = ''; // '' | online | offline
  Map<String, dynamic> offlineState = {};
  String courseId = 'html';
  String localName = '';

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

  // ---------------------------------------------------------------- yordamchilar / помощники
  bool get online => user != null;
  bool get isTeacher => online && user!['role'] == 'teacher';
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

  String get username => online ? '${user!['username'] ?? ''}' : '';

  Course get course => kCourses.firstWhere((x) => x.id == courseId, orElse: () => kCourses.first);
  int progressOf(Course co) => co.lessons.where((l) => st.isDone(l.id)).length;
  Lesson? nextLesson(Course co) {
    for (final l in co.lessons) {
      if (!st.isDone(l.id)) return l;
    }
    return null;
  }

  bool unlocked(Course co, int i) => i == 0 || st.isDone(co.lessons[i - 1].id);

  List<String> get tabs => ['home', 'courses', 'play', 'ranking', isTeacher ? 'teacher' : 'profile'];

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
      // buzilgan sozlamalar — standart qiymatlar bilan davom etamiz
      // повреждённые настройки — продолжаем со значениями по умолчанию
    }
    api = Api(server, token: token.isEmpty ? null : token);
    st = normalize(offlineState);
    if (mode == 'online' && token.isNotEmpty) {
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
  }

  // ---------------------------------------------------------------- kirish / вход
  /// Xato matnini qaytaradi yoki null / возвращает текст ошибки или null.
  Future<String?> auth({
    required bool register,
    required String username,
    required String password,
    required String name,
    required String serverUrl,
  }) async {
    if (username.trim().length < 3 || password.length < 4) return t('err_short');
    if (busy) return null;
    busy = true;
    notifyListeners();
    final srv = serverUrl.trim().isEmpty ? kDefaultServer : serverUrl.trim();
    final a = Api(srv);
    try {
      final res = await a.call(register ? '/api/register' : '/api/login',
          {'username': username.trim(), 'password': password, 'name': name.trim()});
      a.token = '${res['token']}';
      api = a;
      server = srv;
      token = a.token!;
      mode = 'online';
      bootError = '';
      tab = 'home';
      _setUser(res['user']);
      await savePrefs();
      return null;
    } on ApiError catch (e) {
      return t(switch (e.code) { 'conn' => 'err_conn', 'taken' => 'err_taken', 'short' => 'err_short', _ => 'err_auth' });
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

  // ---------------------------------------------------------------- o‘yin amallari / игровые действия
  /// Onlayn — serverga, oflayn — shu yerda / онлайн — на сервер, офлайн — локально.
  Future<Map<String, dynamic>?> _serverOrLocal(
      String path, Map<String, Object?> payload, Map<String, dynamic> Function() local) async {
    if (online) {
      try {
        final res = await api.call(path, payload);
        _setUser(res['user']);
        notifyListeners();
        return res;
      } on ApiError catch (e) {
        if (e.code == 'auth') {
          toast(t('err_auth'), icon: Icons.lock_rounded);
        } else {
          toast(e.code == 'conn' ? t('err_conn') : t('error'), icon: Icons.cloud_off_rounded);
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
      final (s, g) = claimQuest(st, questId);
      st = s;
      return {'gems': g};
    });
    busy = false;
    final g = (res?['gems'] as num?)?.toInt() ?? 0;
    if (g > 0) toast('+$g', icon: Icons.diamond_rounded);
    notifyListeners();
  }

  Future<void> chest(Course co) async {
    if (busy) return;
    busy = true;
    final res = await _serverOrLocal('/api/chest', {'course_id': co.id}, () {
      final (s, g) = openChest(st, co.id, co.lessonIds);
      st = s;
      return {'gems': g};
    });
    busy = false;
    final g = (res?['gems'] as num?)?.toInt() ?? 0;
    if (g > 0) toast('${t('chest')}: +$g', icon: Icons.redeem_rounded);
    notifyListeners();
  }

  Future<void> pickAvatar(String emoji) async {
    if (busy) return;
    if (!st.owned.contains(emoji) && st.gems < (kAvatars[emoji] ?? 0)) {
      toast(t('not_enough'), icon: Icons.diamond_rounded);
      return;
    }
    busy = true;
    await _serverOrLocal('/api/avatar', {'avatar': emoji}, () {
      final (s, ok) = buyAvatar(st, emoji);
      st = s;
      return {'ok': ok};
    });
    busy = false;
    notifyListeners();
  }

  /// null — saqlab bo‘lmadi / не удалось сохранить.
  Future<LessonResult?> finishLesson(Lesson l, bool perfect, int bestCombo) async {
    final res = await _serverOrLocal(
        '/api/complete', {'lesson_id': l.id, 'perfect': perfect, 'best_combo': bestCombo}, () {
      final (s, r) = completeLesson(st, l.id, l.xp, perfect: perfect, bestCombo: bestCombo);
      st = s;
      return {
        'result': {
          'xp': r.xp,
          'gems': r.gems,
          'first': r.first,
          'perfect': r.perfect,
          'level_up': r.levelUp,
          'level': r.level
        }
      };
    });
    if (res == null) return null;
    return LessonResult.fromJson(res['result']);
  }

  Future<void> saveName(String name) async {
    final n = name.trim();
    if (online) {
      if (n == '${user!['name'] ?? ''}') return;
      try {
        final res = await api.call('/api/name', {'name': n});
        _setUser(res['user']);
      } on ApiError {
        toast(t('err_conn'), icon: Icons.cloud_off_rounded);
      }
    } else {
      localName = n.length > 30 ? n.substring(0, 30) : n;
      await savePrefs();
    }
    notifyListeners();
  }

  Future<void> resetProgress() async {
    st = normalize(null);
    await savePrefs();
    notifyListeners();
  }

  Future<RunResult> run(String code, {List<String> inputs = const []}) => runPython(server, code, inputs: inputs);

  /// Testlarda o‘chiriladi / отключается в тестах.
  bool allowWarmUp = true;

  void warmUp() {
    if (allowWarmUp) warmUpRunner(server);
  }

  // ---------------------------------------------------------------- sozlamalar / настройки
  void go(String name) {
    tab = name;
    notifyListeners();
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

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Qayta chizmasdan olish / получить без подписки на перерисовку.
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
