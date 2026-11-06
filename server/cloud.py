"""
Bepul Supabase Storage'ga zaxira nusxa / резервная копия в бесплатном Supabase Storage.

Render'ning bepul serveri uxlaganda yoki qayta ishga tushganda diskdagi hamma narsa o‘chadi.
Shuning uchun:
  * ishga tushganda baza (kodla.db) Supabase'dan qayta tiklanadi;
  * har bir o‘zgarishdan keyin (ko‘pi bilan 15 soniyada bir marta) baza Supabase'ga yuklanadi;
  * profil rasmlari alohida fayl sifatida saqlanadi va kerak bo‘lganda yuklab olinadi.

Бесплатный сервер Render стирает диск, когда засыпает или перезапускается. Поэтому:
  * при запуске база (kodla.db) восстанавливается из Supabase;
  * после изменений (не чаще раза в 15 секунд) база загружается в Supabase;
  * фото профилей хранятся отдельными файлами и скачиваются по требованию.

Sozlash / настройка (Render → kodla-api → Environment):
    SUPABASE_URL = https://xxxx.supabase.co
    SUPABASE_KEY = service_role kaliti (Project Settings → API keys) / ключ service_role
Faqat standart kutubxona ishlatiladi / только стандартная библиотека.
"""
import json
import os
import sqlite3
import tempfile
import threading
import time
import urllib.error
import urllib.request
from pathlib import Path

URL = os.environ.get("SUPABASE_URL", "").strip().rstrip("/")
KEY = os.environ.get("SUPABASE_KEY", "").strip()
BUCKET = os.environ.get("SUPABASE_BUCKET", "idrok-academy")
DB_NAME = "kodla.db"
INTERVAL = 15  # soniya / секунд

enabled = bool(URL and KEY)
_lock = threading.Lock()
_last_sig = None
_stop = threading.Event()


def _request(method, path, data=None, ctype="application/octet-stream", upsert=False, timeout=60):
    headers = {"Authorization": f"Bearer {KEY}", "apikey": KEY, "Content-Type": ctype}
    if upsert:
        headers["x-upsert"] = "true"
    req = urllib.request.Request(f"{URL}/storage/v1/{path}", data=data, method=method, headers=headers)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()


def put(name, data):
    """Faylni yuklash (bor bo‘lsa — almashtirish) / загрузить файл (перезаписать, если есть)."""
    _request("POST", f"object/{BUCKET}/{name}", data, upsert=True)


def get(name):
    """Faylni yuklab olish; yo‘q bo‘lsa None / скачать файл; если нет — None."""
    try:
        return _request("GET", f"object/{BUCKET}/{name}")
    except urllib.error.HTTPError as e:
        if e.code in (400, 404):
            return None
        raise


def ensure_bucket():
    try:
        _request("POST", "bucket", json.dumps({"id": BUCKET, "name": BUCKET, "public": False}).encode(),
                 ctype="application/json")
    except urllib.error.HTTPError as e:
        if e.code not in (400, 409):  # allaqachon bor / уже существует
            raise


def restore(db_path: Path):
    """Ishga tushishda bazani tiklash / восстановить базу при запуске."""
    if not enabled:
        print("  Supabase: o‘chirilgan / выключен (SUPABASE_URL va SUPABASE_KEY yo‘q)", flush=True)
        return False
    ensure_bucket()
    data = get(DB_NAME)
    if data is None:
        print("  Supabase: zaxira hali yo‘q — yangi baza / резервной копии пока нет — новая база", flush=True)
        return False
    db_path.parent.mkdir(parents=True, exist_ok=True)
    for extra in ("-wal", "-shm"):
        Path(str(db_path) + extra).unlink(missing_ok=True)
    db_path.write_bytes(data)
    print(f"  Supabase: baza tiklandi / база восстановлена ({len(data) // 1024} KB)", flush=True)
    return True


def _signature(db_path: Path):
    sig = []
    for p in (db_path, Path(str(db_path) + "-wal")):
        try:
            st = p.stat()
            sig.append((st.st_mtime_ns, st.st_size))
        except FileNotFoundError:
            sig.append(None)
    return tuple(sig)


def backup(db_path: Path, force=False):
    """Bazaning izchil nusxasini yuklash / загрузить согласованную копию базы."""
    global _last_sig
    if not enabled or not db_path.exists():
        return False
    with _lock:
        sig = _signature(db_path)
        if not force and sig == _last_sig:
            return False
        with tempfile.TemporaryDirectory() as tmp:
            copy = Path(tmp) / DB_NAME
            src = sqlite3.connect(db_path, timeout=10)
            dst = sqlite3.connect(copy)
            try:
                src.backup(dst)
            finally:
                dst.close()
                src.close()
            put(DB_NAME, copy.read_bytes())
        _last_sig = sig
        return True


def start(db_path: Path):
    """Fon oqimi: o‘zgarish bo‘lsa yuklaydi / фоновый поток: загружает при изменениях."""
    global _last_sig
    if not enabled:
        return
    _last_sig = _signature(db_path)

    def loop():
        while not _stop.wait(INTERVAL):
            try:
                if backup(db_path):
                    print(f"  Supabase: zaxira saqlandi / копия сохранена {time.strftime('%H:%M:%S')}", flush=True)
            except Exception as e:  # tarmoq xatosi — keyingi safar / ошибка сети — в следующий раз
                print(f"  Supabase: zaxira xatosi / ошибка копии: {e}", flush=True)

    threading.Thread(target=loop, daemon=True).start()


def put_async(name, data):
    if not enabled:
        return

    def run():
        try:
            put(name, data)
        except Exception as e:
            print(f"  Supabase: fayl xatosi / ошибка файла {name}: {e}", flush=True)

    threading.Thread(target=run, daemon=True).start()
