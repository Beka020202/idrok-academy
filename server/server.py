"""Idrok Academy serveri — qo‘shimcha kutubxonasiz (faqat Python).
Сервер Idrok Academy — без дополнительных библиотек (только Python).

Ishga tushirish / Запуск:
    python server.py
    python server.py --teacher-password YangiParol

Rollar / Роли:
    admin   — «ustoz» akkaunti: ustoz kodlari, sovg‘a buyurtmalari, hamma o‘quvchilar
    teacher — kod bilan kirgan ustoz: faqat o‘z maktabi, o‘z testlari (XP berilmaydi)
    student — o‘quvchi

Muhit o‘zgaruvchilari / Переменные окружения (Render):
    PORT               — port
    TEACHER_PASSWORD   — ustoz paroli / пароль учителя
    KODLA_DB_PATH      — ma’lumotlar bazasi / база данных (rasmlar yonidagi "photos" papkada)
    KODLA_DISABLE_RUN  — "1": /api/run o‘chiriladi (Python alohida runner.py da)
"""

import argparse
import base64
import hashlib
import json
import os
import secrets
import signal
import socket
import sqlite3
import statistics
import threading
import time
from datetime import date, datetime, timedelta
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from progress import (HELPER_COST, LEAGUES, cancel_test, claim_quest, complete_lesson, level_of, normalize,
                      open_chest, promote, set_league, spend)
from runner import client_ip, handle_run
import cloud  # noqa: E402  Supabase zaxirasi / резервная копия Supabase
import platform_api  # noqa: E402  darslar, AI, kitoblar / уроки, AI, книги

HERE = Path(__file__).resolve().parent
DB_PATH = Path(os.environ.get("KODLA_DB_PATH", str(HERE / "kodla.db")))
PHOTO_DIR = DB_PATH.parent / "photos"
RUN_ENABLED = os.environ.get("KODLA_DISABLE_RUN", "") not in ("1", "true", "yes")
DEFAULT_PORT = 8765
TEACHER_LOGIN = "ustoz"
DEFAULT_TEACHER_PASSWORD = "ustoz123"
TOKEN_DAYS = 120
LOGIN_TRIES = 15
MAX_BODY = 100_000
MAX_PHOTO_BODY = 1_500_000

LESSONS = json.loads((HERE / "content" / "lessons.json").read_text(encoding="utf-8"))
SHOP = {item["id"]: item for item in json.loads((HERE / "content" / "shop.json").read_text(encoding="utf-8"))}
COURSE_LESSONS = {}
for _lid, _m in LESSONS.items():
    COURSE_LESSONS.setdefault(_m["course"], []).append(_lid)
BUILTIN_LESSONS = {k: dict(v) for k, v in LESSONS.items()}

_write_lock = threading.Lock()
_login_lock = threading.Lock()
_login_hits = {}


def login_allowed(ip):
    """Parolni taxmin qilishdan himoya / защита от подбора пароля."""
    now = time.time()
    with _login_lock:
        hits = [t for t in _login_hits.get(ip, []) if now - t < 600]
        ok = len(hits) < LOGIN_TRIES
        if ok:
            hits.append(now)
        _login_hits[ip] = hits
        if len(_login_hits) > 5000:
            for k in [k for k, v in _login_hits.items() if not v or now - v[-1] > 600]:
                _login_hits.pop(k, None)
        return ok


# ---------------------------------------------------------------- ma’lumotlar bazasi / база данных
def db():
    conn = sqlite3.connect(DB_PATH, timeout=10)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys=ON")
    return conn


