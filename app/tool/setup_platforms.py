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
    if "usesCleartextTraffic" not in xml:
        xml = re.sub(r"<application\b", '<application\n        android:usesCleartextTraffic="true"', xml, count=1)
    xml = re.sub(r'android:label="[^"]*"', f'android:label="{NAME}"', xml, count=1)
    manifest.write_text(xml, encoding="utf-8")
    print("✓ Android sozlandi / настроен")
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
    ok = patch_android() & patch_ios() & patch_main_activity()
    if "--patch-only" not in sys.argv:
        make_icons()
    print("\nTayyor! Endi / Готово! Теперь:  flutter run   yoki / или   flutter build apk --release" if ok else "")


if __name__ == "__main__":
    main()
