import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Test paytida bildirishnomalarni o‘chirish (Android "Bezovta qilmang").
/// Отключение уведомлений во время теста (Android «Не беспокоить»).
///
/// iPhone’da ilovalar bildirishnomalarni o‘chira olmaydi — u yerda
/// "Yo‘naltirilgan kirish" (Guided Access) bo‘yicha qo‘llanma ko‘rsatiladi.
/// На iPhone приложения не могут отключать уведомления — там показывается
/// инструкция по «Гид-доступу» (Guided Access).
class FocusMode {
  static const _ch = MethodChannel('idrok/focus');

  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool _active = false;

  /// "Bezovta qilmang" ruxsati bormi / есть ли доступ к «Не беспокоить».
  static Future<bool> hasAccess() async {
    if (!isAndroid) return false;
    try {
      return await _ch.invokeMethod<bool>('hasAccess') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Sozlamalarda ruxsat sahifasini ochadi / открывает страницу доступа в настройках.
  static Future<void> requestAccess() async {
    if (!isAndroid) return;
    try {
      await _ch.invokeMethod<void>('requestAccess');
    } catch (_) {}
  }

  /// Bildirishnomalarni o‘chiradi (faqat budilniklar qoladi) / выключает уведомления (кроме будильников).
  static Future<bool> enable() async {
    if (!isAndroid) return false;
    try {
      _active = await _ch.invokeMethod<bool>('enable') ?? false;
    } catch (_) {
      _active = false;
    }
    return _active;
  }

  /// Avvalgi holatga qaytaradi / возвращает прежний режим.
  static Future<void> restore() async {
    if (!_active) return;
    _active = false;
    try {
      await _ch.invokeMethod<void>('restore');
    } catch (_) {}
  }
}
