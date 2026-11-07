"""Darslar ma'lumot sifatida, AI yordamchi va kitoblar.
Уроки как данные, AI-помощник и книги (PDF).

Faqat standart kutubxona + pypdf (kitoblar uchun) / только stdlib + pypdf (для книг).
"""
import base64
import io
import json
import os
import re
import secrets
import time
import urllib.error
import urllib.request

COURSES = ("html", "css", "js", "py", "ai")
LEAGUES = ("beginner", "advanced", "master")
ANIM_KINDS = ("trace", "render", "chat", "box", "flex", "learn", "grid")
STEP_TYPES = ("read", "quiz", "fill", "order", "try")
MAX_LESSON = 80_000
MAX_BOOK = 22_000_000          # base64 (~16 MB PDF)
MAX_PAGES = 800
AI_DAILY = 40                  # bir kunda AI so‘rovlari / AI-запросов в день

GEMINI_KEY = os.environ.get("GEMINI_API_KEY", "").strip()
GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-2.5-flash").strip()


def init(conn):
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS clessons (
            id TEXT PRIMARY KEY,
            scope TEXT NOT NULL,            -- global | school
            school_key TEXT NOT NULL DEFAULT '',
            course TEXT NOT NULL,
            data TEXT NOT NULL,
            hidden INTEGER NOT NULL DEFAULT 0,
            author INTEGER NOT NULL DEFAULT 0,
            updated REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS books (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            school_key TEXT NOT NULL,
            author INTEGER NOT NULL,
            title TEXT NOT NULL,
            pages TEXT NOT NULL,
            created REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS ai_usage (
            user_id INTEGER NOT NULL,
            day TEXT NOT NULL,
            n INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY (user_id, day)
        );
    """)


# ------------------------------------------------------------------ tozalash / очистка
def _s(v, n):
    if v is None:
        return ""
    v = str(v).replace("\r", "")
    return v[:n]


def _tr(v, n=600):
    if isinstance(v, dict):
        uz, ru = _s(v.get("uz"), n).strip(), _s(v.get("ru"), n).strip()
    else:
        uz = ru = _s(v, n).strip()
    if not uz and not ru:
        return None
    return {"uz": uz or ru, "ru": ru or uz}


def _lines(v, n=60, w=200):
    if isinstance(v, str):
        v = v.split("\n")
    if not isinstance(v, list):
        return []
    return [_s(x, w) for x in v[:n]]


def clean_anim(a):
    if not isinstance(a, dict) or a.get("kind") not in ANIM_KINDS:
        return None
    out = {"kind": a["kind"], "lang": _s(a.get("lang"), 10), "code": _lines(a.get("code"), 30, 160)}
    frames = []
    for f in (a.get("frames") or [])[:40]:
        if not isinstance(f, dict):
            continue
        say = _tr(f.get("say"), 300) or {"uz": "", "ru": ""}
        fr = {"say": say, "line": int(f.get("line", -1)) if str(f.get("line", -1)).lstrip("-").isdigit() else -1}
        vars_ = f.get("vars")
        if isinstance(vars_, dict):
            fr["vars"] = {_s(k, 20): _s(v, 40) for k, v in list(vars_.items())[:8]}
        if f.get("hot"):
            fr["hot"] = _s(f.get("hot"), 20)
        fr["out"] = _lines(f.get("out"), 12, 120)
        if isinstance(f.get("arr"), list):
            fr["arr"] = _lines(f.get("arr"), 12, 30)
            fr["arrName"] = _s(f.get("arrName"), 20)
            fr["arrHot"] = int(f.get("arrHot", -1)) if str(f.get("arrHot", -1)).lstrip("-").isdigit() else -1
        rv = f.get("reveal", 0)
        fr["reveal"] = int(rv) if str(rv).isdigit() else 0
        ex = f.get("extra")
        if isinstance(ex, dict):
            fr["extra"] = json.loads(json.dumps(ex)[:4000]) if len(json.dumps(ex)) < 4000 else {}
        frames.append(fr)
    if not frames:
        return None
    out["frames"] = frames
    els = []
    for e in (a.get("els") or [])[:20]:
        if isinstance(e, dict):
            st = e.get("style") if isinstance(e.get("style"), dict) else {}
            els.append({"tag": _s(e.get("tag"), 12) or "p", "text": _s(e.get("text"), 120),
                        "line": int(e.get("line", 0)) if str(e.get("line", 0)).isdigit() else 0,
                        "style": {_s(k, 30): _s(v, 60) for k, v in list(st.items())[:10]}})
    if els:
        out["els"] = els
    chat = []
    for m in (a.get("chat") or [])[:16]:
        if isinstance(m, dict) and _tr(m.get("text"), 300):
            chat.append({"me": bool(m.get("me")), "text": _tr(m.get("text"), 300)})
    if chat:
        out["chat"] = chat
    for key in ("points", "grids"):
        if isinstance(a.get(key), list):
            out[key] = json.loads(json.dumps(a[key][:40]))
    return out


def clean_step(st):
    if not isinstance(st, dict):
        return None
    t = st.get("t")
    if t not in STEP_TYPES:
        return None
    d = max(1, min(3, int(st.get("d", 1)) if str(st.get("d", 1)).isdigit() else 1))
    if t == "read":
        h, p = _tr(st.get("h"), 200), _tr(st.get("p"), 1500)
        if not h or not p:
            return None
        out = {"t": "read", "h": h, "p": p}
        if st.get("code"):
            out["code"] = _s(st.get("code"), 1500)
        an = clean_anim(st.get("anim"))
        if an:
            out["anim"] = an
        return out
    if t == "quiz":
        q = _tr(st.get("q"), 400)
        opts = [o for o in (_tr(x, 200) for x in (st.get("o") or [])[:4]) if o]
        a = st.get("a", 0)
        if not q or len(opts) < 2 or not isinstance(a, int) or not 0 <= a < len(opts):
            return None
        out = {"t": "quiz", "q": q, "o": opts, "a": a, "d": d, "mono": bool(st.get("mono"))}
        if st.get("code"):
            out["code"] = _s(st.get("code"), 800)
        if _tr(st.get("e"), 500):
            out["e"] = _tr(st.get("e"), 500)
        return out
    if t == "fill":
        q = _tr(st.get("q"), 400)
        ans = [a for a in (_s(x, 80).strip() for x in (st.get("answers") or [])[:5]) if a]
        if not q or not ans:
            return None
        out = {"t": "fill", "q": q, "pre": _s(st.get("pre"), 300), "post": _s(st.get("post"), 300), "answers": ans, "d": d}
        if _tr(st.get("e"), 500):
            out["e"] = _tr(st.get("e"), 500)
        return out
    if t == "order":
        q = _tr(st.get("q"), 400)
        lines = [x for x in _lines(st.get("lines"), 10, 160) if x.strip()]
        if not q or not 2 <= len(lines) <= 10:
            return None
        out = {"t": "order", "q": q, "lines": lines, "d": d}
        if _tr(st.get("e"), 500):
            out["e"] = _tr(st.get("e"), 500)
        return out
    # try
    task = _tr(st.get("task"), 500)
    mode = st.get("mode") if st.get("mode") in ("html", "css", "js", "py") else "html"
    if not task:
        return None
    must = [x for x in (_s(m, 80).strip() for m in (st.get("must") or [])[:8]) if x]
    outs = [x for x in (_s(m, 120).strip() for m in (st.get("out") or [])[:5]) if x]
    return {"t": "try", "mode": mode, "task": task, "start": _s(st.get("start"), 1500),
            "hint": _tr(st.get("hint"), 400) or {"uz": "", "ru": ""}, "solution": _s(st.get("solution"), 2000),
            "must": must, "out": outs, "d": d}


def clean_lesson(d, scope):
    if not isinstance(d, dict):
        return None
    title = _tr(d.get("title"), 120)
    course = d.get("course")
    if not title or course not in COURSES:
        return None
    steps = [s for s in (clean_step(x) for x in (d.get("steps") or [])[:30]) if s]
    if not steps:
        return None
    leagues = d.get("leagues")
    if isinstance(leagues, list):
        leagues = [x for x in leagues if x in LEAGUES] or None
    else:
        leagues = None
    xp = 0 if scope == "school" else max(5, min(50, int(d.get("xp", 20)) if str(d.get("xp", 20)).isdigit() else 20))
    pos = d.get("pos")
    out = {"title": title, "course": course, "xp": xp, "leagues": leagues, "steps": steps,
           "pos": int(pos) if isinstance(pos, int) else None}
    if len(json.dumps(out, ensure_ascii=False)) > MAX_LESSON:
        return None
    return out


# ------------------------------------------------------------------ katalog / каталог
def rebuild(conn, builtin, lessons, course_lessons):
    """Asl darslar + global darslar → LESSONS va COURSE_LESSONS / встроенные + глобальные."""
    lessons.clear()
    for k, v in builtin.items():
        lessons[k] = dict(v)
    order = {}
    for lid, m in builtin.items():
        order.setdefault(m["course"], []).append(lid)
    rows = conn.execute("SELECT * FROM clessons WHERE scope='global' ORDER BY updated").fetchall()
    hidden = set()
    extra = []
    for r in rows:
        if r["hidden"]:
            hidden.add(r["id"])
        try:
            d = json.loads(r["data"]) if r["data"] else None
        except ValueError:
            d = None
        if d is None:
            continue
        lessons[r["id"]] = {"course": d["course"], "xp": d.get("xp", 20), "leagues": d.get("leagues"),
                            "title": d["title"].get("uz", "")}
        if r["id"] not in builtin:
            extra.append((r["id"], d))
    for lid, d in extra:
        lst = order.setdefault(d["course"], [])
        pos = d.get("pos")
        if isinstance(pos, int) and 0 <= pos <= len(lst):
            lst.insert(pos, lid)
        else:
            lst.append(lid)
    course_lessons.clear()
    for c, ids in order.items():
        course_lessons[c] = [i for i in ids if i not in hidden]


def content_for(conn, user, school_key):
    rows = conn.execute("SELECT * FROM clessons WHERE scope='global' OR (scope='school' AND school_key=?)",
                        (school_key,)).fetchall()
    out = []
    for r in rows:
        try:
            d = json.loads(r["data"]) if r["data"] else None
        except ValueError:
            d = None
        out.append({"id": r["id"], "scope": r["scope"], "hidden": bool(r["hidden"]), "updated": int(r["updated"]),
                    "data": d})
    return out


# ------------------------------------------------------------------ AI (Gemini)
LESSON_SCHEMA = """Dars JSON formati (faqat shu formatda javob ber):
{"title":{"uz":"...","ru":"..."},"steps":[STEP,...]}
STEP turlari:
- {"t":"read","h":{"uz","ru"},"p":{"uz","ru"},"code":"(ixtiyoriy kod misol)","anim":ANIM(ixtiyoriy)}
- {"t":"quiz","q":{"uz","ru"},"o":[{"uz","ru"},... 3-4 ta],"a":<to'g'ri variant indeksi>,"code":"(ixtiyoriy)","mono":<variantlar kodmi>,"e":{"uz","ru"}(tushuntirish),"d":1-3}
- {"t":"fill","q":{"uz","ru"},"pre":"kod boshi","post":"kod oxiri","answers":["to'g'ri javob",...],"e":{"uz","ru"},"d":1-3}
- {"t":"order","q":{"uz","ru"},"lines":["to'g'ri tartibdagi 3-6 qator kod"],"e":{"uz","ru"},"d":1-3}
- {"t":"try","mode":"html|css|js|py","task":{"uz","ru"},"start":"boshlang'ich kod","hint":{"uz","ru"},"solution":"to'liq to'g'ri yechim","must":["kodda bo'lishi shart bo'lgan qismlar, masalan <h1>"],"out":["py uchun: natijada chiqishi kerak bo'lgan matn"]}
ANIM (animatsiya) turlari:
- kod qadamma-qadam: {"kind":"trace","lang":"py|js","code":["qator1","qator2"],"frames":[{"line":0,"say":{"uz","ru"},"vars":{"x":"3"},"out":["chiqish"]},...]}
- HTML/CSS sahifada paydo bo'lishi: {"kind":"render","lang":"html","code":["<h1>Salom</h1>","<p>Matn</p>"],"els":[{"tag":"h1","text":"Salom","line":0},{"tag":"p","text":"Matn","line":1,"style":{"color":"#0A6CFF"}}],"frames":[{"line":0,"reveal":1,"say":{"uz","ru"}},{"line":1,"reveal":2,"say":{"uz","ru"}}]}
- suhbat (AI mavzulari uchun): {"kind":"chat","chat":[{"me":true,"text":{"uz","ru"}},{"me":false,"text":{"uz","ru"}}],"frames":[{"reveal":1,"say":{"uz","ru"}},{"reveal":2,"say":{"uz","ru"}}]}
Qoidalar: matnlar O'zbek (lotin) va Rus tillarida, 10-15 yoshli o'quvchiga oddiy so'zlar bilan, hayotiy misol bilan.
Dars tuzilishi: 1) nazariya (read) qisqa va tushunarli, 2) animatsiyali read (anim bilan, 3-8 kadr), 3) 3-5 ta savol (quiz/fill/order, har birida e - tushuntirish), 4) 1 ta amaliyot (try).
Kod va javoblar 100% to'g'ri bo'lsin. 'a' indeksi to'g'ri variantni ko'rsatsin. Faqat JSON qaytar."""


def _usage_ok(conn, uid):
    day = time.strftime("%Y-%m-%d")
    r = conn.execute("SELECT n FROM ai_usage WHERE user_id=? AND day=?", (uid, day)).fetchone()
    if r and r["n"] >= AI_DAILY:
        return False
    conn.execute("INSERT INTO ai_usage (user_id, day, n) VALUES (?,?,1) ON CONFLICT(user_id, day) DO UPDATE SET n=n+1",
                 (uid, day))
    return True


def gemini(prompt, system):
    if not GEMINI_KEY:
        return None, "ai_off"
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent"
    body = {"systemInstruction": {"parts": [{"text": system}]},
            "contents": [{"role": "user", "parts": [{"text": prompt}]}],
            "generationConfig": {"responseMimeType": "application/json", "temperature": 0.6}}
    req = urllib.request.Request(url, data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json", "x-goog-api-key": GEMINI_KEY})
    try:
        with urllib.request.urlopen(req, timeout=110) as r:
            res = json.loads(r.read())
    except urllib.error.HTTPError as e:
        return None, "ai_busy" if e.code in (429, 503) else "ai_error"
    except Exception:  # tarmoq / сеть
        return None, "ai_error"
    try:
        text = "".join(p.get("text", "") for p in res["candidates"][0]["content"]["parts"]).strip()
        if text.startswith("```"):
            text = re.sub(r"^```(json)?|```$", "", text, flags=re.M).strip()
        return json.loads(text), None
    except (KeyError, IndexError, ValueError):
        return None, "ai_error"


TEST_SCHEMA = """Test JSON formati: {"title":"...","questions":[{"type":"quiz","q":"savol","options":["A","B","C","D"],"answer":<to'g'ri indeks>},{"type":"fill","q":"savol (javob bitta so'z yoki son)","answers":["javob"]}]}
Savollar 8-15 ta, faqat berilgan matn asosida, aniq va bir ma'noli. Til: O'zbek (lotin). Faqat JSON qaytar."""

AI_PATHS = ("/api/ai/lesson", "/api/teacher/books/lesson", "/api/teacher/books/test")


def ai_prepare(conn, user, path, data, school_key):
    """Bazadan kerakli narsani oladi (qulf ostida). Natija: (status, javob) yoki ('job', ...).
    Берёт нужное из базы (под блокировкой). Результат: (status, ответ) или ('job', ...)."""
    role = user["role"]
    if path == "/api/ai/lesson" and role not in ("admin", "teacher"):
        return 403, {"error": "forbidden"}
    book_text = None
    if path.startswith("/api/teacher/books/"):
        if role != "teacher":
            return 403, {"error": "forbidden"}
        try:
            bid = int(data.get("id") or 0)
        except (TypeError, ValueError):
            bid = 0
        b = conn.execute("SELECT * FROM books WHERE id=? AND school_key=?", (bid, school_key)).fetchone()
        if b is None:
            return 404, {"error": "not_found"}
        pages = json.loads(b["pages"])
        try:
            a = max(1, int(data.get("from") or 1))
            z = min(len(pages), max(a, int(data.get("to") or a)), a + 29)
        except (TypeError, ValueError):
            return 400, {"error": "pages"}
        book_text = "\n\n".join(f"[{i + 1}-bet]\n{pages[i]}" for i in range(a - 1, z))
        if len(book_text.strip()) < 100:
            return 400, {"error": "pdf_scan"}
    course = data.get("course") if data.get("course") in COURSES else "html"
    level = data.get("level") if data.get("level") in LEAGUES else "beginner"
    topic = _s(data.get("topic"), 4000)
    if path.endswith("/test"):
        prompt = f"Qo'shimcha istak: {_s(topic, 500)}\n\nMATN:\n{book_text[:30000]}"
        kind, system = "test", TEST_SCHEMA
    else:
        draft, instr = data.get("draft"), _s(data.get("instruction"), 2000)
        if isinstance(draft, dict) and instr.strip():
            prompt = (f"Mana mavjud dars JSON:\n{json.dumps(draft, ensure_ascii=False)[:30000]}\n\n"
                      f"O'zgartirish so'rovi: {instr}\nDarsni shu so'rov bo'yicha o'zgartir va to'liq JSON qaytar.")
        elif book_text:
            prompt = (f"Kurs: {course}. Daraja: {level}. Quyidagi kitob sahifalari asosida bitta dars tuz. "
                      f"Faqat kitobdagi mavzuni ol, lekin o'z so'zlaring bilan tushuntir.\n"
                      f"Qo'shimcha istak: {topic}\n\nKITOB MATNI:\n{book_text[:30000]}")
        else:
            if not topic.strip():
                return 400, {"error": "topic"}
            prompt = f"Kurs: {course}. Daraja: {level}. Mavzu va tushuntirish:\n{topic}\nShu mavzuda dars tuz."
        kind, system = "lesson", LESSON_SCHEMA
    if not GEMINI_KEY:
        return 503, {"error": "ai_off"}
    if not _usage_ok(conn, user["id"]):
        return 429, {"error": "ai_limit"}
    return ("job", kind, prompt, system, course, "school" if role == "teacher" else "global")


def ai_run(job, call=None):
    """Gemini'ga so‘rov (qulfsiz, uzoq). / Запрос к Gemini (без блокировки, долго)."""
    _, kind, prompt, system, course, scope = job
    res, err = (call or gemini)(prompt, system)
    if err:
        return 503, {"error": err}
    if kind == "test":
        if not isinstance(res, dict) or not isinstance(res.get("questions"), list):
            return 503, {"error": "ai_error"}
        return 200, {"test": res}
    if isinstance(res, dict):
        res["course"] = course
        res.setdefault("xp", 20)
    lesson = clean_lesson(res, scope)
    if lesson is None:
        return 503, {"error": "ai_error"}
    return 200, {"lesson": lesson}


