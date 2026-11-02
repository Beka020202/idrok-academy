"""Android va iOS papkalarini yaratadi va sozlaydi (bir marta ishga tushiring).
Создаёт и настраивает папки Android и iOS (запустите один раз).

    cd app
    python tool/setup_platforms.py

Nima qiladi / Что делает:
  1. `flutter create` — android/ va ios/ papkalarini yaratadi (lib/ ga tegmaydi).
  2. Android: internetga ruxsat, sinf Wi‑Fi serveri (http://) uchun ruxsat, nom «Idrok Academy».
  3. iOS: http:// serverga ruxsat, nom «Idrok Academy».
  4. Ilova ikonkasi assets/icon/ dan / иконка приложения из assets/icon/.
Qayta ishga tushirish xavfsiz / повторный запуск безопасен.
"""

import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

APP = Path(__file__).resolve().parent.parent
ORG = "uz.kodla"
NAME = "Idrok Academy"


def run_flutter_create():
    flutter = shutil.which("flutter")
    if not flutter:
        sys.exit("Flutter topilmadi. https://docs.flutter.dev/get-started/install dan o‘rnating.\n"
                 "Flutter не найден. Установите с https://docs.flutter.dev/get-started/install")
    cmd = [flutter, "create", "--platforms=android,ios", "--org", ORG, "--project-name", "kodla", "."]
    print("→", " ".join(cmd), flush=True)
    subprocess.run(cmd, cwd=APP, check=True, shell=(os.name == "nt"))


def make_icons():
    """Ikonkalarni yaratish / создать иконки (assets/icon/icon.png)."""
    flutter = shutil.which("flutter")
    nt = os.name == "nt"
    subprocess.run([flutter, "pub", "get"], cwd=APP, check=True, shell=nt)
    dart = shutil.which("dart") or flutter
    cmd = [dart, "run", "flutter_launcher_icons"] if dart != flutter else [flutter, "pub", "run", "flutter_launcher_icons"]
    print("→", " ".join(cmd), flush=True)
    subprocess.run(cmd, cwd=APP, check=True, shell=nt)
    print("✓ Ikonka tayyor / иконка готова")


MAIN_ACTIVITY = """package {pkg}

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Test paytida "Bezovta qilmang" rejimi / режим «Не беспокоить» во время теста.
class MainActivity : FlutterActivity() {{
    private var previousFilter: Int? = null

    private fun nm(): NotificationManager =
        getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private fun granted(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && nm().isNotificationPolicyAccessGranted

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {{
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "idrok/focus").setMethodCallHandler {{ call, result ->
            when (call.method) {{
                "hasAccess" -> result.success(granted())
                "requestAccess" -> {{
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {{
                        try {{
                            startActivity(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                        }} catch (e: Exception) {{ }}
                    }}
                    result.success(null)
                }}
                "enable" -> {{
                    if (!granted()) {{
                        result.success(false)
                    }} else {{
                        if (previousFilter == null) previousFilter = nm().currentInterruptionFilter
                        nm().setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALARMS)
                        result.success(true)
                    }}
                }}
                "restore" -> {{
                    restoreFilter()
                    result.success(null)
                }}
                else -> result.notImplemented()
            }}
        }}
    }}

    private fun restoreFilter() {{
        val p = previousFilter
        if (p != null && granted()) {{
            try {{ nm().setInterruptionFilter(p) }} catch (e: Exception) {{ }}
        }}
        previousFilter = null
    }}

    override fun onDestroy() {{
        restoreFilter()
        super.onDestroy()
    }}
}}
"""


def patch_main_activity(root=APP):
    """Android "Bezovta qilmang" kanali / канал «Не беспокоить» для Android."""
    files = list((root / "android" / "app" / "src" / "main").rglob("MainActivity.kt"))
    if not files:
        print("! MainActivity.kt topilmadi / не найден")
        return False
    f = files[0]
    m = re.search(r"^package\s+([\w.]+)", f.read_text(encoding="utf-8"), re.M)
    pkg = m.group(1) if m else "uz.kodla.kodla"
    f.write_text(MAIN_ACTIVITY.format(pkg=pkg), encoding="utf-8")
    print("✓ MainActivity (Bezovta qilmang / Не беспокоить)")
    return True


