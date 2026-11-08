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
        AppLockChannel.register(this, flutterEngine)
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


ROOT_GRADLE_MARK = "idrok: plugin compileSdk"


def patch_root_gradle(root=APP):
    """Eski plaginlar (file_picker) uchun compileSdk 36 / compileSdk 36 для старых плагинов (file_picker)."""
    kts = root / "android" / "build.gradle.kts"
    groovy = root / "android" / "build.gradle"
    f = kts if kts.exists() else groovy
    if not f.exists():
        print("! android/build.gradle topilmadi / не найден")
        return False
    src = f.read_text(encoding="utf-8")
    if ROOT_GRADLE_MARK in src:
        return True
    if f == kts:
        block = (
            "// " + ROOT_GRADLE_MARK + "\n"
            "subprojects {\n"
            "    if (name != \"app\") {\n"
            "        afterEvaluate {\n"
            "            val ext = extensions.findByName(\"android\")\n"
            "            if (ext != null) {\n"
            "                try {\n"
            "                    ext.javaClass.getMethod(\"setCompileSdk\", java.lang.Integer::class.java).invoke(ext, 36)\n"
            "                } catch (e: Exception) {\n"
            "                    try {\n"
            "                        ext.javaClass.getMethod(\"compileSdkVersion\", Int::class.javaPrimitiveType).invoke(ext, 36)\n"
            "                    } catch (e2: Exception) {\n"
            "                        println(\"compileSdk patch skipped for $name\")\n"
            "                    }\n"
            "                }\n"
            "            }\n"
            "        }\n"
            "    }\n"
            "}\n\n"
        )
    else:
        block = (
            "// " + ROOT_GRADLE_MARK + "\n"
            "subprojects {\n"
            "    if (name != 'app') {\n"
            "        afterEvaluate { p -> if (p.hasProperty('android')) { p.android { compileSdkVersion 36 } } }\n"
            "    }\n"
            "}\n\n"
        )
    m = re.search(r"subprojects\s*\{\s*project\.evaluationDependsOn", src)
    src = src[:m.start()] + block + src[m.start():] if m else block + src
    f.write_text(src, encoding="utf-8")
    print("✓ Gradle (plugin compileSdk 36)")
    return True


APP_LOCK_KT = """package PKG

import android.accessibilityservice.AccessibilityService
import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.provider.Settings
import android.view.accessibility.AccessibilityEvent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.Calendar
import java.util.Locale

// Fokus rejimi: tanlangan ilovalar bugungi dars o'tilmaguncha qulflanadi.
// Режим фокуса: выбранные приложения блокируются, пока не пройден урок.
class AppLockService : AccessibilityService() {
    private var last = 0L

    companion object {
        // Hech qachon qulflanmaydi / никогда не блокируются
        val NEVER = setOf(
            "com.android.settings", "com.android.systemui", "com.android.phone", "com.android.dialer",
            "com.google.android.dialer", "com.samsung.android.dialer", "com.android.incallui",
            "com.android.server.telecom", "com.google.android.apps.messaging", "com.android.mms",
            "com.samsung.android.messaging", "com.android.emergency", "com.android.contacts",
            "com.google.android.contacts", "com.samsung.android.contacts", "com.android.camera",
            "com.android.deskclock", "com.google.android.deskclock", "com.sec.android.app.clockpackage"
        )
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return
        if (pkg == packageName || pkg in NEVER) return
        if (pkg !in AppLockRules.apps(this) || !AppLockRules.locked(this)) return
        val now = System.currentTimeMillis()
        if (now - last < 800) return
        last = now
        performGlobalAction(GLOBAL_ACTION_HOME)
        try {
            val i = packageManager.getLaunchIntentForPackage(packageName)
            if (i != null) startActivity(i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT))
        } catch (e: Exception) { }
    }

    override fun onInterrupt() { }
}

object AppLockRules {
    private fun sp(c: Context) = c.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
    private fun num(c: Context, k: String, d: Long): Long = try { sp(c).getLong("flutter." + k, d) } catch (e: Exception) { d }

    fun apps(c: Context): Set<String> =
        (sp(c).getString("flutter.lock_apps", "") ?: "").split(",").filter { it.isNotEmpty() }.toSet()

    fun locked(c: Context): Boolean {
        val p = sp(c)
        val on = try { p.getBoolean("flutter.lock_on", false) } catch (e: Exception) { false }
        if (!on) return false
        val cal = Calendar.getInstance()
        val today = String.format(Locale.US, "%04d-%02d-%02d", cal.get(Calendar.YEAR), cal.get(Calendar.MONTH) + 1, cal.get(Calendar.DAY_OF_MONTH))
        if ((p.getString("flutter.lock_done", "") ?: "") == today) return false
        if (num(c, "lock_pass_until", 0L) > System.currentTimeMillis()) return false
        val m = num(c, "lock_hour", 18L) * 60 + num(c, "lock_min", 0L)
        return cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE) >= m
    }
}

object AppLockChannel {
    fun register(a: Activity, engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, "idrok/applock").setMethodCallHandler { call, result ->
            when (call.method) {
                "enabled" -> result.success(enabled(a))
                "openSettings" -> {
                    try {
                        a.startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                    } catch (e: Exception) { }
                    result.success(null)
                }
                "apps" -> Thread {
                    val list = try { apps(a) } catch (e: Exception) { ArrayList<Map<String, Any>>() }
                    a.runOnUiThread { result.success(list) }
                }.start()
                else -> result.notImplemented()
            }
        }
    }

    private fun enabled(c: Context): Boolean {
        val s = Settings.Secure.getString(c.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES) ?: return false
        val cn = ComponentName(c, AppLockService::class.java)
        val a = cn.flattenToString()
        val b = cn.flattenToShortString()
        return s.split(":").any { it.equals(a, ignoreCase = true) || it.equals(b, ignoreCase = true) }
    }

    private fun apps(c: Context): List<Map<String, Any>> {
        val pm = c.packageManager
        val i = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val out = ArrayList<Map<String, Any>>()
        val seen = HashSet<String>()
        for (r in pm.queryIntentActivities(i, 0)) {
            val pkg = r.activityInfo.packageName
            if (pkg == c.packageName || pkg in AppLockService.NEVER || !seen.add(pkg)) continue
            val m = HashMap<String, Any>()
            m["pkg"] = pkg
            m["label"] = r.loadLabel(pm).toString()
            try {
                val d = r.loadIcon(pm)
                val bm = Bitmap.createBitmap(72, 72, Bitmap.Config.ARGB_8888)
                val cv = Canvas(bm)
                d.setBounds(0, 0, 72, 72)
                d.draw(cv)
                val os = ByteArrayOutputStream()
                bm.compress(Bitmap.CompressFormat.PNG, 100, os)
                m["icon"] = os.toByteArray()
            } catch (e: Exception) { }
            out.add(m)
        }
        return out
    }
}
"""