def init_db():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    PHOTO_DIR.mkdir(parents=True, exist_ok=True)
    with db() as conn:
        conn.execute("PRAGMA journal_mode=WAL")
        platform_api.init(conn)
        conn.executescript("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE COLLATE NOCASE,
            name TEXT NOT NULL DEFAULT '',
            salt TEXT NOT NULL,
            pw_hash TEXT NOT NULL,
            role TEXT NOT NULL DEFAULT 'student',
            state TEXT NOT NULL DEFAULT '{}',
            created REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS tokens (
            token TEXT PRIMARY KEY,
            user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            created REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS xp_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            day TEXT NOT NULL,
            amount INTEGER NOT NULL
        );
        CREATE INDEX IF NOT EXISTS xp_log_day ON xp_log(day, user_id);
        CREATE TABLE IF NOT EXISTS attempts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            ts REAL NOT NULL,
            lesson_id TEXT NOT NULL,
            correct INTEGER NOT NULL,
            total INTEGER NOT NULL,
            time_share REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            item_id TEXT NOT NULL,
            price INTEGER NOT NULL,
            status TEXT NOT NULL DEFAULT 'new',
            ts REAL NOT NULL
        );
        """)
        conn.executescript("""
        CREATE TABLE IF NOT EXISTS teacher_codes (
            code TEXT PRIMARY KEY,
            region TEXT NOT NULL,
            district TEXT NOT NULL,
            school TEXT NOT NULL,
            note TEXT NOT NULL DEFAULT '',
            created REAL NOT NULL,
            used_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
            used_at REAL
        );
        CREATE TABLE IF NOT EXISTS ttests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            school_key TEXT NOT NULL,
            teacher_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            active INTEGER NOT NULL DEFAULT 1,
            created REAL NOT NULL,
            updated REAL NOT NULL
        );
        CREATE INDEX IF NOT EXISTS ttests_school ON ttests(school_key);
        CREATE TABLE IF NOT EXISTS photos (user_id INTEGER PRIMARY KEY, ts REAL NOT NULL);
        CREATE TABLE IF NOT EXISTS portfolio (
            user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            course TEXT NOT NULL,
            slug TEXT NOT NULL UNIQUE,
            title TEXT NOT NULL,
            mode TEXT NOT NULL,
            code TEXT NOT NULL,
            updated REAL NOT NULL,
            PRIMARY KEY (user_id, course)
        );
        CREATE TABLE IF NOT EXISTS exams (
            user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            course TEXT NOT NULL,
            tries INTEGER NOT NULL DEFAULT 0,
            best INTEGER NOT NULL DEFAULT 0,
            started REAL NOT NULL DEFAULT 0,
            open INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY (user_id, course)
        );
        CREATE TABLE IF NOT EXISTS certs (
            id TEXT PRIMARY KEY,
            user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            course TEXT NOT NULL,
            score INTEGER NOT NULL,
            name TEXT NOT NULL,
            school TEXT NOT NULL DEFAULT '',
            issued REAL NOT NULL,
            UNIQUE (user_id, course)
        );
        CREATE TABLE IF NOT EXISTS tresults (
            test_id INTEGER NOT NULL REFERENCES ttests(id) ON DELETE CASCADE,
            user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            correct INTEGER NOT NULL,
            total INTEGER NOT NULL,
            best INTEGER NOT NULL,
            tries INTEGER NOT NULL,
            ts REAL NOT NULL,
            PRIMARY KEY (test_id, user_id)
        );
        """)
        cols = {r["name"] for r in conn.execute("PRAGMA table_info(users)")}
        for col in ("school", "city", "league", "region", "district"):
            if col not in cols:
                conn.execute(f"ALTER TABLE users ADD COLUMN {col} TEXT NOT NULL DEFAULT ''")
        if "promoted_at" not in cols:
            conn.execute("ALTER TABLE users ADD COLUMN promoted_at REAL NOT NULL DEFAULT 0")
        # Eski «ustoz» akkaunti endi admin / старый аккаунт «ustoz» теперь админ
        conn.execute("UPDATE users SET role='admin' WHERE role='teacher' AND username=?", (TEACHER_LOGIN,))


def hash_pw(password, salt):
    return hashlib.pbkdf2_hmac("sha256", password.encode(), bytes.fromhex(salt), 200_000).hex()


def create_user(conn, username, password, name, role="student", school="", city="", region="", district=""):
    salt = secrets.token_hex(16)
    cur = conn.execute(
        "INSERT INTO users (username, name, salt, pw_hash, role, state, created, school, city, region, district) "
        "VALUES (?,?,?,?,?,?,?,?,?,?,?)",
        (username, name, salt, hash_pw(password, salt), role, "{}", time.time(), school, city, region, district))
    return cur.lastrowid


def school_key(row_or_dict):
    """Maktabning yagona kaliti / единый ключ школы: viloyat|tuman|maktab."""
    r = row_or_dict
    return f"{r['region']}|{r['district']}|{r['school']}".lower()


CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"


def new_code():
    part = lambda: "".join(secrets.choice(CODE_ALPHABET) for _ in range(4))  # noqa: E731
    return f"IDR-{part()}-{part()}"


def clean(value, limit=60):
    return str(value or "").strip()[:limit]


def ensure_teacher(new_password=None):
    """Admin («ustoz») akkaunti / аккаунт администратора («ustoz»)."""
    with _write_lock, db() as conn:
        row = conn.execute("SELECT id FROM users WHERE role='admin'").fetchone()
        if row is None:
            create_user(conn, TEACHER_LOGIN, new_password or DEFAULT_TEACHER_PASSWORD, "Admin", "admin")
            return "created"
        if new_password:
            salt = secrets.token_hex(16)
            conn.execute("UPDATE users SET salt=?, pw_hash=? WHERE id=?", (salt, hash_pw(new_password, salt), row["id"]))
            return "changed"
    return "exists"


def photo_path(user_id):
    return PHOTO_DIR / f"{int(user_id)}.img"


# Rasmi bor foydalanuvchilar (bazada saqlanadi — Supabase bilan birga tiklanadi)
# Пользователи с фото (хранится в базе — восстанавливается вместе с Supabase)
_photo_ids = set()


def load_photo_ids():
    with _write_lock, db() as conn:
        for f in PHOTO_DIR.glob("*.img"):
            if f.stem.isdigit():
                conn.execute("INSERT OR IGNORE INTO photos (user_id, ts) VALUES (?,?)", (int(f.stem), time.time()))
        _photo_ids.clear()
        _photo_ids.update(r["user_id"] for r in conn.execute("SELECT user_id FROM photos"))


def has_photo(user_id):
    return int(user_id) in _photo_ids or photo_path(user_id).exists()


def save_photo(conn, user_id, data):
    photo_path(user_id).write_bytes(data)
    conn.execute("INSERT OR REPLACE INTO photos (user_id, ts) VALUES (?,?)", (int(user_id), time.time()))
    _photo_ids.add(int(user_id))
    cloud.put_async(f"photos/{int(user_id)}.img", data)


def read_photo(user_id):
    p = photo_path(user_id)
    if p.exists():
        return p.read_bytes()
    if cloud.enabled:
        try:
            data = cloud.get(f"photos/{int(user_id)}.img")
        except Exception:
            data = None
        if data:
            p.write_bytes(data)
            return data
    return None


def state_of(row):
    s = normalize(json.loads(row["state"] or "{}"))
    # liga ustuni — asosiy manba / столбец league — главный источник
    if row["league"] in LEAGUES:
        s["league"] = row["league"]
    return s


def public_user(row):
    return {"username": row["username"], "name": row["name"], "role": row["role"], "school": row["school"],
            "city": row["city"], "region": row["region"], "district": row["district"], "league": row["league"],
            "has_photo": has_photo(row["id"]), "state": state_of(row)}


def student_row(r, extra=None):
    s = state_of(r)
    return {"username": r["username"], "name": r["name"] or r["username"], "school": r["school"],
            "city": r["city"], "region": r["region"], "district": r["district"], "league": r["league"],
            "level": level_of(s["xp_total"]), "streak": s["streak"], "done_n": len(s["done"]),
            "has_photo": has_photo(r["id"]), **(extra or {})}


# ---------------------------------------------------------------- ustoz testlari / тесты учителя
MAX_QUESTIONS = 30


def parse_test(data):
    """Ustoz testini tekshiradi / проверяет тест учителя. None — xato / ошибка."""
    title = clean(data.get("title"), 80)
    text = clean(data.get("text"), 3000)
    qs = data.get("questions")
    if not title or not isinstance(qs, list) or not 1 <= len(qs) <= MAX_QUESTIONS:
        return None
    out = []
    for q in qs:
        if not isinstance(q, dict):
            return None
        kind = q.get("type")
        question = clean(q.get("q"), 400)
        if not question:
            return None
        if kind == "quiz":
            opts = [clean(o, 200) for o in (q.get("options") or []) if clean(o, 200)]
            ans = q.get("answer")
            if not 2 <= len(opts) <= 4 or not isinstance(ans, int) or not 0 <= ans < len(opts):
                return None
            out.append({"type": "quiz", "q": question, "options": opts, "answer": ans})
        elif kind == "fill":
            answers = [clean(a, 100) for a in (q.get("answers") or []) if clean(a, 100)]
            if not answers or len(answers) > 5:
                return None
            out.append({"type": "fill", "q": question, "answers": answers})
        else:
            return None
    return {"title": title, "text": text, "questions": out}


def public_test(row, with_answers=False):
    body = json.loads(row["body"])
    qs = body["questions"] if with_answers else [
        {k: v for k, v in q.items() if k not in ("answer", "answers")} for q in body["questions"]]
    return {"id": row["id"], "title": body["title"], "text": body.get("text", ""), "questions": qs,
            "active": bool(row["active"]), "updated": row["updated"]}


# ---------------------------------------------------------------- portfolio
import html as _html  # noqa: E402

PORTFOLIO_MODES = ("html", "py")
MAX_PROJECT = 20_000


def portfolio_page(row):
    """Loyihaning ochiq sahifasi / публичная страница проекта."""
    e = _html.escape
    who = e(row["name"] or row["username"])
    school = e(" · ".join(x for x in (row["school"], row["district"]) if x))
    title = e(row["title"])
    if row["mode"] == "html":
        work = (f'<iframe sandbox="allow-scripts" srcdoc="{e(row["code"], quote=True)}" '
                'title="project"></iframe>')
    else:
        work = f'<pre><code>{e(row["code"])}</code></pre>'
    return f"""<!DOCTYPE html><html lang="uz"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title} — {who} · Idrok Academy</title>