def patch_android(root=APP):
    manifest = root / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
    if not manifest.exists():
        print("! AndroidManifest.xml topilmadi / не найден")
        return False
    xml = manifest.read_text(encoding="utf-8")
    if "android.permission.INTERNET" not in xml:
        xml = re.sub(r"(<manifest[^>]*>)",
                     r'\1\n    <uses-permission android:name="android.permission.INTERNET"/>', xml, count=1)
    if "ACCESS_NOTIFICATION_POLICY" not in xml:
        xml = re.sub(r"(<manifest[^>]*>)",
                     r'\1\n    <uses-permission android:name="android.permission.ACCESS_NOTIFICATION_POLICY"/>', xml, count=1)
    if "RECEIVE_BOOT_COMPLETED" not in xml:
        xml = re.sub(r"(<manifest[^>]*>)",
                     r'\1\n    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>', xml, count=1)
    if "ScheduledNotificationReceiver" not in xml:
        receivers = (
            '\n        <receiver android:exported="false" '
            'android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />\n'
            '        <receiver android:exported="false" '
            'android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">\n'
            '            <intent-filter>\n'
            '                <action android:name="android.intent.action.BOOT_COMPLETED"/>\n'
            '                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>\n'
            '                <action android:name="android.intent.action.QUICKBOOT_POWERON" />\n'
            '                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>\n'
            '            </intent-filter>\n'
            '        </receiver>\n')
        i = xml.rfind("</application>")
        xml = xml[:i] + receivers + "    " + xml[i:]
    if "usesCleartextTraffic" not in xml:
        xml = re.sub(r"<application\b", '<application\n        android:usesCleartextTraffic="true"', xml, count=1)
    xml = re.sub(r'android:label="[^"]*"', f'android:label="{NAME}"', xml, count=1)
    manifest.write_text(xml, encoding="utf-8")
    print("✓ Android sozlandi / настроен")
    return True


def patch_gradle(root=APP):
    """Eslatmalar uchun desugaring / desugaring для напоминаний (flutter_local_notifications)."""
    kts = root / "android" / "app" / "build.gradle.kts"
    groovy = root / "android" / "app" / "build.gradle"
    f = kts if kts.exists() else groovy
    if not f.exists():
        print("! app/build.gradle topilmadi / не найден")
        return False
    src = f.read_text(encoding="utf-8")
    if "desugar_jdk_libs" not in src:
        flag = "isCoreLibraryDesugaringEnabled = true" if f == kts else "coreLibraryDesugaringEnabled true"
        src, n = re.subn(r"compileOptions\s*\{", "compileOptions {\n        " + flag, src, count=1)
        if n == 0:
            src = re.sub(r"android\s*\{", "android {\n    compileOptions {\n        " + flag + "\n    }", src, count=1)
        dep = ('coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")' if f == kts
               else "coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'")
        src += "\ndependencies {\n    " + dep + "\n}\n"
        f.write_text(src, encoding="utf-8")
    print("✓ Gradle (desugaring)")
    return True


def patch_ios(root=APP):
    plist = root / "ios" / "Runner" / "Info.plist"
    if not plist.exists():
        print("! Info.plist topilmadi / не найден")
        return False
    xml = plist.read_text(encoding="utf-8")
    if "NSAppTransportSecurity" not in xml:
        ats = ("\t<key>NSAppTransportSecurity</key>\n\t<dict>\n"
               "\t\t<key>NSAllowsArbitraryLoads</key>\n\t\t<true/>\n\t</dict>\n")
        i = xml.rfind("</dict>")
        xml = xml[:i] + ats + xml[i:]
    xml = re.sub(r"(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)", rf"\g<1>{NAME}\g<2>", xml, count=1)
    usage = {
        "NSPhotoLibraryUsageDescription": "Profil rasmini tanlash uchun / Чтобы выбрать фото профиля",
        "NSCameraUsageDescription": "Profil rasmini olish uchun / Чтобы сделать фото профиля",
    }
    for key, text in usage.items():
        if key not in xml:
            i = xml.rfind("</dict>")
            xml = xml[:i] + f"\t<key>{key}</key>\n\t<string>{text}</string>\n" + xml[i:]
    plist.write_text(xml, encoding="utf-8")
    print("✓ iOS sozlandi / настроен")
    return True


def main():
    if "--patch-only" not in sys.argv:
        run_flutter_create()
    ok = patch_android() & patch_ios() & patch_main_activity() & patch_gradle()
    if "--patch-only" not in sys.argv:
        make_icons()
    print("\nTayyor! Endi / Готово! Теперь:  flutter run   yoki / или   flutter build apk --release" if ok else "")


if __name__ == "__main__":
    main()