# ------------------------------------------------------------------ kitoblar / книги
def pdf_pages(raw):
    try:
        from pypdf import PdfReader
    except ImportError:
        return None
    try:
        reader = PdfReader(io.BytesIO(raw))
        pages = []
        for p in reader.pages[:MAX_PAGES]:
            try:
                t = p.extract_text() or ""
            except Exception:
                t = ""
            pages.append(re.sub(r"[ \t]+", " ", t).strip()[:6000])
        return pages
    except Exception:
        return None


def new_id(prefix):
    return prefix + secrets.token_hex(4)


def handle(conn, user, path, data, school_key, builtin, lessons, course_lessons):
    """Yangi API yo‘llari. None — bu modulga tegishli emas.
    Новые маршруты API. None — не относится к этому модулю."""
    role = user["role"]

    # ---- admin: global darslar
    if path == "/api/admin/lessons/save":
        if role != "admin":
            return 403, {"error": "forbidden"}
        lesson = clean_lesson(data.get("lesson"), "global")
        if lesson is None:
            return 400, {"error": "lesson"}
        lid = _s(data.get("id"), 40).strip() or new_id("g_")
        if not re.fullmatch(r"[A-Za-z0-9_]+", lid) or lid.startswith("s_"):
            return 400, {"error": "lesson"}
        if lid in builtin:
            lesson["course"] = builtin[lid]["course"]
        conn.execute("INSERT INTO clessons (id, scope, school_key, course, data, hidden, author, updated) "
                     "VALUES (?, 'global', '', ?, ?, 0, ?, ?) ON CONFLICT(id) DO UPDATE SET data=excluded.data, "
                     "course=excluded.course, author=excluded.author, updated=excluded.updated",
                     (lid, lesson["course"], json.dumps(lesson, ensure_ascii=False), user["id"], time.time()))
        rebuild(conn, builtin, lessons, course_lessons)
        return 200, {"id": lid}
    if path == "/api/admin/lessons/hide":
        if role != "admin":
            return 403, {"error": "forbidden"}
        lid = _s(data.get("id"), 40)
        hidden = 1 if data.get("hidden") else 0
        if lid not in lessons and lid not in builtin:
            return 404, {"error": "not_found"}
        row = conn.execute("SELECT id FROM clessons WHERE id=?", (lid,)).fetchone()
        if row:
            conn.execute("UPDATE clessons SET hidden=?, updated=? WHERE id=?", (hidden, time.time(), lid))
        else:
            conn.execute("INSERT INTO clessons (id, scope, school_key, course, data, hidden, author, updated) "
                         "VALUES (?, 'global', '', ?, '', ?, ?, ?)",
                         (lid, builtin[lid]["course"], hidden, user["id"], time.time()))
        rebuild(conn, builtin, lessons, course_lessons)
        return 200, {"ok": True}
    if path == "/api/admin/lessons/delete":
        # o‘zgartirilgan asl dars → aslini tiklash; yangi dars → o‘chirish
        if role != "admin":
            return 403, {"error": "forbidden"}
        lid = _s(data.get("id"), 40)
        conn.execute("DELETE FROM clessons WHERE id=? AND scope='global'", (lid,))
        rebuild(conn, builtin, lessons, course_lessons)
        return 200, {"ok": True}

    # ---- ustoz: maktab darslari (XP yo‘q)
    if path == "/api/teacher/lessons/save":
        if role != "teacher":
            return 403, {"error": "forbidden"}
        lesson = clean_lesson(data.get("lesson"), "school")
        if lesson is None:
            return 400, {"error": "lesson"}
        lid = _s(data.get("id"), 40).strip()
        if lid:
            r = conn.execute("SELECT * FROM clessons WHERE id=? AND scope='school' AND school_key=?", (lid, school_key)).fetchone()
            if r is None:
                return 404, {"error": "not_found"}
        else:
            lid = new_id("s_")
        conn.execute("INSERT INTO clessons (id, scope, school_key, course, data, hidden, author, updated) "
                     "VALUES (?, 'school', ?, ?, ?, 0, ?, ?) ON CONFLICT(id) DO UPDATE SET data=excluded.data, "
                     "course=excluded.course, updated=excluded.updated",
                     (lid, school_key, lesson["course"], json.dumps(lesson, ensure_ascii=False), user["id"], time.time()))
        return 200, {"id": lid}
    if path == "/api/teacher/lessons/delete":
        if role != "teacher":
            return 403, {"error": "forbidden"}
        conn.execute("DELETE FROM clessons WHERE id=? AND scope='school' AND school_key=?", (_s(data.get("id"), 40), school_key))
        return 200, {"ok": True}

    # ---- kitoblar
    if path == "/api/teacher/books/upload":
        if role != "teacher":
            return 403, {"error": "forbidden"}
        title = _s(data.get("title"), 120).strip() or "Kitob"
        try:
            raw = base64.b64decode(str(data.get("pdf", "")), validate=False)
        except ValueError:
            return 400, {"error": "pdf"}
        if not raw.startswith(b"%PDF"):
            return 400, {"error": "pdf"}
        pages = pdf_pages(raw)
        if pages is None:
            return 400, {"error": "pdf"}
        if sum(len(p) for p in pages) < 200:
            return 400, {"error": "pdf_scan"}
        bid = conn.execute("INSERT INTO books (school_key, author, title, pages, created) VALUES (?,?,?,?,?)",
                           (school_key, user["id"], title, json.dumps(pages, ensure_ascii=False), time.time())).lastrowid
        return 200, {"id": bid, "pages": len(pages)}
    if path == "/api/teacher/books/delete":
        if role != "teacher":
            return 403, {"error": "forbidden"}
        conn.execute("DELETE FROM books WHERE id=? AND school_key=?", (int(data.get("id") or 0), school_key))
        return 200, {"ok": True}
    return None