<style>
*{{box-sizing:border-box}}body{{margin:0;font-family:-apple-system,system-ui,Segoe UI,Roboto,sans-serif;
background:linear-gradient(160deg,#2EA6FF,#0047D6);min-height:100vh;color:#0A1226;padding:24px 16px}}
.wrap{{max-width:860px;margin:0 auto}}.top{{color:#fff;margin-bottom:18px}}
.brand{{font-weight:800;letter-spacing:-.3px;opacity:.9}}h1{{margin:6px 0 4px;font-size:28px;letter-spacing:-.6px}}
.who{{opacity:.9}}.card{{background:#fff;border-radius:22px;padding:14px;box-shadow:0 20px 50px rgba(0,30,90,.35)}}
iframe{{width:100%;height:70vh;border:0;border-radius:14px;background:#fff}}
pre{{margin:0;background:#0A1226;color:#E8F0FF;padding:18px;border-radius:14px;overflow:auto;font-size:14px;line-height:1.55}}
.foot{{color:#fff;opacity:.8;text-align:center;margin-top:18px;font-size:13px}}
</style></head><body><div class="wrap"><div class="top"><div class="brand">IDROK ACADEMY · Portfolio</div>
<h1>{title}</h1><div class="who">{who}{(" — " + school) if school else ""}</div></div>
<div class="card">{work}</div><div class="foot">Idrok Academy ilovasida yaratilgan</div></div></body></html>"""


# ---------------------------------------------------------------- yakuniy imtihon / итоговый экзамен
EXAM_SIZE = 30
EXAM_PASS = 70  # foiz / процент
EXAM_WAIT = 24 * 3600  # qayta topshirish / пересдача
EXAM_TIME = 3 * 3600  # bitta urinish uchun eng ko‘p vaqt / максимум на попытку
COURSE_NAMES = {"html": "HTML", "css": "CSS", "js": "JavaScript", "py": "Python", "ai": "Sun’iy intellekt"}
COURSE_NAMES_RU = {"html": "HTML", "css": "CSS", "js": "JavaScript", "py": "Python", "ai": "Искусственный интеллект"}


def course_done(state, course):
    """Ligadagi barcha darslar tugaganmi / пройдены ли все уроки лиги."""
    league = state.get("league") or "beginner"
    ids = [lid for lid in COURSE_LESSONS.get(course, [])
           if LESSONS[lid].get("leagues") is None or league in LESSONS[lid]["leagues"]]
    done = state.get("done") or {}
    return bool(ids) and all(done.get(lid) for lid in ids)


def new_cert_id(conn):
    alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    while True:
        cid = "IDR-" + "".join(secrets.choice(alphabet) for _ in range(4)) + "-" + \
              "".join(secrets.choice(alphabet) for _ in range(4))
        if conn.execute("SELECT 1 FROM certs WHERE id=?", (cid,)).fetchone() is None:
            return cid


def cert_json(row):
    return {"id": row["id"], "course": row["course"], "score": row["score"], "name": row["name"],
            "school": row["school"], "issued": int(row["issued"] * 1000)}


def exam_json(row):
    return {"course": row["course"], "tries": row["tries"], "best": row["best"],
            "last": int(row["started"] * 1000), "open": bool(row["open"])}


def cert_page(row):
    """Sertifikatni tekshirish sahifasi / страница проверки сертификата."""
    e = _html.escape
    if row is None:
        body = ('<div class="bad">✕</div><h1>Topilmadi</h1><p>Bunday raqamli sertifikat yo‘q.<br>'
                'Сертификат с таким номером не найден.</p>')
    else:
        date = time.strftime("%d.%m.%Y", time.gmtime(row["issued"] + 5 * 3600))
        uz, ru = e(COURSE_NAMES.get(row["course"], row["course"])), e(COURSE_NAMES_RU.get(row["course"], row["course"]))
        school = f'<div class="row"><span>Maktab · Школа</span><b>{e(row["school"])}</b></div>' if row["school"] else ""
        body = (f'<div class="ok">✓</div><h1>Haqiqiy sertifikat</h1><p class="sub">Подлинный сертификат</p>'
                f'<div class="name">{e(row["name"])}</div>'
                f'<div class="row"><span>Kurs · Курс</span><b>{uz} · {ru}</b></div>{school}'
                f'<div class="row"><span>Natija · Результат</span><b>{row["score"]}%</b></div>'
                f'<div class="row"><span>Sana · Дата</span><b>{date}</b></div>'
                f'<div class="row"><span>ID</span><b>{e(row["id"])}</b></div>')
    return f"""<!DOCTYPE html><html lang="uz"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>Sertifikat · Idrok Academy</title>
<style>*{{box-sizing:border-box}}body{{margin:0;font-family:-apple-system,system-ui,Segoe UI,Roboto,sans-serif;
background:linear-gradient(160deg,#2EA6FF,#0047D6);min-height:100vh;color:#0A1226;padding:32px 16px;display:flex;
justify-content:center}}.card{{background:#fff;border-radius:24px;padding:28px 22px;max-width:440px;width:100%;
box-shadow:0 20px 50px rgba(0,30,90,.35);text-align:center}}.brand{{font-weight:800;color:#0A6CFF;letter-spacing:1.5px;
font-size:12px}}.ok,.bad{{width:64px;height:64px;border-radius:50%;margin:18px auto 10px;display:flex;align-items:center;
justify-content:center;font-size:32px;color:#fff;background:#34C759}}.bad{{background:#FF3B30}}h1{{margin:4px 0;
font-size:24px;letter-spacing:-.5px}}.sub{{margin:0 0 16px;color:#6B7280}}.name{{font-size:22px;font-weight:800;
margin:8px 0 16px}}.row{{display:flex;justify-content:space-between;gap:12px;padding:11px 0;border-top:1px solid #EEF1F6;
text-align:left;font-size:15px}}.row span{{color:#6B7280}}.row b{{text-align:right}}p{{color:#4B5563;line-height:1.5}}
</style></head><body><div class="card"><div class="brand">IDROK ACADEMY</div>{body}</div></body></html>"""


def grade_test(body, answers):
    qs = body["questions"]
    if not isinstance(answers, list):
        answers = []
    correct = 0
    for k, q in enumerate(qs):
        a = answers[k] if k < len(answers) else None
        if q["type"] == "quiz" and isinstance(a, int) and a == q["answer"]:
            correct += 1
        elif q["type"] == "fill" and isinstance(a, str) and a.strip().lower() in [x.lower() for x in q["answers"]]:
            correct += 1
    return correct, len(qs)


# ---------------------------------------------------------------- davrlar / периоды
def period_start(period):
    today = date.today()
    if period == "month":
        return today.replace(day=1).isoformat()
    return (today - timedelta(days=today.weekday())).isoformat()  # dushanba / понедельник


def earned_since(conn, since, league=None):
    """{user_id: XP} davr ichida ishlab topilgan / заработано за период."""
    q = ("SELECT x.user_id AS uid, SUM(x.amount) AS s FROM xp_log x JOIN users u ON u.id=x.user_id "
         "WHERE x.day>=? AND u.role='student'")
    args = [since]
    if league:
        q += " AND u.league=?"
        args.append(league)
    q += " GROUP BY x.user_id"
    return {r["uid"]: int(r["s"] or 0) for r in conn.execute(q, args)}


def save_state(conn, user_id, old_state, new_state):
    """Holatni saqlaydi va ishlab topilgan XP ni jurnalga yozadi / сохраняет и пишет заработанный XP в журнал."""
    gained = int(new_state.get("xp_total", 0)) - int(old_state.get("xp_total", 0))
    if gained > 0:
        conn.execute("INSERT INTO xp_log (user_id, day, amount) VALUES (?,?,?)", (user_id, date.today().isoformat(), gained))
    conn.execute("UPDATE users SET state=?, league=? WHERE id=?",
                 (json.dumps(new_state, ensure_ascii=False), new_state.get("league", ""), user_id))


# ---------------------------------------------------------------- avtomatik ko‘tarilish / авто-повышение
PROMO_MIN_ATTEMPTS = 5
PROMO_ACCURACY = 0.9
PROMO_TIME_SHARE = 0.55
PROMO_MIN_WEEK_XP = 120
PROMO_COOLDOWN = 7 * 86400


def check_promotion(conn, row, state):
    """Kuchli o‘quvchini keyingi ligaga ko‘taradi. Qaytaradi: yangi liga yoki None.
    Сильного ученика переводит в следующую лигу. Возвращает новую лигу или None."""
    league = state.get("league") or ""
    if league not in LEAGUES or league == LEAGUES[-1]:
        return None
    if time.time() - float(row["promoted_at"] or 0) < PROMO_COOLDOWN:
        return None
    recent = conn.execute(
        "SELECT correct, total, time_share FROM attempts WHERE user_id=? AND ts>? ORDER BY ts DESC LIMIT 10",
        (row["id"], time.time() - 14 * 86400)).fetchall()
    if len(recent) < PROMO_MIN_ATTEMPTS:
        return None
    total = sum(r["total"] for r in recent)
    accuracy = sum(r["correct"] for r in recent) / total if total else 0
    speed = sum(r["time_share"] for r in recent) / len(recent)
    if accuracy < PROMO_ACCURACY or speed > PROMO_TIME_SHARE:
        return None
    week = earned_since(conn, period_start("week"), league)
    mine = week.get(row["id"], 0)
    if mine < PROMO_MIN_WEEK_XP:
        return None
    others = [v for k, v in week.items() if k != row["id"]]
    if others:
        median = statistics.median(others)
        top = sorted(week.values(), reverse=True)
        top_cut = top[max(0, len(top) // 10 - 1)] if len(top) >= 10 else top[0]
        if mine < 1.5 * median and mine < top_cut:
            return None
    return LEAGUES[LEAGUES.index(league) + 1]


# ---------------------------------------------------------------- so‘rovlar / запросы
class Handler(BaseHTTPRequestHandler):
    server_version = "Idrok/2.0"

    def log_message(self, fmt, *args):
        print(f"  {self.address_string()}  {self.command} {self.path.split('?')[0]}  →  {args[1] if len(args) > 1 else ''}")

    def end_headers(self):
        # Brauzer versiyasi uchun (boshqa domendan so‘rov) / для веб-версии (запросы с другого домена)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Max-Age", "86400")
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Content-Length", "0")
        self.end_headers()

    def send_json(self, status, data):
        body = json.dumps(data, ensure_ascii=False).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def read_json(self, limit=MAX_BODY):
        length = int(self.headers.get("Content-Length") or 0)
        if length > limit:
            return None
        try:
            data = json.loads(self.rfile.read(length) or b"{}")
            return data if isinstance(data, dict) else None
        except (json.JSONDecodeError, UnicodeDecodeError):
            return None

    def current_user(self, conn):
        auth = self.headers.get("Authorization", "")
        if not auth.startswith("Bearer "):
            return None
        return conn.execute(
            "SELECT u.* FROM tokens t JOIN users u ON u.id=t.user_id WHERE t.token=? AND t.created>?",
            (auth[7:].strip(), time.time() - TOKEN_DAYS * 86400)).fetchone()

    def new_token(self, conn, user_id):
        token = secrets.token_urlsafe(32)
        conn.execute("INSERT INTO tokens (token, user_id, created) VALUES (?,?,?)", (token, user_id, time.time()))
        return token

    # ---- GET
    def do_GET(self):
        path, _, query = self.path.partition("?")
        params = dict(p.split("=", 1) for p in query.split("&") if "=" in p)
        if path in ("/", "/api/ping"):
            return self.send_json(200, {"ok": True, "app": "idrok"})
        if path == "/api/shop":
            return self.send_json(200, {"items": list(SHOP.values())})
        if path.startswith("/c/"):
            with db() as conn:
                row = conn.execute("SELECT * FROM certs WHERE id=?", (path[3:].strip().upper(),)).fetchone()
            page = cert_page(row).encode()
            self.send_response(200 if row is not None else 404)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(page)))
            self.send_header("Content-Security-Policy", "default-src 'none'; style-src 'unsafe-inline'")
            self.end_headers()
            self.wfile.write(page)
            return None
        if path.startswith("/p/"):
            with db() as conn:
                row = conn.execute("SELECT p.*, u.name, u.username, u.school, u.district FROM portfolio p "
                                   "JOIN users u ON u.id=p.user_id WHERE p.slug=?", (path[3:],)).fetchone()
            if row is None:
                return self.send_json(404, {"error": "not_found"})
            body = portfolio_page(row).encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Content-Security-Policy", "default-src 'none'; style-src 'unsafe-inline'; script-src 'unsafe-inline'; frame-src 'self'; "
                             "img-src https: data:")
            self.end_headers()
            self.wfile.write(body)
            return None
        with db() as conn:
            user = self.current_user(conn)
            if user is None:
                return self.send_json(401, {"error": "auth"})

            if path.startswith("/api/photo/"):
                target = conn.execute("SELECT id FROM users WHERE username=?", (path[len("/api/photo/"):],)).fetchone()
                data = read_photo(target["id"]) if target is not None and has_photo(target["id"]) else None
                if data is None:
                    return self.send_json(404, {"error": "not_found"})
                self.send_response(200)
                self.send_header("Content-Type", "image/png" if data[:4] == b"\x89PNG" else "image/jpeg")
                self.send_header("Content-Length", str(len(data)))
                self.send_header("Cache-Control", "private, max-age=600")
                self.end_headers()
                self.wfile.write(data)
                return None

            if path == "/api/me":
                return self.send_json(200, {"user": public_user(user)})

            got = platform_api.handle_get(conn, user, path, school_key(user), LESSONS, COURSE_LESSONS)
            if got is not None:
                return self.send_json(*got)

            if path == "/api/exams":
                exams = conn.execute("SELECT * FROM exams WHERE user_id=?", (user["id"],)).fetchall()
                certs = conn.execute("SELECT * FROM certs WHERE user_id=?", (user["id"],)).fetchall()
                return self.send_json(200, {"exams": [exam_json(r) for r in exams], "certs": [cert_json(r) for r in certs],
                                            "now": int(time.time() * 1000)})

            if path == "/api/leaderboard":
                period = "month" if params.get("period") == "month" else "week"
                scope = "school" if params.get("scope") == "school" and user["role"] == "teacher" else "league"
                if scope == "school":
                    earned = earned_since(conn, period_start(period))
                    key = school_key(user)
                    pool = [r for r in conn.execute("SELECT * FROM users WHERE role='student'") if school_key(r) == key]
                    league = ""
                else:
                    league = user["league"] if user["role"] == "student" and user["league"] in LEAGUES else \
                        (params.get("league") if params.get("league") in LEAGUES else "beginner")
                    earned = earned_since(conn, period_start(period), league)
                    pool = conn.execute("SELECT * FROM users WHERE role='student' AND league=?", (league,)).fetchall()
                rows = [student_row(r, {"xp": earned.get(r["id"], 0)}) for r in pool]
                rows.sort(key=lambda x: (-x["xp"], x["name"].lower()))
                me = next((i for i, r in enumerate(rows) if r["username"].lower() == user["username"].lower()), None)
                return self.send_json(200, {"rows": rows[:50], "league": league, "scope": scope, "period": period,
                                            "me": {"rank": me + 1, **rows[me]} if me is not None and me >= 50 else None})

            if path == "/api/tests":
                if user["role"] != "student":
                    return self.send_json(403, {"error": "forbidden"})
                key = school_key(user)
                rows = []
                for t in conn.execute("SELECT * FROM ttests WHERE school_key=? AND active=1 ORDER BY updated DESC", (key,)):
                    res = conn.execute("SELECT * FROM tresults WHERE test_id=? AND user_id=?", (t["id"], user["id"])).fetchone()
                    rows.append({**public_test(t), "result": None if res is None else
                                 {"correct": res["correct"], "best": res["best"], "total": res["total"], "tries": res["tries"]}})
                return self.send_json(200, {"rows": rows})

            if path == "/api/orders":
                rows = [{"id": r["id"], "item_id": r["item_id"], "price": r["price"], "status": r["status"], "ts": r["ts"]}
                        for r in conn.execute("SELECT * FROM orders WHERE user_id=? ORDER BY ts DESC", (user["id"],))]
                return self.send_json(200, {"rows": rows})

            if path.startswith("/api/teacher/") and user["role"] not in ("teacher", "admin"):
                return self.send_json(403, {"error": "forbidden"})
            if path.startswith("/api/admin/") and user["role"] != "admin":
                return self.send_json(403, {"error": "forbidden"})

            if path in ("/api/teacher/students", "/api/admin/students"):
                week = earned_since(conn, period_start("week"))
                lesson_order = list(LESSONS.keys())
                key = school_key(user)
                rows = []
                for r in conn.execute("SELECT * FROM users WHERE role='student' ORDER BY name COLLATE NOCASE"):
                    if user["role"] == "teacher" and school_key(r) != key:
                        continue
                    s = state_of(r)
                    rows.append(student_row(r, {
                        "xp": s["xp"], "xp_total": s["xp_total"], "week_xp": week.get(r["id"], 0),
                        "today_xp": s["today_xp"], "last_day": s["last_day"],
                        "done": [lid for lid in lesson_order if s["done"].get(lid)]}))
                return self.send_json(200, {"rows": rows, "lessons": lesson_order})

            if path == "/api/teacher/tests":
                if user["role"] != "teacher":
                    return self.send_json(403, {"error": "forbidden"})
                rows = []
                for t in conn.execute("SELECT * FROM ttests WHERE school_key=? ORDER BY updated DESC", (school_key(user),)):
                    st = conn.execute("SELECT COUNT(*) AS n, AVG(best * 1.0 / total) AS avg FROM tresults WHERE test_id=?",
                                      (t["id"],)).fetchone()
                    rows.append({**public_test(t, with_answers=True), "mine": t["teacher_id"] == user["id"],
                                 "submitted": st["n"], "avg": round((st["avg"] or 0) * 100)})
                return self.send_json(200, {"rows": rows})

            if path == "/api/teacher/results":
                t = conn.execute("SELECT * FROM ttests WHERE id=? AND school_key=?",
                                 (int(params.get("id") or 0), school_key(user))).fetchone()
                if t is None:
                    return self.send_json(404, {"error": "not_found"})
                rows = [{"username": r["username"], "name": r["name"], "has_photo": has_photo(r["user_id"]),
                         "correct": r["correct"], "best": r["best"], "total": r["total"], "tries": r["tries"], "ts": r["ts"]}
                        for r in conn.execute("SELECT r.*, u.username, u.name FROM tresults r JOIN users u ON u.id=r.user_id "
                                              "WHERE r.test_id=? ORDER BY r.best DESC, r.ts", (t["id"],))]
                return self.send_json(200, {"rows": rows, "test": public_test(t, with_answers=True)})

            if path == "/api/admin/codes":
                rows = [{"code": r["code"], "region": r["region"], "district": r["district"], "school": r["school"],
                         "note": r["note"], "created": r["created"], "used_at": r["used_at"],
                         "used_by": r["uname"] or ""}
                        for r in conn.execute("SELECT c.*, u.name AS uname FROM teacher_codes c "
                                              "LEFT JOIN users u ON u.id=c.used_by ORDER BY c.created DESC LIMIT 300")]
                return self.send_json(200, {"rows": rows})

            if path == "/api/admin/orders":
                rows = [{"id": r["id"], "item_id": r["item_id"], "price": r["price"], "status": r["status"], "ts": r["ts"],
                         "username": r["username"], "name": r["name"], "school": r["school"], "city": r["city"],
                         "region": r["region"], "district": r["district"]}
                        for r in conn.execute(
                            "SELECT o.*, u.username, u.name, u.school, u.city, u.region, u.district "
                            "FROM orders o JOIN users u ON u.id=o.user_id "
                            "ORDER BY (o.status='new') DESC, o.ts DESC LIMIT 500")]
                return self.send_json(200, {"rows": rows})
        return self.send_json(404, {"error": "not_found"})

    # ---- POST
    def do_POST(self):
        path = self.path.split("?")[0]
        photo_route = path in ("/api/photo", "/api/register")
        limit = platform_api.MAX_BOOK if path == "/api/teacher/books/upload" else \
            MAX_PHOTO_BODY if photo_route else 400_000 if "/lessons/" in path or path in platform_api.AI_PATHS else MAX_BODY
        data = self.read_json(limit)
        if data is None:
            return self.send_json(400, {"error": "bad_json"})

        if path in platform_api.AI_PATHS:
            # AI uzoq ishlaydi — bazani qulflamasdan / AI долго — без блокировки базы
            with _write_lock, db() as conn:
                user = self.current_user(conn)
                if user is None:
                    return self.send_json(401, {"error": "auth"})
                job = platform_api.ai_prepare(conn, user, path, data, school_key(user))
            if job[0] != "job":
                return self.send_json(*job)
            return self.send_json(*platform_api.ai_run(job))

        if path == "/api/run":
            if not RUN_ENABLED:
                return self.send_json(404, {"error": "not_found"})
            status, res = handle_run(data, client_ip(self))
            return self.send_json(status, res)

        if path in ("/api/register", "/api/login"):
            if not login_allowed(client_ip(self)):
                return self.send_json(429, {"error": "too_many"})
            username = str(data.get("username", "")).strip()
            password = str(data.get("password", ""))
            if len(username) < 3 or len(password) < 4 or len(username) > 30:
                return self.send_json(400, {"error": "short"})
            with _write_lock, db() as conn:
                if path == "/api/register":
                    name = clean(data.get("name"), 40)
                    code = clean(data.get("code"), 20).upper()
                    photo = decode_photo(data.get("photo"))
                    if not name:
                        return self.send_json(400, {"error": "profile"})
                    if code:
                        # Ustoz: maktab koddan olinadi / учитель: школа берётся из кода
                        c = conn.execute("SELECT * FROM teacher_codes WHERE code=?", (code,)).fetchone()
                        if c is None or c["used_by"] is not None:
                            return self.send_json(400, {"error": "code"})
                        region, district, school, role = c["region"], c["district"], c["school"], "teacher"
                    else:
                        region, district = clean(data.get("region")), clean(data.get("district"))
                        school = clean(data.get("school"))
                        role = "student"
                        if not region or not district or not school:
                            return self.send_json(400, {"error": "profile"})
                        if photo is None:
                            return self.send_json(400, {"error": "photo"})
                    try:
                        uid = create_user(conn, username, password, name, role=role, school=school, city=district,
                                          region=region, district=district)
                    except sqlite3.IntegrityError:
                        return self.send_json(409, {"error": "taken"})
                    if code:
                        conn.execute("UPDATE teacher_codes SET used_by=?, used_at=? WHERE code=?", (uid, time.time(), code))
                    if photo is not None:
                        save_photo(conn, uid, photo)
                row = conn.execute("SELECT * FROM users WHERE username=?", (username,)).fetchone()
                if row is None or not secrets.compare_digest(row["pw_hash"], hash_pw(password, row["salt"])):
                    return self.send_json(401, {"error": "auth"})
                token = self.new_token(conn, row["id"])
                return self.send_json(200, {"token": token, "user": public_user(row)})

        with _write_lock, db() as conn:
            user = self.current_user(conn)
            if user is None:
                return self.send_json(401, {"error": "auth"})
            old = state_of(user)

            game = ("/api/complete", "/api/placement", "/api/cancel", "/api/helper", "/api/claim", "/api/chest",
                    "/api/shop/buy", "/api/tests/submit", "/api/portfolio", "/api/exam/start", "/api/exam/finish")
            if path in game and user["role"] != "student":
                return self.send_json(403, {"error": "forbidden"})
            if path.startswith("/api/teacher/") and user["role"] != "teacher":
                return self.send_json(403, {"error": "forbidden"})
            if path.startswith("/api/admin/") and user["role"] != "admin":
                return self.send_json(403, {"error": "forbidden"})

            res = platform_api.handle(conn, user, path, data, school_key(user), BUILTIN_LESSONS, LESSONS, COURSE_LESSONS)
            if res is not None:
                return self.send_json(*res)

            def reply(new_state, extra=None):
                save_state(conn, user["id"], old, new_state)
                fresh = conn.execute("SELECT * FROM users WHERE id=?", (user["id"],)).fetchone()
                return self.send_json(200, {"user": public_user(fresh), **(extra or {})})

            if path == "/api/complete":
                lid = str(data.get("lesson_id", ""))
                meta = LESSONS.get(lid)
                if meta is None:
                    return self.send_json(400, {"error": "lesson"})
                total = max(0, min(int(data.get("total") or 0), 20))
                correct = max(0, min(int(data.get("correct") or 0), total))
                share = max(0.0, min(float(data.get("time_share") or 1.0), 1.0))
                combo = max(0, min(int(data.get("best_combo") or 0), 20))
                perfect = bool(data.get("perfect")) and correct == total
                state, result = complete_lesson(old, lid, meta["xp"], perfect, combo, correct, total, share)
                conn.execute("INSERT INTO attempts (user_id, ts, lesson_id, correct, total, time_share) VALUES (?,?,?,?,?,?)",
                             (user["id"], time.time(), lid, correct, total, share))
                save_state(conn, user["id"], old, state)
                promoted = check_promotion(conn, conn.execute("SELECT * FROM users WHERE id=?", (user["id"],)).fetchone(), state)
                if promoted:
                    state, _ = promote(state)
                    conn.execute("UPDATE users SET state=?, league=?, promoted_at=? WHERE id=?",
                                 (json.dumps(state, ensure_ascii=False), state["league"], time.time(), user["id"]))
                    result["promoted"] = promoted
                fresh = conn.execute("SELECT * FROM users WHERE id=?", (user["id"],)).fetchone()
                return self.send_json(200, {"user": public_user(fresh), "result": result})

            if path == "/api/placement":
                points = max(0, min(int(data.get("points") or 0), 15))
                share = max(0.0, min(float(data.get("time_share") or 1.0), 1.0))
                league = str(data.get("league", ""))
                if league not in LEAGUES:
                    league = "master" if points >= 13 or (points >= 12 and share < 0.75) else (
                        "advanced" if points >= 7 else "beginner")
                state, gained = set_league(old, league)
                return reply(state, {"xp": gained})

            if path == "/api/cancel":
                lid = str(data.get("lesson_id", ""))
                if lid not in LESSONS:
                    return self.send_json(400, {"error": "lesson"})
                return reply(cancel_test(old, lid))

            if path == "/api/helper":
                state, ok = spend(old, HELPER_COST)
                if not ok:
                    return self.send_json(402, {"error": "not_enough"})
                return reply(state, {"cost": HELPER_COST})

            if path == "/api/claim":
                state, xp = claim_quest(old, str(data.get("quest_id", "")))
                return reply(state, {"xp": xp})

            if path == "/api/chest":
                cid = str(data.get("course_id", ""))
                ids = COURSE_LESSONS.get(cid)
                if not ids:
                    return self.send_json(400, {"error": "course"})
                league = old.get("league") or "beginner"
                ids = [i for i in ids if LESSONS[i]["leagues"] is None or league in LESSONS[i]["leagues"]]
                state, xp = open_chest(old, cid, ids)
                return reply(state, {"xp": xp})

            if path == "/api/shop/buy":
                item = SHOP.get(str(data.get("item_id", "")))
                if item is None:
                    return self.send_json(400, {"error": "item"})
                if user["role"] != "student":
                    return self.send_json(403, {"error": "forbidden"})
                state, ok = spend(old, item["price"])
                if not ok:
                    return self.send_json(402, {"error": "not_enough"})
                cur = conn.execute("INSERT INTO orders (user_id, item_id, price, status, ts) VALUES (?,?,?,?,?)",
                                   (user["id"], item["id"], item["price"], "new", time.time()))
                return reply(state, {"order_id": cur.lastrowid})

            if path == "/api/profile":
                name = clean(data.get("name", user["name"]), 40) or user["name"]
                region, district, school = user["region"], user["district"], user["school"]
                if user["role"] == "student":
                    region = clean(data.get("region", region)) or region
                    district = clean(data.get("district", district)) or district
                    school = clean(data.get("school", school)) or school
                conn.execute("UPDATE users SET name=?, region=?, district=?, school=?, city=? WHERE id=?",
                             (name, region, district, school, district, user["id"]))
                fresh = conn.execute("SELECT * FROM users WHERE id=?", (user["id"],)).fetchone()
                return self.send_json(200, {"user": public_user(fresh)})

            if path == "/api/tests/submit":
                t = conn.execute("SELECT * FROM ttests WHERE id=? AND school_key=? AND active=1",
                                 (int(data.get("test_id") or 0), school_key(user))).fetchone()
                if t is None:
                    return self.send_json(404, {"error": "not_found"})
                body = json.loads(t["body"])
                correct, total = grade_test(body, data.get("answers"))
                old_r = conn.execute("SELECT * FROM tresults WHERE test_id=? AND user_id=?", (t["id"], user["id"])).fetchone()
                best = max(correct, old_r["best"] if old_r else 0)
                tries = (old_r["tries"] if old_r else 0) + 1
                conn.execute("INSERT OR REPLACE INTO tresults (test_id, user_id, correct, total, best, tries, ts) "
                             "VALUES (?,?,?,?,?,?,?)", (t["id"], user["id"], correct, total, best, tries, time.time()))
                # XP berilmaydi / XP не начисляется
                key = [{"answer": q.get("answer"), "answers": q.get("answers")} for q in body["questions"]]
                return self.send_json(200, {"correct": correct, "total": total, "best": best, "key": key})

            if path == "/api/exam/start":
                course = clean(data.get("course"), 20)
                if course not in COURSE_LESSONS or not course_done(old, course):
                    return self.send_json(400, {"error": "locked"})
                if conn.execute("SELECT 1 FROM certs WHERE user_id=? AND course=?", (user["id"], course)).fetchone():
                    return self.send_json(400, {"error": "passed"})
                ex = conn.execute("SELECT * FROM exams WHERE user_id=? AND course=?", (user["id"], course)).fetchone()
                now = time.time()
                if ex is not None and ex["tries"] > 0 and now < ex["started"] + EXAM_WAIT:
                    return self.send_json(400, {"error": "wait", "until": int((ex["started"] + EXAM_WAIT) * 1000)})
                # Boshlash — urinish hisoblanadi (chiqib ketish ham) / старт — это попытка (выход тоже)
                conn.execute("INSERT INTO exams (user_id, course, tries, best, started, open) VALUES (?,?,1,0,?,1) "
                             "ON CONFLICT(user_id, course) DO UPDATE SET tries=tries+1, started=excluded.started, open=1",
                             (user["id"], course, now))
                ex = conn.execute("SELECT * FROM exams WHERE user_id=? AND course=?", (user["id"], course)).fetchone()
                return self.send_json(200, {"exam": exam_json(ex)})

            if path == "/api/exam/finish":
                course = clean(data.get("course"), 20)
                ex = conn.execute("SELECT * FROM exams WHERE user_id=? AND course=?", (user["id"], course)).fetchone()
                if ex is None or not ex["open"] or time.time() > ex["started"] + EXAM_TIME:
                    return self.send_json(400, {"error": "exam"})
                total = max(1, min(int(data.get("total") or 0), EXAM_SIZE))
                correct = max(0, min(int(data.get("correct") or 0), total))
                score = round(correct * 100 / total)
                if total < EXAM_SIZE // 2:
                    score = 0
                conn.execute("UPDATE exams SET open=0, best=MAX(best, ?) WHERE user_id=? AND course=?",
                             (score, user["id"], course))
                cert = None
                if score >= EXAM_PASS:
                    row = conn.execute("SELECT * FROM certs WHERE user_id=? AND course=?", (user["id"], course)).fetchone()
                    if row is None:
                        school = " · ".join(x for x in (user["school"], user["district"]) if x)
                        conn.execute("INSERT INTO certs (id, user_id, course, score, name, school, issued) VALUES (?,?,?,?,?,?,?)",
                                     (new_cert_id(conn), user["id"], course, score, user["name"] or user["username"],
                                      school, time.time()))
                        row = conn.execute("SELECT * FROM certs WHERE user_id=? AND course=?", (user["id"], course)).fetchone()
                    cert = cert_json(row)
                ex = conn.execute("SELECT * FROM exams WHERE user_id=? AND course=?", (user["id"], course)).fetchone()
                return self.send_json(200, {"passed": cert is not None, "score": score, "cert": cert, "exam": exam_json(ex)})

            if path == "/api/portfolio":
                course = clean(data.get("course"), 20)
                mode = clean(data.get("mode"), 10)
                code = str(data.get("code") or "")
                if course not in COURSE_LESSONS or mode not in PORTFOLIO_MODES or not code.strip() or len(code) > MAX_PROJECT:
                    return self.send_json(400, {"error": "project"})
                old_p = conn.execute("SELECT slug FROM portfolio WHERE user_id=? AND course=?", (user["id"], course)).fetchone()
                slug = old_p["slug"] if old_p else secrets.token_urlsafe(6)
                conn.execute("INSERT OR REPLACE INTO portfolio (user_id, course, slug, title, mode, code, updated) "
                             "VALUES (?,?,?,?,?,?,?)", (user["id"], course, slug, clean(data.get("title"), 80) or course,
                                                        mode, code, time.time()))
                return self.send_json(200, {"slug": slug, "path": f"/p/{slug}"})

            if path == "/api/teacher/tests/save":
                parsed = parse_test(data)
                if parsed is None:
                    return self.send_json(400, {"error": "test"})
                tid = int(data.get("id") or 0)
                active = 1 if data.get("active", True) else 0
                now = time.time()
                if tid:
                    t = conn.execute("SELECT * FROM ttests WHERE id=? AND teacher_id=?", (tid, user["id"])).fetchone()
                    if t is None:
                        return self.send_json(404, {"error": "not_found"})
                    conn.execute("UPDATE ttests SET title=?, body=?, active=?, updated=? WHERE id=?",
                                 (parsed["title"], json.dumps(parsed, ensure_ascii=False), active, now, tid))
                else:
                    tid = conn.execute("INSERT INTO ttests (school_key, teacher_id, title, body, active, created, updated) "
                                       "VALUES (?,?,?,?,?,?,?)", (school_key(user), user["id"], parsed["title"],
                                                                  json.dumps(parsed, ensure_ascii=False), active, now, now)).lastrowid
                return self.send_json(200, {"id": tid})

            if path == "/api/teacher/tests/delete":
                conn.execute("DELETE FROM ttests WHERE id=? AND teacher_id=?", (int(data.get("id") or 0), user["id"]))
                return self.send_json(200, {"ok": True})

            if path == "/api/admin/codes":
                region, district, school = clean(data.get("region")), clean(data.get("district")), clean(data.get("school"))
                if not region or not district or not school:
                    return self.send_json(400, {"error": "profile"})
                code = new_code()
                while conn.execute("SELECT 1 FROM teacher_codes WHERE code=?", (code,)).fetchone():
                    code = new_code()
                conn.execute("INSERT INTO teacher_codes (code, region, district, school, note, created) VALUES (?,?,?,?,?,?)",
                             (code, region, district, school, clean(data.get("note"), 80), time.time()))
                return self.send_json(200, {"code": code})

            if path == "/api/admin/codes/revoke":
                conn.execute("DELETE FROM teacher_codes WHERE code=? AND used_by IS NULL", (clean(data.get("code"), 20).upper(),))
                return self.send_json(200, {"ok": True})

            if path == "/api/name":  # eski ilovalar uchun / для старых версий
                conn.execute("UPDATE users SET name=? WHERE id=?", (str(data.get("name", "")).strip()[:40], user["id"]))
                fresh = conn.execute("SELECT * FROM users WHERE id=?", (user["id"],)).fetchone()
                return self.send_json(200, {"user": public_user(fresh)})

            if path == "/api/photo":
                photo = decode_photo(data.get("photo"))
                if photo is None:
                    return self.send_json(400, {"error": "photo"})
                save_photo(conn, user["id"], photo)
                fresh = conn.execute("SELECT * FROM users WHERE id=?", (user["id"],)).fetchone()
                return self.send_json(200, {"user": public_user(fresh)})

            if path == "/api/admin/order":
                order = conn.execute("SELECT * FROM orders WHERE id=?", (int(data.get("order_id") or 0),)).fetchone()
                status = str(data.get("status", ""))
                if order is None or status not in ("delivered", "cancelled") or order["status"] != "new":
                    return self.send_json(400, {"error": "order"})
                conn.execute("UPDATE orders SET status=? WHERE id=?", (status, order["id"]))
                if status == "cancelled":  # XP qaytariladi / XP возвращается
                    owner = conn.execute("SELECT * FROM users WHERE id=?", (order["user_id"],)).fetchone()
                    s = state_of(owner)
                    s["xp"] += order["price"]
                    conn.execute("UPDATE users SET state=? WHERE id=?", (json.dumps(s, ensure_ascii=False), owner["id"]))
                return self.send_json(200, {"ok": True})

            if path == "/api/logout":
                conn.execute("DELETE FROM tokens WHERE token=?", (self.headers["Authorization"][7:].strip(),))
                return self.send_json(200, {"ok": True})

        return self.send_json(404, {"error": "not_found"})


def decode_photo(value):
    """base64 JPEG/PNG rasmni tekshiradi (≤ 1 MB). / Проверяет фото JPEG/PNG в base64 (≤ 1 МБ)."""
    if not isinstance(value, str) or not value:
        return None
    try:
        raw = base64.b64decode(value.split(",")[-1], validate=True)
    except (ValueError, TypeError):
        return None
    if len(raw) > 1_000_000 or not (raw[:3] == b"\xff\xd8\xff" or raw[:8] == b"\x89PNG\r\n\x1a\n"):
        return None
    return raw


def lan_ip():
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("10.255.255.255", 1))
            return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"


def main():
    ap = argparse.ArgumentParser(description="Idrok Academy server")
    ap.add_argument("--port", type=int, default=int(os.environ.get("PORT", DEFAULT_PORT)))
    ap.add_argument("--teacher-password", default=os.environ.get("TEACHER_PASSWORD") or None)
    args = ap.parse_args()

    if os.environ.get("RENDER") and len(args.teacher_password or "") < 12:
        raise SystemExit("ERROR: Render Environment'da TEACHER_PASSWORD ni kamida 12 belgili qilib o‘rnating. "
                         "/ Задайте TEACHER_PASSWORD (минимум 12 символов) в Render Environment.")

    try:
        cloud.restore(DB_PATH)
    except Exception as e:
        # Zaxirani o‘qib bo‘lmasa, eski ma’lumotni yo‘qotmaslik uchun to‘xtaymiz.
        # Если копию не прочитать — останавливаемся, чтобы не затереть старые данные.
        raise SystemExit(f"ERROR: Supabase zaxirasini o‘qib bo‘lmadi / не удалось прочитать копию: {e}")
    init_db()
    with db() as conn:
        platform_api.rebuild(conn, BUILTIN_LESSONS, LESSONS, COURSE_LESSONS)
    load_photo_ids()
    status = ensure_teacher(args.teacher_password)
    ip = lan_ip()
    print("=" * 60)
    print("  Idrok Academy server ishga tushdi / сервер запущен")
    print(f"  Shu kompyuterda:  http://127.0.0.1:{args.port}")
    print(f"  Wi‑Fi:            http://{ip}:{args.port}")
    if status == "created":
        print(f"  Ustoz akkaunti / аккаунт учителя: «{TEACHER_LOGIN}»")
        if not args.teacher_password:
            print("  ⚠ Parol standart. O‘zgartiring! / Пароль по умолчанию. Смените!")
    print(f"  Python /api/run: {'yoqilgan' if RUN_ENABLED else 'o‘chirilgan'}")
    print("=" * 60, flush=True)
    with _write_lock, db() as conn:
        conn.execute("DELETE FROM tokens WHERE created<?", (time.time() - TOKEN_DAYS * 86400,))
    cloud.start(DB_PATH)

    def stop(*_):
        # Render to‘xtatishidan oldin oxirgi zaxira / последняя копия перед остановкой Render
        try:
            cloud.backup(DB_PATH, force=True)
        except Exception as e:
            print(f"  Supabase: oxirgi zaxira xatosi / ошибка последней копии: {e}", flush=True)
        raise SystemExit(0)

    signal.signal(signal.SIGTERM, stop)
    httpd = ThreadingHTTPServer(("0.0.0.0", args.port), Handler)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        stop()
        print("\nServer to‘xtadi / Сервер остановлен")


if __name__ == "__main__":
    main()
