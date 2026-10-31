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


def patch_android(root=APP):
    manifest = root / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
    if not manifest.exists():
        print("! AndroidManifest.xml topilmadi / не найден")
        return False
    xml = manifest.read_text(encoding="utf-8")
    if "android.permission.INTERNET" not in xml:
        xml = re.sub(r"(<manifest[^>]*>)",
                     r'\1\n    <uses-permission android:name="android.permission.INTERNET"/>', xml, count=1)
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
    plist.write_text(xml, encoding="utf-8")
    print("✓ iOS sozlandi / настроен")
    return True


def main():
    if "--patch-only" not in sys.argv:
        run_flutter_create()
    ok = patch_android() & patch_ios()
    if "--patch-only" not in sys.argv:
        make_icons()
    print("\nTayyor! Endi / Готово! Теперь:  flutter run   yoki / или   flutter build apk --release" if ok else "")


if __name__ == "__main__":
    main()
