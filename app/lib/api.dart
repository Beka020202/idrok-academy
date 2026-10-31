import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'config.dart';

/// Server xatosi / ошибка сервера. code: conn | auth | taken | short | busy | ...
class ApiError implements Exception {
  final String code;
  const ApiError(this.code);
  @override
  String toString() => 'ApiError($code)';
}

class Api {
  final String base;
  String? token;
  // Bitta ulanishni qayta ishlatish — tezroq / одно соединение на все запросы — быстрее.
  static final http.Client _client = http.Client();

  Api(String base, {this.token}) : base = _clean(base);

  static String _clean(String b) {
    var s = b.trim();
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    if (s.isNotEmpty && !s.startsWith('http://') && !s.startsWith('https://')) s = 'http://$s';
    return s;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  /// data == null -> GET, aks holda POST / иначе POST.
  Future<Map<String, dynamic>> call(String path, [Map<String, Object?>? data, Duration? timeout]) async {
    final Uri uri;
    try {
      uri = Uri.parse(base + path);
    } on FormatException {
      throw const ApiError('conn');
    }
    http.Response r;
    try {
      final f = data == null
          ? _client.get(uri, headers: _headers)
          : _client.post(uri, headers: _headers, body: jsonEncode(data));
      r = await f.timeout(timeout ?? kRequestTimeout);
    } on TimeoutException {
      throw const ApiError('conn');
    } on SocketException {
      throw const ApiError('conn');
    } on HandshakeException {
      throw const ApiError('conn');
    } on http.ClientException {
      throw const ApiError('conn');
    } on ArgumentError {
      throw const ApiError('conn');
    }
    Object? body;
    try {
      body = jsonDecode(utf8.decode(r.bodyBytes));
    } on FormatException {
      body = null;
    }
    if (r.statusCode >= 200 && r.statusCode < 300 && body is Map<String, dynamic>) return body;
    if (r.statusCode == 503) throw const ApiError('busy');
    if (body is Map && body['error'] is String) throw ApiError(body['error'] as String);
    throw ApiError(r.statusCode >= 500 ? 'conn' : 'error');
  }
}

/// Python kodini serverda bajarish natijasi / результат запуска Python на сервере.
class RunResult {
  final String out;
  final String? err; // null | "timeout" | "conn" | "busy" | "Xato matni"
  const RunResult(this.out, this.err);
}

/// Qaysi server Python'ni bajaradi / какой сервер выполняет Python.
/// Standart internet server → alohida runner; sinf serveri (Wi‑Fi) → o‘sha serverning o‘zi.
/// Стандартный интернет-сервер → отдельный runner; сервер класса (Wi‑Fi) → он сам.
String runnerBase(String serverUrl) {
  final usingDefault = Api._clean(serverUrl) == Api._clean(kDefaultServer);
  return kRunnerServer.isNotEmpty && usingDefault ? kRunnerServer : serverUrl;
}

Future<RunResult> runPython(String serverUrl, String code, {List<String> inputs = const []}) async {
  final api = Api(runnerBase(serverUrl));
  try {
    // Bepul server uxlab qolgan bo‘lsa, uyg‘onishi uchun ko‘proq kutamiz.
    // Бесплатный сервер может спать — ждём дольше, пока он проснётся.
    final res = await api.call('/api/run', {'code': code, 'inputs': inputs}, const Duration(seconds: 75));
    final err = res['err'];
    return RunResult('${res['out'] ?? ''}', err is String && err.isNotEmpty ? err : null);
  } on ApiError catch (e) {
    return RunResult('', e.code == 'busy' ? 'busy' : 'conn');
  }
}

/// Python serverini oldindan uyg‘otish / заранее «будим» сервер Python.
void warmUpRunner(String serverUrl) {
  final api = Api(runnerBase(serverUrl));
  api.call('/api/ping', null, const Duration(seconds: 75)).then((_) {}, onError: (_) {});
}