APP_LOCK_XML = """<?xml version="1.0" encoding="utf-8"?>
<accessibility-service xmlns:android="http://schemas.android.com/apk/res/android"
    android:accessibilityEventTypes="typeWindowStateChanged"
    android:accessibilityFeedbackType="feedbackGeneric"
    android:notificationTimeout="100"
    android:canRetrieveWindowContent="false"
    android:description="@string/app_lock_desc" />
"""

APP_LOCK_STRINGS = """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_lock_label">Idrok Academy — fokus rejimi</string>
    <string name="app_lock_desc">Bugungi dars o‘tilmaguncha siz tanlagan ilovalarni (o‘yinlar, ijtimoiy tarmoqlar) yopadi. Faqat qaysi ilova ochilganini ko‘radi, ekrandagi matnni o‘qimaydi.</string>
</resources>
"""


FOCUS_ACCESSIBILITY = False


def patch_applock(root=APP):
    """Fokus rejimi (Android maxsus imkoniyatlar xizmati) / режим фокуса (служба спец. возможностей)."""
    main = root / "android" / "app" / "src" / "main"
    files = list(main.rglob("MainActivity.kt"))
    if not files:
        print("! MainActivity.kt topilmadi / не найден")
        return False
    m = re.search(r"^package\s+([\w.]+)", files[0].read_text(encoding="utf-8"), re.M)
    pkg = m.group(1) if m else "uz.kodla.kodla"
    (files[0].parent / "AppLock.kt").write_text(APP_LOCK_KT.replace("PKG", pkg), encoding="utf-8")
    (main / "res" / "xml").mkdir(parents=True, exist_ok=True)
    (main / "res" / "xml" / "app_lock.xml").write_text(APP_LOCK_XML, encoding="utf-8")
    (main / "res" / "values").mkdir(parents=True, exist_ok=True)
    (main / "res" / "values" / "app_lock_strings.xml").write_text(APP_LOCK_STRINGS, encoding="utf-8")
    manifest = main / "AndroidManifest.xml"
    xml = manifest.read_text(encoding="utf-8")
    # Vaqtincha o‘chirilgan: Play Protect maxsus imkoniyatlar xizmatli APK ni bloklaydi.
    # Временно выключено: Play Protect блокирует APK со службой спец. возможностей.
    if FOCUS_ACCESSIBILITY and "AppLockService" not in xml:
        svc = ('\n        <service android:name=".AppLockService" android:exported="true"\n'
               '            android:label="@string/app_lock_label"\n'
               '            android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE">\n'
               '            <intent-filter>\n'
               '                <action android:name="android.accessibilityservice.AccessibilityService"/>\n'
               '            </intent-filter>\n'
               '            <meta-data android:name="android.accessibilityservice" android:resource="@xml/app_lock"/>\n'
               '        </service>\n')
        i = xml.rfind("</application>")
        xml = xml[:i] + svc + "    " + xml[i:]
    if "CATEGORY_LAUNCHER_QUERY" not in xml:
        q = ('\n    <!-- CATEGORY_LAUNCHER_QUERY: fokus rejimi uchun ilovalar royxati -->\n'
             '    <queries>\n        <intent>\n            <action android:name="android.intent.action.MAIN"/>\n'
             '            <category android:name="android.intent.category.LAUNCHER"/>\n        </intent>\n    </queries>\n')
        i = xml.rfind("</manifest>")
        xml = xml[:i] + q + xml[i:]
    manifest.write_text(xml, encoding="utf-8")
    print("✓ Fokus rejimi / режим фокуса")
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
    ok = patch_android() & patch_ios() & patch_main_activity() & patch_gradle() & patch_root_gradle() & patch_applock()
    if "--patch-only" not in sys.argv:
        make_icons()
    print("\nTayyor! Endi / Готово! Теперь:  flutter run   yoki / или   flutter build apk --release" if ok else "")


if __name__ == "__main__":
    main()
