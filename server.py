"""Kodla mahalliy serveri — bepul, qo‘shimcha kutubxonasiz (faqat Python).
Локальный сервер Kodla — бесплатный, без дополнительных библиотек (только Python).

Ishga tushirish / Запуск:
    python server.py
    python server.py --teacher-password YangiParol   # ustoz parolini o‘zgartirish / сменить пароль учителя

Ma’lumotlar shu papkadagi kodla.db fayliga saqlanadi.
Данные хранятся в файле kodla.db в этой папке.
"""

import argparse
import hashlib
import json
import secrets
import socket
import sqlite3
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from lessons import ALL_LESSONS, COURSES
from progress import buy_avatar, claim_quest, complete_lesson, level_of, normalize, open_chest

DB_PATH = Path(__import__("os").environ.get("KODLA_DB_PATH", str(Path(__file__).with_name("kodla.db"))))
DEFAULT_PORT = 8765
TEACHER_LOGIN = "ustoz"
DEFAULT_TEACHER_PASSWORD = "ustoz123"
LESSON_ORDER = [l["id"] for c in COURSES for l in c["lessons"]]

_write_lock = threading.Lock()


# ---------------------------------------------------------------- ma’lumotlar bazasi / база данных
def db():
    conn = sqlite3.connect(DB_PATH, timeout=10)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    with db() as conn:
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
        """)


def hash_pw(password, salt):
    return hashlib.pbkdf2_hmac("sha256", password.encode(), bytes.fromhex(salt), 200_000).hex()


def create_user(conn, username, password, name, role="student"):
    salt = secrets.token_hex(16)
    conn.execute("INSERT INTO users (username, name, salt, pw_hash, role, state, created) VALUES (?,?,?,?,?,?,?)",
                 (username, name, salt, hash_pw(password, salt), role, "{}", time.time()))


def ensure_teacher(new_password=None):
    with _write_lock, db() as conn:
        row = conn.execute("SELECT id FROM users WHERE role='teacher'").fetchone()
        if row is None:
            create_user(conn, TEACHER_LOGIN, new_password or DEFAULT_TEACHER_PASSWORD, "Ustoz", "teacher")
            return "created"
        if new_password:
            salt = secrets.token_hex(16)
            conn.execute("UPDATE users SET salt=?, pw_hash=? WHERE id=?", (salt, hash_pw(new_password, salt), row["id"]))
            return "changed"
    return "exists"


def public_user(row):
    state = normalize(json.loads(row["state"] or "{}"))
    return {"username": row["username"], "name": row["name"], "role": row["role"], "state": state}


# ---------------------------------------------------------------- so‘rovlar / запросы
class Handler(BaseHTTPRequestHandler):
    server_version = "Kodla/1.0"

    def log_message(self, fmt, *args):  # qisqa log / короткий лог
        print(f"  {self.address_string()}  {self.command} {self.path}  →  {args[1] if len(args) > 1 else ''}")

    def send_json(self, status, data):
        body = json.dumps(data, ensure_ascii=False).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def read_json(self):
        length = int(self.headers.get("Content-Length") or 0)
        if length > 100_000:
            return None
        try:
            return json.loads(self.rfile.read(length) or b"{}")
        except json.JSONDecodeError:
            return None

    def current_user(self, conn):
        auth = self.headers.get("Authorization", "")
        if not auth.startswith("Bearer "):
            return None
        return conn.execute("SELECT u.* FROM tokens t JOIN users u ON u.id=t.user_id WHERE t.token=?",
                            (auth[7:].strip(),)).fetchone()

    def new_token(self, conn, user_id):
        token = secrets.token_urlsafe(32)
        conn.execute("INSERT INTO tokens (token, user_id, created) VALUES (?,?,?)", (token, user_id, time.time()))
        return token

    # ---- GET
    def do_GET(self):
        path = self.path.split("?")[0]
        if path == "/api/ping":
            return self.send_json(200, {"ok": True, "app": "kodla"})
        with db() as conn:
            user = self.current_user(conn)
            if user is None:
                return self.send_json(401, {"error": "auth"})
            if path == "/api/me":
                return self.send_json(200, {"user": public_user(user)})
            if path == "/api/leaderboard":
                rows = []
                for r in conn.execute("SELECT * FROM users WHERE role='student'"):
                    s = normalize(json.loads(r["state"] or "{}"))
                    if s["xp"] > 0:
                        rows.append({"username": r["username"], "name": r["name"] or r["username"], "xp": s["xp"],
                                     "level": level_of(s["xp"]), "streak": s["streak"], "done": len(s["done"]),
                                     "avatar": s["avatar"]})
                rows.sort(key=lambda x: (-x["xp"], x["name"].lower()))
                return self.send_json(200, {"rows": rows[:50]})
            if path == "/api/teacher/students":
                if user["role"] != "teacher":
                    return self.send_json(403, {"error": "forbidden"})
                rows = []
                for r in conn.execute("SELECT * FROM users WHERE role='student' ORDER BY name COLLATE NOCASE"):
                    s = normalize(json.loads(r["state"] or "{}"))
                    rows.append({"username": r["username"], "name": r["name"] or r["username"], "xp": s["xp"],
                                 "streak": s["streak"], "today_xp": s["today_xp"], "last_day": s["last_day"],
                                 "avatar": s["avatar"], "gems": s["gems"],
                                 "done": [lid for lid in LESSON_ORDER if s["done"].get(lid)]})
                return self.send_json(200, {"rows": rows, "lessons": LESSON_ORDER})
        return self.send_json(404, {"error": "not_found"})

    # ---- POST
    def do_POST(self):
        path = self.path.split("?")[0]
        data = self.read_json()
        if data is None:
            return self.send_json(400, {"error": "bad_json"})

        if path in ("/api/register", "/api/login"):
            username = str(data.get("username", "")).strip()
            password = str(data.get("password", ""))
            if len(username) < 3 or len(password) < 4 or len(username) > 30:
                return self.send_json(400, {"error": "short"})
            with _write_lock, db() as conn:
                if path == "/api/register":
                    try:
                        create_user(conn, username, password, str(data.get("name", "")).strip()[:30] or username)
                    except sqlite3.IntegrityError:
                        return self.send_json(409, {"error": "taken"})
                row = conn.execute("SELECT * FROM users WHERE username=?", (username,)).fetchone()
                if row is None or not secrets.compare_digest(row["pw_hash"], hash_pw(password, row["salt"])):
                    return self.send_json(401, {"error": "auth"})
                token = self.new_token(conn, row["id"])
                return self.send_json(200, {"token": token, "user": public_user(row)})

        with _write_lock, db() as conn:
            user = self.current_user(conn)
            if user is None:
                return self.send_json(401, {"error": "auth"})

            old_state = json.loads(user["state"] or "{}")

            def save_and_reply(state, extra):
                conn.execute("UPDATE users SET state=? WHERE id=?", (json.dumps(state), user["id"]))
                fresh = conn.execute("SELECT * FROM users WHERE id=?", (user["id"],)).fetchone()
                return self.send_json(200, {"user": public_user(fresh), **extra})

            if path == "/api/complete":
                lid = str(data.get("lesson_id", ""))
                if lid not in ALL_LESSONS:
                    return self.send_json(400, {"error": "lesson"})
                lesson, _ = ALL_LESSONS[lid]
                combo = max(0, min(int(data.get("best_combo") or 0), len(lesson["steps"])))
                state, result = complete_lesson(old_state, lid, lesson["xp"], bool(data.get("perfect")), combo)
                return save_and_reply(state, {"result": result})

            if path == "/api/claim":
                state, gems = claim_quest(old_state, str(data.get("quest_id", "")))
                return save_and_reply(state, {"gems": gems})

            if path == "/api/chest":
                cid = str(data.get("course_id", ""))
                course = next((c for c in COURSES if c["id"] == cid), None)
                if course is None:
                    return self.send_json(400, {"error": "course"})
                state, gems = open_chest(old_state, cid, [l["id"] for l in course["lessons"]])
                return save_and_reply(state, {"gems": gems})

            if path == "/api/avatar":
                state, ok = buy_avatar(old_state, str(data.get("avatar", "")))
                return save_and_reply(state, {"ok": ok})

            if path == "/api/name":
                conn.execute("UPDATE users SET name=? WHERE id=?", (str(data.get("name", "")).strip()[:30], user["id"]))
                fresh = conn.execute("SELECT * FROM users WHERE id=?", (user["id"],)).fetchone()
                return self.send_json(200, {"user": public_user(fresh)})

            if path == "/api/logout":
                conn.execute("DELETE FROM tokens WHERE token=?", (self.headers["Authorization"][7:].strip(),))
                return self.send_json(200, {"ok": True})

        return self.send_json(404, {"error": "not_found"})


def lan_ip():
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("10.255.255.255", 1))  # paket yuborilmaydi / пакет не отправляется
            return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"


def main():
    ap = argparse.ArgumentParser(description="Kodla local server")
    ap.add_argument("--port", type=int, default=DEFAULT_PORT)
    ap.add_argument("--teacher-password", help="ustoz parolini o‘rnatish / задать пароль учителя")
    args = ap.parse_args()

    init_db()
    status = ensure_teacher(args.teacher_password)
    ip = lan_ip()
    print("=" * 60)
    print("  Kodla server ishga tushdi / сервер запущен")
    print(f"  Shu kompyuterda / На этом компьютере:  http://127.0.0.1:{args.port}")
    print(f"  Wi‑Fi dagi qurilmalar / Устройства в Wi‑Fi:  http://{ip}:{args.port}")
    if status == "created":
        print(f"  Ustoz akkaunti / Аккаунт учителя: login «{TEACHER_LOGIN}»")
        if not args.teacher_password:
            print("  ⚠ Parol standart qiymatda. Uni o‘zgartiring / Смените пароль учителя.")
    elif status == "changed":
        print("  Ustoz paroli yangilandi / Пароль учителя обновлён")
    print("  To‘xtatish / Остановить:  Ctrl+C")
    print("=" * 60)
    httpd = ThreadingHTTPServer(("0.0.0.0", args.port), Handler)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer to‘xtadi / Сервер остановлен")


if __name__ == "__main__":
    main()