def handle_get(conn, user, path, school_key, lessons, course_lessons):
    role = user["role"]
    if path == "/api/content":
        return 200, {"lessons": content_for(conn, user, school_key), "ai": bool(GEMINI_KEY)}
    if path == "/api/teacher/books":
        if role != "teacher":
            return 403, {"error": "forbidden"}
        rows = conn.execute("SELECT id, title, pages, created FROM books WHERE school_key=? ORDER BY created DESC",
                            (school_key,)).fetchall()
        return 200, {"books": [{"id": r["id"], "title": r["title"], "pages": len(json.loads(r["pages"])),
                                "created": int(r["created"] * 1000)} for r in rows]}
    if path == "/api/admin/stats":
        if role != "admin":
            return 403, {"error": "forbidden"}
        q = lambda sql, *a: conn.execute(sql, a).fetchone()[0]  # noqa: E731
        week = time.time() - 7 * 86400
        day = time.strftime("%Y-%m-%d")
        schools = set()
        for r in conn.execute("SELECT region, district, school FROM users WHERE role='student'"):
            schools.add(f"{r['region']}|{r['district']}|{r['school']}".lower())
        return 200, {
            "students": q("SELECT COUNT(*) FROM users WHERE role='student'"),
            "teachers": q("SELECT COUNT(*) FROM users WHERE role='teacher'"),
            "schools": len(schools),
            "new_week": q("SELECT COUNT(*) FROM users WHERE role='student' AND created>?", week),
            "active_today": q("SELECT COUNT(DISTINCT user_id) FROM xp_log WHERE day=?", day),
            "attempts_week": q("SELECT COUNT(*) FROM attempts WHERE ts>?", week),
            "orders_new": q("SELECT COUNT(*) FROM orders WHERE status='new'"),
            "lessons": sum(len(v) for v in course_lessons.values()),
            "custom": q("SELECT COUNT(*) FROM clessons WHERE scope='global' AND data!=''"),
            "school_lessons": q("SELECT COUNT(*) FROM clessons WHERE scope='school'"),
            "certs": q("SELECT COUNT(*) FROM certs"),
            "ai": bool(GEMINI_KEY),
            "per_course": {c: len(v) for c, v in course_lessons.items()},
        }
    return None
